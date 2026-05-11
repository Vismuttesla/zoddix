# TAA `scripts/` — KXD muammolarini yechish to'plami

Bu papka **KXD muammolari** hujjatida keltirilgan 5 ta amaliy tarmoq xavfsizlik muammosini quyidagi to'rt qurilma sherikligida hal qiluvchi barcha skript, konfiguratsiya va hujjatlarni o'z ichiga oladi:

| Rol | Qurilma | Tarmoqdagi vazifasi |
|-----|---------|---------------------|
| Server | **HP ProLiant DL-160 Gen9** | TAA (Linux + Docker), barcha alert/inventory skriptlari shu yerda |
| L3 Switch | **Cisco Catalyst 3560G 48-port** | Port-security, DHCP snooping, ARP inspection, EEM applet'lar, SNMP trap manbasi |
| Router | **Cisco 1800 series** | WAN/NAT, EEM applet bilan brute force va CPU monitoring |
| L1 Switch | **TP-Link TL-SF 1024D** | Unmanaged. **Skript yozib bo'lmaydi.** 3560G uplinkda cheklanadi |

Yechimning to'liq strategik xaritasi va asoslari uchun loyiha ildizida joylashgan [`KXD_TAA_SCRIPT_YECHIM.md`](../KXD_TAA_SCRIPT_YECHIM.md) ga qarang. Ushbu `scripts/` papkasi shu hujjatning **amaliy ko'rinishi** — har bir bo'lim u yerdagi muvofiq raqamga (P1..P5) ishora qiladi.

---

## 1. Papka tuzilmasi

```
scripts/
├── alertscripts/       # TAA media type / action skriptlari (Telegram, auto-remediation)
├── externalscripts/    # TAA External Check skriptlari (SNMP trap parser, inventory poller)
├── provisioning/       # Catalyst 3560G portlarini avtomatik provisioning (netmiko + Jinja2)
├── network-configs/    # Cisco IOS baseline config'lar va EEM applet shablonlari
├── sql/                # IPAM (Postgres) database schemasi va seed migratsiyalari
├── docker/             # phpIPAM va boshqa qo'shimcha xizmatlar uchun compose fragmentlari
└── docs/               # Setup, validatsiya va xavfsizlik bo'yicha to'liq yo'riqnomalar
    ├── setup.md
    ├── validation.md
    └── security.md
```

> **Eslatma**: `sql/` va `docker/` papkalari hujjatda rejalashtirilgan bo'lib, P5 (IP jurnal) ni to'liq IPAM darajasiga ko'tarmoqchi bo'lganlar uchun. Minimal o'rnatishda `alertscripts/`, `externalscripts/`, `provisioning/`, `network-configs/` yetarli.

---

## 2. Tezkor boshlash (Quick start) — 5 qadam

Quyidagi oqim **toza apparat** (yangi DL-160 + zavod sozlamalaridagi 3560G va 1800) bilan ishlovchi tarmoq admin uchun yozilgan.

### Qadam 1 — DL-160 Gen9 tayyorlash

```bash
# Ubuntu 22.04 LTS o'rnatildi, IP 10.0.10.10/24, gateway 10.0.10.1.
# Asosiy paketlar va Docker:
sudo apt update && sudo apt install -y docker.io docker-compose-plugin \
    python3-pip tftpd-hpa snmptrapd
sudo pip3 install netmiko psycopg2-binary jinja2 pyyaml
cd /opt && sudo git clone <ushbu repo> taa && cd taa
sudo docker compose up -d
# TAA web UI: http://10.0.10.10  (login: Admin / parol: zabbix dastlab)
```

To'liq yo'riqnoma: [`docs/setup.md`](docs/setup.md).

### Qadam 2 — Catalyst 3560G baseline push (TFTP)

```bash
# DL-160 da TFTP root: /srv/tftp
sudo cp scripts/network-configs/3560g_baseline.cfg /srv/tftp/
# 3560G konsoldan:
#   copy tftp://10.0.10.10/3560g_baseline.cfg running-config
#   write memory
```

EEM applet'larni (PORT_SEC_VIOLATION, STP_LOOP_DETECT, EXPORT_BINDING_HOURLY) qo'lda paste qilish kerak, chunki ular `!` va `event` qatorlari bilan IOS parser uchun maxsus. Shabloni: `scripts/network-configs/eem_applets.txt`.

### Qadam 3 — Cisco 1800 baseline push

```bash
sudo cp scripts/network-configs/cisco1800_baseline.cfg /srv/tftp/
# Routerda:
#   copy tftp://10.0.10.10/cisco1800_baseline.cfg running-config
#   write memory
```

### Qadam 4 — TAA UI sozlash

TAA web UI ga kiring (http://10.0.10.10) va quyidagilarni yarating:

1. **Hostlar**: `core-sw01` (3560G, SNMPv3), `edge-rt01` (1800, SNMPv3), `tp-link-edge` (faqat ICMP), `taa-server` (Linux agent).
2. **Media types**: `Telegram-custom` → Script: `taa_telegram.sh`.
3. **Actions**: "Network critical events" → Operation: Telegram + Remote command (`auto_remediation.py`).
4. **Network discovery**: `10.0.10.0/24`, `10.0.20.0/24`, `10.0.30.0/24`.

Batafsil: [`docs/setup.md`](docs/setup.md) — 7..12-qadamlar.

### Qadam 5 — Test va validatsiya

```bash
# Begona MAC bilan user portga ulanib P1 ni tekshirish;
# patch-kord bilan loop yaratib P3 ni tekshirish;
# nmap bilan port-scan urinishi P2 ni tekshirish;
# psql orqali inventarni P5 da ko'rish.
```

Har bir test bo'yicha batafsil yo'riqnoma — [`docs/validation.md`](docs/validation.md).

---

## 3. Apparat ro'yxati va versiyalar

| # | Apparat | Versiya / IOS | Tarmoqdagi IP | Boshqaruv interfeysi |
|---|---------|---------------|---------------|----------------------|
| 1 | HP ProLiant DL-160 Gen9 | Ubuntu 22.04 LTS, Docker 24.x, TAA 7.x | `10.0.10.10/24` | SSH, TAA Web |
| 2 | Cisco Catalyst 3560G-48TS | IOS `12.2(55)SE12` yoki yuqori | `10.0.99.2/24` (Vlan99 mgmt) | SSH (v2), SNMPv3 |
| 3 | Cisco 1800 (1841/1812) | IOS `15.1(4)M12` yoki `12.4(15)T17` | WAN: ISP, LAN: `10.0.99.1/24` | SSH (v2), SNMPv3 |
| 4 | TP-Link TL-SF 1024D v3 | Aparat unmanaged (firmware yo'q) | IPsiz | **Boshqarib bo'lmaydi** |

> Foydalanish: 3560G ning uplink `Gi0/25` portiga TP-Link 1024D ni ulang; 1800 ning LAN portini 3560G `Gi0/1` ga ulang; DL-160 ni 3560G `Gi0/48` ga ulang.

---

## 4. TP-Link TL-SF 1024D haqida — nima uchun skript yo'q?

TP-Link TL-SF 1024D — **unmanaged L1 switch**. Quyidagi sabablarga ko'ra unga biror skript yozib bo'lmaydi:

- Qurilmaning **IP manzili yo'q** (boshqaruv stek mavjud emas).
- **SNMP, Telnet, SSH, Web GUI — hech qaysi biri yo'q**.
- **STP yo'q**, **BPDU yubormaydi va ushlamaydi**.
- Port-security, MAC binding, VLAN, port-mirror — qo'llab-quvvatlanmaydi.

Shu sababli ushbu papkada TP-Link uchun **alohida skript joylashtirilmagan**. KXD muammolari nuqtai-nazaridan TP-Link orqasidagi 24 ta foydalanuvchi bitta umumiy "noma'lum" zona sifatida ko'rinadi va 3560G uplink portidagi `port-security maximum 24` + `bpduguard` + `storm-control` qoidalari bilan **butun segment darajasida** cheklanadi (qarang: `scripts/network-configs/3560g_baseline.cfg`).

Uzoq muddat tavsiya: ushbu segmentni managed L2 switch (TP-Link TL-SG2424, Cisco SG350-28, yana bir 3560/2960) bilan almashtirish.

---

## 5. Dependencies (yashash to'plami)

DL-160 Gen9 da quyidagi paketlar va kutubxonalar talab qilinadi:

| Paket | Versiyasi | Vazifasi |
|-------|-----------|----------|
| Python 3 | 3.10+ | Skriptlar ish muhiti |
| `netmiko` | 4.2+ | Cisco IOS ga SSH orqali ulanish |
| `psycopg2-binary` | 2.9+ | Postgres (IPAM DB) bilan ishlash |
| `jinja2` | 3.1+ | Provisioning template'lari |
| `pyyaml` | 6.0+ | `inventory.yml` ni o'qish |
| `curl` | 7.x+ | Telegram Bot API ga POST |
| `tftpd-hpa` | 5.2+ | 3560G konfiguratsiyasini va binding'larni qabul qilish |
| `snmptrapd` | net-snmp 5.9+ | SNMP trap'larni qabul qilish |
| Docker Engine | 24.x+ | TAA, Postgres, (ixtiyoriy) phpIPAM konteynerlari |

O'rnatish:

```bash
sudo apt update
sudo apt install -y python3 python3-pip tftpd-hpa snmptrapd snmp curl docker.io docker-compose-plugin
sudo pip3 install --upgrade netmiko psycopg2-binary jinja2 pyyaml
```

---

## 6. Litsenziya

Loyiha asosiy hujjati ([`README.md`](../README.md)) ga muvofiq, ushbu skript to'plami ham **AGPL-3.0-only** litsenziyasi ostida tarqatiladi. To'liq matn loyiha ildizidagi [`COPYING`](../COPYING) faylida.

---

## 7. Qo'shimcha o'qish

- [`../KXD_TAA_SCRIPT_YECHIM.md`](../KXD_TAA_SCRIPT_YECHIM.md) — strategik yechim xaritasi
- [`docs/setup.md`](docs/setup.md) — to'liq o'rnatish yo'riqnomasi (BIOS dan dashboardgacha)
- [`docs/validation.md`](docs/validation.md) — har bir KXD muammosi bo'yicha test stsenariylari
- [`docs/security.md`](docs/security.md) — xavfsizlik bo'yicha eslatmalar va sekretlarni boshqarish
