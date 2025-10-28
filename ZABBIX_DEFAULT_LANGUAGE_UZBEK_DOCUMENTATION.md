# ZABBIX DEFAULT LANGUAGE → UZBEK KONFIGURATSIYASI

## 📋 OVERVIEW

Bu dokumentatsiya Zabbix monitoring sistemasining default tilini Uzbek ga o'tkazish jarayonini batafsil tushuntiradi. Dokumentatsiya Docker container ichidagi va local filesystem'dagi barcha komponentlarni chuqur tahlil qiladi.

## 🔍 CONTAINER VA LOCAL ARXITEKTURA TAHLILI

### Docker Container Holati
```bash
Container: zabbix-web
Document Root: /usr/share/zabbix/
Nginx Config: /etc/nginx/http.d/nginx.conf
Language Files: /usr/share/zabbix/locale/
```

### Local Workspace Holati
```bash
Local Root: ./ui/
Language Files: ./ui/locale/
Configuration: ./ui/include/
```

---

## 🎯 LANGUAGE SYSTEM ARXITEKTURASI

### 1. Language Definition Hierarchy

**Level 1: PHP Constants (ui/include/defines.inc.php)**
```php
define('ZBX_DEFAULT_LANG', 'en_US');  // Line 1849
```

**Level 2: Locale Registry (ui/include/locales.inc.php)**
```php
'uz_UZ' => ['name' => _('Uzbek (uz_UZ)'), 'display' => true]
```

**Level 3: Database Schema (ui/include/schema.inc.php)**
```php
'default_lang' => [
    'type' => DB_TYPE_CHAR,
    'length' => 7,
    'default' => 'en_US'    // Database default
]
```

**Level 4: Localization Files**
```
Container: /usr/share/zabbix/locale/uz/LC_MESSAGES/
- frontend.po (source text)
- frontend.mo (compiled binary)

Local: ./ui/locale/uz/LC_MESSAGES/
- frontend.po
- frontend.mo
```

### 2. Language Loading Mechanism

**Step 1: System Initialization**
- `jsLoader.php` → calls `setupLocale(ZBX_DEFAULT_LANG)`
- `setup.php` → uses `ZBX_DEFAULT_LANG` as fallback

**Step 2: User Session**
- `CWebUser.php` → reads from `CSettingsHelper::DEFAULT_LANG`
- Database `config` table → stores user preferences

**Step 3: Runtime Loading**
- GNU gettext system loads `.mo` files
- `zbx_locale_variants()` function handles OS differences

---

## 📊 CURRENT STATE ANALYSIS

### Docker Container Analysis

**Uzbek Language Support:**
✅ Directory exists: `/usr/share/zabbix/locale/uz/`
✅ Directory exists: `/usr/share/zabbix/locale/uz_UZ/`
✅ Binary file: `/usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo`
✅ Locale registered in `locales.inc.php`: `'uz_UZ' => ['display' => true]`

**Current Default:**
❌ PHP Constant: `ZBX_DEFAULT_LANG = 'en_US'`
❌ Database Schema: `'default' => 'en_US'`
❌ Container Runtime: English interface

### Local Workspace Analysis

**Files Structure:**
```
./ui/locale/uz/LC_MESSAGES/
├── frontend.po    # Human-readable translation source
└── frontend.mo    # Compiled gettext binary
```

**Configuration Files:**
- `./ui/include/defines.inc.php` - Contains ZBX_DEFAULT_LANG
- `./ui/include/locales.inc.php` - Language registry
- `./ui/include/schema.inc.php` - Database schema defaults

---

## 🔧 DOCKER INTEGRATION STRATEGIES

### Strategy 1: Volume Mount (Recommended)

**docker-compose.yml Configuration:**
```yaml
services:
  zabbix-web:
    volumes:
      # Full UI directory mount
      - ./ui:/usr/share/zabbix:ro
      
      # OR selective file mounting
      - ./ui/include/defines.inc.php:/usr/share/zabbix/include/defines.inc.php:ro
      - ./ui/include/locales.inc.php:/usr/share/zabbix/include/locales.inc.php:ro
      - ./ui/locale:/usr/share/zabbix/locale:ro
```

**Advantages:**
- ✅ Real-time changes visible
- ✅ No container rebuild needed
- ✅ Easy development workflow

**Disadvantages:**
- ❌ Production deployment complexity
- ❌ File permission issues possible

### Strategy 2: Build-time Copy

**Dockerfile Modifications:**
```dockerfile
# Copy modified configuration
COPY ui/include/defines.inc.php /usr/share/zabbix/include/
COPY ui/include/locales.inc.php /usr/share/zabbix/include/
COPY ui/locale/ /usr/share/zabbix/locale/

# Set correct permissions
RUN chown -R www-data:www-data /usr/share/zabbix/locale/
```

**Advantages:**
- ✅ Production ready
- ✅ Self-contained image
- ✅ No external dependencies

**Disadvantages:**
- ❌ Requires rebuild for changes
- ❌ Slower development cycle

### Strategy 3: Runtime Environment

**Environment Variables:**
```yaml
environment:
  - ZABBIX_DEFAULT_LANG=uz_UZ
```

**Requires Application Modification:**
```php
// In defines.inc.php
$default_lang = getenv('ZABBIX_DEFAULT_LANG') ?: 'en_US';
define('ZBX_DEFAULT_LANG', $default_lang);
```

---

## 📝 STEP-BY-STEP IMPLEMENTATION

### Phase 1: Local Configuration

#### Step 1.1: PHP Constants Modification
```bash
# File: ui/include/defines.inc.php
# Line: 1849

# BEFORE:
define('ZBX_DEFAULT_LANG', 'en_US');

# AFTER:
define('ZBX_DEFAULT_LANG', 'uz_UZ');
```

#### Step 1.2: Database Schema Update (Optional)
```bash
# File: ui/include/schema.inc.php
# Search for: 'default_lang' configuration

# BEFORE:
'default' => 'en_US'

# AFTER:
'default' => 'uz_UZ'
```

#### Step 1.3: Verify Uzbek Locale Files
```bash
# Check files exist:
ls -la ui/locale/uz_UZ/LC_MESSAGES/
# Should contain:
# - frontend.po (source)
# - frontend.mo (compiled)
```

### Phase 2: Docker Integration

#### Step 2.1: Volume Mount Setup
```yaml
# docker-compose.yml
services:
  zabbix-web:
    volumes:
      - ./ui:/usr/share/zabbix:ro
```

#### Step 2.2: Container Restart
```bash
docker-compose down
docker-compose up -d
```

#### Step 2.3: Verification
```bash
# Check if changes are visible in container:
docker exec -it zabbix-web grep "ZBX_DEFAULT_LANG" /usr/share/zabbix/include/defines.inc.php

# Expected output:
# define('ZBX_DEFAULT_LANG', 'uz_UZ');
```

### Phase 3: Database Configuration

#### Step 3.1: Admin Panel Setup
```
1. Login to Zabbix Web Interface
2. Navigate to: Administration → General → GUI
3. Set "Default language" to "Uzbek (uz_UZ)"
4. Click "Update"
```

#### Step 3.2: Direct Database Update (Advanced)
```sql
-- Connect to Zabbix database
UPDATE config SET default_lang = 'uz_UZ' WHERE configid = 1;
```

### Phase 4: User Preferences

#### Step 4.1: Existing Users
```
Each user can individually change language:
1. User Settings → Profile
2. Language → Uzbek (uz_UZ)
3. Update
```

#### Step 4.2: New Users Default
```
New users will automatically get Uzbek as default language
after system-level configuration is complete.
```

---

## 🔍 ADVANCED CONFIGURATION

### Locale File Customization

#### Editing Translation Files
```bash
# Edit source file:
nano ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# Key entries to verify:
msgid "Zabbix"
msgstr "TAA"

msgid "Dashboard"
msgstr "Boshqaruv paneli"
```

#### Compiling .mo Files
```bash
# Compile after editing .po files:
msgfmt ui/locale/uz_UZ/LC_MESSAGES/frontend.po -o ui/locale/uz_UZ/LC_MESSAGES/frontend.mo
```

### System Locale Configuration

#### Container Locale Support
```dockerfile
# Add to Dockerfile if needed:
RUN locale-gen uz_UZ.UTF-8
ENV LANG uz_UZ.UTF-8
ENV LANGUAGE uz_UZ:uz
ENV LC_ALL uz_UZ.UTF-8
```

#### Host System Verification
```bash
# Check if Uzbek locale is available:
locale -a | grep uz
docker exec -it zabbix-web locale -a | grep uz
```

---

## 🚨 TROUBLESHOOTING

### Issue 1: Changes Not Visible

**Symptoms:**
- Local file changes don't appear in container
- Interface still shows English

**Solutions:**
1. Verify volume mount in docker-compose.yml
2. Check file permissions: `ls -la ui/`
3. Restart container: `docker-compose restart zabbix-web`
4. Clear browser cache

### Issue 2: Uzbek Language Not Available

**Symptoms:**
- "uz_UZ" not in language dropdown
- Error in logs about missing locale

**Solutions:**
1. Verify files exist: `ls ui/locale/uz_UZ/LC_MESSAGES/`
2. Check .mo file: `file ui/locale/uz_UZ/LC_MESSAGES/frontend.mo`
3. Regenerate .mo: `msgfmt frontend.po -o frontend.mo`
4. Check locales.inc.php registration

### Issue 3: Mixed Language Interface

**Symptoms:**
- Some parts in Uzbek, some in English
- Incomplete translations

**Solutions:**
1. Update .po file with missing translations
2. Recompile .mo file
3. Clear gettext cache
4. Restart web server

### Issue 4: Database Connection Issues

**Symptoms:**
- Settings not persisting
- Admin panel changes don't save

**Solutions:**
1. Check database connectivity
2. Verify user permissions
3. Check config table structure
4. Review PHP error logs

---

## 📊 VERIFICATION CHECKLIST

### Pre-Implementation
- [ ] Backup current configuration
- [ ] Verify Uzbek locale files exist
- [ ] Test docker-compose.yml syntax
- [ ] Document current state

### Post-Implementation
- [ ] Interface loads in Uzbek
- [ ] Login page shows Uzbek
- [ ] Menu items translated
- [ ] Error messages in Uzbek
- [ ] Date/time format correct
- [ ] Number format localized

### Browser Testing
- [ ] Chrome/Chromium
- [ ] Firefox
- [ ] Safari
- [ ] Mobile browsers
- [ ] Different screen resolutions

### User Experience
- [ ] New user registration
- [ ] Existing user login
- [ ] Admin panel access
- [ ] Settings persistence
- [ ] Language switching works

---

## 🔐 SECURITY CONSIDERATIONS

### File Permissions
```bash
# Recommended permissions for locale files:
chmod 644 ui/locale/uz_UZ/LC_MESSAGES/frontend.mo
chmod 644 ui/locale/uz_UZ/LC_MESSAGES/frontend.po
chown www-data:www-data ui/locale/uz_UZ/LC_MESSAGES/*
```

### Volume Mount Security
```yaml
# Use read-only mounts when possible:
volumes:
  - ./ui:/usr/share/zabbix:ro
```

### Configuration Protection
```bash
# Protect sensitive configuration files:
chmod 600 ui/include/defines.inc.php
```

---

## 🚀 PERFORMANCE OPTIMIZATION

### Locale Loading
```php
// Consider locale caching mechanisms
// Preload frequently used translations
// Optimize .mo file sizes
```

### Container Optimization
```dockerfile
# Multi-stage builds for smaller images
# Only copy necessary locale files
COPY ui/locale/uz_UZ/ /usr/share/zabbix/locale/uz_UZ/
```

### Browser Caching
```nginx
# Nginx configuration for locale files
location ~* \.(mo|po)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

---

## 📈 MONITORING AND MAINTENANCE

### Log Monitoring
```bash
# Monitor for locale-related errors:
docker logs zabbix-web | grep -i locale
docker logs zabbix-web | grep -i translation
```

### Health Checks
```bash
# Automated checks for language functionality:
curl -H "Accept-Language: uz-UZ" http://localhost:8098/
```

### Update Procedures
```bash
# When updating Zabbix version:
1. Backup current locale files
2. Check for new translation keys
3. Update .po files as needed
4. Test language functionality
5. Deploy changes
```

---

## 📞 SUPPORT AND RESOURCES

### Official Documentation
- Zabbix Localization Guide
- GNU Gettext Manual
- Docker Compose Documentation

### Community Resources
- Zabbix Uzbek Translation Team
- Docker Hub Zabbix Images
- GitHub Issues and Discussions

### Development Tools
- Poedit (Translation Editor)
- msgfmt (Gettext Compiler)
- Docker Desktop
- VS Code with i18n extensions

---

*Dokumentatsiya versiyasi: 2.0*  
*Yaratilgan sana: 2025-01-27*  
*Mualliflar: Zabbix → TAA Rebranding Team*