# KXD muammolari → TAA + Apparat: Script darajasidagi yechim xaritasi

Ushbu hujjat `KXD muammolari.docx` da keltirilgan 5 ta amaliy muammoning quyidagi 4 ta qurilmada **script** (TAA tomondan tashqi skript, qurilma tomondan EEM/TCL, SNMP polling skripti, va h.k.) yordamida qanday hal qilinishini bosqichma‑bosqich ko‘rsatadi.

Apparat ro‘yxati (foydalanuvchi tomonidan belgilangan):
1. **Server**: HP ProLiant DL‑160 Gen9 — TAA server (Linux + Docker) shu yerda turadi.
2. **Router**: Cisco 1800 series — internet/WAN edge, IOS 12.4+ (EEM 2.x).
3. **L3 Switch**: Catalyst 3560G 48‑port — IOS 12.2(50)SE+ (EEM 3.x, port‑security, DHCP snooping, ARP inspection, STP, MAC notification).
4. **L1 Switch**: TP‑Link TL‑SF 1024D 24‑port — **boshqarib bo‘lmaydigan (unmanaged) switch**. Bu qurilma uchun **biror script yozish imkoniyati YO‘Q**.

---

## 0. Muammolar (KXD muammolari.docx dan)

| Kod | Muammo | Asl matn (qisqartirilgan) |
|-----|--------|---------------------------|
| **P1** | Port → IP → MAC binding va ruxsatsiz qurilmani bloklash | Foydalanuvchiga aniq IP biriktirilmayapti, port → MAC → IP bog‘lanishi va boshqa qurilma ulanganda bloklash kerak |
| **P2** | Ruxsatsiz ulanish, port scan, DOS, Brute Force | Tarmoqqa o‘zboshimcha qo‘shilib olib IP qo‘yib, skanerlash yoki DoS qilish mumkin |
| **P3** | STP ishlamasdan tarmoq halqasi hosil bo‘lishi | Loop hosil bo‘lganda *qaerda, qaysi VLAN, qaysi port, qaysi MAC* — bilish kerak |
| **P4** | Faqat sutkalik navbatchi nazoratidagi monitoring; alert yo‘q | O‘zgarish bo‘lganda avtomatik elektron pochta/Telegram alert kerak |
| **P5** | IP manzil jurnali MS Excelda | Qulay bo‘lmagan; IP/MAC/foydalanuvchi taqsimotini yuritadigan tizim kerak |

---

## 1. Umumiy qobiliyat matritsasi (qurilma × muammo)

| Qurilma | P1 (binding/blok) | P2 (DoS/scan) | P3 (loop) | P4 (alert) | P5 (IP jurnal) |
|---------|:-----------------:|:-------------:|:---------:|:----------:|:--------------:|
| **DL‑160 Gen9** (TAA host) | Aralash skript: SNMP polling + auto‑remediation (netmiko orqali switchda port `shutdown`) | TAA trigger + custom Python skript (fail2ban‑uslubidagi auto‑blok) | TAA SNMP trap kollektor skripti — port/VLAN/MAC ni ajratib oluvchi parser | **To‘liq.** Telegram/Email skripti — Python/Bash | **To‘liq.** Python skript IP/MAC ni DBga yozadi, web UI da ko‘rsatadi |
| **Cisco 1800** | Imkoniyati past — bu router, switching uchun emas. EEM orqali NAT/ACL log + interfeys monitor | EEM applet: log pattern → shutdown / ACL update | Yo‘q — router STP qatnashmaydi | EEM applet → syslog → TAA (alert) | Yo‘q (router IPlarni biriktirmaydi) |
| **Catalyst 3560G** | **To‘liq.** Port‑security + DHCP snooping + ARP inspection + EEM applet | **To‘liq.** EEM applet violation → err‑disable + SNMP trap | **To‘liq.** BPDU/Loop guard + EEM applet → shutdown + trap | EEM applet → SNMP trap → TAA | DHCP snooping binding jadvali (`show ip dhcp snooping binding`) — TAA skripti parser |
| **TP‑Link TL‑SF 1024D** | **YO‘Q.** Unmanaged | **YO‘Q.** Unmanaged | **YO‘Q.** STP yo‘q. Loop bo‘lsa BPDU guardni 3560G da ushlaymiz | **YO‘Q** | **YO‘Q** |

> Asosiy xulosa: **deyarli barcha muammolarning ish bajaruvchi tomoni Catalyst 3560G + DL‑160 Gen9 (TAA server) sherikligi**. Cisco 1800 — yordamchi (WAN/NAT/log), TP‑Link — passiv L1 segment.

---

## 2. DL‑160 Gen9 (TAA server) — yozish mumkin bo‘lgan skriptlar

TAA serverida skript shu yerlarga joylashadi:
- **External Checks**: `/usr/lib/zabbix/externalscripts/` (TAA frontenddan item turi “External check” bilan chaqiriladi).
- **Alert Scripts**: `/usr/lib/zabbix/alertscripts/` (Media type orqali chaqiriladi — Telegram, email, custom).
- **Custom cron**: TAA serveridan tashqari skriptlar — masalan IP inventarini har 5 daqiqada yangilab turish.

### 2.1. P1/P2/P3 yechimi — `auto_remediation.py`
Qachon ishlaydi: **TAA action** “port‑security violation” triggerni ko‘rganda Operation → **Remote command → Custom script** orqali bu skriptni chaqiradi.

Fayl: `/usr/lib/zabbix/alertscripts/auto_remediation.py`
```python
#!/usr/bin/env python3
"""
TAA Trigger -> Catalyst 3560G da violation bo'lgan portni shutdown qiladi
va hodisani SQLite ga yozib qo'yadi (audit jurnali).
Chaqirish: auto_remediation.py <switch_ip> <port> <reason>
"""
import sys, sqlite3, datetime, os
from netmiko import ConnectHandler

SWITCH_IP, PORT, REASON = sys.argv[1], sys.argv[2], sys.argv[3]
DB = "/var/lib/taa/audit.db"

conn = ConnectHandler(
    device_type="cisco_ios",
    host=SWITCH_IP,
    username=os.environ["SW_USER"],
    password=os.environ["SW_PASS"],
    secret=os.environ["SW_ENABLE"],
)
conn.enable()
conn.send_config_set([
    f"interface {PORT}",
    "shutdown",
    f"description AUTO-BLOCKED {REASON} {datetime.datetime.utcnow().isoformat()}",
])
conn.disconnect()

db = sqlite3.connect(DB)
db.execute("""CREATE TABLE IF NOT EXISTS blocks
              (ts TEXT, switch TEXT, port TEXT, reason TEXT)""")
db.execute("INSERT INTO blocks VALUES (?,?,?,?)",
           (datetime.datetime.utcnow().isoformat(), SWITCH_IP, PORT, REASON))
db.commit()
print(f"OK: {SWITCH_IP} {PORT} shutdown ({REASON})")
```
Bunga `pip install netmiko` kerak. Switch user `taa_auto` privilege 15 bilan, faqat 10.0.10.10 dan kirishga ruxsat (3560G da `access-class` ACL bilan).

### 2.2. P3 yechimi — `stp_loop_parser.py` (SNMP trap parser)
Qachon ishlaydi: TAA `snmptrap` itemiga **preprocessing** sifatida chaqiriladi yoki TAA item key `system.run["stp_loop_parser.py {ITEM.VALUE}"]` orqali. Maqsadi — trap matnidan port, VLAN, MAC ni JSON sifatida ajratish.

Fayl: `/usr/lib/zabbix/externalscripts/stp_loop_parser.py`
```python
#!/usr/bin/env python3
import sys, re, json

raw = sys.stdin.read() if len(sys.argv) < 2 else " ".join(sys.argv[1:])
port  = (re.search(r"(GigabitEthernet\S+|Fa\S+)",  raw) or [""])[0] if re.search(r"(GigabitEthernet\S+|Fa\S+)", raw) else ""
port  = re.search(r"(GigabitEthernet\S+|Fa\S+|Gi\S+)", raw)
vlan  = re.search(r"[Vv]lan[:\s]*(\d+)", raw)
mac   = re.search(r"([0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})", raw, re.I)
print(json.dumps({
    "port": port.group(1) if port else None,
    "vlan": vlan.group(1) if vlan else None,
    "mac":  mac.group(1)  if mac  else None,
    "raw":  raw[:300],
}))
```
TAA trigger expressionida `{ITEM.LASTVALUE}` ichida shu JSON ko‘rinadi → hodisa matni *aniq qaerda loop borligini* ko‘rsatadi.

### 2.3. P4 yechimi — `taa_telegram.sh` (custom alert script)
TAA da “Telegram” media type ichki ravishda bor, lekin custom skript orqali boshqa formatda yuborish (markdown, jadval, foydalanuvchi tagi) qulay.

Fayl: `/usr/lib/zabbix/alertscripts/taa_telegram.sh`
```bash
#!/usr/bin/env bash
# Foydalanish: taa_telegram.sh <chat_id> <subject> <message>
TOKEN="${TG_TOKEN:?TG_TOKEN env required}"
CHAT_ID="$1"; SUBJECT="$2"; MESSAGE="$3"
TEXT=$(printf "*TAA: %s*\n\`\`\`\n%s\n\`\`\`" "$SUBJECT" "$MESSAGE")
curl -sS -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}" \
     -d "parse_mode=Markdown" \
     --data-urlencode "text=${TEXT}" >/dev/null
```
TAA → Administration → Media types → Script → `taa_telegram.sh`, parametrlar `{ALERT.SENDTO}`, `{ALERT.SUBJECT}`, `{ALERT.MESSAGE}`.

### 2.4. P5 yechimi — `ip_inventory.py` (IPAM o‘rnida)
Qachon ishlaydi: cron har 5 daqiqada yoki TAA External Check orqali. 3560G dan DHCP snooping binding va MAC jadvalini chiqaradi va PostgreSQL/SQLite ga yozadi. Frontend uchun kichik Flask sahifa ham yozish mumkin.

Fayl: `/opt/taa/scripts/ip_inventory.py`
```python
#!/usr/bin/env python3
"""3560G: 'show ip dhcp snooping binding' + 'show mac address-table'
   -> Postgres (taa_ipam) ga UPSERT."""
import os, re, psycopg2
from netmiko import ConnectHandler

SW = {"device_type":"cisco_ios", "host":"10.0.99.2",
      "username":os.environ["SW_USER"], "password":os.environ["SW_PASS"]}

c = ConnectHandler(**SW)
binding = c.send_command("show ip dhcp snooping binding")
mactab  = c.send_command("show mac address-table dynamic")
c.disconnect()

# Binding satrlari: MAC IP Lease VLAN Type Interface
rows_b = re.findall(
    r"([0-9a-f]{2}(?::[0-9a-f]{2}){5})\s+(\d+\.\d+\.\d+\.\d+)\s+\d+\s+\S+\s+(\d+)\s+(\S+)",
    binding, re.I)
# MAC jadvali: VLAN MAC Type Port
rows_m = re.findall(
    r"^\s*(\d+)\s+([0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})\s+\S+\s+(\S+)",
    mactab, re.M | re.I)

db = psycopg2.connect("dbname=taa_ipam user=taa password=...")
cur = db.cursor()
cur.execute("""CREATE TABLE IF NOT EXISTS leases(
   mac TEXT PRIMARY KEY, ip TEXT, vlan INT, port TEXT, seen_at TIMESTAMP DEFAULT now())""")
for mac, ip, vlan, port in rows_b:
    cur.execute("""INSERT INTO leases(mac,ip,vlan,port) VALUES (%s,%s,%s,%s)
                   ON CONFLICT(mac) DO UPDATE SET ip=EXCLUDED.ip,
                   vlan=EXCLUDED.vlan, port=EXCLUDED.port, seen_at=now()""",
                (mac.lower(), ip, int(vlan), port))
db.commit(); db.close()
```
Excelga eksport: `psql -c "\copy leases TO 'leases.csv' CSV HEADER"`.

---

## 3. Cisco 1800 router — yozish mumkin bo‘lgan skriptlar

IOS 12.4(15)T va undan yuqori bo‘lsa **EEM 2.4 applet** ishlaydi. Cheklov: bu *router*, port‑security va STP yo‘q. Demak P1/P3 bu yerda hal qilinmaydi. Faqat P2 (WAN tomondan kelgan scan/DoS) va P4 (alert) uchun foydali.

### 3.1. P2 yechimi — EEM applet: WAN brute force detect
```cisco
event manager applet WAN_BRUTE_DETECT
 event syslog pattern "Authentication failure" period 60 occurs 5
 action 010 cli command "enable"
 action 020 cli command "show users | append flash:/brute.log"
 action 030 syslog priority warnings msg "TAA-ALERT: 5 ta login fail 60s ichida"
 action 040 mail server "10.0.10.10" to "admin@taa.local" from "rt1800@taa.local" \
            subject "WAN brute" body "1800 routerda 5+ auth fail"
```
TAA `logging host 10.0.10.10` orqali bu syslog xabarini SNMP trap yoki log itemi sifatida olib trigger qiladi.

### 3.2. P4 yechimi — EEM: interfeys/yuk haddan oshganda
```cisco
event manager applet HIGH_CPU_TRAP
 event snmp oid "1.3.6.1.4.1.9.9.109.1.1.1.1.7.1" get-type next \
       entry-op gt entry-val 85 poll-interval 30
 action 010 syslog priority critical msg "TAA-ALERT: Router CPU > 85%"
```
TAA `Cisco IOS by SNMP` template trigger bilan dublikatlash mumkin — bunda EEM darhol ishlaydi, TAA esa keyingi polling siklida ko‘radi.

### 3.3. Skript yozish iloji **YO‘Q** bo‘lgan narsalar (Cisco 1800)
- **P1** (port‑security): router asosan WAN intefeysli — switching emas. Iloji yo‘q.
- **P3** (loop topish): router L2 STP qatnashmaydi. Iloji yo‘q.
- **P5** (IP jurnal): router DHCP lease beradi (agar yoqilsa), lekin foydalanuvchi → port bog‘lashi yo‘q. Iloji yo‘q.

---

## 4. Catalyst 3560G 48‑port — eng ko‘p script yozsa bo‘ladigan qurilma

Bu qurilmada **EEM 3.x** (TCL applet va aksiya rejimida) hamda CLI configuration darajasidagi qoidalar P1/P2/P3 ni *qurilmaning o‘zida* hal qiladi. TAA esa hodisalarni qabul qilib alert beradi.

### 4.1. P1 yechimi — port‑security + DHCP snooping (asosiy)
Bu “script” emas, **deklarativ config**. Lekin bittagina foydalanuvchi MAC ga IP biriktirib qo‘yish quyidagicha:
```cisco
! Bitta foydalanuvchini qattiq biriktirish:
interface GigabitEthernet0/5
 description User: Aliyev A.
 switchport mode access
 switchport access vlan 30
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address aabb.ccdd.eeff
 switchport port-security violation shutdown
 ip dhcp snooping limit rate 15
!
! ARP inspection orqali boshqa IP ni "sinab ko'rish"ni bloklash:
ip arp inspection vlan 30
ip arp inspection validate src-mac dst-mac ip
```
Bu konfiguratsiyani 47 ta foydalanuvchi portiga avtomatik tarqatish uchun DL‑160 dagi `provision_ports.py` skripti (netmiko + Jinja2 template) yozsa bo‘ladi.

### 4.2. P2 yechimi — EEM applet: violation → trap + email
```cisco
event manager applet PORT_SEC_VIOLATION
 event syslog pattern "PSECURE_VIOLATION" maxrun 30
 action 010 regexp "Gi[0-9]+\/[0-9]+" "$_syslog_msg" port
 action 020 regexp "([0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})" "$_syslog_msg" mac
 action 030 cli command "enable"
 action 040 cli command "show running-config interface $port | append flash:/violations.log"
 action 050 snmp-trap strdata "TAA-PSEC port=$port mac=$mac"
 action 060 syslog priority critical msg "TAA-ALERT: $port da $mac MAC violation"
```
DL‑160 (TAA) bu `snmp-trap strdata` ni `snmptrap.fallback` itemida qabul qiladi, parser orqali tahlil qilib trigger ishga tushiradi.

### 4.3. P3 yechimi — EEM applet: loop / BPDU guard
```cisco
event manager applet STP_LOOP_DETECT
 event syslog pattern "(SPANTREE.*BPDUGUARD|LOOPBACK|BLOCK_PVID)"
 action 010 regexp "Gi[0-9]+\/[0-9]+" "$_syslog_msg" port
 action 020 cli command "enable"
 action 030 cli command "show spanning-tree active | append flash:/stp_event.log"
 action 040 cli command "configure terminal"
 action 050 cli command "interface $port"
 action 060 cli command "shutdown"
 action 070 snmp-trap strdata "TAA-LOOP port=$port shutdown"
 action 080 syslog priority emergencies msg "TAA-ALERT: LOOP $port shutdown qilindi"
```
Bu applet *qurilma o‘zida* loopni avtomatik to‘xtatib qo‘yadi va TAA ga alert beradi — bu KXD muammolari hujjatining 3‑bandiga (qaerda halqa hosil bo‘ldi) to‘g‘ridan‑to‘g‘ri javob.

### 4.4. P4 yechimi — SNMP traps to TAA
Configuration:
```cisco
snmp-server host 10.0.10.10 version 3 priv taa_user udp-port 162
snmp-server enable traps port-security
snmp-server enable traps mac-notification change move threshold
snmp-server enable traps bridge newroot topologychange
snmp-server enable traps stpx inconsistency root-inconsistency loop-inconsistency
snmp-server enable traps storm-control trap-rate 10
snmp-server enable traps snmp linkdown linkup
logging host 10.0.10.10
```
DL‑160 da `snmptrapd` + Zabbix SNMP trapper (`StartSNMPTrapper=1`) qabul qiladi.

### 4.5. P5 yechimi — `show` natijalarini avtomatik chiqarish (TCL)
3560G ichida tclsh ishlaydi. EEM applet har soatda DHCP binding ni TFTP orqali DL‑160 ga yuboradi:
```cisco
event manager applet EXPORT_BINDING_HOURLY
 event timer cron name BINDING cron-entry "0 * * * *"
 action 010 cli command "enable"
 action 020 cli command "copy running-config tftp://10.0.10.10/configs/3560g.cfg"
 action 030 cli command "show ip dhcp snooping binding | redirect tftp://10.0.10.10/binding/3560g_binding.txt"
```
DL‑160 da `tftpd-hpa` ko‘tarilgan; `ip_inventory.py` (2.4 bo‘limi) shu faylni ham o‘qiy oladi.

### 4.6. Skript yozish iloji **YO‘Q** bo‘lgan narsalar (3560G)
- L1 segmentini (TP‑Link 1024D ortidagi 24 ta uyani) alohida ko‘rinmaydi — uplink portda umumiy nazorat.
- 3560G dagi EEM applet maksimum 50 ta qoida — sezilarli cheklov emas, lekin minda bo‘lsin.
- Cisco IOS uzoq vaqt ishlaganda EEM xotira buzilishi mumkin — applet logikasini *qisqa* tutib turish kerak.

---

## 5. TP‑Link TL‑SF 1024D — **HECH NIMA skript yozib bo‘lmaydi**

Bu qurilma:
- L1 (unmanaged) — **IP manzili yo‘q**.
- **SNMP yo‘q**, **CLI yo‘q**, **Web GUI yo‘q**, **Telnet/SSH yo‘q**.
- STP qo‘llab‑quvvatlamaydi (forwarding ham, BPDU yuborish ham yo‘q).
- Port‑security, MAC binding, VLAN, mirror — **hech qaysi biri yo‘q**.

| KXD muammosi | TP‑Link 1024D da skript bilan hal qilish | Imkoniyat |
|--------------|------------------------------------------|-----------|
| P1 binding/blok | — | **Yo‘q** |
| P2 DoS/scan | — | **Yo‘q** |
| P3 loop | — | **Yo‘q** (BPDU ham yubormaydi) |
| P4 alert | — | **Yo‘q** |
| P5 IP jurnal | — | **Yo‘q** |

**Yagona aralash yo‘l**: TP‑Link uplink portini *Catalyst 3560G* ning bitta portiga ulab, shu 3560G portida quyidagi cheklash:
```cisco
interface GigabitEthernet0/25
 description Uplink_TP-Link_1024D (unmanaged - high risk)
 switchport mode access
 switchport access vlan 30
 switchport port-security
 switchport port-security maximum 24
 switchport port-security violation restrict
 switchport port-security mac-address sticky
 spanning-tree bpduguard enable
 storm-control broadcast level 1.00
 storm-control multicast level 1.00
 storm-control action shutdown
```
Bu *TP‑Linkning o‘zida* emas, balki **uning sherigi bo‘lgan 3560G da** qoida. Ya’ni TP‑Link ostidagi 24 ta foydalanuvchini individual identifikatsiyalab bo‘lmaydi; agar ulardan biri loop yoki broadcast storm yaratsa — *butun uplink* o‘chadi.

> **Rost tavsiya**: TP‑Link TL‑SF 1024D ni minimal joyga ulang (faqat ofis stoli darajasida 2‑3 kishi), uzoq muddatda **managed L2 switch** (TP‑Link TL‑SG2424, Cisco SG350‑28, yoki yana bir 3560/2960) bilan almashtirilsin. Aks holda KXD muammolarining (P1) talabi tarmoqning o‘sha qismida printsipial darajada bajarilmaydi.

---

## 6. KXD muammosi → konkret skript fayl xaritasi

| KXD | Qaysi qurilmada | Skript / Config fayli | TAA da nima yoziladi |
|-----|------------------|------------------------|------------------------|
| **P1** binding | 3560G (asosiy) + DL‑160 (provisioning) | 3560G config + `provision_ports.py` (netmiko + Jinja) | Host `core-sw01` + SNMPv3 + port‑security violation trigger |
| **P1** auto‑blok | DL‑160 + 3560G | `auto_remediation.py` | Action → Operation → Remote command → script |
| **P2** DoS/scan | 3560G EEM + DL‑160 | `PORT_SEC_VIOLATION` applet + `auto_remediation.py` | `snmptrap[*ciscoCpsIfPort*]` item + trigger |
| **P2** WAN brute | Cisco 1800 EEM | `WAN_BRUTE_DETECT` applet | Log item `log[/var/log/cisco1800.log,"Authentication failure"]` + trigger |
| **P3** loop | 3560G EEM (asosiy) + DL‑160 | `STP_LOOP_DETECT` applet + `stp_loop_parser.py` | `snmptrap[*bridgeNewRoot*]` + trigger; dashboard “Halqa hodisalari” |
| **P4** Telegram alert | DL‑160 | `taa_telegram.sh` | Media type “Telegram‑custom”, action |
| **P4** Email alert | DL‑160 | (TAA ichki SMTP) yoki `taa_email.sh` | Media type Email |
| **P5** IP jurnal (asosiy) | DL‑160 (cron) + 3560G (TFTP push) | `ip_inventory.py` + 3560G `EXPORT_BINDING_HOURLY` | Inventory mode = Automatic; custom Inventory dashboard |
| **P5** IPAM kengaytma | DL‑160 (qo‘shimcha konteyner) | `docker-compose.yml` ga **phpIPAM** xizmati | TAA Script orqali phpIPAM REST API sinxronizatsiyasi |

---

## 7. Aniq bajarish tartibi (qisqa to‑do)

1. **DL‑160**: Ubuntu 22.04 → `docker compose up -d` → TAA web ishlayotganini tasdiqlash.
2. **3560G**: 2‑bo‘limdagi konfiguratsiyani kiritish (VLAN, port‑security, DHCP snooping, EEM appletlar, SNMPv3 + traplar, logging host).
3. **Cisco 1800**: SNMPv3 + `logging host 10.0.10.10` + `WAN_BRUTE_DETECT` EEM applet.
4. **TP‑Link**: hech narsa qilinmaydi. Faqat uni 3560G ning `Gi0/25` portiga ulash va uplinkda cheklash qoidalari.
5. **DL‑160 da skriptlar**:
   - `mkdir -p /usr/lib/zabbix/{externalscripts,alertscripts} /opt/taa/scripts`
   - `pip install netmiko psycopg2-binary`
   - 2.1, 2.2, 2.3, 2.4 dagi skriptlarni shu papkalarga yozish.
   - `chmod +x` qilish, `zabbix:zabbix` egasi.
   - SW credentialslarni `/etc/zabbix/.env` da saqlash (`chmod 600`).
6. **TAA UI**:
   - Hostlar: `core-sw01` (3560G, SNMPv3), `edge-rt01` (1800, SNMPv3), `tp-link-edge` (faqat ICMP ping), `taa-server` (Linux agent).
   - Media types: Telegram‑custom (script `taa_telegram.sh`), Email (SMTP).
   - Actions: “Network critical events” → Telegram + Email + Remote command `auto_remediation.py`.
   - Network discovery rule: 10.0.10.0/24, 10.0.20.0/24, 10.0.30.0/24.
   - Inventory: Automatic mode.
   - Dashboard: “Halqa hodisalari”, “Port security violations”, “DHCP binding count”.
7. **Tekshirish (validation)**:
   - Bir foydalanuvchi portiga begona MAC ulash → 3560G err‑disable + TAA Telegram alert ≤ 30 s.
   - Ikkita user portni o‘zaro patch‑kord bilan ulash (loop) → BPDU guard tushadi + `STP_LOOP_DETECT` applet shutdown + TAA alert “qaerda” aniq matn bilan.
   - `psql -c "select count(*) from leases"` — IP jurnali to‘ldirilayotganini ko‘rish.
   - Telegram botida xabar olish.

---

## 8. Yakuniy ochiq baho

| Talab (KXD) | Skript bilan to‘liq hal | Skript bilan qisman | Iloji yo‘q |
|-------------|:------------------------:|:--------------------:|:-----------:|
| P1 binding/blok (3560G+TAA) | ✔ | | |
| P1 binding (TP‑Link orqasidagi user) | | | ✘ |
| P2 ichki tarmoqda DoS/scan | ✔ | | |
| P2 WAN brute (1800) | ✔ | | |
| P3 loop (3560G EEM + TAA parser) | ✔ | | |
| P3 loop (faqat TP‑Link segmentida) | | | ✘ |
| P4 Telegram/Email alert | ✔ | | |
| P5 IP jurnal (host inventory + skript) | | ✔ | |
| P5 IP jurnal (to‘liq IPAM) | ✔ (phpIPAM konteyner qo‘shilsa) | | |

**Xulosa**: KXD muammolari hujjatidagi 5 ta talabning **4 tasi to‘liq, 1 tasi (P5) qisman/kengaytma bilan** TAA + Catalyst 3560G + DL‑160 sherikligida skript darajasida hal qilinadi. **TP‑Link TL‑SF 1024D ostidagi alohida foydalanuvchilar uchun talab printsipial darajada bajarilmaydi** — apparat almashtirilmaguncha bu qism *xavfli zona* bo‘lib qoladi.
