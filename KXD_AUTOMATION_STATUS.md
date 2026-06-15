# KXD muammolari bo'yicha avtomatik yechim holati

Ushbu hujjat `KXD_TAA_SCRIPT_YECHIM.md` dagi P1-P5 muammolar TAA loyihasida qaysi script, trigger va action orqali real ishlashini ko'rsatadi.

## Qisqa xulosa

| KXD muammo | Holat | Real ishlaydigan mexanizm |
|---|---|---|
| P1: Port -> IP -> MAC binding va ruxsatsiz qurilma | Real avtomatik | `provision_ports.py`, `port_sec_violation.tcl`, `auto_remediation.py` |
| P2.a: Ichki tarmoqda port-scan/DoS/ruxsatsiz ulanish | Real avtomatik | 3560G port-security/storm-control + TAA trigger/action |
| P2.b: WAN brute-force | Real alert | `wan_brute_detect.tcl` + `edge-rt01 WAN brute xabari` |
| P3: STP loop/halqa | Real avtomatik | `stp_loop_detect.tcl` + TAA STP trigger/action |
| P4: Alert yo'qligi | Real alert | `taa_email.sh`, `taa_telegram.sh`, TAA actionlar |
| P5: IP/MAC/port jurnal | Real yig'ish | `export_binding_hourly.tcl`, `ip_inventory.py` |

## P1 - port binding va ruxsatsiz ulanish

Ishlaydigan qismlar:

- `scripts/provisioning/provision_ports.py` - Catalyst 3560G portlariga port-security, storm-control va DHCP snooping qoidalarini tarqatadi.
- `scripts/network-configs/eem-applets/port_sec_violation.tcl` - `PSECURE_VIOLATION` syslog hodisasini ushlaydi, port/MAC ajratadi va TAA ga trap/syslog yuboradi.
- TAA DB ichida `core-sw01: Port Security violation trap keldi` triggeri bor.
- TAA DB ichida `core-sw01 Port Security xabari` email actioni bor.
- TAA DB ichida `core-sw01 Port Security auto-remediation` actioni yoqilgan.
- `scripts/alertscripts/auto_remediation.py` trap matnidan portni ajratib, shu portni `shutdown` qiladi va `/var/lib/taa/audit.db` ichiga yozadi.

Real action command:

```bash
/usr/lib/zabbix/alertscripts/auto_remediation.py --switch {HOST.IP} --trap-text "{ITEM.LASTVALUE}" --reason "{EVENT.NAME}" --operator "TAA-ACTION"
```

Majburiy environment:

```text
SW_USER
SW_PASS
SW_ENABLE
AUDIT_DB
```

## P2.a - ichki tarmoqda scan/DoS/ruxsatsiz harakat

Ichki segmentdagi muammo 3560G orqali ushlanadi:

- port-security violation;
- storm-control;
- MAC notification;
- EEM trap/syslog.

TAA tomonda P1 bilan bir xil Port Security trigger/action flow ishlaydi. Agar event port-security violationga aylansa, `auto_remediation.py` portni shutdown qiladi.

## P2.b - WAN brute-force

Router tomoni:

```text
scripts/network-configs/eem-applets/wan_brute_detect.tcl
```

Bu applet 60 sekund ichida 5 ta `Authentication failure` aniqlasa:

- `flash:/brute.log` ga diagnostika yozadi;
- `TAA-BRUTE` trap yuboradi;
- `TAA-ALERT` syslog chiqaradi;
- router mail serverga kira olsa, email yuboradi.

TAA tomonda:

```text
Host: edge-rt01
Item: WAN Brute Force Trap
Key: snmptrap[TAA-BRUTE|WAN_BRUTE_DETECT|TAA-ALERT]
Trigger: edge-rt01: WAN brute-force urinishlari aniqlandi
Action: edge-rt01 WAN brute xabari
```

Bu flow router portini o'chirmaydi. U WAN brute-force hodisasini real vaqtda xabar qiladi.

## P3 - STP loop/halqa

Switch tomoni:

```text
scripts/network-configs/eem-applets/stp_loop_detect.tcl
```

Bu applet quyidagilarni ushlaydi:

```text
SPANTREE.*BPDUGUARD
LOOPBACK
BLOCK_PVID
LOOPGUARD
```

Natija:

- port nomini ajratadi;
- `show spanning-tree` diagnostikasini yozadi;
- muammoli portni switchning o'zida `shutdown` qiladi;
- `TAA-LOOP` trap yuboradi;
- `TAA-ALERT` syslog chiqaradi.

TAA tomonda:

```text
Host: core-sw01
Item: STP Topology Change Trap
Trigger: core-sw01: STP topologiya o'zgarishi aniqlandi
Action: core-sw01 STP xabari
```

## P4 - alert yo'qligi

Alert scriptlar:

```text
scripts/alertscripts/taa_email.sh
scripts/alertscripts/taa_telegram.sh
```

Hozir DB ichida email actionlar tayyor:

```text
core-sw01 Port Security xabari
core-sw01 STP xabari
edge-rt01 WAN brute xabari
```

Admin userda placeholder email bor:

```text
admin@example.com
```

Real muhitda uni haqiqiy emailga almashtirish kerak.

## P5 - IP/MAC/port inventarizatsiya

Switch tomoni:

```text
scripts/network-configs/eem-applets/export_binding_hourly.tcl
```

Bu applet TFTP orqali quyidagilarni TAA serverga chiqaradi:

- DHCP snooping binding;
- dynamic MAC table;
- interface status;
- running-config backup.

TAA server tomoni:

```text
scripts/externalscripts/ip_inventory.py
```

Bu script switchdan yoki eksport qilingan fayllardan IP/MAC/port ma'lumotlarini yig'ib DBga yozadi. Real ishlashi uchun `scripts/install.sh`, credentiallar va cron sozlangan bo'lishi kerak.

## Real ishlashi uchun minimal checklist

- [ ] `core-sw01` IP real Catalyst 3560G IPga almashtirilgan.
- [ ] `edge-rt01` IP real Cisco 1800 IPga almashtirilgan.
- [ ] SNMPv3 sozlamalari real qurilmalarga mos.
- [ ] UDP 162 traplar TAA serverga yetib keladi.
- [ ] `scripts/install.sh` bajarilgan yoki scriptlar `/usr/lib/zabbix/alertscripts/` va `/usr/lib/zabbix/externalscripts/` ichida mavjud.
- [ ] `/etc/zabbix/.env` ichida `SW_USER`, `SW_PASS`, `SW_ENABLE`, SMTP/Telegram sekretlari bor.
- [ ] `auto_remediation.py` ishlatadigan switch user cheklangan privilege bilan yaratilgan.
- [ ] `core-sw01 Port Security auto-remediation` actioni enabled.
- [ ] `edge-rt01 WAN brute xabari` actioni enabled.

