# TAA ni clone qilib qurilmasiz tekshirish va keyin real qurilmaga ulash

Ushbu qo'llanma TAA loyihasini boshqa kompyuterda `git clone` qilib tekshirish uchun yozilgan. Hozir real Catalyst 3560G, router yoki TP-Link qurilmalari bo'lmasa ham, TAA UI ichidagi tayyor konfiguratsiya ko'riladi:

- `core-sw01` hosti;
- `edge-rt01` hosti;
- SNMP trap itemlari;
- Port Security va STP triggerlari;
- WAN brute-force triggeri;
- email actionlari;
- port-security uchun real auto-remediation action.

Real qurilmalar keyin ulanganda foydalanuvchi faqat IP, SNMP credential, email va script credentiallarini o'z muhitiga moslaydi.

## 1. Nima tayyor holda keladi

DB dump ichida quyidagilar oldindan yaratilgan:

| Qism | Holat |
|---|---|
| Host | `core-sw01` |
| Placeholder IP | `192.168.99.2` |
| SNMP port | `161` |
| Trap item | `Port Security Violation Trap` |
| Trap item | `STP Topology Change Trap` |
| Trap item | `Interface Link State Trap` |
| Trap item | `SNMP traps (fallback)` |
| Trigger | `core-sw01: Port Security violation trap keldi` |
| Trigger | `core-sw01: STP topologiya o'zgarishi aniqlandi` |
| Action | `core-sw01 Port Security xabari` |
| Action | `core-sw01 STP xabari` |
| Auto-remediation action | `core-sw01 Port Security auto-remediation` |
| Host | `edge-rt01` |
| Placeholder IP | `192.168.99.1` |
| SNMP port | `161` |
| Trap item | `WAN Brute Force Trap` |
| Trigger | `edge-rt01: WAN brute-force urinishlari aniqlandi` |
| Action | `edge-rt01 WAN brute xabari` |

Auto-remediation action real rejimda yoqilgan. U `Port Security Violation Trap` qiymatidan port nomini ajratadi va `auto_remediation.py` orqali shu portni `shutdown` qiladi. Shuning uchun real muhitda `SW_USER`, `SW_PASS`, `SW_ENABLE` va script pathlari to'g'ri sozlangan bo'lishi shart.

## 2. Talablar

Kerak bo'ladi:

- Git;
- Docker;
- Docker Compose plugin;
- kamida 8 GB RAM tavsiya qilinadi;
- brauzer.

Portlar:

| Port | Vazifa |
|---:|---|
| `8098` | TAA Web UI |
| `10051` | TAA server trapper/active checks |
| `10050` | lokal agent konteyneri |
| `5433` | PostgreSQL host porti |

## 3. Clone qilish

```bash
git clone <REPO_URL> zoddix
cd zoddix
```

Agar repo allaqachon clone qilingan bo'lsa:

```bash
git pull
```

## 4. Toza DB bilan ishga tushirish

Yangi clone qilinganda quyidagi buyruq yetarli:

```bash
docker compose up -d --build
```

Muhim: PostgreSQL container faqat birinchi startda `taa_database_backup_utf8.sql` faylini import qiladi. Agar sizda oldingi `postgres-data` volume mavjud bo'lsa, yangi dump avtomatik import bo'lmaydi.

Test uchun toza DB kerak bo'lsa:

```bash
docker compose down -v
docker compose up -d --build
```

Bu buyruq eski PostgreSQL volume ichidagi ma'lumotlarni o'chiradi. Faqat test muhitida ishlating.

## 5. Containerlar holatini tekshirish

```bash
docker compose ps
```

Kutilgan holat:

```text
taa-server          Up
taa-web             Up / healthy
postgres            Up
taa-agent           Up
```

Web UI:

```text
http://localhost:8098
```

Default login:

```text
Username: Admin
Password: zabbix
```

## 6. DB ichida tayyor konfiguratsiyani tekshirish

Quyidagilarni ishlatish mumkin:

```bash
docker exec zoddix-postgres-1 psql -U zabbix -d zabbix -c "select h.host,h.name,hi.ip,hi.port from hosts h left join interface hi on hi.hostid=h.hostid where h.host='core-sw01';"
```

Kutilgan natija:

```text
core-sw01 | Catalyst 3560G - core-sw01 | 192.168.99.2 | 161
```

Triggerlarni tekshirish:

```bash
docker exec zoddix-postgres-1 psql -U zabbix -d zabbix -c "select triggerid,description,status,priority from triggers where description ilike '%core-sw01%' order by triggerid;"
```

Router triggerini tekshirish:

```bash
docker exec zoddix-postgres-1 psql -U zabbix -d zabbix -c "select triggerid,description,status,priority from triggers where description ilike '%edge-rt01%' order by triggerid;"
```

Actionlarni tekshirish:

```bash
docker exec zoddix-postgres-1 psql -U zabbix -d zabbix -c "select actionid,name,status from actions where name ilike '%core-sw01%' order by actionid;"
```

Router actionini tekshirish:

```bash
docker exec zoddix-postgres-1 psql -U zabbix -d zabbix -c "select actionid,name,status from actions where name ilike '%edge-rt01%' order by actionid;"
```

Status qiymati:

- `0` - yoqilgan;
- `1` - o'chirilgan.

Auto-remediation action real rejimda `0` bo'lishi kerak.

## 7. UI ichida tekshirish

TAA UI da:

```text
Ma'lumot yig'ish -> Hostlar
```

`core-sw01` hostini toping.

Tekshiriladigan joylar:

- Host interface IP: `192.168.99.2`;
- port: `161`;
- itemlar ichida SNMP trap itemlari bor;
- triggerlar ichida ikki custom trigger bor;
- actionlar ichida Port Security va STP xabarlari bor.

Keyin `edge-rt01` hostini toping.

Tekshiriladigan joylar:

- Host interface IP: `192.168.99.1`;
- port: `161`;
- itemlar ichida `WAN Brute Force Trap` bor;
- triggerlar ichida `edge-rt01: WAN brute-force urinishlari aniqlandi` bor;
- actionlar ichida `edge-rt01 WAN brute xabari` bor.

Qurilma ulanmagan bo'lsa, Latest data ichida SNMP metrikalar kelmasligi normal holat.

## 8. Real switch ulanganda nima o'zgartiriladi

TAA UI da:

```text
Ma'lumot yig'ish -> Hostlar -> core-sw01 -> Interfeyslar
```

Placeholder IP ni real switch IP manziliga almashtiring.

Misol:

```text
192.168.99.2 -> 10.0.10.2
```

Router uchun:

```text
Ma'lumot yig'ish -> Hostlar -> edge-rt01 -> Interfeyslar
```

Placeholder IP ni real Cisco 1800 IP manziliga almashtiring.

Misol:

```text
192.168.99.1 -> 10.0.10.1
```

SNMPv3 credentiallar ishlatilsa, template yoki host macro qismida real qiymatlarni kiriting. Aniq macro nomlari ulangan templatega qarab farq qilishi mumkin. Odatda quyidagilar bo'ladi:

```text
{$SNMPV3_USER}
{$SNMPV3_AUTH_PASS}
{$SNMPV3_PRIV_PASS}
{$SNMPV3_AUTH_PROTOCOL}
{$SNMPV3_PRIV_PROTOCOL}
```

## 9. Catalyst 3560G tomoni

Repo ichida switch config va EEM appletlar bor:

```text
scripts/network-configs/catalyst-3560g.cfg
scripts/network-configs/eem-applets/port_sec_violation.tcl
scripts/network-configs/eem-applets/stp_loop_detect.tcl
scripts/network-configs/eem-applets/export_binding_hourly.tcl
```

Real switchda quyidagilar sozlangan bo'lishi kerak:

- SNMP traplar TAA server IP manziliga yuboriladi;
- port-security traplar yoqilgan;
- bridge/STP topology change traplar yoqilgan;
- EEM appletlar flashga yuklangan va registered;
- `logging host <TAA_SERVER_IP>` sozlangan.

Namuna config ichidagi `10.0.10.10` qiymatini o'z TAA server IP manzilingizga almashtiring.

## 10. Cisco 1800 router tomoni

Repo ichida router config va WAN brute-force EEM appleti bor:

```text
scripts/network-configs/cisco-1800.cfg
scripts/network-configs/eem-applets/wan_brute_detect.tcl
```

`wan_brute_detect.tcl` quyidagi holatni kuzatadi:

```text
60 sekund ichida 5 ta Authentication failure
```

Applet ishga tushganda:

- `flash:/brute.log` ichiga diagnostika yozadi;
- `TAA-BRUTE` SNMP trap yuboradi;
- `TAA-ALERT` syslog xabarini chiqaradi;
- agar router mail serverga kira olsa, qisqa email yuboradi.

TAA tomonda oldindan yaratilgan item:

```text
WAN Brute Force Trap
snmptrap[TAA-BRUTE|WAN_BRUTE_DETECT|TAA-ALERT]
```

Oldindan yaratilgan trigger:

```text
edge-rt01: WAN brute-force urinishlari aniqlandi
```

Oldindan yaratilgan action:

```text
edge-rt01 WAN brute xabari
```

Real routerda quyidagilar sozlangan bo'lishi kerak:

- SNMP traplar TAA server IP manziliga yuboriladi;
- `logging host <TAA_SERVER_IP>` sozlangan;
- `WAN_BRUTE_DETECT` EEM applet registered;
- TAA serverda SNMP trapper ishlaydi.

## 11. Email actionni sozlash

DB ichida `Admin` userga vaqtincha placeholder address qo'yilgan:

```text
admin@example.com
```

TAA UI da uni o'zgartiring:

```text
Foydalanuvchilar -> Admin -> Media
```

`Email-custom` bo'yicha real email yozing.

`Email-custom` script SMTP env qiymatlarini talab qiladi:

```text
SMTP_HOST
SMTP_PORT
SMTP_USER
SMTP_PASS
FROM_ADDR
```

Bu qiymatlar real muhitda `/etc/zabbix/.env` yoki server/container environment orqali beriladi.

## 12. Scriptlarni serverga joylash

Repo ichida alert va external scriptlar bor:

```text
scripts/alertscripts/auto_remediation.py
scripts/alertscripts/taa_email.sh
scripts/alertscripts/taa_telegram.sh
scripts/externalscripts/stp_loop_parser.py
scripts/externalscripts/ip_inventory.py
```

Bare-metal TAA serverda:

```bash
sudo bash scripts/install.sh
```

Bu scriptlar uchun quyidagi yo'llarni tayyorlaydi:

```text
/usr/lib/zabbix/alertscripts/
/usr/lib/zabbix/externalscripts/
```

Docker test muhitida ham DB ichida script action yoqilgan. Real trap kelganda script ishga tushishi uchun scriptlar container yoki server ichida aynan shu pathlarda mavjud bo'lishi kerak.

## 13. Auto-remediation action qanday ishlaydi

Quyidagi action real rejimda yoqilgan:

```text
core-sw01 Port Security auto-remediation
```

U quyidagi global scriptni chaqiradi:

```text
TAA auto-remediation port shutdown
```

Command:

```bash
/usr/lib/zabbix/alertscripts/auto_remediation.py --switch {HOST.IP} --trap-text "{ITEM.LASTVALUE}" --reason "{EVENT.NAME}" --operator "TAA-ACTION"
```

`auto_remediation.py` trap matnidan `Gi0/5`, `Fa0/24`, `Te1/0/1` yoki to'liq `GigabitEthernet0/5` kabi port nomini avtomatik ajratadi. Port topilmasa, script `exit 2` bilan to'xtaydi va hech qanday shutdown qilmaydi.

Real ishlashi uchun:

1. `auto_remediation.py` serverda mavjudligini tekshiring.
2. `netmiko` o'rnatilganligini tekshiring.
3. Switch credentiallarini sozlang:

```text
SW_USER
SW_PASS
SW_ENABLE
AUDIT_DB
```

4. Trap ichida real port nomi kelayotganini tekshiring, masalan:

```text
TAA-PSEC port=Gi0/5 mac=aabb.ccdd.eeff host=core-sw01
```

5. Switchda `taa_auto` user faqat kerakli buyruqlarni bajaradigan cheklangan privilege bilan yaratilgan bo'lsin.
6. `/var/lib/taa/audit.db` yoziladigan bo'lsin.

## 14. Qurilmasiz tekshiruv nimani isbotlaydi

Qurilmasiz quyidagilar tekshiriladi:

- Docker stack ko'tariladi;
- UI ochiladi;
- DB dump import bo'lgan;
- `core-sw01` hosti bor;
- item, trigger va actionlar DBda mavjud;
- clone qilgan odam configni ko'ra oladi;
- real qurilma ulanganda qaysi joylarni almashtirish kerakligi aniq.

Qurilmasiz quyidagilar tekshirilmaydi:

- real SNMP polling;
- real SNMP trap kelishi;
- EEM applet ishlashi;
- port shutdown remediation, agar real trap va credentiallar sozlanmagan bo'lsa;
- SMTP/Telegram real yuborish.

## 15. Real qurilma ulangandan keyingi final checklist

- [ ] `core-sw01` IP real switch IPga almashtirildi.
- [ ] `edge-rt01` IP real router IPga almashtirildi.
- [ ] SNMPv3 user/password/protocol qiymatlari to'g'ri.
- [ ] Switchdan TAA serverga UDP 162 traplar boradi.
- [ ] Routerdan TAA serverga UDP 162 traplar boradi.
- [ ] TAA serverda SNMP trapper ishlaydi.
- [ ] `Monitoring -> Latest data` ichida SNMP qiymatlar paydo bo'ldi.
- [ ] Port security trap test qilindi.
- [ ] STP topology/root change trap test qilindi.
- [ ] WAN brute-force / authentication failure trap test qilindi.
- [ ] Email action real manzilga xabar yubordi.
- [ ] Auto-remediation action enabled holatda.
- [ ] Port security trap qiymatida port nomi bor.
- [ ] Auto-remediation portni shutdown qildi va `/var/lib/taa/audit.db` ichiga yozuv qo'shdi.
