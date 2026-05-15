# TAA Agent 2 — Linux uchun build, o'rnatish va Docker

Ushbu papka TAA monitoring tizimining **Linux** uchun mo'ljallangan agentini
(`taa_agent2`) bare-metal serverga (masalan, **HPE DL-160 Gen9 + Ubuntu 22.04**)
o'rnatish va Docker konteynerida ishga tushirish uchun barcha artifactlarni
o'z ichiga oladi.

Windows varianti `D:\TAA\zoddix\bin\win64\taa_agent2.exe` da, bu yerdagi
fayllar esa Linux uchun **kross-kompilyatsiya** va **o'rnatish skriptlari**dir.

---

## Fayllar tarkibi

| Fayl                                | Vazifasi                                                       |
|-------------------------------------|----------------------------------------------------------------|
| `build.sh`                          | Linux uchun Go bilan kross-kompilyatsiya                       |
| `taa_agent2.conf`                   | Linux FHS yo'llari bilan agent konfiguratsiyasi                |
| `taa-agent2.service`                | systemd unit fayli                                             |
| `install.sh`                        | DL-160 Gen9 / Ubuntu 22.04 uchun idempotent o'rnatuvchi        |
| `uninstall.sh`                      | O'rnatishni bekor qiluvchi                                     |
| `Dockerfile`                        | TAA-brandlangan multi-stage Docker image                       |
| `docker-compose.taa-agent.yml`      | Asosiy compose ustida overlay                                  |

---

## 1. Tezkor boshlash (bare-metal)

```bash
# 1) Linux uchun binar yig'ish (statik, amd64)
./scripts/linux-agent/build.sh --arch amd64 --static

# 2) Maqsadli serverga ko'chiring (rsync/scp), so'ng o'rnatuvchini ishga tushiring
sudo ./scripts/linux-agent/install.sh

# 3) Configni tahrirlang: Server, ServerActive, Hostname
sudo nano /etc/taa/agent/taa_agent2.conf

# 4) Servisni ishga tushiring
sudo systemctl start taa-agent2
sudo systemctl status taa-agent2
```

`install.sh` quyidagilarni bajaradi:

- `taa-agent` tizim foydalanuvchisi va guruhini yaratadi (idempotent)
- `/etc/taa/agent`, `/var/log/taa/agent`, `/var/run/taa/agent`,
  `/var/lib/taa/agent` papkalarini `0750` ruxsat bilan tayyorlaydi
- `taa_agent2` ni `/usr/sbin/` ga joylaydi (`0755`, `root:root`)
- `taa_agent2.conf` ni `/etc/taa/agent/` ga joylaydi (`0640`, `taa-agent:taa-agent`).
  Mavjud config bo'lsa `.bak.<timestamp>` qilib saqlaydi va ustiga yozmaydi.
- `taa-agent2.service` ni `/etc/systemd/system/` ga joylaydi va `enable` qiladi
- UFW faol bo'lsa `10050/tcp` ni ochadi
- SELinux Enforcing bo'lsa `semanage port` orqali siyosat qo'shadi

### Dry-run rejim

```bash
sudo ./scripts/linux-agent/install.sh --dry-run
```

---

## 2. Docker varianti

```bash
# TAA-brandlangan image yig'ish va ishga tushirish
docker compose \
    -f docker-compose.yml \
    -f scripts/linux-agent/docker-compose.taa-agent.yml \
    up -d --build

# Konteyner logini ko'rish
docker logs -f taa-agent-linux

# Sog'liq tekshiruvi
docker inspect --format '{{.State.Health.Status}}' taa-agent-linux
```

Hostda port: **10053** -> konteynerda **10050**
(Windows agenti `10055` ishlatadi, shu sababli to'qnashmaydi).

---

## 3. Konfiguratsiya

Asosiy fayl: `/etc/taa/agent/taa_agent2.conf`

Eng kamida o'zgartirishingiz lozim parametrlar:

```ini
Server=<TAA server IP>
ServerActive=<TAA server IP>:10051
Hostname=<frontendda ro'yxatdan o'tkazilgan host nomi>
```

Drop-in fayllar uchun `/etc/taa/agent/taa_agent2.d/*.conf` qo'shilishi mumkin.

### TLS (ishlab chiqarishda majburiy)

`taa_agent2.conf` ichida PSK misoli izohlangan. PSK kalit yarating:

```bash
sudo openssl rand -hex 32 | sudo tee /etc/taa/agent/taa_agent2.psk
sudo chown taa-agent:taa-agent /etc/taa/agent/taa_agent2.psk
sudo chmod 0600 /etc/taa/agent/taa_agent2.psk
```

Configdagi `TLSConnect`, `TLSAccept`, `TLSPSKIdentity`, `TLSPSKFile` qatorlarini yoqing.

---

## 4. Sinov

```bash
# Lokal agentdan kalitni so'rash
taa_agent2 -t agent.ping -c /etc/taa/agent/taa_agent2.conf
taa_agent2 -t system.uname -c /etc/taa/agent/taa_agent2.conf

# Server tomonidan tekshirish (TAA serverdan)
zabbix_get -s <agent_ip> -p 10050 -k agent.ping
```

---

## 5. Loglar

```bash
# systemd jurnali (jonli)
journalctl -u taa-agent2 -f

# Agent log fayli
sudo tail -f /var/log/taa/agent/taa_agent2.log
```

---

## 6. O'chirish

```bash
sudo ./scripts/linux-agent/uninstall.sh

# To'liq tozalash (foydalanuvchini ham olib tashlash):
sudo ./scripts/linux-agent/uninstall.sh --purge-user
```

`uninstall.sh` config va data papkalariga **tegmaydi** — ularni qo'lda
o'chirish kerak (avval backup oling).

---

## 7. Talablar

- **Bare-metal**: Linux yadrosi >= 5.x, systemd, glibc (statik build bo'lsa kerak emas)
- **Build mashinasi**: Go >= 1.20, `git` (ixtiyoriy — versiya teglash uchun)
- **Docker**: Docker Engine 20.10+, Compose v2
