# TAA Frontend O'zbek Tiliga O'tkazish Yo'riqnomasi

Bu dokumentatsiya Zabbix frontend'ini **to'liq o'zbek tiliga** o'tkazish va "Zabbix" nomini "TAA" ga o'zgartirish bo'yicha batafsil yo'riqnoma.

## 📋 Asosiy Maqsad

Client va admin ko'radigan **barcha matnlar 100% o'zbek tilida**:
- "Zabbix" → "TAA" ga o'zgartirish
- "TAA Monitoring System" → "TAA Monitor Tizimi"
- "Login" → "Kirish", "Password" → "Parol"
- "Dashboard" → "Boshqaruv Paneli"
- "Administration" → "Boshqaruv Bo'limi"
- **Hech qanday inglizcha so'z qolmasin**
- Backend kod va fayl nomlari o'zgarmasin
- Docker va local muhitda bir xil ko'rinishi kerak

## 🎯 O'zgartirilishi Kerak Bo'lgan Joylar

### 1. KIRISH SAHIFASI (Login Page)
**Fayl:** `ui/include/views/general.login.php`
- **Muammo:** Footer'da "Powered by Zabbix" inglizcha ko'rinadi
- **Maqsad:** "TAA Monitor Tizimi" o'zbekcha ko'rsatish
- **Yechim:** Brand configuration va localization orqali

### 2. BRAND SOZLAMALARI (Brand Configuration)
**Fayl:** `ui/local/conf/brand.conf.php`
- **5-qator:** `'BRAND_FOOTER' => 'TAA Monitor Tizimi'`
- **6-qator:** `'BRAND_HELP_URL' => 'https://taa.uz/hujjatlar/'`

### 3. O'RNATISH USTASI (Setup Wizard)
**Fayl:** `ui/include/classes/setup/CSetupWizard.php`
- **484-qator:** `'Xush kelibsiz', 'TAA '.$version[0]` → "Xush kelibsiz TAA 7.4"
- **823-qator:** `_('TAA server nomi')` 
- **1066-qator:** `_('TAA server nomi')`
- **1322-qator:** `_('Tabriklaymiz! Siz TAA frontend muvaffaqiyatli o\'rnatdingiz.')`

### 4. TIZIM MA'LUMOTLARI (System Information)
**Fayl:** `ui/app/partials/administration.system.info.php`
- **28-qator:** `_('TAA server ishlayapti')` 
- **82-qator:** `_('TAA server versiyasi')`
- **89-qator:** `_('TAA frontend versiyasi')`
- **197-qator:** `_('TAA serverdagi global skriptlar')`

### 5. SAHIFA PASTKI QISMI (Footer Helper)
**Fayl:** `ui/include/classes/helpers/CBrandHelper.php`
- **114-qator:** `'TAA '.ZABBIX_VERSION.'. '` 
- **116-qator:** `'TAA Jamoasi'` (TAA Team)

### 6. O'ZBEK TILIGA TARJIMA (Localization)
**Fayllar:** `ui/locale/uz_UZ/LC_MESSAGES/frontend.po`

Barcha matnlar **100% o'zbekcha**:
```po
msgid "Zabbix server is running"
msgstr "TAA server ishlayapti"

msgid "Zabbix server version"  
msgstr "TAA server versiyasi"

msgid "Zabbix frontend version"
msgstr "TAA frontend versiyasi"

msgid "Welcome to"
msgstr "Xush kelibsiz"

msgid "Zabbix server name"
msgstr "TAA server nomi"

msgid "Congratulations! You have successfully installed Zabbix frontend."
msgstr "Tabriklaymiz! Siz TAA frontendni muvaffaqiyatli o'rnatdingiz."

msgid "Global scripts on Zabbix server"
msgstr "TAA serverdagi global skriptlar"

msgid "Powered by Zabbix"
msgstr "TAA Monitor Tizimi"

msgid "Monitoring System"
msgstr "Monitor Tizimi"

msgid "TAA Monitoring System"
msgstr "TAA Monitor Tizimi"
```

### 7. BARCHA MATNLARNI O'ZBEK TILIGA O'TKAZISH

#### 🎯 Asosiy Maqsad
Client ko'radigan **barcha matn va xabarlar 100% o'zbekcha**:
- "TAA server name" → "TAA server nomi"
- "Login" → "Kirish"
- "Password" → "Parol"  
- "Dashboard" → "Boshqaruv Paneli"
- "Administration" → "Boshqaruv Bo'limi"
- "Monitoring" → "Nazorat Qilish"
- "Configuration" → "Sozlamalar"
- **Hech qanday inglizcha so'z qolmasin**

#### 📁 Asosiy Tarjima Fayli

**Fayl:** `ui/locale/uz_UZ/LC_MESSAGES/frontend.po`

##### A) KIRISH SAHIFASI TARJIMASI
```po
msgid "Username"
msgstr "Foydalanuvchi nomi"

msgid "Password"
msgstr "Parol"

msgid "Sign in"
msgstr "Tizimga kirish"

msgid "Remember me for 30 days"
msgstr "Meni 30 kun davomida eslab qol"

msgid "Language"
msgstr "Til"

msgid "Guest user"
msgstr "Mehmon foydalanuvchi"

msgid "Enable"
msgstr "Yoqish"

msgid "Disable"
msgstr "O'chirish"

msgid "Auto-login"
msgstr "Avtomatik kirish"

msgid "Default theme"
msgstr "Standart mavzu"
```

##### B) ASOSIY MENYU TARJIMASI
```po
msgid "Dashboard"
msgstr "Boshqaruv Paneli"

msgid "Monitoring"
msgstr "Nazorat Qilish"

msgid "Services"
msgstr "Xizmatlar"

msgid "Inventory"
msgstr "Inventar Ro'yxati"

msgid "Reports"
msgstr "Hisobotlar"

msgid "Configuration"
msgstr "Sozlamalar"

msgid "Administration"
msgstr "Boshqaruv Bo'limi"

msgid "User settings"
msgstr "Foydalanuvchi sozlamalari"

msgid "Support"
msgstr "Yordam"

msgid "Logout"
msgstr "Tizimdan chiqish"

msgid "Profile"
msgstr "Profil"

msgid "Help"
msgstr "Yordam"
```

##### C) TIZIM MA'LUMOTLARI TARJIMASI
```po
msgid "System information"
msgstr "Tizim ma'lumotlari"

msgid "TAA server is running"
msgstr "TAA server ishlayapti"

msgid "TAA server version"
msgstr "TAA server versiyasi"

msgid "TAA frontend version"
msgstr "TAA frontend versiyasi"

msgid "Database"
msgstr "Ma'lumotlar bazasi"

msgid "Database version"
msgstr "Ma'lumotlar bazasi versiyasi"

msgid "Database size"
msgstr "Ma'lumotlar bazasi hajmi"

msgid "Server name"
msgstr "Server nomi"

msgid "Server time"
msgstr "Server vaqti"

msgid "Uptime"
msgstr "Ishlash muddati"

msgid "High availability cluster"
msgstr "Yuqori ishonchlilik klasteri"

msgid "Fail-over delay"
msgstr "Xatolik kechikishi"

msgid "Running"
msgstr "Ishlayapti"

msgid "Not running"
msgstr "Ishlamayapti"

msgid "Connected"
msgstr "Ulangan"

msgid "Disconnected"
msgstr "Uzilib qolgan"
```

##### D) O'RNATISH USTASI TARJIMASI
```po
msgid "Welcome to"
msgstr "Xush kelibsiz"

msgid "Installation"
msgstr "O'rnatish jarayoni"

msgid "Check of pre-requisites"
msgstr "Talab qilinadigan shartlarni tekshirish"

msgid "Configure DB connection"
msgstr "Ma'lumotlar bazasi ulanishini sozlash"

msgid "TAA server details"
msgstr "TAA server tafsilotlari"

msgid "Pre-installation summary"
msgstr "O'rnatish oldidan umumiy ma'lumot"

msgid "Install"
msgstr "O'rnatish"

msgid "Congratulations! You have successfully installed TAA frontend."
msgstr "Tabriklaymiz! Siz TAA frontendni muvaffaqiyatli o'rnatdingiz."

msgid "TAA server name"
msgstr "TAA server nomi"

msgid "TAA server port"
msgstr "TAA server porti"

msgid "Name"
msgstr "Nomi"

msgid "Default"
msgstr "Standart"

msgid "Next step"
msgstr "Keyingi bosqich"

msgid "Back"
msgstr "Orqaga"

msgid "Finish"
msgstr "Yakunlash"

msgid "Continue"
msgstr "Davom etish"

msgid "Retry"
msgstr "Qayta urinish"
```

##### E) XATO VA MUVAFFAQIYAT XABARLARI
```po
msgid "Login name or password is incorrect."
msgstr "Foydalanuvchi nomi yoki parol noto'g'ri."

msgid "Access denied."
msgstr "Kirish rad etildi."

msgid "Session terminated, re-login, please."
msgstr "Sessiya tugadi, iltimos qaytadan kiring."

msgid "Configuration updated"
msgstr "Sozlamalar yangilandi"

msgid "Cannot connect to the database."
msgstr "Ma'lumotlar bazasiga ulanib bo'lmadi."

msgid "Data saved"
msgstr "Ma'lumotlar saqlandi"

msgid "Data deleted"
msgstr "Ma'lumotlar o'chirildi"

msgid "No permissions to referred object or it does not exist!"
msgstr "Ko'rsatilgan obyektga ruxsat yo'q yoki u mavjud emas!"

msgid "Operation completed successfully"
msgstr "Amal muvaffaqiyatli bajarildi"

msgid "Error occurred"
msgstr "Xatolik yuz berdi"

msgid "Connection failed"
msgstr "Ulanish muvaffaqiyatsiz"

msgid "Invalid input"
msgstr "Noto'g'ri ma'lumot"

msgid "Required field"
msgstr "Majburiy maydon"
```

##### F) FORMA ELEMENTLARI
```po
msgid "Save"
msgstr "Saqlash"

msgid "Cancel"
msgstr "Bekor qilish"

msgid "Delete"
msgstr "O'chirish"

msgid "Edit"
msgstr "Tahrirlash"

msgid "Add"
msgstr "Qo'shish"

msgid "Update"
msgstr "Yangilash"

msgid "Create"
msgstr "Yaratish"

msgid "Apply"
msgstr "Qo'llash"

msgid "Reset"
msgstr "Qaytarish"

msgid "Search"
msgstr "Qidirish"

msgid "Filter"
msgstr "Saralash"

msgid "Clear"
msgstr "Tozalash"

msgid "Submit"
msgstr "Jo'natish"

msgid "Close"
msgstr "Yopish"

msgid "Refresh"
msgstr "Yangilash"

msgid "Export"
msgstr "Eksport qilish"

msgid "Import"
msgstr "Import qilish"
```

#### 🚀 O'ZBEK TILIGA O'TKAZISH AMALIY QADAMLARI

##### 1-BOSQICH: Frontend.po Faylini To'liq Tahrirlash
```bash
# ui/locale/uz_UZ/LC_MESSAGES/frontend.po faylida:

# 1. Barcha "server name" → "server nomi"
sed -i 's/server name/server nomi/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# 2. Asosiy menyu elementlari
sed -i 's/msgstr "Dashboard"/msgstr "Boshqaruv Paneli"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
sed -i 's/msgstr "Monitoring"/msgstr "Nazorat Qilish"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
sed -i 's/msgstr "Administration"/msgstr "Boshqaruv Bo\047limi"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# 3. Kirish sahifasi elementlari
sed -i 's/msgstr "Username"/msgstr "Foydalanuvchi nomi"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
sed -i 's/msgstr "Password"/msgstr "Parol"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
sed -i 's/msgstr "Sign in"/msgstr "Tizimga kirish"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# 4. Tizim ma'lumotlari
sed -i 's/msgstr "System information"/msgstr "Tizim ma\047lumotlari"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
sed -i 's/msgstr "Database"/msgstr "Ma\047lumotlar bazasi"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# 5. TAA branding
sed -i 's/msgstr "Powered by Zabbix"/msgstr "TAA Monitor Tizimi"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
sed -i 's/msgstr "TAA Monitoring System"/msgstr "TAA Monitor Tizimi"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
```

##### 2-BOSQICH: O'zbek Tilini Standart Til Qilish
```php
// ui/include/locales.inc.php faylida:

// Standart tilni o'zbek qilish
define('ZBX_DEFAULT_LANG', 'uz_UZ');

// O'zbek tilini ro'yxatda birinchi joyga qo'yish
$locales = [
    'uz_UZ' => ['name' => 'O\'zbekcha (O\'zbekiston)', 'display' => true],
    'en_US' => ['name' => 'English (United States)', 'display' => true],
    'ru_RU' => ['name' => 'Русский (Россия)', 'display' => true],
    // ...qolgan tillar
];
```

##### 3-BOSQICH: Tarjima Faylini Qayta Yaratish
```bash
# Po fayldan mo fayl yaratish
msgfmt ui/locale/uz_UZ/LC_MESSAGES/frontend.po -o ui/locale/uz_UZ/LC_MESSAGES/frontend.mo

# Fayl to'g'ri yaratilganini tekshirish
file ui/locale/uz_UZ/LC_MESSAGES/frontend.mo

# Faylni o'qish huquqini berish
chmod 644 ui/locale/uz_UZ/LC_MESSAGES/frontend.mo
```

##### 4-BOSQICH: Docker'da O'zbek Tilini Standart Qilish
```yaml
# docker-compose.yml faylida:
services:
  zabbix-web:
    environment:
      - ZBX_DEFAULT_LANG=uz_UZ
      - ZBX_SERVER_NAME=TAA Monitor Tizimi
    volumes:
      - ./ui/locale/uz_UZ:/usr/share/zabbix/locale/uz_UZ:ro
      - ./ui/include/locales.inc.php:/usr/share/zabbix/include/locales.inc.php:ro
      - ./ui/local/conf/brand.conf.php:/usr/share/zabbix/local/conf/brand.conf.php:ro
```

#### ✅ O'ZBEK TILIGA O'TKAZISH SINOVLARI

##### 1. Kirish Sahifasi Sinovi
- "Foydalanuvchi nomi" va "Parol" maydonlari o'zbekcha ko'rinishi
- "Tizimga kirish" tugmasi to'liq o'zbekcha bo'lishi
- "Meni 30 kun davomida eslab qol" belgisi o'zbekcha
- "TAA Monitor Tizimi" footer'da ko'rinishi

##### 2. Asosiy Menyu Sinovi  
- "Boshqaruv Paneli", "Nazorat Qilish", "Boshqaruv Bo'limi" menu'lar o'zbekcha
- "Tizimdan chiqish" tugmasi o'zbekcha
- "Foydalanuvchi sozlamalari" o'zbekcha

##### 3. Tizim Ma'lumotlari Sinovi
- "Tizim ma'lumotlari" sarlavha o'zbekcha
- "TAA server nomi", "TAA server versiyasi" o'zbekcha
- "Ma'lumotlar bazasi" va "Ishlash muddati" o'zbekcha

##### 4. Xato Xabarlari Sinovi
- "Foydalanuvchi nomi yoki parol noto'g'ri" o'zbekcha
- "Ma'lumotlar saqlandi" va "Amal muvaffaqiyatli bajarildi" o'zbekcha
- "Ulanish muvaffaqiyatsiz" xabari o'zbekcha

##### 5. O'rnatish Ustasi Sinovi
- "Xush kelibsiz TAA 7.4" sarlavha o'zbekcha
- "O'rnatish jarayoni" va "Keyingi bosqich" tugmalari o'zbekcha
- "Tabriklaymiz! Siz TAA frontendni muvaffaqiyatli o'rnatdingiz" xabari

#### 📝 MUHIM MASLAHATLAR

1. **Matn Uzunligi:** O'zbek tarjimalar HTML elementlarga mos kelishini tekshiring
2. **Klaviatura Qo'llab-quvvatlash:** O'zbek klaviatura tartibini qo'llab-quvvatlash
3. **Matn Yo'nalishi:** O'zbek tili uchun chapdan o'ngga yo'nalish to'g'ri
4. **Shrift Qo'llab-quvvatlash:** O'zbek harflari (ʻ, ʼ) to'g'ri ko'rinishini ta'minlash
5. **Mobil Qurilmalar:** Smartfon va planshetlarda ham o'zbekcha matnlar to'g'ri ko'rinishi

## 🚀 AMALIY AMALGA OSHIRISH QADAMLARI

### 1-BOSQICH: Brand Sozlamalarini O'zgartirish

```php
// ui/local/conf/brand.conf.php
<?php
return [
    'BRAND_FOOTER' => 'TAA Monitor Tizimi',  // "Powered by Zabbix" ni olib tashlash
    'BRAND_HELP_URL' => 'https://taa.uz/hujjatlar/',
    'BRAND_SIDEBAR_FOOTER' => false
];
```

### 2-BOSQICH: O'rnatish Ustasini O'zgartirish

```php
// ui/include/classes/setup/CSetupWizard.php

// 484-qator:
return (new CDiv([
    (new CTag('h1', true, [_('Xush kelibsiz'), ' TAA '.$version[0]]))
        ->addClass(ZBX_STYLE_SETUP_TITLE),
    ...
```

### 3-BOSQICH: Tizim Ma'lumotlarini O'zgartirish

```php
// ui/app/partials/administration.system.info.php

// 28-qator:
'name' => _('TAA server ishlayapti'),

// 82-qator:
'name' => _('TAA server versiyasi'),

// 89-qator:
'name' => _('TAA frontend versiyasi'),

// 197-qator:
'name' => _('TAA serverdagi global skriptlar'),
```

### 4-BOSQICH: Sahifa Pastki Qismini O'zgartirish

```php
// ui/include/classes/helpers/CBrandHelper.php

// 114-qator:
$version_string = array_key_exists('BRAND_FOOTER', $config)
    ? $config['BRAND_FOOTER']
    : 'TAA '.ZABBIX_VERSION.'. ';

// 116-qator:
$link = array_key_exists('BRAND_HELP_URL', $config)
    ? $config['BRAND_HELP_URL']
    : (new CLink('TAA Jamoasi', 'https://taa.uz'))
        ->addClass(ZBX_STYLE_GREY)
        ->addClass(ZBX_STYLE_LINK_ALT)
        ->setTarget('_blank');
```

### 5-BOSQICH: O'zbek Tiliga Tarjima Qilish

```bash
# Har bir til uchun (masalan uz_UZ):
# ui/locale/uz_UZ/LC_MESSAGES/frontend.po faylida:

# "Zabbix" ni "TAA" ga almashtirish
sed -i 's/msgstr "Zabbix server/msgstr "TAA server/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po
sed -i 's/msgstr ".*Zabbix frontend/msgstr "TAA frontend/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# Monitoring System → Monitor Tizimi
sed -i 's/msgstr ".*Monitoring System"/msgstr "TAA Monitor Tizimi"/g' ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# .mo fayl qayta yaratish:
msgfmt ui/locale/uz_UZ/LC_MESSAGES/frontend.po -o ui/locale/uz_UZ/LC_MESSAGES/frontend.mo
```

## 🐳 DOCKER BILAN INTEGRATSIYA

### Docker Compose Volume Sozlamalari

```yaml
# docker-compose.yml
services:
  zabbix-web:
    environment:
      - ZBX_DEFAULT_LANG=uz_UZ
      - ZBX_SERVER_NAME=TAA Monitor Tizimi
    volumes:
      # Brand sozlamalari
      - ./ui/local/conf/brand.conf.php:/usr/share/zabbix/local/conf/brand.conf.php:ro
      
      # O'zbek tiliga tarjima fayllari
      - ./ui/locale/uz_UZ:/usr/share/zabbix/locale/uz_UZ:ro
      - ./ui/locale/en_US:/usr/share/zabbix/locale/en_US:ro
      
      # O'zgartirilgan PHP fayllar
      - ./ui/include/classes/setup/CSetupWizard.php:/usr/share/zabbix/include/classes/setup/CSetupWizard.php:ro
      - ./ui/app/partials/administration.system.info.php:/usr/share/zabbix/app/partials/administration.system.info.php:ro
      - ./ui/include/classes/helpers/CBrandHelper.php:/usr/share/zabbix/include/classes/helpers/CBrandHelper.php:ro
      - ./ui/include/locales.inc.php:/usr/share/zabbix/include/locales.inc.php:ro
```

### Dockerfile Qo'shimcha Sozlamalari

```dockerfile
# Dockerfile qo'shimcha qatorilar
FROM zabbix/zabbix-web-nginx-mysql:latest

# TAA branding fayllarini nusxalash
COPY ui/local/conf/brand.conf.php /usr/share/zabbix/local/conf/brand.conf.php
COPY ui/locale/ /usr/share/zabbix/locale/

# O'zgartirilgan PHP fayllar
COPY ui/include/classes/setup/CSetupWizard.php /usr/share/zabbix/include/classes/setup/
COPY ui/app/partials/administration.system.info.php /usr/share/zabbix/app/partials/
COPY ui/include/classes/helpers/CBrandHelper.php /usr/share/zabbix/include/classes/helpers/
COPY ui/include/locales.inc.php /usr/share/zabbix/include/

# O'zbek tilini standart qilish
ENV ZBX_DEFAULT_LANG=uz_UZ
ENV ZBX_SERVER_NAME="TAA Monitor Tizimi"

# Keshni tozalash
RUN rm -rf /tmp/cache/* /usr/share/zabbix/local/cache/*
```

## ✅ SINOV VA TEKSHIRISH

### 1. Kirish Sahifasi Sinovi
- Browser'da `/` ga kirish
- Footer'da "TAA Monitor Tizimi" o'zbekcha ko'rinishi kerak
- "Powered by Zabbix" inglizcha yozuv ko'rinmasligi kerak
- "Tizimga kirish" tugmasi o'zbekcha bo'lishi kerak

### 2. O'rnatish Ustasi Sinovi
- Browser'da `/setup.php` ga kirish  
- "Xush kelibsiz TAA 7.4" o'zbekcha ko'rinishi kerak
- Server nomi maydonida "TAA server nomi" o'zbekcha ko'rinishi kerak
- "Keyingi bosqich" va "Orqaga" tugmalari o'zbekcha bo'lishi kerak

### 3. Tizim Ma'lumotlari Sinovi
- Admin paneliga kirish
- Boshqaruv Bo'limi → Umumiy → Tizim ma'lumotlari
- "TAA server ishlayapti", "TAA server versiyasi" o'zbekcha ko'rinishi kerak
- "Ma'lumotlar bazasi" va boshqa maydonlar o'zbekcha bo'lishi kerak

### 4. Til O'zgartirish Sinovi
- Til o'zgartirish (o'zbekcha, inglizcha, ruscha)
- Barcha tillarda "TAA" ko'rinishi kerak, "Zabbix" yo'q bo'lishi kerak
- O'zbek tili standart til sifatida ochilishi kerak

### 5. Docker Container Sinovi
- `docker-compose up -d` buyrug'i bilan ishga tushirish
- Container ichida o'zbekcha matnlar ko'rinishi kerak
- Browser cache'ni tozalab qayta tekshirish

## 🚨 EHTIYOT VA XAVFSIZLIK CHORALARI

1. **Zaxira Nusxa:** O'zgartirish oldidan barcha fayllardan zaxira nusxa oling
2. **Ma'lumotlar Bazasi:** Database'da "Zabbix" nomlari o'zgarmasligi kerak
3. **API Javoblari:** API response'larda "Zabbix" o'zgarmasligi kerak  
4. **Log Fayllari:** Server log'larida "Zabbix" o'zgarmasligi kerak
5. **Sinov:** Har bir o'zgarishdan keyin to'liq sinov o'tkazing
6. **Performance:** Tizim ishlash tezligi pasaymasligi kerak

## 📁 FAYL TUZILISHI

```
ui/
├── local/conf/brand.conf.php          # ✅ O'zgartiriladi
├── include/classes/setup/CSetupWizard.php  # ✅ O'zgartiriladi  
├── app/partials/administration.system.info.php  # ✅ O'zgartiriladi
├── include/classes/helpers/CBrandHelper.php  # ✅ O'zgartiriladi
├── include/locales.inc.php            # ✅ O'zgartiriladi
├── locale/
│   ├── uz_UZ/LC_MESSAGES/frontend.po  # ✅ Asosiy o'zbek tarjimasi
│   ├── uz_UZ/LC_MESSAGES/frontend.mo  # ✅ Compiled fayl
│   ├── en_US/LC_MESSAGES/frontend.po  # ✅ Ingliz tili
│   └── .../LC_MESSAGES/frontend.po    # ✅ Boshqa tillar (40+)
└── include/views/general.login.php     # ℹ️ CBrandHelper orqali avtomatik
```

## 🔄 ORQAGA QAYTARISH REJASI

Agar muammo yuzaga kelsa, quyidagi fayllarni asl holatiga qaytaring:

### Asl Fayllarni Tiklash:
1. `ui/local/conf/brand.conf.php` - Original brand settings
2. `ui/include/classes/setup/CSetupWizard.php` - Setup wizard asl holati
3. `ui/app/partials/administration.system.info.php` - System info asl holati
4. `ui/include/classes/helpers/CBrandHelper.php` - Footer helper asl holati
5. `ui/include/locales.inc.php` - Til sozlamalari asl holati
6. `ui/locale/*/LC_MESSAGES/frontend.po` - Barcha tillar asl holati

### Tiklash Qadamlari:
```bash
# Git orqali asl holatga qaytarish
git checkout HEAD -- ui/local/conf/brand.conf.php
git checkout HEAD -- ui/include/classes/setup/CSetupWizard.php
git checkout HEAD -- ui/app/partials/administration.system.info.php

# Docker container'ni qayta ishga tushirish
docker-compose restart zabbix-web

# Browser cache'ni tozalash (Ctrl+F5)
```

---

**Hujjat Muallifi:** Rovo Dev  
**Yaratilgan Sana:** 2025-01-27  
**Hujjat Versiyasi:** 1.0  
**Maqsad:** TAA Frontend To'liq O'zbek Tiliga O'tkazish