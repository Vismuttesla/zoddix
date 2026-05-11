#!/usr/bin/env python3
"""TAA External Check: SNMP trap matnidan port/VLAN/MAC ni ajratib JSON qaytaradi.

Bu skript TAA tomondan ikki xil chaqirilishi mumkin:
  1. Argument orqali:
        stp_loop_parser.py "%SPANTREE-2-BLOCK_PVID: Blocking Gi0/12 on VLAN0030 ..."
  2. Stdin orqali (TAA preprocessing "Script" item bilan):
        echo "<trap matni>" | stp_loop_parser.py

Chiqishi (stdout) — bitta satrli JSON:
    {"port": "...", "vlan": "...", "mac": "...", "severity": "..."}

severity qoidasi:
    - "PSECURE" so'zi -> "CRITICAL"
    - "BPDU" yoki "LOOP" so'zi -> "HIGH"
    - aks holda -> "INFO"

Xatolik bo'lsa, JSON da "error" maydoni qaytadi va exit code 1 bo'ladi.
"""
from __future__ import annotations

import json
import logging
import re
import sys
from typing import Optional


logging.basicConfig(
    level=logging.WARNING,
    format="%(asctime)s [%(levelname)s] stp_loop_parser: %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("stp_loop_parser")


# Port nomi: GigabitEthernet0/5, Gi0/5, Fa0/24, FastEthernet0/24, Te1/0/1
PORT_RE = re.compile(
    r"\b("
    r"GigabitEthernet\d+(?:/\d+){1,2}|"
    r"FastEthernet\d+(?:/\d+){1,2}|"
    r"TenGigabitEthernet\d+(?:/\d+){1,2}|"
    r"Gi\d+(?:/\d+){1,2}|"
    r"Fa\d+(?:/\d+){1,2}|"
    r"Te\d+(?:/\d+){1,2}"
    r")\b",
    re.IGNORECASE,
)

# VLAN: "Vlan30", "VLAN 0030", "vlan: 30", "on VLAN0030"
VLAN_RE = re.compile(r"\bV[Ll][Aa][Nn]\s*[:#]?\s*0*(\d{1,4})\b")

# MAC: cisco-dot format (aabb.ccdd.eeff)
MAC_DOT_RE = re.compile(r"\b([0-9a-fA-F]{4}\.[0-9a-fA-F]{4}\.[0-9a-fA-F]{4})\b")
# MAC: kolon yoki defis (aa:bb:cc:dd:ee:ff yoki aa-bb-cc-dd-ee-ff)
MAC_COLON_RE = re.compile(r"\b([0-9a-fA-F]{2}(?:[:\-][0-9a-fA-F]{2}){5})\b")


def read_input() -> str:
    """Argument bo'lsa shuni, aks holda stdin ni o'qiydi."""
    if len(sys.argv) > 1:
        return " ".join(sys.argv[1:])
    try:
        data = sys.stdin.read()
    except Exception as exc:  # noqa: BLE001
        log.error("Kirishni o'qib bo'lmadi: %s", exc)
        return ""
    return data


def normalize_mac(mac: str) -> str:
    """MAC ni cisco-dot formatga keltiradi (aabb.ccdd.eeff, kichik harf)."""
    cleaned = re.sub(r"[:\-.]", "", mac).lower()
    if len(cleaned) != 12:
        return mac.lower()
    return f"{cleaned[0:4]}.{cleaned[4:8]}.{cleaned[8:12]}"


def detect_severity(text: str) -> str:
    """Trap matnidagi kalit so'zlardan severity aniqlaydi."""
    upper = text.upper()
    if "PSECURE" in upper:
        return "CRITICAL"
    if "BPDU" in upper or "LOOP" in upper:
        return "HIGH"
    return "INFO"


def parse_trap(raw: str) -> dict[str, Optional[str]]:
    """Trap matnini parse qilib lug'at qaytaradi."""
    port_m = PORT_RE.search(raw)
    vlan_m = VLAN_RE.search(raw)

    mac_m = MAC_DOT_RE.search(raw)
    mac_value: Optional[str] = None
    if mac_m:
        mac_value = normalize_mac(mac_m.group(1))
    else:
        mac_m2 = MAC_COLON_RE.search(raw)
        if mac_m2:
            mac_value = normalize_mac(mac_m2.group(1))

    return {
        "port": port_m.group(1) if port_m else None,
        "vlan": vlan_m.group(1) if vlan_m else None,
        "mac": mac_value,
        "severity": detect_severity(raw),
    }


def main() -> int:
    """Asosiy kirish nuqtasi."""
    raw = read_input().strip()
    if not raw:
        # Bo'sh kirishda ham TAA uchun JSON qaytaramiz
        sys.stdout.write(
            json.dumps(
                {
                    "port": None,
                    "vlan": None,
                    "mac": None,
                    "severity": "INFO",
                    "error": "empty input",
                }
            )
            + "\n"
        )
        return 1

    try:
        result = parse_trap(raw)
    except re.error as exc:
        log.error("Regex xatosi: %s", exc)
        sys.stdout.write(
            json.dumps(
                {
                    "port": None,
                    "vlan": None,
                    "mac": None,
                    "severity": "INFO",
                    "error": f"regex: {exc}",
                }
            )
            + "\n"
        )
        return 1

    sys.stdout.write(json.dumps(result, ensure_ascii=False) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
