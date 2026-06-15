# TAA Agent 2 Windows uchun to'liq o'rnatish va tekshirish qo'llanmasi

Ushbu qo'llanma Windows kompyuter yoki Windows serverga `TAA Agent 2` ni o'rnatish, TAA serverga ulash, TAA UI da host/template sozlash va metrikalar kelayotganini tekshirish uchun yozilgan.

## 1. Maqsad

TAA Agent 2 Windows hostdan quyidagi ma'lumotlarni TAA serverga olib keladi:

- agent holati: `agent.ping`, `agent.version`;
- CPU yuklamasi;
- RAM ishlatilishi;
- disk hajmi va bo'sh joy;
- tarmoq interfeyslari;
- Windows service/process holatlari;
- kerak bo'lsa custom `UserParameter` metrikalari.

To'liq ishlashi uchun ikkala tomon sozlanadi:

- Windows hostda `TAA Agent 2` servisi ishlashi kerak;
- TAA server UI da shu host yaratilgan va Windows template ulangan bo'lishi kerak.

## 2. Namuna qiymatlar

Quyidagi qiymatlar misol sifatida ishlatiladi. O'z muhitingizga moslab almashtiring.

| Parametr | Namuna qiymat | Izoh |
|---|---:|---|
| TAA server IP | `10.0.10.10` | TAA server yoki proxy manzili |
| Windows host IP | `10.0.20.50` | Monitoring qilinadigan Windows host |
| Hostname | `PC-BUH-01` | TAA UI dagi host nomi bilan bir xil bo'lishi shart |
| Passive agent port | `10050` | Standart agent porti |
| Server active port | `10051` | TAA server trapper/active check porti |

Muhim: repo ichidagi `conf/taa_agent2.conf` faylida `ListenPort=10055` bo'lishi mumkin. Standart va sodda o'rnatish uchun uni `10050` ga almashtiring yoki server UI va firewall qoidalarida ham `10055` ni ishlating. Tavsiya: `10050`.

## 3. Kerakli fayllar

Repo ichida Windows agent uchun kerakli fayllar:

| Fayl yoki papka | Vazifasi |
|---|---|
| `bin/win64/taa_agent2.exe` | Windows x64 agent binary |
| `conf/taa_agent2.conf` | Asosiy config namunasi |
| `conf/taa_agent2.d/` | Qo'shimcha `UserParameter` configlari |
| `logs/` | Lokal test paytida loglar uchun ishlatilgan papka |

Windows hostga quyidagi strukturada o'rnatish tavsiya qilinadi:

```text
C:\Program Files\TAA\Agent\
  taa_agent2.exe
  taa_agent2.conf
  taa_agent2.d\

C:\ProgramData\TAA\Agent\logs\
  taa_agent2.log
```

## 4. Windows hostga fayllarni ko'chirish

Windows hostda PowerShell ni Administrator sifatida oching.

Repo fayllari Windows hostga allaqachon ko'chirilgan deb faraz qilamiz. Masalan, repo `D:\TAA\zoddix` da bo'lsa:

```powershell
New-Item -ItemType Directory -Force -Path 'C:\Program Files\TAA\Agent'
New-Item -ItemType Directory -Force -Path 'C:\ProgramData\TAA\Agent\logs'

Copy-Item 'D:\TAA\zoddix\bin\win64\taa_agent2.exe' 'C:\Program Files\TAA\Agent\'
Copy-Item 'D:\TAA\zoddix\conf\taa_agent2.conf' 'C:\Program Files\TAA\Agent\'
Copy-Item 'D:\TAA\zoddix\conf\taa_agent2.d' 'C:\Program Files\TAA\Agent\' -Recurse -Force
```

Agar fayllar boshqa joyda bo'lsa, `D:\TAA\zoddix` qismini o'sha joyga almashtiring.

## 5. Agent configini sozlash

Quyidagi faylni tahrirlang:

```text
C:\Program Files\TAA\Agent\taa_agent2.conf
```

Minimal tavsiya qilingan config:

```ini
LogType=file
LogFile=C:\ProgramData\TAA\Agent\logs\taa_agent2.log
LogFileSize=10
DebugLevel=3

Server=10.0.10.10
ServerActive=10.0.10.10:10051
Hostname=PC-BUH-01

ListenPort=10050
ListenIP=0.0.0.0

Timeout=30
RefreshActiveChecks=60

Include=C:\Program Files\TAA\Agent\taa_agent2.d\*.conf
```

Parametrlar izohi:

| Parametr | Vazifasi |
|---|---|
| `Server` | Passive check uchun agentga ulanishi mumkin bo'lgan TAA server/proxy IP manzili |
| `ServerActive` | Active check uchun agent ulanadigan TAA server/proxy manzili |
| `Hostname` | TAA UI dagi host nomi bilan aynan bir xil bo'lishi kerak |
| `ListenPort` | Passive check porti, tavsiya `10050` |
| `LogFile` | Agent log yozadigan fayl |
| `Include` | Qo'shimcha custom metrikalar joylashgan papka |

Hostname mos kelmasa, active checks ishlamaydi yoki ma'lumot boshqa hostga bog'lanmaydi.

## 6. Config sintaksisini tekshirish

Administrator PowerShell:

```powershell
Set-Location 'C:\Program Files\TAA\Agent'
.\taa_agent2.exe --print --config 'C:\Program Files\TAA\Agent\taa_agent2.conf'
```

Xatolik chiqmasa, config o'qilyapti. Xatolik bo'lsa, ko'rsatilgan qatorni configda to'g'rilang.

## 7. Agentni servis sifatida o'rnatish

Administrator PowerShell:

```powershell
Set-Location 'C:\Program Files\TAA\Agent'
.\taa_agent2.exe --install --config 'C:\Program Files\TAA\Agent\taa_agent2.conf'
Start-Service "TAA Agent 2"
Get-Service "TAA Agent 2"
```

Natija `Running` bo'lishi kerak.

Agar servis nomi boshqacha ko'rinsa, quyidagicha tekshiring:

```powershell
Get-Service | Where-Object { $_.Name -like '*taa*' -or $_.DisplayName -like '*TAA*' }
```

## 8. Windows Firewall sozlash

Passive checks ishlashi uchun Windows hostda agent portini oching:

```powershell
New-NetFirewallRule -DisplayName "TAA Agent 2" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 10050 `
  -Action Allow
```

Faqat active checks ishlatilsa, inbound port ochish shart emas. Lekin diagnostika va `zabbix_get` bilan tekshirish uchun `10050` ochiq bo'lgani qulay.

Firewall qoidasini tekshirish:

```powershell
Get-NetFirewallRule -DisplayName "TAA Agent 2"
```

## 9. Agent logini tekshirish

Windows hostda:

```powershell
Get-Content 'C:\ProgramData\TAA\Agent\logs\taa_agent2.log' -Tail 50
```

Logda quyidagi holatlar tekshiriladi:

- agent start bo'lgan;
- config fayl o'qilgan;
- active checks uchun serverga ulanish xatosi yo'q;
- `Hostname` noto'g'ri degan xabar yo'q;
- permission yoki log yozish xatosi yo'q.

## 10. TAA server tomondan tarmoqni tekshirish

TAA serverdan Windows host porti ochiq ekanini tekshiring.

Linux serverda:

```bash
nc -vz 10.0.20.50 10050
```

Yoki PowerShell mavjud bo'lsa:

```powershell
Test-NetConnection 10.0.20.50 -Port 10050
```

Ulanish muvaffaqiyatli bo'lishi kerak.

## 11. TAA serverdan agentni tekshirish

TAA serverda `zabbix_get` mavjud bo'lsa:

```bash
zabbix_get -s 10.0.20.50 -p 10050 -k agent.ping
zabbix_get -s 10.0.20.50 -p 10050 -k agent.version
zabbix_get -s 10.0.20.50 -p 10050 -k system.hostname
```

Kutilgan natijalar:

```text
1
TAA Agent 2 ...
PC-BUH-01 yoki Windows host nomi
```

Agar `zabbix_get` timeout bersa:

- Windows firewallni tekshiring;
- `ListenPort=10050` ekanini tekshiring;
- `Server=10.0.10.10` ichida TAA server IP to'g'ri yozilganini tekshiring;
- Windows host va TAA server orasida routing borligini tekshiring.

## 12. TAA UI da host yaratish

Brauzerda TAA UI ni oching:

```text
http://10.0.10.10:8098
```

Keyin:

1. `Data collection` -> `Hosts` bo'limiga kiring.
2. `Create host` ni bosing.
3. `Host name` maydoniga configdagi qiymatni yozing:

```text
PC-BUH-01
```

4. `Groups` uchun mos guruh tanlang yoki yangi guruh yarating, masalan:

```text
Windows hosts
```

5. `Interfaces` qismida `Agent` interface qo'shing:

```text
IP address: 10.0.20.50
DNS name: bo'sh qoldirish mumkin
Connect to: IP
Port: 10050
```

6. Hostni saqlang.

Muhim: `Host name` agent configdagi `Hostname=PC-BUH-01` bilan aynan bir xil bo'lishi kerak.

## 13. Windows template ulash

Host yaratilgandan keyin `Templates` qismida Windows agent template ulang.

Tavsiya qilinadigan template nomlari Zabbix/TAA versiyasiga qarab farq qilishi mumkin:

- `Windows by Zabbix agent`;
- `Windows by Zabbix agent active`;
- TAA rebrending qilingan bo'lsa, `Windows by TAA agent` yoki shunga o'xshash nom.

Qaysi rejim tanlanadi:

| Rejim | Qachon ishlatiladi |
|---|---|
| Passive template | Server Windows hostga `10050` port orqali kira olsa |
| Active template | Windows host serverga o'zi chiqishi kerak bo'lsa, NAT/firewall ortida bo'lsa |

Agar ikkala rejim ham kerak bo'lmasa, bitta rejimni tanlang. Oddiy LAN ichida passive template yetarli.

## 14. Metrikalar kelayotganini tekshirish

TAA UI da:

1. `Monitoring` -> `Latest data` ga kiring.
2. Host sifatida `PC-BUH-01` ni tanlang.
3. Quyidagi metrikalarni qidiring:

```text
agent.ping
agent.version
system.cpu.util
vm.memory
vfs.fs
net.if
service.info
```

Kutilgan holat:

- `agent.ping` qiymati `1`;
- `agent.version` qiymati TAA/Zabbix Agent 2 versiyasini ko'rsatadi;
- CPU/RAM/disk metrikalari bir necha daqiqa ichida paydo bo'ladi;
- host availability yashil bo'ladi.

## 15. Custom metrikani tekshirish

Config ichida quyidagi custom metrika bo'lsa:

```ini
UserParameter=taa.custom.ping,cmd /c echo 1
```

Serverdan tekshirish:

```bash
zabbix_get -s 10.0.20.50 -p 10050 -k taa.custom.ping
```

Kutilgan natija:

```text
1
```

`conf/taa_agent2.d/userparameter_examples.conf` ichidagi `taa.test` ham ishlatilsa:

```bash
zabbix_get -s 10.0.20.50 -p 10050 -k taa.test
```

## 16. 1C yoki boshqa dastur uchun custom monitoring qo'shish

Masalan, 1C process sonini monitoring qilish uchun Windows hostda quyidagi fayl yarating:

```text
C:\Program Files\TAA\Agent\taa_agent2.d\userparameter_1c.conf
```

Ichiga:

```ini
UserParameter=taa.1c.process.count,powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Process -Name '1cv8*' -ErrorAction SilentlyContinue | Measure-Object).Count"
```

Agentni restart qiling:

```powershell
Restart-Service "TAA Agent 2"
```

Serverdan tekshiring:

```bash
zabbix_get -s 10.0.20.50 -p 10050 -k taa.1c.process.count
```

Keyin TAA UI da shu key bilan item yarating yoki maxsus templatega qo'shing.

## 17. Servisni boshqarish buyruqlari

Windows hostda:

```powershell
Get-Service "TAA Agent 2"
Start-Service "TAA Agent 2"
Stop-Service "TAA Agent 2"
Restart-Service "TAA Agent 2"
```

Agent versiyasini tekshirish:

```powershell
& 'C:\Program Files\TAA\Agent\taa_agent2.exe' --version
```

## 18. Yangilash tartibi

Agent binary yangilanganda:

```powershell
Stop-Service "TAA Agent 2"
Copy-Item 'D:\TAA\zoddix\bin\win64\taa_agent2.exe' 'C:\Program Files\TAA\Agent\' -Force
Start-Service "TAA Agent 2"
Get-Service "TAA Agent 2"
```

Keyin serverdan tekshiring:

```bash
zabbix_get -s 10.0.20.50 -p 10050 -k agent.version
```

## 19. O'chirish tartibi

Administrator PowerShell:

```powershell
Set-Location 'C:\Program Files\TAA\Agent'
Stop-Service "TAA Agent 2"
.\taa_agent2.exe --uninstall
```

Fayllarni qo'lda o'chirish kerak bo'lsa:

```powershell
Remove-Item 'C:\Program Files\TAA\Agent' -Recurse -Force
Remove-Item 'C:\ProgramData\TAA\Agent' -Recurse -Force
```

Bu buyruqlar config va loglarni ham o'chiradi. Ishlatishdan oldin kerakli fayllarni backup qiling.

## 20. Tezkor checklist

Windows hostda:

- [ ] `C:\Program Files\TAA\Agent\taa_agent2.exe` mavjud;
- [ ] `C:\Program Files\TAA\Agent\taa_agent2.conf` mavjud;
- [ ] `Server=10.0.10.10` to'g'ri;
- [ ] `ServerActive=10.0.10.10:10051` to'g'ri;
- [ ] `Hostname=PC-BUH-01` TAA UI bilan bir xil;
- [ ] `ListenPort=10050`;
- [ ] `Get-Service "TAA Agent 2"` natijasi `Running`;
- [ ] firewall inbound TCP `10050` ochiq;
- [ ] log faylda xatolik yo'q.

TAA serverda:

- [ ] `zabbix_get -s 10.0.20.50 -p 10050 -k agent.ping` natijasi `1`;
- [ ] TAA UI da host yaratilgan;
- [ ] Host agent interface IP `10.0.20.50`, port `10050`;
- [ ] Windows template ulangan;
- [ ] `Monitoring -> Latest data` da CPU/RAM/disk metrikalari kelmoqda;
- [ ] host availability yashil.

## 21. Ko'p uchraydigan muammolar

### Agent service start bo'lmayapti

Tekshiring:

```powershell
Get-Content 'C:\ProgramData\TAA\Agent\logs\taa_agent2.log' -Tail 100
.\taa_agent2.exe --print --config 'C:\Program Files\TAA\Agent\taa_agent2.conf'
```

Sabablar:

- configda noto'g'ri parametr;
- log papkasi mavjud emas;
- binary noto'g'ri joyda;
- service eski config bilan o'rnatilgan.

### zabbix_get timeout beradi

Sabablar:

- Windows firewall `10050` portni bloklagan;
- `ListenPort` configda `10055`, server esa `10050` ga urinyapti;
- `Server=` ichida TAA server IP yo'q;
- Windows host IP noto'g'ri;
- tarmoq routing yo'q.

### Active checks ishlamayapti

Sabablar:

- `ServerActive=10.0.10.10:10051` noto'g'ri;
- TAA serverda `10051` portga ulanish yo'q;
- `Hostname` TAA UI dagi host nomi bilan mos emas;
- active template ulanmagan.

### Latest data bo'sh

Tekshiring:

- host enabled holatda;
- template ulangan;
- agent interface to'g'ri;
- host availability qizil bo'lsa, error matnini ochib ko'ring;
- `zabbix_get` bilan `agent.ping` ishlayaptimi.

### Custom UserParameter ishlamayapti

Tekshiring:

- `Include=C:\Program Files\TAA\Agent\taa_agent2.d\*.conf` bor;
- custom `.conf` fayl shu papkada;
- agent restart qilingan;
- buyruq Windows hostda qo'lda ishlaydi;
- key nomi serverdagi item key bilan bir xil.

## 22. Yakuniy tekshiruv

O'rnatish to'liq tugagan deb hisoblanadi, agar:

1. Windows hostda `TAA Agent 2` servisi `Running`.
2. TAA serverdan `agent.ping` qiymati `1` qaytyapti.
3. TAA UI da host availability yashil.
4. `Latest data` da CPU, RAM, disk va network metrikalari kelmoqda.
5. Kerakli custom metrikalar, masalan `taa.custom.ping` yoki `taa.1c.process.count`, qiymat qaytaryapti.

