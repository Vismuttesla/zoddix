# TAA — xavfsizlik bo'yicha eslatmalar

Bu hujjat TAA + Catalyst 3560G + Cisco 1800 + DL-160 Gen9 yechimini ishlatish jarayonida e'tibor berilishi kerak bo'lgan **sekret boshqaruvi, SNMP kuchaytirilgan rejimi, ACL, audit jurnali va backup** bo'yicha minimal majburiy chora-tadbirlarni belgilaydi.

> Bu yo'riqnomadagi sozlamalar **majburiy minimum** — ulardan pastroq darajada qoldirish KXD muammolari hujjatining maqsadlariga ziddir.

---

## 1. Sekretlar va `.env` fayli

Barcha parollar, tokenlar va DB DSN-lari **bitta** faylda saqlanadi:

| Yo'l | Egasi | Permissions | Mazmuni |
|------|-------|-------------|---------|
| `/etc/zabbix/.env` | `zabbix:zabbix` | `chmod 600` | `SW_USER`, `SW_PASS`, `SW_ENABLE`, `TG_TOKEN`, `TG_DEFAULT_CHAT`, `PG_DSN` |

Sozlash:

```bash
sudo chown zabbix:zabbix /etc/zabbix/.env
sudo chmod 600 /etc/zabbix/.env
ls -la /etc/zabbix/.env
# -rw------- 1 zabbix zabbix 312 May 11 14:00 /etc/zabbix/.env
```

**Qoidalar**:

- `.env` ni **hech qachon git'ga yubormang**. `.gitignore` da bo'lishi shart.
- Tokenni almashtirganda: avval Telegram BotFather'da `/revoke`, keyin yangisini `.env` ga yozing, keyin `sudo systemctl restart zabbix-server`.
- Skript ichida hech qachon parolni "hardcode" qilmang — har doim `os.environ["SW_PASS"]` orqali oling.

Buni avtomatik tekshirish (CI/CD da yoki qo'lda):

```bash
grep -RIn --exclude-dir=.git --include="*.py" --include="*.sh" \
     -E "password[[:space:]]*=[[:space:]]*['\"][^'\"]+" /opt/taa/scripts \
     && echo "WARNING: hardcoded password found!" || echo "OK"
```

---

## 2. SNMPv3 — faqat SHA + AES128

Cisco IOS qurilmalarida **SNMP v1 va v2c**ni butunlay o'chiring. Faqat SNMPv3 `authPriv` rejimida ishlating.

### 3560G

```cisco
core-sw01(config)# ! v1/v2c ni o'chirish:
core-sw01(config)# no snmp-server community public
core-sw01(config)# no snmp-server community private
core-sw01(config)# !
core-sw01(config)# snmp-server view TAA_VIEW iso included
core-sw01(config)# snmp-server group TAA_GROUP v3 priv read TAA_VIEW
core-sw01(config)# snmp-server user taa_user TAA_GROUP v3 \
                       auth sha <STRONG_SHA_PASS> priv aes 128 <STRONG_AES_PASS>
core-sw01(config)# snmp-server host 10.0.10.10 version 3 priv taa_user udp-port 162
```

### Cisco 1800 — xuddi shu sozlamalar.

### Tasdiqlash

```bash
# DL-160 dan v2c bilan urinish XATO qaytarishi kerak:
snmpwalk -v2c -c public 10.0.99.2 sysDescr
# Timeout: No Response from 10.0.99.2

# v3 bilan ishlashi kerak:
snmpwalk -v3 -l authPriv -u taa_user -a SHA -A <STRONG_SHA_PASS> \
         -x AES -X <STRONG_AES_PASS> 10.0.99.2 sysDescr.0
```

**Qoidalar**:

- SHA pass va AES pass — **kamida 16 belgi**, har xil.
- Parol generatsiya: `openssl rand -base64 24`.
- SNMP credentials har 6 oyda yangilansin.

---

## 3. Switch CLI access — `access-class` ACL

Switch va router'larga SSH faqat TAA serveridan (`10.0.10.10`) kirishga ruxsat etiladi. Boshqa hech qaysi xostdan kirish — **rad etilgan**.

### 3560G va 1800

```cisco
core-sw01(config)# ip access-list standard MGMT_ACL
core-sw01(config-std-nacl)# permit host 10.0.10.10
core-sw01(config-std-nacl)# deny   any log
core-sw01(config-std-nacl)# exit
core-sw01(config)# line vty 0 15
core-sw01(config-line)# access-class MGMT_ACL in
core-sw01(config-line)# transport input ssh
core-sw01(config-line)# login local
core-sw01(config-line)# exec-timeout 5 0
core-sw01(config-line)# end
```

### Konsoldan kirish

Konsol portga ham parol qo'ying:

```cisco
core-sw01(config)# line con 0
core-sw01(config-line)# login local
core-sw01(config-line)# exec-timeout 10 0
```

### Tekshirish

```bash
# 10.0.10.10 dan kirish - OK:
ssh taa_auto@10.0.99.2

# Boshqa IP dan urinish - REFUSED bo'lishi kerak:
# (boshqa workstationdan)
ssh taa_auto@10.0.99.2
# ssh: connect to host 10.0.99.2 port 22: Connection refused
# Yoki "Permission denied"
```

ACL `log` qatori bilan `show logging | include MGMT_ACL` orqali ruxsatsiz urinishlarni ko'rsa bo'ladi — bu *o'zi* TAA log itemi orqali alert beradi.

---

## 4. `auto_remediation.py` — cheklangan privilege

`auto_remediation.py` skripti switch'larda **shutdown** komandasini bajaradi — bu kuchli amal. Shu sababli skript ishlatadigan user **alohida** va **cheklangan** bo'lishi shart.

### Cisco da privilege darajasini cheklash

To'liq privilege 15 berish o'rniga, faqat kerakli komandalarga ruxsat bering:

```cisco
core-sw01(config)# privilege exec    level 7 show port-security
core-sw01(config)# privilege exec    level 7 show interfaces
core-sw01(config)# privilege configure level 7 interface
core-sw01(config)# privilege interface level 7 shutdown
core-sw01(config)# privilege interface level 7 no shutdown
core-sw01(config)# privilege interface level 7 description
core-sw01(config)# !
core-sw01(config)# username taa_auto privilege 7 secret <STRONG>
```

`taa_auto` user endi:

- `show port-security`, `show interfaces` ko'ra oladi
- Faqat **interfeys ostida shutdown/no shutdown/description** qila oladi
- `write memory`, `reload`, `erase`, `tftp` kabi xavfli komandalarni **bajara olmaydi**

### Tasdiqlash

```bash
ssh taa_auto@10.0.99.2
core-sw01> show privilege
# Current privilege level is 7
core-sw01> reload
# Command authorization failed.
core-sw01> configure terminal
core-sw01(config)# interface Gi0/3
core-sw01(config-if)# shutdown        # OK
core-sw01(config-if)# spanning-tree portfast   # Command authorization failed.
```

---

## 5. Audit trail — barcha auto-shutdown jurnalga yoziladi

`auto_remediation.py` har safar port o'chirilganda **ikki joyga** yozadi:

1. **SQLite** `/var/lib/taa/audit.db` `blocks` jadvali (DL-160 da).
2. **Cisco logging buffer + flash** (`flash:/violations.log` — 3560G da).

### SQLite jadval schemasi

```sql
CREATE TABLE IF NOT EXISTS blocks(
    ts      TEXT,        -- ISO 8601 UTC
    switch  TEXT,        -- masalan "10.0.99.2"
    port    TEXT,        -- masalan "Gi0/3"
    reason  TEXT,        -- masalan "psecure-violation"
    actor   TEXT,        -- skript chaqirgan TAA user (qo'shimcha)
    trigger_id TEXT      -- TAA trigger ID (qo'shimcha)
);
```

### Audit ko'rish

```bash
sudo -u zabbix sqlite3 /var/lib/taa/audit.db \
   "select ts, switch, port, reason from blocks order by ts desc limit 20;"
```

### Postgres'da audit (qo'shimcha)

P5 ham IPAM ham Postgres'da bo'lgani uchun, ixtiyoriy holda `blocks` jadvalini Postgres'ga ko'chirish mumkin:

```sql
CREATE TABLE IF NOT EXISTS audit_blocks (
    id         BIGSERIAL PRIMARY KEY,
    ts         TIMESTAMPTZ NOT NULL DEFAULT now(),
    switch     INET NOT NULL,
    port       TEXT NOT NULL,
    reason     TEXT NOT NULL,
    actor      TEXT,
    trigger_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_blocks_ts ON audit_blocks(ts DESC);
CREATE INDEX IF NOT EXISTS idx_audit_blocks_switch_port ON audit_blocks(switch, port);
```

### Saqlash muddati

| Manba | Saqlash davri | Tashlash strategiyasi |
|-------|---------------|------------------------|
| SQLite `blocks` | 1 yil | `vacuum` + `delete where ts < datetime('now','-365 day')` |
| Postgres `audit_blocks` | 2 yil | Partitionlash yoki `pg_cron` bilan `DELETE` |
| Cisco `flash:/violations.log` | Fayl 10 MB ga yetganda rotate | EEM applet `event timer cron` bilan tozalash |

---

## 6. Backup va tiklash

Loyiha ildiz papkasida (`D:\TAA\zoddix`) tayyor backup fayli mavjud:

| Fayl | Hajmi (taxminan) | Mazmuni |
|------|------------------|---------|
| `taa_database_backup.sql` | SQL dump | TAA Postgres DB to'liq nusxasi |
| `taa_database_backup_utf8.sql` | SQL dump (UTF-8) | UTF-8 sarlavhali variant |
| `taa_database_backup.zip` | Siqilgan | Yuqoridagi SQL ning zip nusxasi |
| `taa_deployment_package.zip` | Siqilgan | To'liq deployment paket |
| `taa_restore.sh` | Bash skript | Linux/Bash da tiklash |
| `taa_restore.ps1` | PowerShell skript | Windows da tiklash |

### Tiklash (Linux)

```bash
cd /opt/taa
sudo bash taa_restore.sh
# Bu skript taa-db konteyneriga ulanib taa_database_backup_utf8.sql ni
# import qiladi va admin parolini default holatga qaytaradi.
```

### Backup jadvali

Kunlik (cron):

```bash
sudo crontab -e
# Quyidagini qo'shing:
0 2 * * * docker exec taa-db pg_dump -U postgres taa | gzip > /var/backups/taa/taa_$(date +\%F).sql.gz
0 3 * * * docker exec taa-db pg_dump -U taa  taa_ipam | gzip > /var/backups/taa/taa_ipam_$(date +\%F).sql.gz
0 4 * * 0 find /var/backups/taa -name "*.sql.gz" -mtime +30 -delete
```

### IOS konfiguratsiyasi backup

3560G dagi `EXPORT_BINDING_HOURLY` applet allaqachon `running-config` ni har soatda DL-160 ga jo'natadi:

```cisco
core-sw01# more event manager applet EXPORT_BINDING_HOURLY
# action 020 cli command "copy running-config tftp://10.0.10.10/configs/3560g.cfg"
```

DL-160 da `/srv/tftp/configs/` papkasini ham `git` bilan versiyalash mumkin:

```bash
cd /srv/tftp/configs
sudo git init && sudo git add -A && sudo git commit -m "initial"
# va keyin har soat avtomatik commit:
0 * * * * cd /srv/tftp/configs && git add -A && git commit -m "auto: $(date +\%F-\%T)" 2>/dev/null
```

---

## 7. TAA web UI xavfsizligi

| Sozlama | Tavsiya etilgan qiymat | Joyi |
|---------|------------------------|------|
| `Admin` default parolini almashtirish | Birinchi kun | Administration → Users → Admin |
| HTTPS (`https://10.0.10.10`) | Yoqilgan | Docker compose'da nginx reverse proxy + Let's Encrypt yoki self-signed |
| Session davri | `15 min` | Administration → General → GUI |
| Login attempt limit | `5` | Administration → General → GUI |
| Per-user 2FA | Yoqilgan (TOTP) | User → Profile |
| API token | Faqat kerakli `host.get`, `trigger.get` skopli | User → API tokens |

---

## 8. Xulosa — minimal majburiy ro'yxat

Quyidagi 10 ta majburiy element bajarilgan bo'lsa, yechim **xavfsiz minimal darajada** hisoblanadi:

- [ ] `/etc/zabbix/.env` egasi `zabbix:zabbix`, `chmod 600`, `.gitignore` da.
- [ ] SNMPv1 va v2c o'chirilgan, faqat SNMPv3 SHA+AES128 ishlaydi.
- [ ] `vty access-class` faqat `10.0.10.10` ga ruxsat beradi.
- [ ] `taa_auto` user privilege 7 (cheklangan), `reload`/`erase` qila olmaydi.
- [ ] `auto_remediation.py` har shutdown ni SQLite `blocks` ga yozadi.
- [ ] `taa_database_backup_utf8.sql` mavjud va `taa_restore.sh` test qilingan.
- [ ] Postgres dump kunlik cron orqali olinadi va 30 kun saqlanadi.
- [ ] 3560G `running-config` har soat TFTP orqali DL-160 ga jo'natiladi va git da versiyalanadi.
- [ ] TAA Admin parol default holatdan almashtirilgan.
- [ ] TAA login session davri 15 daqiqa.

Agar ulardan bittasi yo'q bo'lsa — yechim ishlaydi, lekin KXD muammolari hujjatining xavfsizlik talablarini **to'liq qoplamaydi**.
