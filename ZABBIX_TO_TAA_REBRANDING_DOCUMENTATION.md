# ZABBIX → TAA REBRANDING DOKUMENTATSIYASI

## 📋 OVERVIEW

Bu dokumentatsiya Zabbix monitoring sistemasini TAA (Telecom Analytics & Automation) brendiga o'tkazish jarayonini batafsil tushuntiradi. Rebrand jarayoni barcha frontend komponentlar, backend constants, localization fayllar va container konfiguratsiyalarini qamrab oladi.

## 🔍 CONTAINER ARXITEKTURA TAHLILI

### Nginx Konfiguratsiya
- **Nginx fayl:** `/etc/nginx/nginx.conf`
- **HTTP konfiguratsiya:** `/etc/nginx/http.d/nginx.conf`
- **Document root:** `/usr/share/zabbix/`
- **Assets yo'li:** `/usr/share/zabbix/assets/`
- **PHP handler:** FastCGI orqali

### Zabbix Web Struktura
```
/usr/share/zabbix/
├── include/           # PHP backend constants
├── js/               # JavaScript fayllar
├── assets/           # CSS, images, fonts
├── locale/           # Tarjima fayllar
├── ui/               # Main UI files
└── widgets/          # Dashboard widget'lar
```

## 🎯 REBRANDING STRATEGIYASI

### Phase 1: Backend Constants
**Maqsad:** PHP constants va core identifiers o'zgartirish

### Phase 2: Frontend Interface
**Maqsad:** UI elements, page titles, CSS classes yangilash

### Phase 3: Localization
**Maqsad:** Barcha tillardagi "Zabbix" ni "TAA" ga almashtirish

### Phase 4: Assets & Branding
**Maqsad:** Logo, favicon, branding elements yangilash

## 📝 BATAFSIL JARAYONLAR

---

## PHASE 1: BACKEND CONSTANTS O'ZGARTIRISH

### 1.1 Asosiy Constants (`ui/include/defines.inc.php`)

**O'zgartirilishi kerak bo'lgan qatorlar:**

```php
// ESKI ⬇️
define('ZABBIX_VERSION', '7.4.0rc2');
define('ZABBIX_API_VERSION', '7.4.0');
define('ZABBIX_EXPORT_VERSION', '7.4');
define('ZABBIX_DB_VERSION', 7030048);
define('ZABBIX_COPYRIGHT_FROM', '2001');
define('ZABBIX_COPYRIGHT_TO', '2025');
define('ZBX_DEFAULT_AGENT', 'Zabbix');

// YANGI ⬇️
define('TAA_VERSION', '7.4.0rc2');
define('TAA_API_VERSION', '7.4.0');
define('TAA_EXPORT_VERSION', '7.4');
define('TAA_DB_VERSION', 7030048);
define('TAA_COPYRIGHT_FROM', '2001');
define('TAA_COPYRIGHT_TO', '2025');
define('ZBX_DEFAULT_AGENT', 'TAA');
```

### 1.2 CSS Style Constants

```php
// ESKI ⬇️
define('ZBX_STYLE_ZABBIX_LOGO', 'zabbix-logo');
define('ZBX_STYLE_ZABBIX_LOGO_SIDEBAR', 'zabbix-logo-sidebar');
define('ZBX_STYLE_ZABBIX_LOGO_SIDEBAR_COMPACT', 'zabbix-logo-sidebar-compact');

// YANGI ⬇️
define('ZBX_STYLE_TAA_LOGO', 'taa-logo');
define('ZBX_STYLE_TAA_LOGO_SIDEBAR', 'taa-logo-sidebar');
define('ZBX_STYLE_TAA_LOGO_SIDEBAR_COMPACT', 'taa-logo-sidebar-compact');
```

---

## PHASE 2: FRONTEND INTERFACE YANGILASH

### 2.1 Page Title O'zgartirish (`ui/include/page_header.php`)

**111-qator:**
```php
// ESKI ⬇️
$page_title .= isset($page['title']) ? $page['title'] : _('Zabbix');

// YANGI ⬇️
$page_title .= isset($page['title']) ? $page['title'] : _('TAA');
```

### 2.2 CSS Classes O'zgartirish

**Barcha theme fayllarda:**
- `ui/assets/styles/blue-theme.css`
- `ui/assets/styles/dark-theme.css`
- `ui/assets/styles/hc-light.css`
- `ui/assets/styles/hc-dark.css`

```css
/* ESKI CLASS'LAR ⬇️ */
.zabbix-logo { }
.zabbix-logo-sidebar { }
.zabbix-logo-sidebar-compact { }

/* YANGI CLASS'LAR ⬇️ */
.taa-logo { }
.taa-logo-sidebar { }
.taa-logo-sidebar-compact { }
```

### 2.3 HTML Template O'zgartirish

**Logo div'larni topish va yangilash:**
```html
<!-- ESKI ⬇️ -->
<div class="zabbix-logo"></div>
<div class="zabbix-logo-sidebar"></div>
<div class="zabbix-logo-sidebar-compact"></div>

<!-- YANGI ⬇️ -->
<div class="taa-logo"></div>
<div class="taa-logo-sidebar"></div>
<div class="taa-logo-sidebar-compact"></div>
```

---

## PHASE 3: LOCALIZATION YANGILASH

### 3.1 Supported Languages

Docker ichida qo'llab-quvvatlanadigan tillar:
- ar, bg, ca, cs, da, de, el, en_GB, en_US
- es, fa, fi, fr, he, hr, hu, id, it, ja
- ka, kk, ko, lt, lv, nb_NO, nl, pl, pt_BR
- pt_PT, ro, ru, sk, sr, sv_SE, th, tr
- uk, uz, uz_UZ, vi, zh_CN, zh_TW

### 3.2 PO Fayl O'zgartirish

**Har bir til uchun:**
`ui/locale/[LANG]/LC_MESSAGES/frontend.po`

```po
# ESKI ⬇️
msgid "Zabbix"
msgstr "Zabbix"

# YANGI ⬇️
msgid "TAA"
msgstr "TAA"
```

### 3.3 MO Fayl Regenerate

```bash
# Har bir po fayldan mo fayl yaratish
msgfmt frontend.po -o frontend.mo
```

---

## PHASE 4: ASSETS & BRANDING

### 4.1 Logo Fayllar

**O'zgartirish kerak bo'lgan fayllar:**
- `ui/assets/img/logo.svg` (114x30px)
- `ui/assets/img/logo-sidebar.svg` (91x24px)  
- `ui/assets/img/logo-compact.svg` (24x24px)
- `ui/assets/favicon.ico`

### 4.2 Meta Information

**HTML Head o'zgartirish:**
```html
<!-- ESKI ⬇️ -->
<meta name="Author" content="Zabbix SIA" />
<meta name="application-name" content="Zabbix" />

<!-- YANGI ⬇️ -->
<meta name="Author" content="TAA Team" />
<meta name="application-name" content="TAA" />
```

---

## 🔧 DOCKER INTEGRATION

### Volume Mount Konfiguratsiya

**docker-compose.yml ga qo'shish:**
```yaml
services:
  zabbix-web:
    volumes:
      - ./ui:/usr/share/zabbix:ro
      # Yoki specific fayllar uchun:
      - ./ui/include/defines.inc.php:/usr/share/zabbix/include/defines.inc.php:ro
      - ./ui/include/page_header.php:/usr/share/zabbix/include/page_header.php:ro
      - ./ui/assets:/usr/share/zabbix/assets:ro
      - ./ui/locale:/usr/share/zabbix/locale:ro
```

### Build-time Copy

**Dockerfile ga qo'shish:**
```dockerfile
# Copy modified files
COPY ui/include/ /usr/share/zabbix/include/
COPY ui/assets/ /usr/share/zabbix/assets/
COPY ui/locale/ /usr/share/zabbix/locale/

# Update CSS for logo
RUN sed -i 's/zabbix-logo/taa-logo/g' /usr/share/zabbix/assets/styles/*.css
```

---

## 📋 STEP-BY-STEP IMPLEMENTATION

### Step 1: Backup va Git Branch

```bash
# Backup yaratish
git checkout -b zabbix-to-taa-rebranding
git add .
git commit -m "Backup before rebranding"
```

### Step 2: Backend Constants

1. `ui/include/defines.inc.php` ochish
2. ZABBIX_* constants'larni TAA_* ga o'zgartirish
3. ZBX_STYLE_ZABBIX_LOGO'larni yangilash

### Step 3: Page Titles

1. `ui/include/page_header.php` ochish
2. `_('Zabbix')` ni `_('TAA')` ga o'zgartirish

### Step 4: CSS va Assets

1. CSS fayllardagi class'larni o'zgartirish
2. Logo fayllarni yangilash
3. Favicon o'zgartirish

### Step 5: Localization

1. English PO faylni yangilash
2. Boshqa tillar uchun ham takrorlash
3. MO fayllar regenerate qilish

### Step 6: Testing

```bash
# Docker rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Test URLs
curl -I http://localhost:8098
```

### Step 7: Verification

**Tekshirish ro'yxati:**
- [ ] Page title "TAA" ko'rsatadi
- [ ] Logo'lar to'g'ri chiqadi
- [ ] CSS class'lar yangilangan
- [ ] Error'lar yo'q
- [ ] Barcha sahifalar ishlaydi

---

## ⚠️ OGOHLANTIRISHLAR

### Git Ignore

`.gitignore` faylida assets ignore qilinmaganligiga ishonch hosil qiling:
```gitignore
# ui/assets/ yo'q bo'lishi kerak
```

### File Permissions

Docker ichida fayl ruxsatlarini tekshiring:
```bash
docker exec -it zabbix-web ls -la /usr/share/zabbix/
```

### Cache Clearing

Browser cache'ni tozalash:
- Ctrl+F5 (hard refresh)
- Developer tools → Application → Clear Storage

---

## 🔍 TROUBLESHOOTING

### CSS Changes Ko'rinmaydi

1. Docker volume mount'ni tekshiring
2. Nginx cache'ni restart qiling
3. Browser cache'ni tozalang

### Localization Ishlamaydi

1. PO fayllar to'g'ri formatda ekanligini tekshiring
2. MO fayllar regenerate qiling
3. Locale permissions tekshiring

### Logo Ko'rinmaydi

1. SVG fayl yo'llarini tekshiring
2. File permissions tekshiring
3. CSS background-size'ni to'g'rilang

---

## 📊 PROGRESS TRACKING

| Phase | Component | Status | Notes |
|-------|-----------|---------|-------|
| 1 | Backend Constants | ⏳ Pending | defines.inc.php |
| 1 | CSS Style Constants | ⏳ Pending | style definitions |
| 2 | Page Titles | ⏳ Pending | page_header.php |
| 2 | CSS Classes | ⏳ Pending | theme files |
| 3 | Localization | ⏳ Pending | 40+ languages |
| 4 | Logo Assets | ⏳ Pending | SVG files |
| 4 | Favicon | ⏳ Pending | .ico file |

**Legend:**
- ⏳ Pending
- 🟡 In Progress  
- ✅ Complete
- ❌ Failed

---

## 📞 SUPPORT

Rebranding jarayonida muammolar yuzaga kelsa:

1. **Logs tekshirish:**
   ```bash
   docker logs zabbix-web
   ```

2. **File changes verify:**
   ```bash
   docker exec -it zabbix-web grep -r "TAA" /usr/share/zabbix/include/
   ```

3. **Rollback procedure:**
   ```bash
   git checkout main
   docker-compose down && docker-compose up -d
   ```

---

*Dokumentatsiya versiyasi: 1.0*  
*Yaratilgan sana: 2025-01-27*  
*Oxirgi yangilanish: 2025-01-27*