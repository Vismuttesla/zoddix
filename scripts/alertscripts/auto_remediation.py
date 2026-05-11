#!/usr/bin/env python3
"""TAA avtomatik remediation skripti.

Vazifasi:
    TAA action triggeri (masalan, port-security violation yoki STP loop)
    chaqirganda Catalyst 3560G kommutatorda muammoli portni `shutdown`
    qilib, hodisani SQLite audit jurnaliga yozib qo'yadi.

Foydalanish:
    auto_remediation.py --switch 10.0.99.2 --port Gi0/5 --reason "PSEC_VIOLATION"

Muhit o'zgaruvchilari (env):
    SW_USER     - kommutator foydalanuvchi nomi (majburiy)
    SW_PASS     - kommutator paroli (majburiy)
    SW_ENABLE   - enable rejimi paroli (ixtiyoriy; agar yo'q bo'lsa,
                  enable secret'siz ulanish urinadi)
    AUDIT_DB    - SQLite audit DB yo'li (ixtiyoriy,
                  default: /var/lib/taa/audit.db)

Chiqish kodlari:
    0 - muvaffaqiyatli
    2 - argument/konfiguratsiya xatosi
    3 - kommutatorga ulanish xatosi
    4 - DB yozish xatosi
"""
from __future__ import annotations

import argparse
import datetime as dt
import logging
import os
import sqlite3
import sys
from pathlib import Path
from typing import Optional

try:
    from netmiko import ConnectHandler
    from netmiko.exceptions import NetmikoAuthenticationException, NetmikoTimeoutException
except ImportError as exc:  # pragma: no cover - import xatosini aniq ko'rsatish
    sys.stderr.write(
        "XATO: 'netmiko' kutubxonasi o'rnatilmagan. "
        "Iltimos, quyidagini bajaring: pip install -r scripts/requirements.txt\n"
    )
    raise SystemExit(2) from exc


# Loglar stderr ga yoziladi (stdout ni TAA natijaviy matn uchun qoldiramiz)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] auto_remediation: %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("auto_remediation")


DEFAULT_DB_PATH = "/var/lib/taa/audit.db"


def parse_args() -> argparse.Namespace:
    """CLI argumentlarni o'qiydi."""
    parser = argparse.ArgumentParser(
        description="TAA: violation bo'lgan portni avtomatik shutdown qilish.",
    )
    parser.add_argument(
        "--switch",
        required=True,
        help="Kommutator IP manzili (masalan, 10.0.99.2)",
    )
    parser.add_argument(
        "--port",
        required=True,
        help="Port nomi (masalan, Gi0/5 yoki GigabitEthernet0/5)",
    )
    parser.add_argument(
        "--reason",
        required=True,
        help="Bloklash sababi (audit jurnali uchun)",
    )
    parser.add_argument(
        "--operator",
        default="TAA-AUTO",
        help="Audit jurnalida operator nomi (default: TAA-AUTO)",
    )
    return parser.parse_args()


def get_credentials() -> tuple[str, str, Optional[str]]:
    """SW_USER / SW_PASS / SW_ENABLE muhit o'zgaruvchilarini o'qiydi."""
    user = os.environ.get("SW_USER")
    password = os.environ.get("SW_PASS")
    enable_secret = os.environ.get("SW_ENABLE")  # ixtiyoriy

    if not user or not password:
        log.error(
            "SW_USER va SW_PASS muhit o'zgaruvchilari sozlanmagan. "
            "Iltimos, /etc/zabbix/.env faylida ularni belgilang."
        )
        sys.exit(2)

    if not enable_secret:
        log.warning(
            "SW_ENABLE belgilanmagan — enable rejimi parolisiz davom etiladi "
            "(failsafe rejim)."
        )

    return user, password, enable_secret


def shutdown_port(
    switch_ip: str,
    port: str,
    reason: str,
    username: str,
    password: str,
    enable_secret: Optional[str],
) -> None:
    """netmiko orqali kommutatorga ulanib portni shutdown qiladi."""
    timestamp_iso = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

    device: dict[str, object] = {
        "device_type": "cisco_ios",
        "host": switch_ip,
        "username": username,
        "password": password,
        # Ulanish vaqti uchun mantiqiy timeout
        "conn_timeout": 15,
        "fast_cli": False,
    }
    if enable_secret:
        device["secret"] = enable_secret

    log.info("Kommutatorga ulanmoqda: %s", switch_ip)
    try:
        conn = ConnectHandler(**device)
    except NetmikoAuthenticationException:
        log.error(
            "Autentifikatsiya xatosi: SW_USER/SW_PASS noto'g'ri yoki "
            "foydalanuvchi privilege darajasi yetarli emas."
        )
        sys.exit(3)
    except NetmikoTimeoutException:
        log.error(
            "Ulanish vaqti tugadi: %s ga SSH/Telnet orqali ulanib bo'lmadi. "
            "Tarmoq yoki ACL sozlamalarini tekshiring.",
            switch_ip,
        )
        sys.exit(3)
    except Exception as exc:  # noqa: BLE001 - umumiy xatoni ko'rsatish kerak
        log.error("Kutilmagan ulanish xatosi: %s", exc)
        sys.exit(3)

    try:
        if enable_secret:
            conn.enable()

        # Konfiguratsiya buyruqlari ro'yxati
        # Tavsifda ' va " bo'lishi mumkin — ularni xavfsizroq belgi bilan almashtiramiz.
        safe_reason = reason.replace('"', "'")[:80]
        config_cmds = [
            f"interface {port}",
            f"description AUTO-BLOCKED {safe_reason} {timestamp_iso}",
            "shutdown",
        ]
        log.info("Buyruqlar yuborilmoqda: %s", config_cmds)
        output = conn.send_config_set(config_cmds)
        log.debug("Kommutator javobi:\n%s", output)
    finally:
        conn.disconnect()

    log.info("%s portida shutdown bajarildi (sabab: %s)", port, reason)


def write_audit(
    db_path: str,
    switch_ip: str,
    port: str,
    reason: str,
    operator: str,
) -> None:
    """Hodisani SQLite audit jurnaliga yozadi."""
    timestamp_iso = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

    # DB papkasi mavjudligini ta'minlash
    db_dir = Path(db_path).parent
    try:
        db_dir.mkdir(parents=True, exist_ok=True)
    except PermissionError:
        log.error(
            "Audit DB papkasini yaratib bo'lmadi: %s. "
            "Iltimos, papka huquqlarini tekshiring yoki AUDIT_DB ni o'zgartiring.",
            db_dir,
        )
        sys.exit(4)

    try:
        db = sqlite3.connect(db_path, timeout=10)
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS blocks (
                ts        TEXT NOT NULL,
                switch    TEXT NOT NULL,
                port      TEXT NOT NULL,
                reason    TEXT NOT NULL,
                operator  TEXT NOT NULL
            )
            """
        )
        db.execute(
            "INSERT INTO blocks (ts, switch, port, reason, operator) VALUES (?, ?, ?, ?, ?)",
            (timestamp_iso, switch_ip, port, reason, operator),
        )
        db.commit()
        db.close()
    except sqlite3.Error as exc:
        log.error("Audit DB ga yozishda xato: %s", exc)
        sys.exit(4)

    log.info("Audit jurnaliga yozildi: %s", db_path)


def main() -> int:
    """Asosiy kirish nuqtasi."""
    args = parse_args()
    db_path = os.environ.get("AUDIT_DB", DEFAULT_DB_PATH)

    user, password, enable_secret = get_credentials()

    shutdown_port(
        switch_ip=args.switch,
        port=args.port,
        reason=args.reason,
        username=user,
        password=password,
        enable_secret=enable_secret,
    )

    write_audit(
        db_path=db_path,
        switch_ip=args.switch,
        port=args.port,
        reason=args.reason,
        operator=args.operator,
    )

    # TAA Action uchun qisqa muvaffaqiyat xabari (stdout)
    print(f"OK: {args.switch} {args.port} shutdown ({args.reason})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
