# TAA — KXD muammolari bo'yicha validatsiya yo'riqnomasi

Bu hujjat **KXD muammolari** dan har biri (P1..P5) uchun *qanday qilib amalda test qilish* kerakligini bosqichma-bosqich ko'rsatadi. Har bir test bo'limi quyidagi struktura asosida tuzilgan:

1. **Tayyorgarlik** — test boshlanishidan oldin nima kerakligi.
2. **Test bajarish komandalari** (PowerShell yoki bash).
3. **Kutilgan natija** — qurilmalar va TAA da nima ko'rinishi kerakligi, vaqt chegarasi bilan.
4. **Tekshirish komandalari** — natijani tasdiqlovchi komandalar.
5. **Muvaffaqiyatsiz bo'lsa nima qilish** (troubleshooting).

Asosiy laboratoriya topologiyasi (validatsiyaga taalluqli):

| Qurilma | IP | Sinov roli |
|---------|----|-----------|
| `taa-server` (DL-160 Gen9) | `10.0.10.10` | Skriptlar va TAA bu yerda |
| `core-sw01` (3560G) | `10.0.99.2` | Test portlari: `Gi0/3` user, `Gi0/4` user, `Gi0/25` TP-Link uplink |
| `edge-rt01` (1800) | `10.0.99.1` (LAN) | WAN testlari |
| Test laptop A | DHCP, port `Gi0/3` ga ulanadi | KXD muammosi simulyatsiyasi |
| Test laptop B | DHCP, port `Gi0/4` ga ulanadi | Ikkinchi tomon (loop testi va h.k.) |

> **Diqqat**: barcha testlar ish vaqtidan **tashqarida** yoki ajratilgan VLAN da bajarilsin. `STP_LOOP_DETECT` applet *butun portni shutdown* qiladi — bu real foydalanuvchini uzib qo'yishi mumkin.

---

## P1 testi — Port → IP → MAC binding va begona qurilmani avtomatik bloklash

**Maqsad**: `Gi0/3` portiga faqat `aabb.ccdd.eeff` MAC ga ega laptop ulanishi kerak; boshqa laptop ulansa — port `err-disabled` ga tushishi, TAA <30 sekund ichida Telegram alert berishi va `auto_remediation.py` SQLite `blocks` jadvaliga yozib qo'yishi kerak.

### Tayyorgarlik

```bash
# 3560G dan tekshiramiz - port-security yoqilgan, MAC biriktirilgan:
ssh admin@10.0.99.2
core-sw01> enable
core-sw01# show running-config interface Gi0/3
# Quyidagi qatorlar bo'lishi shart:
#   switchport port-security
#   switchport port-security maximum 1
#   switchport port-security mac-address aabb.ccdd.eeff
#   switchport port-security violation shutdown
```

DL-160 da TAA tomondan tayyorgarlikni tekshirish:

```bash
ssh zabbix@10.0.10.10
ls -la /usr/lib/zabbix/alertscripts/auto_remediation.py   # -rwx------ zabbix:zabbix
cat /etc/zabbix/.env                                       # SW_USER, SW_PASS, TG_TOKEN
sudo -u zabbix sqlite3 /var/lib/taa/audit.db ".schema blocks"
# CREATE TABLE blocks(ts TEXT, switch TEXT, port TEXT, reason TEXT);
```

### Testni bajarish

Laboratoriya laptopining MAC manzili `aabb.ccdd.eeff` **emas** ekanini tekshiring va `Gi0/3` portiga ulang:

```powershell
# Test laptopida (Windows):
Get-NetAdapter | Select-Object Name,MacAddress
# Misol: 00-15-5D-AA-BB-CC  — biriktirilgandan farq qiladi.
```

Patch-kordni `Gi0/3` ga ulang va 5..15 sekund kuting.

### Kutilgan natija

1. **3560G** (≤2s): `%PM-4-ERR_DISABLE: psecure-violation error detected on Gi0/3, putting Gi0/3 in err-disable state`.
2. **TAA item** (≤10s, SNMP trap orqali): `snmptrap[*]` itemida `TAA-PSEC port=Gi0/3 mac=0015.5daa.bbcc` qiymati ko'rinadi.
3. **TAA trigger** (≤15s): "Port security violation on core-sw01:Gi0/3" — Severity: High.
4. **Telegram alert** (≤30s): `*TAA: Port security violation*` matni admin chatga keladi.
5. **Audit jurnali** (≤30s): SQLite `blocks` jadvalida yangi qator paydo bo'ladi.

### Tekshirish komandalari

```bash
# 3560G da:
core-sw01# show port-security interface Gi0/3
#   Port Security              : Enabled
#   Port Status                : Secure-shutdown
#   Violation Mode             : Shutdown
#   Last Source Address:Vlan   : 0015.5daa.bbcc:30
#   Security Violation Count   : 1

core-sw01# show interfaces status err-disabled
# Gi0/3   ...   err-disabled   psecure-violation

# TAA da (web UI -> Monitoring -> Latest data -> filter "core-sw01"):
# snmptrap[*]  ->  TAA-PSEC port=Gi0/3 mac=0015.5daa.bbcc

# DL-160 da audit jurnalini ko'rish:
sudo -u zabbix sqlite3 /var/lib/taa/audit.db "select * from blocks order by ts desc limit 5;"
# 2026-05-11T14:22:01|10.0.99.2|Gi0/3|psecure-violation
```

### Muvaffaqiyatsiz bo'lsa

| Belgi | Sabab | Tuzatish |
|-------|-------|----------|
| Port `err-disabled` ga tushmadi | `port-security` yoqilmagan yoki `violation` rejimi `protect`/`restrict` | `show run interface Gi0/3` — `violation shutdown` bo'lishi kerak |
| TAA itemiga trap kelmadi | `snmptrapd` ishlamayapti yoki `StartSNMPTrapper=0` | `systemctl status snmptrapd`; `/etc/zabbix/zabbix_server.conf` da `StartSNMPTrapper=1` |
| Telegram alert kelmadi | `TG_TOKEN`/`CHAT_ID` xato | Qo'lda sinov: `bash taa_telegram.sh <chat_id> "test" "test"` |
| `auto_remediation.py` ishlamadi | `netmiko` yo'q yoki SW credentials xato | `pip3 show netmiko`; `/var/log/zabbix/zabbix_server.log` da `Operation` errori |
| SQLite ga yozilmadi | `/var/lib/taa/` egasi `zabbix` emas | `chown -R zabbix:zabbix /var/lib/taa` |

### Tiklash

```bash
core-sw01# configure terminal
core-sw01(config)# interface Gi0/3
core-sw01(config-if)# shutdown
core-sw01(config-if)# no shutdown
core-sw01(config-if)# end
# yoki errdisable recovery yoqilgan bo'lsa - 5 daqiqada o'zi qaytadi.
```

---

## P2 testi — Ruxsatsiz ulanish, port scan, DoS, Brute Force

P2 ikki kichik testdan iborat: **(a) LAN ichida port scan / storm**, **(b) WAN tomondan brute force**.

### P2.a — Ichki tarmoq port scan (nmap)

#### Tayyorgarlik

Test laptopiga `nmap` o'rnating va uni `Gi0/4` portiga ulang. 3560G da `Gi0/4` da port-security `maximum 1` va `storm-control` yoqilganini tekshiring:

```bash
core-sw01# show run interface Gi0/4 | include storm|security
#   storm-control broadcast level 1.00
#   storm-control multicast level 1.00
#   switchport port-security
#   switchport port-security maximum 1
```

#### Testni bajarish

```bash
# Test laptopdan:
sudo nmap -sS -T4 -p1-65535 10.0.20.0/24
# yoki agressivroq:
sudo nmap -sS -T5 -A 10.0.20.0/24
# Broadcast storm sinovi (ehtiyot bo'ling - real foydalanuvchini uzib qo'yadi):
sudo hping3 --flood --rand-source --udp -p 53 10.0.20.255
```

#### Kutilgan natija

| Vaqt | Hodisa |
|------|--------|
| ≤5s | 3560G da `storm-control` yoki `port-security` trip — `%PM-4-ERR_DISABLE` log qatori |
| ≤15s | TAA `snmptrap[*]` itemiga `TAA-PSEC` yoki `TAA-STORM` qiymati keladi |
| ≤30s | Telegram alert "Storm/scan detected on core-sw01:Gi0/4" |
| ≤30s | `auto_remediation.py` portni shutdown qilib qo'yadi va SQLite ga yozadi |

#### Tekshirish komandalari

```bash
core-sw01# show storm-control broadcast
# Gi0/4   Forwarding   1.00%   1.00%   1.00%
core-sw01# show errdisable detect
core-sw01# show logging | include Gi0/4
```

### P2.b — WAN brute force (hydra)

#### Tayyorgarlik

Cisco 1800 da `WAN_BRUTE_DETECT` applet yoqilgan:

```bash
edge-rt01# show event manager policy registered
# Type    Class    LastTime  ...  Name
# applet  user     ...           WAN_BRUTE_DETECT
```

#### Testni bajarish

WAN tomondan (yoki simulyatsiya uchun ichki LAN'dan, agar `vty` `access-class` ruxsat bersa):

```bash
# Kali yoki Linux box dan:
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://<wan_ip_of_1800> -t 4 -V
```

#### Kutilgan natija

| Vaqt | Hodisa |
|------|--------|
| ≤60s (5 ta urinish) | 1800 da `WAN_BRUTE_DETECT` ishga tushadi |
| ≤60s | Syslog: `TAA-ALERT: 5 ta login fail 60s ichida` |
| ≤90s | TAA log itemi `log[/var/log/cisco1800.log,"Authentication failure"]` trigger qiladi |
| ≤2min | Telegram alert "WAN brute force on edge-rt01" |

#### Tekshirish komandalari

```bash
edge-rt01# show event manager history events
edge-rt01# show logging | include Authentication
# DL-160 da:
tail -f /var/log/cisco1800.log | grep -E "Authentication failure|TAA-ALERT"
```

#### Muvaffaqiyatsiz bo'lsa

| Belgi | Sabab | Tuzatish |
|-------|-------|----------|
| Hydra darhol "connection refused" beradi | SSH `access-class` blokladi | Test IP ni ACL ga vaqtinchalik qo'shing yoki LAN dan urinib ko'ring |
| EEM applet ishlamadi | `event syslog pattern` xato | `show event manager policy registered detail` — pattern ni tekshiring |
| TAA log itemi qator topa olmayapti | `Encoding` yoki path xato | `Latest data` da item statusi `Not supported` ekanini tekshiring |

---

## P3 testi — STP ishlamasdan tarmoq halqasi (loop) hosil bo'lishi

**Maqsad**: ikki user portni o'zaro patch-kord bilan ulansa, BPDU guard darhol portni o'chirishi, `STP_LOOP_DETECT` applet `aniq qaerda loop borligini` syslog'da yozishi va TAA da "qaerda loop" matni (port, VLAN, MAC) aniq ko'rinishi kerak.

### Tayyorgarlik

3560G da BPDU guard va `STP_LOOP_DETECT` applet yoqilgan:

```bash
core-sw01# show spanning-tree summary | include BPDU
#   Portfast BPDU Guard Default      is enabled
core-sw01# show event manager policy registered | include STP_LOOP
# applet  ...  STP_LOOP_DETECT
core-sw01# show run interface Gi0/3 | include portfast|bpdu
#   spanning-tree portfast
#   spanning-tree bpduguard enable
```

DL-160 da `stp_loop_parser.py` joyida ekanini tekshiring:

```bash
ls -la /usr/lib/zabbix/externalscripts/stp_loop_parser.py
# Test:
echo "%SPANTREE-2-BLOCK_BPDUGUARD: Received BPDU on port GigabitEthernet0/3 with BPDU Guard enabled. Disabling port. vlan 30 mac 0015.5daa.bbcc" \
  | /usr/lib/zabbix/externalscripts/stp_loop_parser.py
# {"port": "GigabitEthernet0/3", "vlan": "30", "mac": "0015.5daa.bbcc", "raw": "..."}
```

### Testni bajarish

```text
1. Bo'sh patch-kordni oling.
2. Bir uchini  Gi0/3  ga,  ikkinchi uchini  Gi0/4  ga  ulang.
3. 2..5 sekund kuting.
```

### Kutilgan natija

| Vaqt | Hodisa |
|------|--------|
| ≤2s | 3560G: `%SPANTREE-2-BLOCK_BPDUGUARD: Received BPDU on port Gi0/4` |
| ≤2s | 3560G: `%PM-4-ERR_DISABLE: bpduguard error detected on Gi0/4` (BPDU guard ishladi) |
| ≤5s | `STP_LOOP_DETECT` applet ishga tushadi, `flash:/stp_event.log` ga yoziladi |
| ≤5s | SNMP trap `TAA-LOOP port=Gi0/4 shutdown` DL-160 ga keladi |
| ≤15s | TAA item qiymati JSON: `{"port":"Gi0/4","vlan":"30","mac":"0015.5daa.bbcc"}` |
| ≤30s | Telegram alert: "LOOP detected on core-sw01: port=Gi0/4 vlan=30 mac=0015.5daa.bbcc" |

### Tekshirish komandalari

```bash
core-sw01# show interfaces status err-disabled
# Gi0/4   ...   err-disabled   bpduguard
core-sw01# show logging | include BPDU|LOOP|err-disable
core-sw01# more flash:stp_event.log

# DL-160 da TAA Web UI:
# Monitoring -> Latest data -> filter "core-sw01" -> snmptrap[loop]
# Qiymat: {"port":"Gi0/4","vlan":"30","mac":"0015.5daa.bbcc","raw":"..."}

# Yoki qo'lda parser test:
echo "<oxirgi syslog qator>" | /usr/lib/zabbix/externalscripts/stp_loop_parser.py
```

### Muvaffaqiyatsiz bo'lsa

| Belgi | Sabab | Tuzatish |
|-------|-------|----------|
| Port shutdown bo'lmadi | `bpduguard enable` yoki `portfast` qo'yilmagan | `show run int Gi0/4` — ikkalasi ham bo'lishi kerak |
| Applet ishlamadi | EEM `event syslog pattern` regex xato | `show event manager policy registered detail STP_LOOP_DETECT` |
| TAA da JSON o'rniga raw qator | Item preprocessing chaqirilmagan | Item -> Preprocessing -> "External check: stp_loop_parser.py" |
| Trigger expression yolg'on/musbat | Tag yoki regex xato | Trigger expression: `last(/core-sw01/snmptrap[loop],#1)<>""` |

### Tiklash

```bash
core-sw01# configure terminal
core-sw01(config)# interface Gi0/4
core-sw01(config-if)# shutdown
core-sw01(config-if)# no shutdown
core-sw01(config-if)# end
core-sw01# clear errdisable interface Gi0/4
```

---

## P4 testi — Telegram alert (Media type test)

**Maqsad**: TAA frontenddan **Administration → Media types → Telegram-custom → Test** tugmasi orqali Telegram botiga sinov xabari ketishi va admin chatda paydo bo'lishi.

### Tayyorgarlik

```bash
# DL-160 da:
ls -la /usr/lib/zabbix/alertscripts/taa_telegram.sh   # -rwx------ zabbix:zabbix
cat /etc/zabbix/.env | grep TG_   # TG_TOKEN va default CHAT_ID
# Qo'lda sinov:
sudo -u zabbix bash -c 'source /etc/zabbix/.env && \
   /usr/lib/zabbix/alertscripts/taa_telegram.sh "${TG_DEFAULT_CHAT}" "Validation P4" "Hello from TAA"'
# Telegramda xabar kelishi kerak.
```

### TAA UI orqali test

1. TAA web UI ga **Admin** sifatida kiring.
2. **Administration → Media types** ga o'ting.
3. `Telegram-custom` qatorida o'ng tomondagi **Test** tugmasini bosing.
4. Quyidagi maydonlarni to'ldiring:
   - **sendto**: admin chat ID (masalan `123456789`)
   - **subject**: `Validation P4`
   - **message**: `TAA media type test from web UI`
5. **Test** tugmasini bosing.

### Authentication failure simulyatsiyasi

Real trigger orqali ham tekshirish uchun:

```bash
# Sinov user uchun TAA frontendiga 3 marta noto'g'ri parol kiriting:
# Login: admin   Parol: wrong123  (3 marta)
# yoki SSH brute:
for i in 1 2 3 4 5; do
  ssh wrong_user@10.0.99.2 -o PreferredAuthentications=password -o StrictHostKeyChecking=no
done
```

### Kutilgan natija

| Vaqt | Hodisa |
|------|--------|
| Darhol (Test tugmasi) | TAA UI da yashil `Media type test successful` |
| ≤5s | Telegram chatda `*TAA: Validation P4*` matni keladi |
| ≤90s (authfail) | TAA action ishlaydi va admin chatga `Authentication failure on edge-rt01` keladi |

### Tekshirish komandalari

```bash
# TAA logida media type chaqiruvini ko'rish:
sudo tail -f /var/log/zabbix/zabbix_server.log | grep -i "alert\|telegram\|media"

# Action audit jurnali (TAA UI):
# Reports -> Audit log -> filter Resource = "Action"
```

### Muvaffaqiyatsiz bo'lsa

| Belgi | Sabab | Tuzatish |
|-------|-------|----------|
| Test tugmasi `Cannot execute alert script` | `taa_telegram.sh` egasi yoki permissions xato | `chown zabbix:zabbix taa_telegram.sh && chmod 700 taa_telegram.sh` |
| Telegram javob qaytarmaydi | Token yoki chat_id xato | `curl -sS https://api.telegram.org/bot${TG_TOKEN}/getMe` |
| Skript ishladi, lekin xabar yo'q | Bot chatdan blok qilingan | Botga `/start` yuboring; bot guruh ichida bo'lsa - admin huquq berilsin |
| HTTP `400 Bad Request` | Markdown maxsus belgi qochirilmagan | `parse_mode=Markdown` o'rniga `parse_mode=HTML` qilib sinab ko'ring |

---

## P5 testi — IP inventarining ishlashi va eksporti

**Maqsad**: `ip_inventory.py` skripti 3560G dan DHCP snooping binding va MAC jadvalini olib Postgres `taa_ipam.leases` jadvaliga yozishi; yangi DHCP lease olganda keyingi siklda u jadvalda paydo bo'lishi; CSV ga eksport qilish mumkin bo'lishi.

### Tayyorgarlik

```bash
# DL-160 da Postgres ishlayotganini tekshiring:
sudo docker ps | grep postgres
# yoki:
sudo systemctl status postgresql
# DB va user:
sudo -u postgres psql -c "\l" | grep taa_ipam
sudo -u postgres psql -c "\du" | grep taa
# Jadval mavjudligi:
psql -U taa -h 127.0.0.1 -d taa_ipam -c "\d leases"
```

### Skriptni qo'lda ishga tushirish

```bash
sudo -u zabbix bash -c 'source /etc/zabbix/.env && \
   /opt/taa/scripts/ip_inventory.py --switch 10.0.99.2'
# Standart chiqish: "OK: 14 bindings, 38 mac entries upserted"
```

### Boshlang'ich tekshirish

```bash
psql -U taa -h 127.0.0.1 -d taa_ipam -c "select count(*) from leases;"
#  count
# -------
#     14
psql -U taa -h 127.0.0.1 -d taa_ipam \
     -c "select mac, ip, vlan, port, seen_at from leases order by seen_at desc limit 5;"
```

### Yangi lease olish (live test)

```bash
# Test laptopni Gi0/5 portiga ulang va DHCP olishini kutib turing:
sudo dhclient -r eth0 && sudo dhclient eth0
# yoki Windows:
ipconfig /release; ipconfig /renew
```

5 daqiqa (cron oraliq vaqti) ichida `ip_inventory.py` keyingi marta ishlaydi va yangi yozuv paydo bo'ladi:

```bash
psql -U taa -h 127.0.0.1 -d taa_ipam \
     -c "select * from leases order by seen_at desc limit 1;"
# yangi  MAC | IP | VLAN | Gi0/5 | seen_at = hozir
```

### CSV eksport

```bash
psql -U taa -h 127.0.0.1 -d taa_ipam \
     -c "\copy leases TO '/tmp/leases.csv' CSV HEADER"
ls -la /tmp/leases.csv
head /tmp/leases.csv
# mac,ip,vlan,port,seen_at
# 0015.5daa.bbcc,10.0.30.42,30,Gi0/5,2026-05-11 14:30:00+05
```

### Kutilgan natija

| Tekshiruv | Kutilgan |
|-----------|----------|
| `select count(*) from leases;` | ≥1 (aktiv lease soni) |
| Yangi DHCP lease olingach, ≤5 daqiqada | Yangi qator paydo bo'ladi |
| `\copy ... CSV HEADER` | CSV fayl `mac,ip,vlan,port,seen_at` sarlavhali |
| TAA Inventory -> Hosts | `core-sw01` hostining Inventory tab'ida MAC va portlar avtomatik to'ldirilgan |

### Muvaffaqiyatsiz bo'lsa

| Belgi | Sabab | Tuzatish |
|-------|-------|----------|
| Skript `NetMikoAuthenticationException` | SW credentials xato | `/etc/zabbix/.env` da `SW_USER`/`SW_PASS` ni tekshiring; switchda `access-class` 10.0.10.10 ga ruxsat berilganini tasdiqlang |
| Skript `psycopg2.OperationalError` | Postgres yo'q yoki host xato | `pg_isready -h 127.0.0.1`; `pg_hba.conf` da `taa` user uchun `md5` |
| Bindinglar 0 qator | DHCP snooping yoqilmagan | 3560G da `show ip dhcp snooping` — `Switch DHCP snooping is enabled` |
| Yangi lease ko'rinmadi | Cron ishlamayapti | `sudo crontab -u zabbix -l`; `/var/log/cron` ni tekshiring |
| CSV bo'sh | `\copy` permissions xato | `taa` user `pg_write_server_files` rolida bo'lishi shart **emas** (client side `\copy` ishlatilganda) — `\copy` ni o'qing, `COPY` emas |

---

## Yakuniy validatsiya checklist

Quyidagi 5 ta savolga "ha" deyish kerak. Aks holda yechim to'liq emas.

- [ ] **P1**: Begona MAC ulanganida port 30s ichida shutdown bo'ladi va SQLite `blocks` jadvalida yozuv paydo bo'ldi.
- [ ] **P2.a**: nmap port-scan urinishi storm-control / port-security trip qildi va Telegram alert keldi.
- [ ] **P2.b**: 60 sekund ichida 5 ta auth fail bo'lganda `WAN_BRUTE_DETECT` ishladi va TAA log itemi triggerda.
- [ ] **P3**: Patch-kord bilan loop hosil qilganda BPDU guard ishladi va TAA da `{"port":..,"vlan":..,"mac":..}` ko'rindi.
- [ ] **P4**: Media type Test tugmasi muvaffaqiyatli va real auth failure simulyatsiyasidan keyin admin chatga xabar keldi.
- [ ] **P5**: `select count(*) from leases` musbat son qaytaradi, yangi DHCP olingach 5 daqiqada qatordagi `seen_at` yangilanadi va CSV eksport ishlaydi.
