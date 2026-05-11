#!/usr/bin/env python3
"""TAA — Catalyst 3560G ko'p portli port-security provisioning skripti.

Vazifasi:
    Inventory YAML faylidan port konfiguratsiyalarini o'qib,
    Jinja2 template (`interface_template.j2`) orqali har bir port
    uchun Cisco IOS konfiguratsiya bloklarini hosil qiladi va
    netmiko orqali kommutatorga yuboradi.

Foydalanish:
    # Faqat ko'rib chiqish (push qilinmaydi):
    provision_ports.py --inventory inventory.yaml --switch 10.0.99.2 --dry-run

    # Haqiqiy push:
    provision_ports.py --inventory inventory.yaml --switch 10.0.99.2 --commit

Muhit o'zgaruvchilari:
    SW_USER    - kommutator foydalanuvchi nomi (majburiy)
    SW_PASS    - kommutator paroli (majburiy)
    SW_ENABLE  - enable secret (ixtiyoriy)

Chiqish kodlari:
    0 - muvaffaqiyatli
    2 - argument/konfiguratsiya xatosi
    3 - kommutatorga ulanish/push xatosi
"""
from __future__ import annotations

import argparse
import difflib
import logging
import os
import sys
from pathlib import Path
from typing import Optional

try:
    import yaml
except ImportError as exc:  # pragma: no cover
    sys.stderr.write(
        "XATO: 'pyyaml' o'rnatilmagan. Iltimos: pip install -r scripts/requirements.txt\n"
    )
    raise SystemExit(2) from exc

try:
    from jinja2 import Environment, FileSystemLoader, StrictUndefined, TemplateError
except ImportError as exc:  # pragma: no cover
    sys.stderr.write(
        "XATO: 'jinja2' o'rnatilmagan. Iltimos: pip install -r scripts/requirements.txt\n"
    )
    raise SystemExit(2) from exc

try:
    from netmiko import ConnectHandler
    from netmiko.exceptions import NetmikoAuthenticationException, NetmikoTimeoutException
except ImportError as exc:  # pragma: no cover
    sys.stderr.write(
        "XATO: 'netmiko' o'rnatilmagan. Iltimos: pip install -r scripts/requirements.txt\n"
    )
    raise SystemExit(2) from exc


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] provision_ports: %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("provision_ports")


TEMPLATE_NAME = "interface_template.j2"


def parse_args() -> argparse.Namespace:
    """CLI argumentlarni o'qiydi."""
    parser = argparse.ArgumentParser(
        description="TAA: Catalyst 3560G port-security provisioning.",
    )
    parser.add_argument(
        "--inventory",
        required=True,
        help="Inventory YAML fayli yo'li (masalan, inventory.yaml)",
    )
    parser.add_argument(
        "--switch",
        required=True,
        help="Kommutator IP manzili",
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Faqat konfiguratsiyani ko'rsat, kommutatorga push qilma",
    )
    mode.add_argument(
        "--commit",
        action="store_true",
        help="Konfiguratsiyani kommutatorga push qil",
    )
    return parser.parse_args()


def get_credentials() -> tuple[str, str, Optional[str]]:
    """SW_USER, SW_PASS, SW_ENABLE env'larini o'qiydi."""
    user = os.environ.get("SW_USER")
    password = os.environ.get("SW_PASS")
    enable = os.environ.get("SW_ENABLE")
    if not user or not password:
        log.error(
            "SW_USER va SW_PASS muhit o'zgaruvchilari sozlanmagan. "
            "Iltimos, ularni belgilang (masalan, /etc/zabbix/.env)."
        )
        sys.exit(2)
    return user, password, enable


def load_inventory(path: str) -> list[dict[str, object]]:
    """Inventory YAML ni o'qib, validatsiya qiladi."""
    p = Path(path)
    if not p.is_file():
        log.error("Inventory fayli topilmadi: %s", path)
        sys.exit(2)

    try:
        with p.open("r", encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        log.error("YAML parse xatosi: %s", exc)
        sys.exit(2)

    if not isinstance(data, dict) or "ports" not in data:
        log.error(
            "Inventory fayli noto'g'ri formatda. Yuqori darajada 'ports:' "
            "ro'yxati bo'lishi kerak."
        )
        sys.exit(2)

    ports = data["ports"]
    if not isinstance(ports, list) or not ports:
        log.error("'ports' bo'sh yoki ro'yxat emas.")
        sys.exit(2)

    # Har bir port uchun minimal validatsiya
    for idx, port in enumerate(ports):
        if not isinstance(port, dict):
            log.error("ports[%d] lug'at emas.", idx)
            sys.exit(2)
        if "interface" not in port:
            log.error("ports[%d] da 'interface' maydoni yo'q.", idx)
            sys.exit(2)
        if "vlan" not in port:
            log.error(
                "ports[%d] (%s) da 'vlan' maydoni yo'q.",
                idx,
                port.get("interface"),
            )
            sys.exit(2)

    return ports


def render_config(ports: list[dict[str, object]]) -> str:
    """Jinja2 template orqali har bir port uchun config matnini hosil qiladi."""
    template_dir = Path(__file__).resolve().parent
    env = Environment(
        loader=FileSystemLoader(str(template_dir)),
        undefined=StrictUndefined,
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )

    template_path = template_dir / TEMPLATE_NAME
    if not template_path.is_file():
        log.error(
            "Template topilmadi: %s. Iltimos, %s faylini shu papkaga joylashtiring.",
            template_path,
            TEMPLATE_NAME,
        )
        sys.exit(2)

    template = env.get_template(TEMPLATE_NAME)
    blocks: list[str] = []
    for port in ports:
        try:
            rendered = template.render(**port)
        except TemplateError as exc:
            log.error(
                "Template render xatosi (%s): %s",
                port.get("interface", "?"),
                exc,
            )
            sys.exit(2)
        blocks.append(rendered)
    return "\n".join(blocks)


def fetch_running_for_ports(
    conn,  # ConnectHandler
    ports: list[dict[str, object]],
) -> str:
    """Kommutatordan har bir port uchun mavjud running-config ni o'qiydi."""
    parts: list[str] = []
    for port in ports:
        ifname = port["interface"]
        try:
            out = conn.send_command(
                f"show running-config interface {ifname}",
                read_timeout=30,
            )
        except Exception as exc:  # noqa: BLE001
            log.warning("'%s' uchun running-config olinmadi: %s", ifname, exc)
            out = ""
        parts.append(f"! ---- {ifname} ----\n{out.strip()}\n")
    return "\n".join(parts)


def show_diff(before: str, after: str) -> None:
    """Eski va yangi config orasidagi diff ni stdout ga chiqaradi."""
    diff = difflib.unified_diff(
        before.splitlines(),
        after.splitlines(),
        fromfile="before (running-config)",
        tofile="after (rendered)",
        lineterm="",
    )
    diff_text = "\n".join(diff)
    if diff_text:
        sys.stdout.write(diff_text + "\n")
    else:
        sys.stdout.write("(diff bo'sh — o'zgarish yo'q yoki running-config o'qilmadi)\n")


def push_config(
    switch_ip: str,
    config_text: str,
    user: str,
    password: str,
    enable: Optional[str],
    ports: list[dict[str, object]],
) -> None:
    """netmiko orqali konfiguratsiyani kommutatorga yuboradi."""
    device: dict[str, object] = {
        "device_type": "cisco_ios",
        "host": switch_ip,
        "username": user,
        "password": password,
        "conn_timeout": 15,
        "fast_cli": False,
    }
    if enable:
        device["secret"] = enable

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
        if enable:
            conn.enable()

        # Push'dan oldin "before" snapshot
        before = fetch_running_for_ports(conn, ports)

        # Konfiguratsiyani satrlarga ajratib send_config_set ga beramiz.
        # Bo'sh satrlar va izoh ('!') satrlarini olib tashlaymiz.
        cmds = [
            line.rstrip()
            for line in config_text.splitlines()
            if line.strip() and not line.strip().startswith("!")
        ]
        log.info("Push qilinayotgan buyruqlar soni: %d", len(cmds))
        output = conn.send_config_set(cmds, read_timeout=60)
        log.debug("Kommutator javobi:\n%s", output)

        # Saqlash (opsional, lekin tavsiya etiladi)
        try:
            conn.save_config()
            log.info("running-config -> startup-config saqlandi.")
        except Exception as exc:  # noqa: BLE001
            log.warning("Konfiguratsiyani saqlashda xato: %s", exc)

        # Push'dan keyin "after" snapshot va diff
        after = fetch_running_for_ports(conn, ports)
        show_diff(before, after)
    finally:
        conn.disconnect()


def main() -> int:
    """Asosiy kirish nuqtasi."""
    args = parse_args()
    ports = load_inventory(args.inventory)
    log.info("Inventory dan o'qildi: %d ta port", len(ports))

    config_text = render_config(ports)

    if args.dry_run:
        # Dry-run rejimda: hosil qilingan config'ni stdout ga chiqaramiz.
        sys.stdout.write("===== RENDERED CONFIG (dry-run) =====\n")
        sys.stdout.write(config_text)
        sys.stdout.write("===== END =====\n")
        log.info("Dry-run: kommutatorga hech narsa push qilinmadi.")
        return 0

    # --commit
    user, password, enable = get_credentials()
    push_config(
        switch_ip=args.switch,
        config_text=config_text,
        user=user,
        password=password,
        enable=enable,
        ports=ports,
    )
    log.info("Provisioning yakunlandi: %s", args.switch)
    return 0


if __name__ == "__main__":
    sys.exit(main())
