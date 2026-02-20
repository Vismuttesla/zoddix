# TAA Agent: O‘zbekcha versiyaga moslashtirish va TAA logo/ikonka almashtirish bo‘yicha batafsil yo‘riqnoma


1) Maqsad va doira
- Maqsad: Agent komponentini to‘liq TAA brendiga moslashtirish (nomlar, fayl joylari, servis identifikatori, paketlash, installer/ikonka), Uzbek tilidagi hujjatlar va operatorlar uchun yo‘riqnomalar bilan ta’minlash. 
- Doira: 
  - Agent (klassik C agentd) va Agent2 (Go) uchun umumiy siyosat. 
  - Linux va Windows muhitlari. 
  - Docker konteyner varianti. 
  - Tarmoq xavfsizligi (TLS), avtoregistratsiya va TAA server bilan hamkorlik. 
- Cheklovlar: Agentning protokoli, API va diagnostika formatlari moslik uchun asosan inglizcha qoladi. Operator va installer darajasida o‘zbekcha matnlar tavsiya etiladi.


2) Talablar va qarorlar
- Brend identifikatori: "TAA Agent" (agentd) va "TAA Agent2" (agent2). 
- Servis va paket nomlari: taa-agent, taa-agent2 (Windows servis nomlari ham TAA bilan mos). 
- Fayl joylari siyosati (Linux): 
  - Konfiguratsiya: /etc/taa/agent/ 
  - Loglar: /var/log/taa/agent/ 
  - PID: /var/run/taa/agent/ 
  - Holat/keş: /var/lib/taa/agent/ 
- Fayl joylari siyosati (Windows): 
  - Konfiguratsiya: o‘rnatish katalogida 
  - Log/holat: C:\ProgramData\TAA\Agent\ 
- Tarmoq portlari: 
  - Passive checks: agent tinglaydigan port (standart 10050) 
  - Active checks: server tomon ulanish (10051), agent tinglash shart emas 
- Xavfsizlik: TLS PSK yoki Sertifikatli TLS. 
- Log va telemetriya: "TAA Agent" prefiksi, versiya va identifikatsiya izchil bo‘lsin. 


3) Rebrending ob’yektlari (nimalarni o‘zgartiramiz)
- Nomlar va ko‘rinadigan matnlar: 
  - Binar va servis ko‘rinadigan nomi: Zabbix → TAA. 
  - Paket nomi va tavsifi: zabbix-agent → taa-agent; zabbix-agent2 → taa-agent2. 
  - Systemd service DisplayName/Description: TAA Agent. 
  - Windows Service DisplayName/Description: TAA Agent, TAA Agent2. 
- Fayl va kataloglar: yuqoridagi siyosatga mos yo‘llarga o‘tkazish. 
- Log bannerlari va versiya chiqishlari: "TAA Agent vX.Y" kabi izchil identifikatsiya. 
- Installer va distributivlar: 
  - Linux: .deb/.rpm paket nomlari, paket ma’lumotlari (maintainer, description) TAA bilan mos. 
  - Windows: MSI/ZIP nomlash, brend matnlari (ProductName, Manufacturer), ikonkalar. 
- Docker imiji: 
  - Nomlash: taa/agent yoki taa/agent2. 
  - Ta’rif: imij tavsifi va label-lar TAA bilan mos. 


4) O‘zbekcha moslashtirish (lokalizatsiya siyosati)
- Agent loglari: ichki diagnostika inglizcha qolishi tavsiya etiladi (troubleshooting uchun standart). 
- Operator hujjatlari: o‘rnatish, sozlash, ishlatish bo‘yicha yo‘riqnomalar to‘liq o‘zbekcha. 
- Installer matnlari (Windows): Setup bosqichlari, xatolik/habarnomalar o‘zbekcha bo‘lishi mumkin. 
- Konfiguratsiya fayllari: kommentariyalar o‘zbekcha bo‘lishi mumkin, ammo parametr kalitlari o‘zgarmaydi. 
- UI terminlari: Server UI tomonda "Zabbix agent" atamalari o‘rniga "TAA Agent" ko‘rsatilishi kerak (server rebrending siyosati bilan mos). 


5) TAA logo va ikonkalarni almashtirish
- Maqsad: Agent bilan bog‘liq ko‘rinadigan barcha komponentlarda TAA logotipi va ikonkalar ishlatilishi. 
- Qamrov: 
  - Windows installer: Setup banner, product icon, uninstaller icon. 
  - Paket metadata (Linux): paket logotipi odatda ko‘rinmaydi, ammo hujjatlarda va ombor (repo) sahifalarida TAA logosi ishlatiladi. 
  - Docker: Docker Hub sahifasi va README illyustratsiyasi TAA logosi bilan. 
  - Ichki hujjatlar: PDF/rasm aktivlarida TAA logosi. 
- Aktivlar manzili: 
  - Repository ichida assets/ katalogi (logo.svg, favicon.ico va kerakli rasmlar). 
  - Installerga mos formatlar: .ico, .bmp, .png (hajmlar mos kelishi shart). 
- Vizual talablar: 
  - Asosiy logo: 114×30 px (yoki yuqori aniqlikda proporsional). 
  - Sidebar/compact: 91×24 px va 24×24 px variantlar. 
  - Favicon/ico: 16×16, 32×32, 48×48 qatlamlar. 
- Sifat nazorati: Kattalik, kontrast, qorong‘i/yorug‘ fonlardagi differensiya, DPI mosligi tekshiriladi. 


6) Dockerda agentni ko‘tarish (konsepsiya va siyosat)
- Tarmoq: 
  - Passive checks: agent portini (10050) hostga ochish kerak. 
  - Active checks: port ochish shart emas; serverga chiqish yo‘li bo‘lsa kifoya. 
- Volyumlar: 
  - /etc/taa/agent – konfiguratsiya. 
  - /var/log/taa/agent – loglar. 
  - /var/lib/taa/agent – holat/keş. 
- Sog‘liq nazorati: 
  - Oddiy healthcheck: agent ish holati va server bilan aloqa mavjudligi tekshiriladi. 
- Restart siyosati: always yoki unless-stopped. 
- Xavfsizlik: Faqat zarur ruxsat va capabilitiy lar. 
- Identifikatsiya: 
  - Hostname – serverdagi host nomiga aynan mos bo‘lsin. 
  - Metadata – auto-registration uchun mos kalitlar. 


7) Linuxga o‘rnatish (bare-metal/VM)
- Paketlash va nomlash: taa-agent, taa-agent2 nomlari; description va vendor maydonlari TAA bilan mos. 
- Foydalanuvchi/kataloglar: taa-agent foydalanuvchisi; /etc/taa/agent, /var/log/taa/agent, /var/lib/taa/agent, /var/run/taa/agent kataloglari va ruxsatlar. 
- Servis: TAA Agent systemd birligi (enable/start); description TAA bilan mos. 
- Firewall: Passive checks bo‘lsa 10050 inbound ruxsat; active checks uchun outbound ruxsat. 
- SELinux/AppArmor: Log/konf yo‘llari uchun mos profil/label lar. 


8) Windowsga o‘rnatish (bare-metal/VM)
- Installer: MSI yoki ZIP distributiv. ProductName – TAA Agent; Manufacturer – TAA. 
- Servis: Windows Service nomi va tavsifi TAA bilan mos; service install va start. 
- Fayl joylari: Konf – o‘rnatish katalogida; Log/State – ProgramData\TAA\Agent\ 
- Firewall: Passive checks da inbound ruxsat (10050); Active checks uchun outbound yetarli. 
- Ruxsatlar: Sertifikat/PSK fayllari faqat Administrator o‘qiy oladigan joyda saqlansin. 


9) TAA server bilan hamkorlik va sozlash
- Passive checks: 
  - Server agent IP/portiga ucha olishi kerak; Host interfeysi to‘g‘ri kiritiladi. 
- Active checks: 
  - ServerActive – TAA server FQDN/IP. 
  - Hostname – UI dagi nom bilan aynan bir xil bo‘lsin. 
  - Auto-registration – metadata asosida serverda host yaratish va shablon biriktirish. 
- TLS: 
  - PSK: Identity va PSK matni server va agentda aynan mos. 
  - Sertifikat: CA, sertifikat va kalit yo‘llari to‘g‘ri; muddat va vaqt sinxroni tekshiriladi. 


10) Xavfsizlik siyosati
- TLS ni majburiy qilish: PSK yoki sertifikat. 
- Allowed serverlar ro‘yxatini minimal darajada cheklash. 
- Remote buyruqlarni o‘chirish yoki qat’iy cheklash. 
- Fayl ruxsatlari: konf/log/state kataloglari minimal huquqlar bilan. 
- Sirlarni boshqarish: PSK/kalit/sertifikatlarni maxfiy boshqaruv tizimida saqlash. 


11) Avtoregistratsiya siyosati (Active checks tavsiya)
- Agent metadata: rol (db, web, app), muhit (prod, stage, dev), lokatsiya (DC1, Cloud) kabi kalitlar. 
- Server Action: metadata shartlariga ko‘ra host yaratish, guruhga qo‘shish, shablon biriktirish. 
- Standart: yagona metadata format va nomlash konvensiyasi tasdiqlansin. 


12) Test va verifikatsiya
- Log tahlili: agent start, serverga ulanish, TLS qo‘l siqish (handshake) natijalarini logda tekshirish. 
- Tarmoq: passive da 10050 ochiqligi; active da serverga chiqish yo‘li. 
- UI: Host availability yashil bo‘lishi, asosiy metrikalar kelishi. 
- Diagnostika: Unsupported elementlar sababi logda; ruxsat va yo‘l muammolarini tekshirish. 


13) Migratsiya (Zabbix agent → TAA Agent)
- Nomlash: eskining parallel ishlashi uchun vaqtinchalik strategiya; downtime minimal bo‘lsin. 
- Konf ko‘chirish: Server/ServerActive, Hostname, TLS parametrlarini mos holda ko‘chiring. 
- Sinov: avval dev/sinov muhitda, so‘ng bosqichma-bosqich produktsiyaga. 
- Rollback: muammo bo‘lsa, eski agentga qaytish imkoniyati saqlansin. 


14) Ishlab chiqarishdagi eng yaxshi amaliyotlar
- Versiya boshqaruvi: agent va server versiya mosligi; rejalashtirilgan yangilash. 
- Resurslar: log rotate siyosati; resurs limitlari; kuzatuv elementlari. 
- Audit: konfiguratsiya o‘zgarishlari audit trail; markaziy log yig‘ish bo‘lsa, integratsiya. 


15) Cheklistlar (amaliy nazorat ro‘yxatlari)
- Rebrending cheklist: 
  - Nomlar (binar, servis, paket) TAA ga o‘tgani. 
  - Fayl joylari siyosati tatbiq etilgani. 
  - Installer/ikonka/logotiplar almashtirilgani. 
  - Docker imiji, tavsif va label-lar yangilangani. 
  - Hujjatlar o‘zbekcha yangilangani. 
- Integratsiya cheklist: 
  - Hostname mosligi; metadata siyosati. 
  - Passive/Active rejim tanlovi; portlar va firewall sozlamalari. 
  - TLS (PSK yoki sertifikat) mosligi. 
  - Serverdagi shablonlar biriktirilgani. 
- Sinov cheklist: 
  - Loglarda xatolik yo‘qligi. 
  - UI da availability yashil. 
  - Asosiy metrikalar kelmoqda. 
  - Troubleshooting ssenariylari ishlaydi. 


16) Nomlash va katalog siyosati (mos kelish jadvali)
- Agent nomlari: Zabbix Agent → TAA Agent; Zabbix Agent2 → TAA Agent2. 
- Paket nomlari: zabbix-agent → taa-agent; zabbix-agent2 → taa-agent2. 
- Linux kataloglari: 
  - /etc/zabbix → /etc/taa/agent 
  - /var/log/zabbix → /var/log/taa/agent 
  - /var/lib/zabbix → /var/lib/taa/agent 
  - /var/run/zabbix → /var/run/taa/agent 
- Windows yo‘llari: 
  - ProgramData\Zabbix → ProgramData\TAA\Agent 
  - Service DisplayName: "Zabbix Agent" → "TAA Agent" 


17) Hujjatlash va tarqatish
- Ichki standart hujjat: ushbu yo‘riqnoma asosiy manba sifatida qabul qilinsin. 
- Operatorlar uchun qisqa yo‘riqnoma: 10–15 qadamli tezkor qo‘llanma. 
- Tarqatish: CI/CD (Docker imijlari), konfiguratsiya boshqaruvi (Ansible/Puppet/Salt), paket repolari. 
- Versiya va o‘zgarishlar jurnali: rebrendingga tegishli o‘zgarishlar ChangeLog da qayd etilsin. 


18) Qo‘llab-quvvatlash va eskalatsiya
- Muammo triaji: tarmoq → TLS → Hostname/Metadata → ruxsat → shablon/elementlar tartibida tekshirish. 
- Eskalatsiya mezonlari: keng ko‘lamdagi ulanish xatolari, TLS sertifikat muddatlari, agent mass restartlar. 
- Aloqa kanali: ichki monitoring guruhlari va voqea kuzatuv tizimi. 


19) Qo‘shimcha tavsiyalar
- Uzoq muddatli xavfsizlik uchun sertifikatga asoslangan TLS ni joriy etish rejasini tuzing. 
- Auto-registration siyosatini qat’iylashtirib, guruhlash/shablon biriktirishni avtomatlashtiring. 
- Windows va Linux muhitlarida bir xil metadata strategiyasi qo‘llang. 
- Paketlar va imijlarda SBOM va imzolash (signing) siyosatini ko‘rib chiqing. 


20) Yakuniy natija
- TAA Agent(lar) to‘liq rebrend qilingan, operatorlar uchun o‘zbekcha hujjatlar tayyor, installer/ikonka/aktivlar almashtirilgan, Docker va bare-metal o‘rnatish ssenariylari ishlab chiqilgan, TAA server bilan xavfsiz va barqaror hamkorlik yo‘lga qo‘yilgan bo‘ladi.
