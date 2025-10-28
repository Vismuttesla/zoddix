# 🔥 **ZABBIX DOCKER CONTAINER - BRANDING SISTEMASI TO'LIQ DOKUMENTATSIYASI**

## **📋 ASOSIY MUAMMO VA YECHIM**

### **Muammo Tahlili:**
Sizning local logo va iconkalar ishlamaydi chunki:

1. **Nginx bloklovchi konfiguratsiya** - `/local/` yo'lini to'liq blokaydi
2. **Volume mount noto'g'ri** - Local fayllar container ichiga to'g'ri o'tkazilmaydi  
3. **Brand konfiguratsiya yo'li noto'g'ri** - Logo yo'llari Nginx tomonidan accessible emas
4. **Assets papkasi** - Logo fayllar noto'g'ri joyda

### **Asosiy Yechim Strategiyasi:**
- Logo fayllarni `assets/` papkasiga ko'chirish
- Brand konfiguratsiyasini yangilash
- Dockerfile va docker-compose.yml ni to'g'rilash

---

## **🏗️ CONTAINER ICHIDAGI TIZIM ARXITEKTURASI**

### **1. FAYL TUZILMASI TO'LIQ SXEMASI:**

```
/usr/share/zabbix/                                 # Nginx Web Root
├── index.php                                      # Asosiy entry point
├── zabbix.php                                     # Main application
├── 
├── ui/                                            # Frontend UI fayllar
│   ├── local/                                     # ❌ NGINX BLOKAYDI
│   │   ├── conf/
│   │   │   └── brand.conf.php                     # Branding config
│   │   └── img/                                   # ❌ Bu yerdan logo yuklanmaydi
│   │       ├── logo.svg
│   │       ├── logo-compact.svg
│   │       └── favicon.ico
│   └── assets/                                    # Frontend assets
│       └── img/
│
├── assets/                                        # ✅ NGINX ACCESSIBLE
│   ├── styles/                                    # CSS fayllar
│   │   ├── blue-theme.css
│   │   ├── dark-theme.css
│   │   └── hc-light.css
│   └── img/                                       # ✅ Bu yerda logo bo'lishi kerak
│       ├── logo.svg                               # Bu yerga copy qilish kerak
│       ├── logo-compact.svg
│       └── favicon.ico
│
├── include/                                       # PHP Backend fayllar
│   ├── classes/
│   │   └── helpers/
│   │       └── CBrandHelper.php                   # Branding logic
│   ├── html.inc.php                               # makeLogo() function
│   └── config.inc.php                             # APP entry point
│
├── app/                                           # MVC Architecture
│   ├── views/
│   │   ├── layout.htmlpage.php                    # Main layout
│   │   └── general.login.php                      # Login page
│   └── partials/
│       ├── layout.htmlpage.header.php
│       ├── layout.htmlpage.aside.php              # Sidebar (logo ko'rsatiladi)
│       └── layout.htmlpage.footer.php
│
└── vendor/                                        # Third-party libraries
```

### **2. NGINX KONFIGURATSIYA TAHLILI:**

```nginx
# /etc/zabbix/nginx.conf
server {
    listen 8080;
    server_name zabbix;
    root /usr/share/zabbix;                        # Web root
    
    # ❌ ASOSIY MUAMMO: Local papkani blokaydi
    location ~ /(app\/|conf[^\.]|include\/|local\/|locale\/|vendor\/) {
        deny all;                                  # local/ ga kirish taqiqlangan!
        return 404;
    }
    
    # ✅ Bu static fayllar uchun ishlaydi
    location ~* \.(js|css|png|jpg|jpeg|gif|xml|txt|svg|ico)$ {
        expires 14d;                               # assets/ papkasidagi fayllar
    }
    
    # PHP fayllar uchun
    location ~ [^/]\.php(/|$) {
        fastcgi_pass unix:/tmp/php-fpm.sock;
        # ...
    }
}
```

### **3. BRANDING SISTEMASI ISHLASH MEXANIZMI:**

#### **a) CBrandHelper.php - Asosiy Branding Class:**

```php
<?php
class CBrandHelper {
    // ❌ Bu yo'l /usr/share/zabbix/local/conf/brand.conf.php ga ishora qiladi
    const BRAND_CONFIG_FILE_PATH = '/../../../local/conf/brand.conf.php';
    
    private static function loadConfig() {
        // /usr/share/zabbix/include/classes/helpers/CBrandHelper.php dan
        // ../../../local/conf/brand.conf.php = /usr/share/zabbix/local/conf/brand.conf.php
        $config_file_path = realpath(dirname(__FILE__).self::BRAND_CONFIG_FILE_PATH);
        
        if (file_exists($config_file_path)) {
            self::$config = include $config_file_path;  // Config yuklash
        }
    }
    
    public static function getLogo(int $type): ?string {
        switch ($type) {
            case LOGO_TYPE_NORMAL:
                return self::getValue('BRAND_LOGO', null);           // 'local/img/logo.svg'
            case LOGO_TYPE_SIDEBAR:
                return self::getValue('BRAND_LOGO_SIDEBAR', null);   // 'local/img/logo.svg'
            case LOGO_TYPE_SIDEBAR_COMPACT:
                return self::getValue('BRAND_LOGO_SIDEBAR_COMPACT', null); // 'local/img/logo-compact.svg'
        }
        return null;
    }
}
```

#### **b) makeLogo() Function - Logo Rendering:**

```php
// /usr/share/zabbix/include/html.inc.php
function makeLogo(int $type): CTag {
    static $zabbix_logo_classes = [
        LOGO_TYPE_NORMAL => ZBX_STYLE_ZABBIX_LOGO,                    // .zabbix-logo
        LOGO_TYPE_SIDEBAR => ZBX_STYLE_ZABBIX_LOGO_SIDEBAR,          // .zabbix-logo-sidebar  
        LOGO_TYPE_SIDEBAR_COMPACT => ZBX_STYLE_ZABBIX_LOGO_SIDEBAR_COMPACT // .zabbix-logo-sidebar-compact
    ];

    // CBrandHelper dan logo yo'lini olish
    $brand_logo = CBrandHelper::getLogo($type);  // 'local/img/logo.svg' qaytaradi
    
    if ($brand_logo !== null) {
        // ❌ <img src="local/img/logo.svg"> yaratiladi - lekin Nginx buni blokaydi!
        return (new CImg($brand_logo))->addClass($zabbix_logo_classes[$type]);
    }
    
    // Logo topilmasa default CSS background ishlatiladi
    return (new CDiv())->addClass($zabbix_logo_classes[$type]);
}
```

#### **c) Layout Rendering - Sidebar Logo:**

```php
// /usr/share/zabbix/app/partials/layout.htmlpage.aside.php
$header = (new CDiv())
    ->addClass('sidebar-header')
    ->addItem(
        (new CLink([
            makeLogo(LOGO_TYPE_SIDEBAR),           // Normal sidebar logo
            makeLogo(LOGO_TYPE_SIDEBAR_COMPACT)    // Compact sidebar logo  
        ], CMenuHelper::getFirstUrl()))
        ->addClass(ZBX_STYLE_LOGO)
    );
```

#### **d) Login Page Logo:**

```php  
// /usr/share/zabbix/include/views/general.login.php
(new CDiv(makeLogo(LOGO_TYPE_NORMAL)))->addClass(ZBX_STYLE_SIGNIN_LOGO)
```

### **4. SIZNING HOZIRGI BRAND.CONF.PHP:**

```php
<?php
// /usr/share/zabbix/ui/local/conf/brand.conf.php
return [
    'BRAND_LOGO' => 'local/img/logo.svg',                    // ❌ Nginx blokaydi
    'BRAND_LOGO_SIDEBAR' => 'local/img/logo.svg',            // ❌ Nginx blokaydi  
    'BRAND_LOGO_SIDEBAR_COMPACT' => 'local/img/logo-compact.svg', // ❌ Nginx blokaydi
    'BRAND_FOOTER' => 'TAA Monitoring System - Powered by Zabbix',
    'BRAND_HELP_URL' => 'https://www.zabbix.com/documentation/current/en/',
    'BRAND_URL' => '#',
    'BRAND_TITLE' => 'TAA Monitoring System'
];
```

---

## **🔧 TO'LIQ YECHIM STRATEGIYALARI**

### **YECHIM 1: ASSETS PAPKASIGA COPY QILISH (TAVSIYA ETILGAN) ⭐**

Bu eng oson va ishonchli yechim chunki:
- Nginx allaqachon `assets/` ga ruxsat beradi
- Minimal o'zgarishlar kerak
- Production environment uchun xavfsiz

#### **1.1. Dockerfile O'zgartirish:**

```dockerfile
# Dockerfile ga qo'shish kerak:

# Custom logo fayllarni assets papkasiga copy qilish
COPY ui/local/img/ /usr/share/zabbix/assets/img/
COPY ui/assets/ /usr/share/zabbix/assets/

# Favicon ni ham copy qilish
COPY ui/local/img/favicon.ico /usr/share/zabbix/favicon.ico

# Brand config faylni to'g'ri joyga copy qilish  
COPY ui/local/conf/brand.conf.php /usr/share/zabbix/local/conf/brand.conf.php

# Ruxsatlarni to'g'rilash
RUN chown -R zabbix:root /usr/share/zabbix/assets/ && \
    chmod -R 644 /usr/share/zabbix/assets/
```

#### **1.2. Brand.conf.php O'zgartirish:**

```php
<?php
// ui/local/conf/brand.conf.php
return [
    'BRAND_LOGO' => 'assets/img/logo.svg',                    // ✅ local/ dan assets/ ga
    'BRAND_LOGO_SIDEBAR' => 'assets/img/logo.svg',
    'BRAND_LOGO_SIDEBAR_COMPACT' => 'assets/img/logo-compact.svg',
    'BRAND_FOOTER' => 'TAA Monitoring System - Powered by Zabbix',
    'BRAND_HELP_URL' => 'https://taa.uz/documentation/',      // ✅ O'z URL
    'BRAND_URL' => 'https://taa.uz',                          // ✅ O'z URL  
    'BRAND_TITLE' => 'TAA Monitoring System'
];
```

### **YECHIM 2: NGINX KONFIGURATSIYASINI OVERRIDE QILISH**

Agar ko'proq moslashuvchanlik kerak bo'lsa:

#### **2.1. Custom Nginx Config:**

```nginx
# custom-nginx.conf yaratish
server {
    listen 8080;
    server_name zabbix;
    root /usr/share/zabbix;
    
    # ✅ Local img fayllar uchun exception
    location /local/img/ {
        allow all;
        expires 14d;
        access_log off;
    }
    
    # ✅ Static asset fayllar
    location /assets/ {
        allow all;  
        expires 14d;
        access_log off;
    }
    
    # ❌ Boshqa local fayllarni bloklash
    location ~ /(app\/|conf[^\.]|include\/|local/(?!img/)|locale\/|vendor\/) {
        deny all;
        return 404;
    }
    
    # Qolgan konfiguratsiya...
}
```

#### **2.2. Docker-compose.yml Volume:**

```yaml
volumes:
  - ./custom-nginx.conf:/etc/zabbix/nginx.conf:ro
  - ./ui/local:/usr/share/zabbix/local:ro
```

### **YECHIM 3: DOCKER COMPOSE VOLUME MOUNT TO'G'RILASH**

#### **3.1. docker-compose.yml:**

```yaml
version: '3.8'
services:
  zabbix-web:
    image: zabbix/zabbix-web-nginx-pgsql:latest
    volumes:
      # ✅ To'g'ri volume mount
      - ./ui/local:/usr/share/zabbix/local:ro
      - ./ui/assets:/usr/share/zabbix/assets:rw    
      - ./ui/favicon.ico:/usr/share/zabbix/favicon.ico:ro
    environment:
      - DB_SERVER_HOST=postgres
      - POSTGRES_USER=zabbix
      - POSTGRES_PASSWORD=zabbix_password
      - POSTGRES_DB=zabbix
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Asia/Tashkent
    ports:
      - "8098:8080"
    depends_on:
      - postgres
      - zabbix-server
```

---

## **🎨 FRONTEND TO'LIQ CUSTOMIZATION GUIDE**

### **1. LOGO VA ICONKALARNI O'ZGARTIRISH:**

#### **Logo Fayllar Tayyorlash:**
```bash
# Required logo fayllar:
ui/local/img/logo.svg              # Asosiy logo (Login sahifa, normal view)
ui/local/img/logo-compact.svg      # Compact sidebar logo  
ui/assets/img/favicon.ico          # Browser favicon
ui/assets/img/logo.png             # PNG backup (agar SVG ishlamasa)
```

#### **Logo O'lchamlari:**
- **logo.svg**: 200x60px yoki shunga mos nisbat
- **logo-compact.svg**: 40x40px yoki kvadrat
- **favicon.ico**: 16x16, 32x32, 48x48px (multi-size)

### **2. RANGLARNI O'ZGARTIRISH:**

#### **CSS Fayllar Joylashuvi:**
```
/usr/share/zabbix/assets/styles/
├── blue-theme.css          # ✅ Default tema - bu yerda o'zgartirish
├── dark-theme.css          # Qorong'u tema  
├── hc-light.css           # Yuqori kontrastli oq tema
└── hc-dark.css            # Yuqori kontrastli qora tema
```

#### **Asosiy Ranglarni O'zgartirish:**

```css
/* blue-theme.css ga qo'shish */

/* TAA Corporate ranglar */
:root {
  --taa-primary: #41eaf0;      /* TAA asosiy rang */
  --taa-secondary: #8cf0f5;    /* TAA ikkinchi rang */
  --taa-accent: #ffc72c;       /* TAA accent rang */
  --taa-success: #28a745;      /* Muvaffaqiyat rangi */
  --taa-danger: #dc3545;       /* Xato rangi */
}

/* Sidebar ranglarni o'zgartirish */
.sidebar {
  background-color: var(--taa-primary) !important;
}

/* Header ranglar */
.sidebar-header {
  background-color: var(--taa-secondary) !important;
  border-bottom: 1px solid var(--taa-accent);
}

/* Menu item ranglar */
.menu-main .menu-item {
  color: #ffffff !important;
}

.menu-main .menu-item:hover {
  background-color: var(--taa-accent) !important;
  color: var(--taa-primary) !important;
}

/* Button ranglar */
.btn-primary {
  background-color: var(--taa-primary) !important;
  border-color: var(--taa-primary) !important;
}

.btn-primary:hover {
  background-color: var(--taa-secondary) !important;
  border-color: var(--taa-secondary) !important;
}
```

### **3. MATNLARNI O'ZGARTIRISH (ZABBIX → TAA):**

#### **3.1. Brand Title va Footer:**

```php
// ui/local/conf/brand.conf.php
return [
    'BRAND_LOGO' => 'assets/img/logo.svg',
    'BRAND_FOOTER' => 'TAA Monitoring System - Monitoring Infrastructure va Applications',
    'BRAND_TITLE' => 'TAA Monitoring Dashboard',
    'BRAND_HELP_URL' => 'https://taa.uz/help/',
    'BRAND_URL' => 'https://taa.uz'
];
```

#### **3.2. Login Page Matnlari:**

Custom file yaratish: `ui/local/views/general.login.php`

```php
<?php
// Custom login page
$login_form = (new CForm())
    ->setId('login')
    ->addItem([
        (new CDiv([
            (new CDiv(makeLogo(LOGO_TYPE_NORMAL)))->addClass(ZBX_STYLE_SIGNIN_LOGO),
            (new CDiv([
                (new CLabel(_('Username'), 'name'))->addClass('form-label'),
                (new CTextBox('name', $data['name']))
                    ->addClass('form-control')
                    ->setAttribute('autofocus', 'autofocus')
            ]))->addClass('form-group'),
            (new CDiv([
                (new CLabel(_('Password'), 'password'))->addClass('form-label'),
                (new CPassBox('password', $data['password']))
                    ->addClass('form-control')
            ]))->addClass('form-group'),
            (new CDiv([
                (new CSubmitButton(_('Sign in')))
                    ->addClass('btn btn-primary btn-block')
            ]))->addClass('form-group'),
            (new CDiv('TAA Monitoring System v2.0'))
                ->addClass('text-center text-muted small')
        ]))->addClass('signin-container')
    ]);
```

#### **3.3. Page Title O'zgartirish:**

```php
// HTML head title'ni o'zgartirish uchun:
// /usr/share/zabbix/include/defines.inc.php da qo'shish:

define('TAA_SYSTEM_NAME', 'TAA Monitoring');
define('TAA_PAGE_TITLE_SEPARATOR', ' | ');

// /usr/share/zabbix/app/partials/layout.htmlpage.header.php da:
if (isset($ZBX_SERVER_NAME) && $ZBX_SERVER_NAME !== '') {
    $page_title = $page_title !== '' 
        ? TAA_SYSTEM_NAME . TAA_PAGE_TITLE_SEPARATOR . $page_title 
        : TAA_SYSTEM_NAME;
}
```

### **4. MENU VA NAVIGATION O'ZGARTIRISH:**

#### **4.1. Sidebar Menu Matnlari:**

Custom menu items yaratish uchun:

```php
// ui/local/conf/menu.conf.php yaratish
<?php
return [
    'monitoring' => [
        'label' => 'TAA Monitoring',
        'icon' => 'icon-monitoring'
    ],
    'configuration' => [
        'label' => 'TAA Configuration', 
        'icon' => 'icon-configuration'
    ],
    'administration' => [
        'label' => 'TAA Administration',
        'icon' => 'icon-administration'  
    ]
];
```

#### **4.2. Footer Links O'zgartirish:**

```php
// CBrandHelper.php da getFooterContent() o'zgartirish:
public static function getFooterContent($with_version) {
    $footer = [
        $with_version ? 'TAA Monitoring System v2.0. ' : null,
        'Copyright © 2024 TAA. ',
        (new CLink('TAA Official Website', 'https://taa.uz/'))
            ->addClass(ZBX_STYLE_GREY)
            ->addClass(ZBX_STYLE_LINK_ALT)
            ->setTarget('_blank'),
        ' | ',
        (new CLink('Support', 'https://taa.uz/support/'))
            ->addClass(ZBX_STYLE_GREY) 
            ->addClass(ZBX_STYLE_LINK_ALT)
            ->setTarget('_blank')
    ];
    
    return $footer;
}
```

---

## **⚡ DOCKER BUILD VA RUN JARAYONI**

### **1. TO'G'RI BUILD SEQUENCE:**

```bash
# 1. Loyihaning asosiy papkasida
cd /path/to/your/zabbix-project

# 2. Barcha o'zgarishlarni amalga oshirish
# - Dockerfile o'zgartirish
# - brand.conf.php yo'llarini to'g'rilash  
# - CSS fayllar tayyorlash

# 3. Docker cache'ni tozalash
docker-compose down
docker system prune -f
docker volume prune -f

# 4. Container'larni to'liq rebuild qilish
docker-compose build --no-cache --pull

# 5. Container'larni ishga tushirish
docker-compose up -d

# 6. Loglarni kuzatish
docker-compose logs -f zabbix-web
```

### **2. DEBUG VA MONITORING:**

#### **Container Ichini Tekshirish:**
```bash
# Logo fayllar mavjudligini tekshirish
docker exec -it zabbix-web ls -la /usr/share/zabbix/assets/img/

# Brand config to'g'riligini tekshirish  
docker exec -it zabbix-web cat /usr/share/zabbix/local/conf/brand.conf.php

# Nginx access log
docker exec -it zabbix-web tail -f /var/log/nginx/access.log

# PHP error log
docker exec -it zabbix-web tail -f /var/log/php8/error.log
```

#### **Browser Developer Tools:**
```javascript
// Browser console'da tekshirish
console.log('Logo URL:', document.querySelector('.zabbix-logo img')?.src);

// Network tab'da 404 errorlarni topish
// - local/img/logo.svg → 404 bo'lsa muammo Nginx'da  
// - assets/img/logo.svg → 200 bo'lsa muvaffaqiyatli
```

### **3. PRODUCTION DEPLOYMENT:**

#### **3.1. Environment Variables:**
```yaml
# docker-compose.prod.yml
environment:
  - PHP_TZ=Asia/Tashkent
  - ZBX_SERVER_NAME=TAA Monitoring Production
  - DB_SERVER_HOST=postgres-prod
  - ZBX_DENY_GUI_ACCESS=false
  - ZBX_GUI_ACCESS_IP_RANGE=['192.168.1.0/24','10.0.0.0/8']
```

#### **3.2. SSL va Domain:**
```nginx
# nginx-ssl.conf
server {
    listen 443 ssl http2;
    server_name monitoring.taa.uz;
    
    ssl_certificate /etc/ssl/certs/taa.crt;
    ssl_certificate_key /etc/ssl/private/taa.key;
    
    location / {
        proxy_pass http://zabbix-web:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## **📝 QADAMLAR KETMA-KETLIGI**

### **BOSHLASH UCHUN TAYYORGARLIK:**

1. **Logo fayllarni tayyorlash:**
   - `logo.svg` (200x60px)
   - `logo-compact.svg` (40x40px)  
   - `favicon.ico` (16x16, 32x32px)

2. **Fayllar joylashuvi tekshirish:**
   ```
   ui/local/img/logo.svg
   ui/local/img/logo-compact.svg
   ui/local/conf/brand.conf.php
   ```

3. **Docker environment tekshirish:**
   - Docker va docker-compose o'rnatilgan
   - Port 8098 bo'sh
   - Yetarli disk joy (2GB+)

### **QAYSI YECHIMNI TANLAYSIZ?**

**A) YECHIM 1 - Assets Copy (Tavsiya etilgan):**
- ✅ Eng oson
- ✅ Ishonchli  
- ✅ Production-ready
- ❌ Dockerfile o'zgartirish kerak

**B) YECHIM 2 - Nginx Override:**
- ✅ Moslashuvchan
- ✅ Ko'p imkoniyat
- ❌ Murakkab
- ❌ Security risk

**C) YECHIM 3 - Volume Mount:**
- ✅ Development uchun qulay
- ✅ Tez o'zgarish
- ❌ Production uchun mos emas
- ❌ Performance issues

---

## **🎯 KEYINGI QADAMLAR**

**Men sizga qaysi yechimni bosqichma-bosqich amalga oshirishga yordam beraman:**

1. **Dockerfile va docker-compose.yml o'zgartirish**
2. **Brand.conf.php to'g'rilash** 
3. **CSS ranglarni sozlash**
4. **Test va debug qilish**
5. **Production deployment**

**Qaysi yechim bilan boshlaysiz? Menga ayting va men barcha qadamlarni batafsil ko'rsataman!** 🚀