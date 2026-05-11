#!/usr/bin/env python3
"""TAA IP inventarini Catalyst 3560G dan yig'uvchi skript.

Vazifasi:
    Catalyst 3560G kommutatordan quyidagi buyruqlarni o'qiydi:
        - show ip dhcp snooping binding
        - show mac address-table dynamic
    Natijalarni parse qilib, SQLite yoki PostgreSQL bazasidagi
    `leases` jadvaliga UPSERT (mavjud bo'lsa update, yo'q bo'lsa insert)
    qiladi. Ixtiyoriy ravishda eski yozuvlarni tozalaydi.

Foydalanish:
    ip_inventory.py --switch 10.0.99.2 --backend sqlite \
                    --db /var/lib/taa/ipam.db
    ip_inventory.py --switch 10.0.99.2 --backend postgres \
                    --db "host=10.0.10.10 dbname=taa_ipam user=taa"
    ip_inventory.py --switch 10.0.99.2 --purge-days 30

Muhit o'zgaruvchilari:
    SW_USER   - kommutator foydalanuvchi nomi (majburiy)
    SW_PASS   - kommutator paroli (majburiy)
    IPAM_DSN  - PostgreSQL DSN (--db berilmasa, postgres uchun fallback)

Stdout — JSON: {"upserts": <int>, "purged": <int>, "switch": "<ip>"}
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import logging
import os
import re
import sqlite3
import sys
from pathlib import Path
from typing import Optional


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] ip_inventory: %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("ip_inventory")


# DHCP snooping binding satri (Cisco IOS):
#   MacAddress          IpAddress        Lease(sec)  Type           VLAN  Interface
#   00:1A:2B:3C:4D:5E   10.0.30.45       86310       dhcp-snooping  30    GigabitEthernet0/5
BINDING_RE = re.compile(
    r"([0-9a-fA-F]{2}(?:[:\-][0-9a-fA-F]{2}){5})\s+"
    r"(\d{1,3}(?:\.\d{1,3}){3})\s+"
    r"\d+\s+"
    r"\S+\s+"
    r"(\d+)\s+"
    r"(\S+)",
)

# MAC address-table dynamic satri:
#   Vlan    Mac Address       Type        Ports
#    30    0011.2233.4455    DYNAMIC     Gi0/5
MAC_TABLE_RE = re.compile(
    r"^\s*(\d{1,4})\s+([0-9a-fA-F]{4}\.[0-9a-fA-F]{4}\.[0-9a-fA-F]{4})\s+\S+\s+(\S+)",
    re.MULTILINE,
)


try:
    from netmiko import ConnectHandler
    from netmiko.exceptions import NetmikoAuthenticationException, NetmikoTimeoutException
except ImportError as exc:  # pragma: no cover
    sys.stderr.write(
        "XATO: 'netmiko' kutubxonasi o'rnatilmagan. "
        "Iltimos: pip install -r scripts/requirements.txt\n"
    )
    raise SystemExit(2) from exc


def parse_args() -> argparse.Namespace:
    """CLI argumentlarni o'qiydi."""
    parser = argparse.ArgumentParser(
        description="TAA: Catalyst 3560G dan IP/MAC inventarini yig'ish.",
    )
    parser.add_argument(
        "--switch",
        required=True,
        help="Kommutator IP manzili (masalan, 10.0.99.2)",
    )
    parser.add_argument(
        "--backend",
        choices=("sqlite", "postgres"),
        default="sqlite",
        help="DB backend turi (default: sqlite)",
    )
    parser.add_argument(
        "--db",
        default=None,
        help=(
            "SQLite uchun fayl yo'li (default: /var/lib/taa/ipam.db) "
            "yoki PostgreSQL DSN (IPAM_DSN env qo'llaniladi, agar berilmasa)"
        ),
    )
    parser.add_argument(
        "--purge-days",
        type=int,
        default=0,
        help="Berilgan kundan ortiq ko'rinmagan yozuvlarni o'chirish (0 = o'chirilmasin)",
    )
    return parser.parse_args()


def normalize_mac(mac: str) -> str:
    """MAC ni cisco-dot formatga keltiradi (kichik harf)."""
    cleaned = re.sub(r"[:\-.]", "", mac).lower()
    if len(cleaned) != 12:
        return mac.lower()
    return f"{cleaned[0:4]}.{cleaned[4:8]}.{cleaned[8:12]}"


def get_credentials() -> tuple[str, str]:
    """SW_USER va SW_PASS env'larini o'qiydi."""
    user = os.environ.get("SW_USER")
    password = os.environ.get("SW_PASS")
    if not user or not password:
        log.error(
            "SW_USER va SW_PASS muhit o'zgaruvchilari sozlanmagan. "
            "Iltimos, /etc/zabbix/.env faylida ularni belgilang."
        )
        sys.exit(2)
    return user, password


def fetch_from_switch(switch_ip: str, user: str, password: str) -> tuple[str, str]:
    """3560G dan show buyruqlarini chiqaradi."""
    device = {
        "device_type": "cisco_ios",
        "host": switch_ip,
        "username": user,
        "password": password,
        "conn_timeout": 15,
        "fast_cli": False,
    }
    log.info("Kommutatorga ulanmoqda: %s", switch_ip)
    try:
        conn = ConnectHandler(**device)
    except NetmikoAuthenticationException:
        log.error("Autentifikatsiya xatosi (SW_USER/SW_PASS noto'g'ri).")
        sys.exit(3)
    except NetmikoTimeoutException:
        log.error("Kommutatorga ulanish vaqti tugadi: %s", switch_ip)
        sys.exit(3)
    except Exception as exc:  # noqa: BLE001
        log.error("Kutilmagan ulanish xatosi: %s", exc)
        sys.exit(3)

    try:
        binding = conn.send_command("show ip dhcp snooping binding", read_timeout=30)
        mactab = conn.send_command("show mac address-table dynamic", read_timeout=30)
    finally:
        conn.disconnect()
    return binding, mactab


def parse_binding(text: str) -> list[dict[str, object]]:
    """DHCP snooping binding natijasini parse qiladi."""
    rows: list[dict[str, object]] = []
    for mac, ip, vlan, port in BINDING_RE.findall(text):
        rows.append(
            {
                "mac": normalize_mac(mac),
                "ip": ip,
                "vlan": int(vlan),
                "port": port,
            }
        )
    return rows


def parse_mac_table(text: str) -> dict[str, dict[str, object]]:
    """MAC jadval natijasini parse qiladi (MAC -> {vlan, port})."""
    result: dict[str, dict[str, object]] = {}
    for vlan, mac, port in MAC_TABLE_RE.findall(text):
        result[normalize_mac(mac)] = {"vlan": int(vlan), "port": port}
    return result


def merge_rows(
    binding_rows: list[dict[str, object]],
    mac_rows: dict[str, dict[str, object]],
) -> list[dict[str, object]]:
    """DHCP binding ni asos qilib, MAC jadvali bilan to'ldiradi.

    DHCP binding'da yo'q, lekin MAC jadvalda bor MAC'lar ham qo'shiladi
    (ip = None bilan), shunda IP'siz qurilmalar ham ko'rinadi.
    """
    merged: dict[str, dict[str, object]] = {}
    for row in binding_rows:
        merged[str(row["mac"])] = dict(row)

    for mac, info in mac_rows.items():
        if mac in merged:
            # binding ustun; ammo port ma'lumotini yangilab qo'yamiz
            if not merged[mac].get("port"):
                merged[mac]["port"] = info["port"]
            continue
        merged[mac] = {
            "mac": mac,
            "ip": None,
            "vlan": info["vlan"],
            "port": info["port"],
        }
    return list(merged.values())


# ---------------------------------------------------------------------------
# DB qatlamlari
# ---------------------------------------------------------------------------

def _now_iso() -> str:
    return dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"


def upsert_sqlite(
    db_path: str,
    switch_ip: str,
    rows: list[dict[str, object]],
    purge_days: int,
) -> tuple[int, int]:
    """SQLite ga UPSERT va purge bajaradi."""
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    now = _now_iso()

    upserts = 0
    purged = 0

    db = sqlite3.connect(db_path, timeout=10)
    try:
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS leases (
                mac        TEXT PRIMARY KEY,
                ip         TEXT,
                vlan       INTEGER,
                port       TEXT,
                switch     TEXT,
                first_seen TEXT,
                last_seen  TEXT
            )
            """
        )
        for row in rows:
            db.execute(
                """
                INSERT INTO leases (mac, ip, vlan, port, switch, first_seen, last_seen)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(mac) DO UPDATE SET
                    ip = COALESCE(excluded.ip, leases.ip),
                    vlan = excluded.vlan,
                    port = excluded.port,
                    switch = excluded.switch,
                    last_seen = excluded.last_seen
                """,
                (
                    row["mac"],
                    row.get("ip"),
                    row.get("vlan"),
                    row.get("port"),
                    switch_ip,
                    now,
                    now,
                ),
            )
            upserts += 1

        if purge_days > 0:
            cutoff = (
                dt.datetime.utcnow() - dt.timedelta(days=purge_days)
            ).replace(microsecond=0).isoformat() + "Z"
            cur = db.execute("DELETE FROM leases WHERE last_seen < ?", (cutoff,))
            purged = cur.rowcount or 0

        db.commit()
    except sqlite3.Error as exc:
        log.error("SQLite xatosi: %s", exc)
        sys.exit(4)
    finally:
        db.close()

    return upserts, purged


def upsert_postgres(
    dsn: str,
    switch_ip: str,
    rows: list[dict[str, object]],
    purge_days: int,
) -> tuple[int, int]:
    """PostgreSQL ga UPSERT va purge bajaradi."""
    try:
        import psycopg2  # type: ignore
    except ImportError as exc:
        log.error(
            "psycopg2 o'rnatilmagan. Iltimos: pip install -r scripts/requirements.txt"
        )
        raise SystemExit(2) from exc

    now = _now_iso()
    upserts = 0
    purged = 0

    try:
        conn = psycopg2.connect(dsn)
    except Exception as exc:  # noqa: BLE001
        log.error("PostgreSQL ga ulanib bo'lmadi: %s", exc)
        sys.exit(4)

    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS leases (
                        mac        TEXT PRIMARY KEY,
                        ip         TEXT,
                        vlan       INTEGER,
                        port       TEXT,
                        switch     TEXT,
                        first_seen TIMESTAMPTZ DEFAULT now(),
                        last_seen  TIMESTAMPTZ DEFAULT now()
                    )
                    """
                )
                for row in rows:
                    cur.execute(
                        """
                        INSERT INTO leases (mac, ip, vlan, port, switch, first_seen, last_seen)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (mac) DO UPDATE SET
                            ip = COALESCE(EXCLUDED.ip, leases.ip),
                            vlan = EXCLUDED.vlan,
                            port = EXCLUDED.port,
                            switch = EXCLUDED.switch,
                            last_seen = EXCLUDED.last_seen
                        """,
                        (
                            row["mac"],
                            row.get("ip"),
                            row.get("vlan"),
                            row.get("port"),
                            switch_ip,
                            now,
                            now,
                        ),
                    )
                    upserts += 1

                if purge_days > 0:
                    cur.execute(
                        "DELETE FROM leases WHERE last_seen < now() - INTERVAL '%s days'"
                        % int(purge_days)
                    )
                    purged = cur.rowcount or 0
    finally:
        conn.close()

    return upserts, purged


def main() -> int:
    """Asosiy kirish nuqtasi."""
    args = parse_args()
    user, password = get_credentials()

    binding_text, mactab_text = fetch_from_switch(args.switch, user, password)
    log.info(
        "Olingan natija: binding=%d bayt, mac-table=%d bayt",
        len(binding_text),
        len(mactab_text),
    )

    binding_rows = parse_binding(binding_text)
    mac_rows = parse_mac_table(mactab_text)
    merged = merge_rows(binding_rows, mac_rows)
    log.info(
        "Parse: binding=%d, mac-table=%d, jami unique MAC=%d",
        len(binding_rows),
        len(mac_rows),
        len(merged),
    )

    if args.backend == "sqlite":
        db_path = args.db or "/var/lib/taa/ipam.db"
        upserts, purged = upsert_sqlite(
            db_path=db_path,
            switch_ip=args.switch,
            rows=merged,
            purge_days=args.purge_days,
        )
    else:  # postgres
        dsn: Optional[str] = args.db or os.environ.get("IPAM_DSN")
        if not dsn:
            log.error(
                "PostgreSQL backend uchun --db yoki IPAM_DSN env "
                "(masalan: 'host=... dbname=... user=... password=...') belgilanishi shart."
            )
            sys.exit(2)
        upserts, purged = upsert_postgres(
            dsn=dsn,
            switch_ip=args.switch,
            rows=merged,
            purge_days=args.purge_days,
        )

    result = {
        "upserts": upserts,
        "purged": purged,
        "switch": args.switch,
        "backend": args.backend,
    }
    sys.stdout.write(json.dumps(result, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
