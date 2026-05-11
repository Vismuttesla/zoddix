# TAA — to'liq o'rnatish yo'riqnomasi (BIOS dan dashboardgacha)

Bu hujjat **toza HP ProLiant DL-160 Gen9 serveri** asosida butun KXD muammolari yechimini noldan ko'tarish bo'yicha to'liq qadamlar to'plamidir. Boshlovchi tarmoq admini ham qadamlarni *ko'r-ko'rona* takrorlab natijaga erishishi mumkin.

> **Yashil chiziq (laboratoriya holati)**: TAA server 10.0.10.10/24, Catalyst 3560G 10.0.99.2, Cisco 1800 10.0.99.1, TP-Link 1024D — IPsiz. Sizning topologiyangiz boshqacha bo'lsa, har bir IP ni o'zingiznikiga o'zgartiring.

Yo'riqnoma 13 qadamga bo'lingan. Har qadam oxirida natijani tasdiqlovchi komanda yoki screenshot joyi ko'rsatilgan.

---

## Qadam 1 — DL-160 Gen9 BIOS, RAID va Ubuntu o'rnatish

### 1.1 BIOS sozlash

1. Server yuklanayotganida `F9` tugmasi (System Utilities → System Configuration → BIOS/Platform Configuration).
2. **Boot Options** → `Boot Mode = UEFI`, `Legacy BIOS Boot Order` o'chirilgan.
3. **System Options → Virtualization** → `Intel(R) VT-x = Enabled`.
4. **Power Management** → `HP Power Profile = Maximum Performance`.

![](img/01_bios.png)

### 1.2 RAID konfiguratsiya (Smart Storage Administrator)

1. Yuklash paytida `F10` → Intelligent Provisioning yoki tashqi SSA.
2. Diskdan **RAID 1** (mirror) yarating — 2 ta SAS/SSD disk.
3. Logical Drive nomi: `OS_MIRROR`, hajmi to'liq.
4. **OK → Save → Reboot**.

![](img/02_raid.png)

### 1.3 Ubuntu 22.04 LTS o'rnatish

1. Ubuntu Server 22.04 ISO ni USB ga yozing (Rufus / `dd`).
2. Yuklash menyusidan USB ni tanlang.
3. Quyidagi sozlamalar:
   - Til: `English`
   - Tarmoq: statik IP `10.0.10.10/24`, gateway `10.0.10.1`, DNS `8.8.8.8`
   - Storage: Use entire disk + LVM
   - Profile: hostname `taa-server`, user `taauser`
   - **Install OpenSSH server** belgilangan
   - Snap'lardan hech narsa tanlamang
4. O'rnatishdan keyin qayta yuklang va SSH bilan kiring:

```bash
ssh taauser@10.0.10.10
sudo apt update && sudo apt -y upgrade
sudo timedatectl set-timezone Asia/Tashkent
sudo hostnamectl set-hostname taa-server
```

![](img/03_ubuntu_install.png)

**Tasdiqlash**: `lsb_release -a` natijasi `Ubuntu 22.04.x LTS` chiqarsa qadam yakunlangan.

---

## Qadam 2 — Docker va asosiy paketlar

```bash
sudo apt update
sudo apt install -y \
    docker.io docker-compose-plugin \
    python3 python3-pip \
    tftpd-hpa snmptrapd snmp net-snmp \
    sqlite3 postgresql-client curl git jq

sudo systemctl enable --now docker
sudo usermod -aG docker taauser
newgrp docker
sudo pip3 install --upgrade netmiko psycopg2-binary jinja2 pyyaml
```

TFTP root tayyorlash (3560G konfiguratsiyalari va binding'lar shu yerga keladi):

```bash
sudo mkdir -p /srv/tftp/configs /srv/tftp/binding
sudo chown -R tftp:tftp /srv/tftp
sudo sed -i 's|TFTP_DIRECTORY=.*|TFTP_DIRECTORY="/srv/tftp"|' /etc/default/tftpd-hpa
sudo sed -i 's|TFTP_OPTIONS=.*|TFTP_OPTIONS="--secure --create"|' /etc/default/tftpd-hpa
sudo systemctl restart tftpd-hpa
```

**Tasdiqlash**:

```bash
docker --version
docker compose version
python3 -c "import netmiko, psycopg2, jinja2, yaml; print('OK')"
echo "test" | tftp -p -l - 10.0.10.10 -c put test.txt    # /srv/tftp/test.txt paydo bo'ladi
```

![](img/04_docker_versions.png)

---

## Qadam 3 — Switch (3560G, 1800) ulashish va SSH access tayyorlash

### 3.1 Konsol orqali boshlang'ich kirish

1. RJ45-USB konsol kabelni 3560G ning `console` portiga ulang.
2. `PuTTY` yoki `screen /dev/ttyUSB0 9600 8N1` ochib `enable` rejimiga o'ting.

### 3.2 Boshqaruv VLAN va IP

```cisco
core-sw01# configure terminal
core-sw01(config)# vlan 99
core-sw01(config-vlan)# name MGMT
core-sw01(config-vlan)# exit
core-sw01(config)# interface vlan 99
core-sw01(config-if)# ip address 10.0.99.2 255.255.255.0
core-sw01(config-if)# no shutdown
core-sw01(config-if)# exit
core-sw01(config)# ip default-gateway 10.0.99.1
core-sw01(config)# interface GigabitEthernet0/48
core-sw01(config-if)# description To-TAA-Server
core-sw01(config-if)# switchport mode access
core-sw01(config-if)# switchport access vlan 99
core-sw01(config-if)# end
core-sw01# write memory
```

### 3.3 SSH va admin user

```cisco
core-sw01(config)# hostname core-sw01
core-sw01(config)# ip domain-name taa.local
core-sw01(config)# crypto key generate rsa modulus 2048
core-sw01(config)# username taa_auto privilege 15 secret <STRONG_PASSWORD>
core-sw01(config)# line vty 0 15
core-sw01(config-line)# transport input ssh
core-sw01(config-line)# login local
core-sw01(config-line)# access-class 23 in
core-sw01(config-line)# exit
core-sw01(config)# access-list 23 permit 10.0.10.10
core-sw01(config)# access-list 23 deny any log
core-sw01(config)# ip ssh version 2
core-sw01(config)# end
core-sw01# write memory
```

DL-160 dan SSH ulanishni tekshiring:

```bash
ssh taa_auto@10.0.99.2
core-sw01> show version | include IOS
```

Xuddi shu qadamlarni Cisco 1800 (`edge-rt01`) uchun ham takrorlang (IP `10.0.99.1`).

![](img/05_ssh_login.png)

---

## Qadam 4 — `scripts/install.sh` ni ishga tushirish

Loyihaning klonini DL-160 ga oling:

```bash
cd /opt
sudo git clone https://example.git/taa.git
sudo chown -R taauser:taauser /opt/taa
cd /opt/taa
git checkout script   # ushbu skriptlar branchi
```

Asosiy o'rnatish skripti:

```bash
sudo bash scripts/install.sh
```

Bu skript quyidagilarni qiladi:

| Bosqich | Nima qiladi |
|---------|-------------|
| 1 | `/usr/lib/zabbix/{externalscripts,alertscripts}` papkalarini yaratadi |
| 2 | `alertscripts/*.sh|*.py` ni `chmod 700`, egasi `zabbix:zabbix` qilib joylaydi |
| 3 | `externalscripts/*.py` ni `chmod 750` qilib joylaydi |
| 4 | `/etc/zabbix/.env` shablonini yaratadi (`chmod 600`) |
| 5 | `/var/lib/taa/audit.db` SQLite faylini yaratadi va `blocks` jadvalini sozlaydi |
| 6 | `cron` qatori qo'shadi: `*/5 * * * * /opt/taa/scripts/externalscripts/ip_inventory.py` |
| 7 | `snmptrapd` ni TAA bilan integratsiya qilish uchun sozlaydi |

**`/etc/zabbix/.env`** ni tahrirlang (Switch credentials va Telegram token):

```bash
sudo nano /etc/zabbix/.env
```

```bash
SW_USER=taa_auto
SW_PASS=<STRONG_PASSWORD>
SW_ENABLE=<ENABLE_SECRET>

TG_TOKEN=123456:AAFooBarBaz
TG_DEFAULT_CHAT=123456789

PG_DSN=postgresql://taa:taa_pass@127.0.0.1:5432/taa_ipam
```

```bash
sudo chmod 600 /etc/zabbix/.env
sudo chown zabbix:zabbix /etc/zabbix/.env
```

**Tasdiqlash**:

```bash
ls -la /usr/lib/zabbix/alertscripts/ /usr/lib/zabbix/externalscripts/
sudo -u zabbix sqlite3 /var/lib/taa/audit.db ".tables"   # blocks
sudo crontab -u zabbix -l | grep ip_inventory
```

![](img/06_install_sh.png)

---

## Qadam 5 — Docker compose ko'tarish (TAA, Postgres)

```bash
cd /opt/taa
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
```

Quyidagi 3 konteyner `Up` holatda bo'lishi kerak: `taa-server`, `taa-web`, `taa-db` (Postgres).

IPAM uchun ham xuddi shu Postgres ishlatiladi:

```bash
sudo docker exec -it taa-db psql -U postgres -c "CREATE DATABASE taa_ipam;"
sudo docker exec -it taa-db psql -U postgres -c "CREATE USER taa WITH PASSWORD 'taa_pass';"
sudo docker exec -it taa-db psql -U postgres -c "GRANT ALL ON DATABASE taa_ipam TO taa;"
sudo docker exec -i taa-db psql -U taa -d taa_ipam < scripts/sql/ipam_schema.sql
```

**Tasdiqlash**: `http://10.0.10.10` ga brauzerdan kiring, TAA login sahifasi ko'rinadi.

![](img/07_compose_up.png)

---

## Qadam 6 — Cisco config'larini TFTP orqali yuklash

### 6.1 Catalyst 3560G

```bash
# DL-160 da:
sudo cp /opt/taa/scripts/network-configs/3560g_baseline.cfg /srv/tftp/configs/
sudo chown tftp:tftp /srv/tftp/configs/3560g_baseline.cfg
```

```cisco
core-sw01# copy tftp://10.0.10.10/configs/3560g_baseline.cfg running-config
core-sw01# write memory
```

### 6.2 Cisco 1800

```bash
sudo cp /opt/taa/scripts/network-configs/cisco1800_baseline.cfg /srv/tftp/configs/
sudo chown tftp:tftp /srv/tftp/configs/cisco1800_baseline.cfg
```

```cisco
edge-rt01# copy tftp://10.0.10.10/configs/cisco1800_baseline.cfg running-config
edge-rt01# write memory
```

**Tasdiqlash**:

```cisco
core-sw01# show running-config | include port-security|dhcp snooping|arp inspection
core-sw01# show ip dhcp snooping
```

![](img/08_tftp_push.png)

---

## Qadam 7 — EEM applet'larni qo'lda paste qilish

EEM applet'lar IOS parser uchun nozik (har action qatori raqamlangan). Avtomatik push ba'zan satrlarni siqib yuboradi. Qo'lda paste qilish ishonchli:

```cisco
core-sw01# configure terminal
core-sw01(config)# ! --- PORT_SEC_VIOLATION applet ---
core-sw01(config)# event manager applet PORT_SEC_VIOLATION
core-sw01(config-applet)# event syslog pattern "PSECURE_VIOLATION" maxrun 30
core-sw01(config-applet)# action 010 regexp "Gi[0-9]+\/[0-9]+" "$_syslog_msg" port
core-sw01(config-applet)# action 020 regexp "([0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})" "$_syslog_msg" mac
core-sw01(config-applet)# action 030 cli command "enable"
core-sw01(config-applet)# action 040 cli command "show running-config interface $port | append flash:/violations.log"
core-sw01(config-applet)# action 050 snmp-trap strdata "TAA-PSEC port=$port mac=$mac"
core-sw01(config-applet)# action 060 syslog priority critical msg "TAA-ALERT: $port da $mac MAC violation"
core-sw01(config-applet)# exit
```

Xuddi shu tarzda `STP_LOOP_DETECT` va `EXPORT_BINDING_HOURLY` applet'larni paste qiling. To'liq matn: `scripts/network-configs/eem_applets.txt`.

Cisco 1800 da `WAN_BRUTE_DETECT` applet ham xuddi shu yo'l bilan kiritiladi.

### Muqobil yo'l — netmiko orqali avtomatik push

```bash
cd /opt/taa
python3 scripts/provisioning/push_eem.py --switch 10.0.99.2 --applets eem_applets.txt
```

**Tasdiqlash**:

```cisco
core-sw01# show event manager policy registered
# applet  user  ...  PORT_SEC_VIOLATION
# applet  user  ...  STP_LOOP_DETECT
# applet  user  ...  EXPORT_BINDING_HOURLY
```

![](img/09_eem.png)

---

## Qadam 8 — TAA UI da hostlarni yaratish

1. TAA web UI (http://10.0.10.10) → **Configuration → Hosts → Create host**.
2. Quyidagi 3 ta xost yarating:

| Host name | Visible name | Interfaces | Templates |
|-----------|--------------|-----------|-----------|
| `core-sw01` | `Catalyst 3560G` | SNMP 10.0.99.2:161 | `Cisco IOS by SNMP`, `Generic SNMP` |
| `edge-rt01` | `Cisco 1800 Router` | SNMP 10.0.99.1:161 | `Cisco IOS by SNMP` |
| `tp-link-edge` | `TP-Link 1024D (unmanaged)` | Agent 10.0.99.50, faqat ICMP check | `ICMP Ping` |

3. Har bir hostni **Groups**: `Network devices` ga qo'shing.

![](img/10_host_create.png)

---

## Qadam 9 — SNMPv3 credentials kiritish

1. **Configuration → Hosts → core-sw01 → SNMP interface** ni tahrirlang.
2. **SNMP version**: `SNMPv3`
3. **Context name**: bo'sh
4. **Security name**: `taa_user`
5. **Security level**: `authPriv`
6. **Authentication protocol**: `SHA`
7. **Authentication passphrase**: `<sha_pass>`
8. **Privacy protocol**: `AES`
9. **Privacy passphrase**: `<aes_pass>`
10. **Update** ni bosing.

> 3560G da quyidagi config'ni qo'shganingizga ishonch hosil qiling:
> ```cisco
> core-sw01(config)# snmp-server group TAA_GROUP v3 priv
> core-sw01(config)# snmp-server user taa_user TAA_GROUP v3 auth sha <sha_pass> priv aes 128 <aes_pass>
> core-sw01(config)# snmp-server host 10.0.10.10 version 3 priv taa_user udp-port 162
> core-sw01(config)# snmp-server enable traps
> ```

**Tasdiqlash**:

```bash
# DL-160 dan SNMP walk sinov:
snmpwalk -v3 -l authPriv -u taa_user -a SHA -A <sha_pass> -x AES -X <aes_pass> 10.0.99.2 sysDescr
```

![](img/11_snmpv3.png)

---

## Qadam 10 — Network Discovery rule yaratish

1. **Configuration → Discovery → Create discovery rule**.
2. **Name**: `TAA Network Discovery`
3. **IP range**: `10.0.10.1-254,10.0.20.1-254,10.0.30.1-254`
4. **Update interval**: `1h`
5. **Checks**: ICMP ping + SNMPv3 (oid `sysDescr.0`)
6. **Device uniqueness criteria**: `SNMP value of sysDescr.0`
7. **Enabled** belgisini qo'ying va **Add** ni bosing.

![](img/12_discovery.png)

Discovery action ham yarating: **Configuration → Actions → Discovery actions → Create**.

- **Conditions**: `Discovery status = Up` AND `Received value contains "Cisco"`
- **Operations**: `Add host`, `Add to host groups: Network devices`, `Link template: Cisco IOS by SNMP`

---

## Qadam 11 — Media types va Actions sozlash

### 11.1 Telegram-custom media type

1. **Administration → Media types → Create media type**.
2. **Name**: `Telegram-custom`
3. **Type**: `Script`
4. **Script name**: `taa_telegram.sh`
5. **Script parameters**:
   - `{ALERT.SENDTO}`
   - `{ALERT.SUBJECT}`
   - `{ALERT.MESSAGE}`
6. **Message templates**: `Problem`, `Recovery` uchun matnli shablonlar qo'shing.

### 11.2 Action

1. **Configuration → Actions → Trigger actions → Create action**.
2. **Name**: `Network critical events`
3. **Conditions**:
   - `Host group equals Network devices`
   - `Trigger severity >= High`
4. **Operations**:
   - **Send message** to `Admins` via `Telegram-custom`
   - **Remote command** on `core-sw01`: `Custom script` → `auto_remediation.py {HOST.CONN} {ITEM.VALUE1} {TRIGGER.NAME}`

![](img/13_actions.png)

### 11.3 Foydalanuvchini Telegram media bilan bog'lash

1. **Administration → Users → Admin → Media** → **Add**.
2. **Type**: `Telegram-custom`
3. **Send to**: `<your chat_id>`
4. **Update**.

**Tasdiqlash**: Media type → Test tugmasi orqali yuborib ko'ring (qarang `validation.md` § P4).

---

## Qadam 12 — Inventory mode = Automatic va dashboardlar

### 12.1 Inventory mode

1. **Configuration → Hosts → core-sw01 → Inventory** tab.
2. **Inventory mode**: `Automatic` ni tanlang.
3. Inventory maydonlarini SNMP itemlarga bog'lang (yoki shablon ichida tayyor bo'ladi).
4. Edge-rt01 va boshqa xostlar uchun ham takrorlang.

![](img/14_inventory.png)

### 12.2 Custom dashboardlar

1. **Monitoring → Dashboards → Create dashboard**.
2. Quyidagi 2 ta dashboard yarating:

**A) "Halqa hodisalari" (Loop events)**
- Widget 1: **Problems** — `Host: core-sw01`, tag `loop`
- Widget 2: **Graph (classic)** — item `snmptrap[loop]`
- Widget 3: **Item value** — oxirgi JSON qiymati (port/vlan/mac)
- Widget 4: **Plain text** — `flash:/stp_event.log` oxirgi 20 qator

**B) "Port security violations"**
- Widget 1: **Problems** — tag `port-security`
- Widget 2: **Top hosts** — eng ko'p violation bo'lgan portlar (top 10)
- Widget 3: **Graph** — violation counter (SNMP `cpsIfViolationCount`)
- Widget 4: **Trigger overview** — oxirgi 24 soat

![](img/15_dashboard.png)

---

## Qadam 13 — Yakuniy tekshirish

Barcha sozlamalar tayyor. Endi to'liq validatsiya jarayonidan o'ting:

> Batafsil testlar uchun [`validation.md`](validation.md) ga o'ting. Quyidagi minimal *smoke test* uchun yetarli:

```bash
# 1. TAA hostlari "Available" holatda:
curl -s -u Admin:zabbix "http://10.0.10.10/zabbix/api_jsonrpc.php" \
   -H "Content-Type: application/json" \
   -d '{"jsonrpc":"2.0","method":"host.get","params":{"output":["host","status"]},"id":1,"auth":"<token>"}' \
   | jq

# 2. 3560G dan trap kelishini sinash:
core-sw01# event manager run PORT_SEC_VIOLATION   # (qo'lda trigger)

# 3. Telegram media type test (UI dan):
# Administration -> Media types -> Telegram-custom -> Test

# 4. Inventory:
psql -U taa -h 127.0.0.1 -d taa_ipam -c "select count(*) from leases;"
```

![](img/16_done.png)

Hammasi yashil bo'lsa — yechim ishlamoqda. Aks holda **`validation.md`** dagi troubleshooting jadvallariga qarang.

---

## Ilova A — Komandalar konspekti

| Maqsad | Komanda |
|--------|---------|
| Docker konteynerlarni qaytadan ishga tushirish | `cd /opt/taa && sudo docker compose restart` |
| TAA server logini ko'rish | `sudo tail -f /var/log/zabbix/zabbix_server.log` |
| SNMP trap log | `sudo tail -f /var/log/snmptrap.log` |
| 3560G running-config ni TFTP ga yuborish | `core-sw01# copy running-config tftp://10.0.10.10/configs/3560g_backup.cfg` |
| Postgres ga kirish | `sudo docker exec -it taa-db psql -U taa -d taa_ipam` |
| `taa_telegram.sh` ni sinash | `sudo -u zabbix bash -c 'source /etc/zabbix/.env && /usr/lib/zabbix/alertscripts/taa_telegram.sh "$TG_DEFAULT_CHAT" "test" "ok"'` |
