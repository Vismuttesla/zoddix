# TAA Monitoring Platform (Zabbix Uzbek Localization & Rebranding Project)

## Project Overview

This project is a comprehensive effort to fully localize and rebrand the Zabbix monitoring platform into the **TAA** (Tizimshunoslik va Analitik Asboblar / System Analytics and Tools) monitoring platform with complete Uzbek language support. The original Zabbix is an enterprise-class, open-source distributed monitoring solution designed to monitor the performance and availability of network devices, servers, services, and other IT resources.

### Purpose
- **Complete Uzbek Translation**: Translate all user interface elements, messages, and documentation into Uzbek
- **Full Rebranding**: Transform Zabbix into TAA with custom branding, logos, and icons
- **Cultural Adaptation**: Ensure the translation and branding is culturally appropriate for Uzbek-speaking users
- **Custom Identity**: Create a unique monitoring platform identity for the Uzbek market
- **Accessibility**: Make monitoring accessible to Uzbek-speaking IT professionals and organizations
- **Brand Recognition**: Establish TAA as a recognized monitoring solution in Uzbekistan

## Project Structure

```
taa-monitoring/ (formerly zabbix/)
├── assets/                      # TAA Brand Assets
│   ├── favicon.ico              # TAA favicon
│   ├── logo.svg                 # TAA main logo
│   ├── icons/                   # TAA custom icons
│   └── branding/                # Additional brand assets
├── ui/                          # Web interface files
│   ├── assets/                  # UI assets and images
│   │   ├── img/                 # Custom TAA images
│   │   └── styles/              # TAA brand styling
│   ├── locale/                  # Localization files
│   │   ├── uz/                  # Uzbek locale (Latin script)
│   │   ├── uz_UZ/               # Uzbek locale (Cyrillic script)
│   │   ├── add_new_language.sh  # Script to add new languages
│   │   ├── make_mo.sh           # Script to compile .po to .mo files
│   │   └── update_po.sh         # Script to update translation files
│   └── include/
│       ├── locales.inc.php      # Language configuration file
│       └── defines.inc.php      # Brand name definitions
├── branding/                    # TAA Branding Resources
│   ├── logos/                   # TAA logos in various formats
│   ├── icons/                   # TAA icon sets
│   ├── colors.md                # TAA color palette
│   └── style-guide.md           # TAA style guidelines
├── docker-compose.yml           # Docker composition for development
├── Dockerfile                   # Docker build configuration (with branding)
└── src/                         # Source code directories
```

## Features

### Zabbix Core Features
- **Resource Discovery**: Network entities, server resources, device monitoring
- **Metric Acquisition**: Agent and agent-less monitoring from multiple sources
- **Root Cause Analysis**: Real-time problem detection and correlation
- **Alerts & Notifications**: Multi-channel notification system
- **Visualization**: Graphs, lists, geomaps, and network topology
- **Multitenancy**: Support for multiple organizations and data centers
- **Flexibility**: Extensive customization and integration capabilities

### TAA Platform Features
- ✅ **UI Language Support**: Uzbek language is registered in the system
- 📝 **Translation Files**: `.po` and `.mo` files for Uzbek translations
- 🎨 **Custom Branding**: Complete TAA visual identity with logos and icons
- 🏷️ **Name Replacement**: All "Zabbix" references replaced with "TAA"
- 🔧 **Build Integration**: Docker setup includes Uzbek locale and branding assets
- 🌐 **Cultural Adaptation**: Proper date, time, and number formatting
- 📚 **Documentation**: Comprehensive setup and build documentation
- 🖼️ **Asset Management**: Automated copying of brand assets during Docker build
- 🎯 **Brand Consistency**: Unified TAA identity across all platform components

## Prerequisites

### System Requirements
- **Docker**: Version 20.0+ with Docker Compose
- **Git**: For version control
- **Text Editor**: For translation work (recommended: Poedit, VS Code)

### Optional Tools
- **gettext**: For working with .po/.mo files manually
- **msgfmt**: For compiling translation files
- **Poedit**: GUI tool for translation management

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd taa-monitoring
```

### 2. Build and Run with Docker
```bash
# Start the complete TAA stack
docker-compose up -d --build

# Check container status
docker-compose ps

# View logs
docker-compose logs -f taa-web
```

### 3. Access the Application
- **Web Interface**: http://localhost:8098
- **Default Credentials**: Admin/taa (changed from zabbix)
- **Language Setting**: Go to User Settings → Language → Select "Uzbek (uz_UZ)"
- **Branding**: All logos and icons will display TAA branding

## Docker Configuration

### Services Overview

#### PostgreSQL Database
```yaml
postgres:
  image: postgres:15
  environment:
    POSTGRES_USER: zabbix
    POSTGRES_PASSWORD: zabbix_password
    POSTGRES_DB: zabbix
```

#### TAA Server (Zabbix Server Backend)
```yaml
taa-server:
  image: zabbix/zabbix-server-pgsql:alpine-7.0-latest
  environment:
    DB_SERVER_HOST: postgres
    POSTGRES_USER: taa_user
    POSTGRES_PASSWORD: taa_password
    POSTGRES_DB: taa_monitoring
```

#### TAA Web Interface (Custom Build with Branding)
```yaml
taa-web:
  image: taa-web:custom
  build:
    context: .
    dockerfile: Dockerfile.taa
  volumes:
    # Localization files
    - ./ui/locale/uz_UZ:/usr/share/zabbix/locale/uz_UZ:ro
    - ./ui/locale/uz:/usr/share/zabbix/locale/uz:ro
    - ./ui/include/locales.inc.php:/usr/share/zabbix/include/locales.inc.php:ro
    # TAA Branding assets
    - ./assets/logo.svg:/usr/share/zabbix/assets/img/logo.svg:ro
    - ./assets/favicon.ico:/usr/share/zabbix/favicon.ico:ro
    - ./branding/icons:/usr/share/zabbix/assets/img/icons:ro
    - ./branding/logos:/usr/share/zabbix/assets/img/logos:ro
    # Custom TAA configurations
    - ./ui/include/defines.inc.php:/usr/share/zabbix/include/defines.inc.php:ro
    - ./ui/assets/styles:/usr/share/zabbix/assets/styles:ro
```

### Volume Mappings
The Docker setup mounts essential files for complete TAA transformation:
- **Localization**: Uzbek locale directories (`uz` and `uz_UZ`)
- **Language Config**: Language configuration file (`locales.inc.php`)
- **Translation Files**: Compiled `.mo` files for runtime
- **Brand Assets**: TAA logos, icons, and visual elements
- **Custom Styles**: TAA-specific CSS and styling
- **Brand Definitions**: Name replacement configurations
- **Frontend Assets**: All UI customizations for TAA identity

## TAA Transformation & Localization Workflow

### Current Status
- ✅ Language code registered: `uz_UZ` in `locales.inc.php`
- ✅ Locale directories created: `ui/locale/uz/` and `ui/locale/uz_UZ/`
- ✅ Docker configuration updated with branding support
- 🎨 Brand asset directories structured
- 🏷️ Name replacement system prepared
- 📝 Translation files: Ready for population
- 🖼️ Icon and logo replacement framework established

### Brand Transformation Process

#### 1. Asset Preparation
```bash
# Create TAA brand asset directories
mkdir -p branding/{logos,icons,styles}
mkdir -p assets/{icons,branding}

# Prepare TAA assets in various formats
branding/logos/
├── taa-logo-main.svg        # Main TAA logo
├── taa-logo-small.png       # Small size logo
├── taa-logo-large.png       # Large size logo
├── taa-logo-white.svg       # White version for dark backgrounds
└── taa-logo-favicon.ico     # Favicon

branding/icons/
├── taa-icon-16x16.png      # Small icons
├── taa-icon-32x32.png      # Medium icons
├── taa-icon-64x64.png      # Large icons
└── taa-iconset.svg         # Icon sprite sheet
```

#### 2. Name Replacement Configuration
Create `ui/include/defines.inc.php` for global name replacements:
```php
<?php
// TAA Brand Name Definitions
define('PRODUCT_NAME', 'TAA');
define('PRODUCT_FULL_NAME', 'Tizimshunoslik va Analitik Asboblar');
define('PRODUCT_DESCRIPTION', 'Monitoring va Analitik Platform');
define('COPYRIGHT_MESSAGE', '© 2024 TAA Monitoring Platform');
define('DEFAULT_THEME', 'taa-theme');
```

#### 3. Docker Build Integration
Create `Dockerfile.taa` for complete asset copying with explicit source mappings:
```dockerfile
FROM zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest

# ===== TAA BRANDING ASSETS MAPPING =====
# Main Logo Replacements
COPY assets/logo.svg /usr/share/zabbix/assets/img/logo.svg
COPY branding/logos/taa-logo-main.svg /usr/share/zabbix/assets/img/
COPY branding/logos/taa-logo-small.png /usr/share/zabbix/assets/img/
COPY branding/logos/taa-logo-large.png /usr/share/zabbix/assets/img/

# Favicon and Browser Icons
COPY assets/favicon.ico /usr/share/zabbix/favicon.ico
COPY branding/logos/taa-logo-favicon.ico /usr/share/zabbix/assets/img/favicon.ico

# Navigation and UI Icons
COPY branding/icons/taa-icon-16x16.png /usr/share/zabbix/assets/img/icon-16.png
COPY branding/icons/taa-icon-32x32.png /usr/share/zabbix/assets/img/icon-32.png
COPY branding/icons/taa-icon-64x64.png /usr/share/zabbix/assets/img/icon-64.png

# Header and Footer Logos
COPY branding/logos/taa-logo-header.svg /usr/share/zabbix/assets/img/zabbix_logo.svg
COPY branding/logos/taa-logo-white.svg /usr/share/zabbix/assets/img/zabbix_logo_sidebar.svg

# Dashboard and Login Page Assets
COPY branding/logos/taa-logo-login.png /usr/share/zabbix/assets/img/zabbix_logo_login.png
COPY branding/logos/taa-logo-dashboard.svg /usr/share/zabbix/assets/img/dashboard_logo.svg

# Copy all icons to respective UI directories
COPY branding/icons/* /usr/share/zabbix/assets/img/icons/
COPY branding/logos/* /usr/share/zabbix/assets/img/logos/

# Custom TAA Styles and Themes
COPY branding/styles/taa-theme.css /usr/share/zabbix/assets/styles/
COPY branding/styles/* /usr/share/zabbix/assets/styles/

# Copy localization files
COPY ui/locale/uz_UZ /usr/share/zabbix/locale/uz_UZ
COPY ui/locale/uz /usr/share/zabbix/locale/uz
COPY ui/include/locales.inc.php /usr/share/zabbix/include/
COPY ui/include/defines.inc.php /usr/share/zabbix/include/

# Copy custom UI modifications
COPY ui/assets/styles /usr/share/zabbix/assets/styles
COPY ui/assets/img /usr/share/zabbix/assets/img

# ===== CRITICAL: REPLACE ORIGINAL ZABBIX ASSETS =====
# Override original Zabbix branding files with TAA equivalents
RUN cp /usr/share/zabbix/assets/img/taa-logo-main.svg /usr/share/zabbix/assets/img/zabbix_logo.svg
RUN cp /usr/share/zabbix/assets/img/taa-logo-header.svg /usr/share/zabbix/assets/img/zabbix_logo_header.svg
RUN cp /usr/share/zabbix/assets/img/taa-icon-32x32.png /usr/share/zabbix/assets/img/zabbix_icon.png

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/zabbix/assets/
RUN chown -R nginx:nginx /usr/share/zabbix/locale/

# Update index.php and other files to use TAA branding
RUN find /usr/share/zabbix -name "*.php" -exec sed -i 's/Zabbix/TAA/g' {} \;
RUN find /usr/share/zabbix -name "*.js" -exec sed -i 's/Zabbix/TAA/g' {} \;
RUN find /usr/share/zabbix -name "*.css" -exec sed -i 's/zabbix_logo/taa-logo/g' {} \;
```

### Translation Process

#### 1. Generate Translation Template
```bash
cd ui/locale
./update_po.sh
```

#### 2. Create Uzbek Translation Files
```bash
# For uz_UZ locale
./add_new_language.sh uz_UZ

# For uz locale (if needed)
./add_new_language.sh uz
```

#### 3. Translate Strings
Edit the generated `.po` files in `ui/locale/uz_UZ/LC_MESSAGES/frontend.po`:
```po
#: example.php:123
msgid "Dashboard"
msgstr "Boshqaruv paneli"

#: example.php:124
msgid "Monitoring"
msgstr "Monitoring"
```

#### 4. Brand Name Translation
Update translation files to include TAA branding:
```po
#: branding
msgid "Zabbix"
msgstr "TAA"

#: branding
msgid "Zabbix monitoring"
msgstr "TAA monitoring"

#: branding
msgid "System Analytics and Tools"
msgstr "Tizimshunoslik va Analitik Asboblar"
```

#### 5. Compile Translations
```bash
# Compile all .po files to .mo files
./make_mo.sh
```

#### 6. Build TAA Docker Image
```bash
# Build custom TAA image with all assets
docker build -f Dockerfile.taa -t taa-web:custom .

# Verify asset copying
docker run --rm taa-web:custom ls -la /usr/share/zabbix/assets/img/logos/
```

#### 7. Test Complete TAA Platform
```bash
# Rebuild and restart containers with TAA branding
docker-compose down
docker-compose up -d --build

# Verify TAA branding is applied
curl -s http://localhost:8098 | grep -i "TAA"
```

### Translation Guidelines

#### Language Standards
- **Script**: Use Latin script for uz_UZ locale
- **Terminology**: Maintain consistency with IT terminology
- **Context**: Consider technical context in translations
- **Pluralization**: Set correct plural forms in .po file headers

#### Example Translations
| English/Zabbix | Uzbek/TAA | Context |
|---------|-------|---------|
| Dashboard | Boshqaruv paneli | Main interface |
| Host | Xost | IT infrastructure |
| Trigger | Trigger | Monitoring alerts |
| Template | Shablon | Configuration |
| Network | Tarmoq | Infrastructure |
| Zabbix | TAA | Brand name |
| Zabbix Server | TAA Server | System component |
| Zabbix Agent | TAA Agent | Monitoring agent |
| Monitoring | Monitoring | Core function |
| System Analytics | Tizim tahlili | Platform purpose |

## Building from Source

### Manual Build Process
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y build-essential autoconf automake

# Configure build
./bootstrap.sh
./configure --enable-server --enable-agent --with-postgresql

# Build
make

# Install
sudo make install
```

### Docker Build Process
```bash
# Build custom TAA web image with all branding
docker build -f Dockerfile.taa -t taa-web:custom .

# Or use docker-compose with TAA configuration
docker-compose build taa-web

# Build with cache busting for fresh assets
docker build --no-cache -f Dockerfile.taa -t taa-web:latest .

# Verify TAA assets are copied correctly
docker run --rm taa-web:custom find /usr/share/zabbix -name "*taa*" -o -name "*TAA*"
```

### Frontend Asset Management
```bash
# Automated script to prepare all TAA assets
#!/bin/bash
# prepare_taa_assets.sh

echo "Preparing TAA brand assets..."

# Create asset directories
mkdir -p {branding/{logos,icons,styles},assets/{icons,branding},ui/assets/{img,styles}}

# Copy TAA logos to multiple locations
cp branding/logos/taa-logo-main.svg assets/logo.svg
cp branding/logos/taa-logo-favicon.ico assets/favicon.ico

# Copy icons for UI
cp -r branding/icons/* ui/assets/img/icons/

# Copy custom TAA styles
cp -r branding/styles/* ui/assets/styles/

echo "TAA assets prepared for Docker build"
```

## Frontend Asset Source Mapping & Build Process

### Original Zabbix Asset Locations (What Gets Replaced)
During the Docker build, TAA assets replace these original Zabbix locations:

#### **Primary Logo Locations:**
```bash
# Original Zabbix Assets → TAA Replacements
/usr/share/zabbix/assets/img/zabbix_logo.svg → taa-logo-header.svg
/usr/share/zabbix/assets/img/zabbix_logo_header.svg → taa-logo-header.svg
/usr/share/zabbix/assets/img/zabbix_logo_sidebar.svg → taa-logo-white.svg
/usr/share/zabbix/assets/img/zabbix_logo_login.png → taa-logo-login.png
/usr/share/zabbix/favicon.ico → taa-logo-favicon.ico
```

#### **Icon and UI Element Locations:**
```bash
# Icons used throughout the interface
/usr/share/zabbix/assets/img/icon-16.png → taa-icon-16x16.png
/usr/share/zabbix/assets/img/icon-32.png → taa-icon-32x32.png
/usr/share/zabbix/assets/img/icon-64.png → taa-icon-64x64.png
/usr/share/zabbix/assets/img/zabbix_icon.png → taa-icon-32x32.png

# Dashboard and widget icons
/usr/share/zabbix/assets/img/dashboard_logo.svg → taa-logo-dashboard.svg
/usr/share/zabbix/ui/assets/img/ → (entire TAA icon set)
```

#### **CSS and Style References:**
```bash
# CSS files that reference logos
/usr/share/zabbix/assets/styles/blue-theme.css
/usr/share/zabbix/assets/styles/dark-theme.css
/usr/share/zabbix/assets/styles/hc-light.css
/usr/share/zabbix/assets/styles/hc-dark.css
```

### TAA Asset Source Structure (Build Input)
Your local project should have this structure for successful Docker builds:

```bash
taa-monitoring/
├── branding/                    # 📁 Source TAA Brand Assets
│   ├── logos/
│   │   ├── taa-logo-main.svg           # Main TAA logo
│   │   ├── taa-logo-header.svg         # Header logo (replaces zabbix_logo.svg)
│   │   ├── taa-logo-sidebar.svg        # Sidebar logo
│   │   ├── taa-logo-white.svg          # White version for dark themes
│   │   ├── taa-logo-login.png          # Login page logo
│   │   ├── taa-logo-dashboard.svg      # Dashboard widget logo
│   │   ├── taa-logo-small.png          # Small size (16x16, 24x24)
│   │   ├── taa-logo-large.png          # Large size (64x64, 128x128)
│   │   └── taa-logo-favicon.ico        # Browser favicon
│   ├── icons/
│   │   ├── taa-icon-16x16.png          # Small UI icons
│   │   ├── taa-icon-32x32.png          # Medium UI icons
│   │   ├── taa-icon-64x64.png          # Large UI icons
│   │   ├── taa-iconset.svg             # Icon sprite sheet
│   │   └── ui-elements/                # Individual UI element icons
│   │       ├── menu-icon.svg
│   │       ├── settings-icon.svg
│   │       └── notification-icon.svg
│   └── styles/
│       ├── taa-theme.css               # Custom TAA theme
│       ├── taa-colors.css              # TAA color definitions
│       └── logo-overrides.css          # Logo positioning rules
└── assets/                      # 📁 Quick Access Assets
    ├── logo.svg                        # Symlink to taa-logo-main.svg
    ├── favicon.ico                     # Symlink to taa-logo-favicon.ico
    └── branding/                       # Additional brand materials
```

### Build-Time Asset Processing

#### **Step 1: Pre-Build Asset Validation**
```bash
#!/bin/bash
# validate_taa_assets.sh

echo "🔍 Validating TAA assets before Docker build..."

# Check required logo files
required_logos=(
    "branding/logos/taa-logo-main.svg"
    "branding/logos/taa-logo-header.svg"
    "branding/logos/taa-logo-white.svg"
    "branding/logos/taa-logo-login.png"
    "branding/logos/taa-logo-favicon.ico"
)

for logo in "${required_logos[@]}"; do
    if [[ ! -f "$logo" ]]; then
        echo "❌ Missing required asset: $logo"
        exit 1
    else
        echo "✅ Found: $logo"
    fi
done

# Check icon files
required_icons=(
    "branding/icons/taa-icon-16x16.png"
    "branding/icons/taa-icon-32x32.png"
    "branding/icons/taa-icon-64x64.png"
)

for icon in "${required_icons[@]}"; do
    if [[ ! -f "$icon" ]]; then
        echo "❌ Missing required icon: $icon"
        exit 1
    else
        echo "✅ Found: $icon"
    fi
done

echo "✅ All TAA assets validated successfully!"
```

#### **Step 2: Asset Optimization During Build**
```dockerfile
# In Dockerfile.taa - Add optimization steps
FROM zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest

# Install image optimization tools
RUN apk add --no-cache imagemagick optipng

# Copy and optimize TAA assets
COPY branding/logos/ /tmp/logos/
COPY branding/icons/ /tmp/icons/

# Optimize PNG files
RUN find /tmp/icons -name "*.png" -exec optipng -o7 {} \;

# Generate missing icon sizes if needed
RUN convert /tmp/logos/taa-logo-main.svg -resize 16x16 /tmp/icons/taa-icon-16x16.png
RUN convert /tmp/logos/taa-logo-main.svg -resize 32x32 /tmp/icons/taa-icon-32x32.png
RUN convert /tmp/logos/taa-logo-main.svg -resize 64x64 /tmp/icons/taa-icon-64x64.png

# Now copy optimized assets to final locations
# [Previous COPY commands with /tmp/ sources]
```

#### **Step 3: Runtime Asset Verification**
```bash
#!/bin/bash
# verify_taa_deployment.sh

echo "🔍 Verifying TAA branding in deployed container..."

CONTAINER_NAME="taa-web"

# Check if TAA logos are properly placed
echo "Checking logo deployment..."
docker exec $CONTAINER_NAME ls -la /usr/share/zabbix/assets/img/ | grep -i taa

# Verify original Zabbix assets are replaced
echo "Verifying Zabbix asset replacement..."
docker exec $CONTAINER_NAME file /usr/share/zabbix/assets/img/zabbix_logo.svg

# Check favicon
echo "Checking favicon..."
docker exec $CONTAINER_NAME ls -la /usr/share/zabbix/favicon.ico

# Test web accessibility
echo "Testing web interface..."
curl -s http://localhost:8098 | grep -i "TAA" && echo "✅ TAA branding detected in HTML"

echo "🎯 TAA deployment verification complete!"
```

### Frontend Build Integration Points

#### **PHP Template Integration**
The frontend builds need to reference TAA assets in these key files:
```php
// ui/include/page_header.php
$logo_src = 'assets/img/taa-logo-header.svg';

// ui/include/views/general.login.php  
$login_logo = 'assets/img/taa-logo-login.png';

// ui/include/classes/core/CView.php
$favicon = 'favicon.ico'; // Points to TAA favicon
```

#### **JavaScript Asset References**
```javascript
// ui/js/main.js - Update logo references
const LOGO_PATH = 'assets/img/taa-logo-main.svg';
const ICON_PATH = 'assets/img/icons/';

// ui/js/dashboard.js - Dashboard logo
const DASHBOARD_LOGO = 'assets/img/taa-logo-dashboard.svg';
```

#### **CSS Asset Integration**
```css
/* ui/assets/styles/taa-theme.css */
.header-logo {
    background-image: url('../img/taa-logo-header.svg');
}

.login-logo {
    background-image: url('../img/taa-logo-login.png');
}

.sidebar-logo {
    background-image: url('../img/taa-logo-white.svg');
}
```

### Asset Caching and Performance

#### **Browser Caching Headers**
```nginx
# In nginx.conf (part of Docker image)
location ~* \.(svg|png|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary Accept-Encoding;
}

# Specific cache busting for TAA assets
location /assets/img/taa- {
    expires 30d;
    add_header Cache-Control "public";
}
```

#### **Asset Versioning Strategy**
```bash
# Generate version hash for cache busting
TAA_VERSION=$(date +%Y%m%d_%H%M%S)
echo "TAA_ASSET_VERSION='$TAA_VERSION'" > ui/include/taa_version.php

# Update asset URLs with version
sed -i "s/taa-logo-main.svg/taa-logo-main.svg?v=$TAA_VERSION/g" ui/**/*.php
```

This comprehensive mapping ensures that all TAA branding assets are properly integrated during the Docker build process, replacing all original Zabbix visual elements with TAA branding.

## Development Setup

### Local Development Environment
```bash
# Start only database and server
docker-compose up -d postgres taa-server

# Run web interface locally for development with TAA branding
cd ui
php -S localhost:8080

# Or run with TAA assets mounted
docker-compose up -d postgres taa-server
docker run -p 8080:8080 -v $(pwd)/ui:/usr/share/zabbix -v $(pwd)/branding:/usr/share/zabbix/assets/branding taa-web:custom
```

### File Watching and Hot Reload
```bash
# Watch for changes in locale files and branding assets
find ui/locale -name "*.po" -o -path "branding/*" -o -path "assets/*" | entr -r docker-compose restart taa-web

# Watch specifically for TAA asset changes
find branding assets ui/assets -type f | entr -r sh -c 'docker-compose build taa-web && docker-compose up -d taa-web'

# Auto-compile translations and rebuild on changes
find ui/locale -name "*.po" | entr -r sh -c 'cd ui/locale && ./make_mo.sh && docker-compose restart taa-web'
```

### TAA Development Workflow
```bash
# Complete development setup script
#!/bin/bash
# dev_setup_taa.sh

echo "Setting up TAA development environment..."

# Prepare assets
./prepare_taa_assets.sh

# Start development stack
docker-compose up -d postgres taa-server

# Build and start TAA web with development mounts
docker-compose up -d taa-web

echo "TAA development environment ready at http://localhost:8098"
echo "Username: Admin, Password: taa"
```

## Testing

### Functional Testing
1. **Language Switching**: Test UI language switching functionality
2. **Text Display**: Verify all translated text displays correctly
3. **Character Encoding**: Ensure UTF-8 support for Uzbek characters
4. **Date/Time Formatting**: Check localized date and time formats

### Translation Validation
```bash
# Check .po file syntax
msgfmt --check-format ui/locale/uz_UZ/LC_MESSAGES/frontend.po

# Check for missing translations
grep -c "msgstr \"\"" ui/locale/uz_UZ/LC_MESSAGES/frontend.po
```

## Deployment

### Production Deployment
```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Deploy with proper security
docker-compose -f docker-compose.prod.yml up -d
```

### Configuration for Production
- Set secure database passwords
- Configure SSL/TLS certificates
- Set up proper backup procedures
- Configure monitoring and logging

## Contributing

### How to Contribute
1. **Fork** the repository
2. **Create** a feature branch for your translations
3. **Follow** the translation guidelines
4. **Test** your changes thoroughly
5. **Submit** a pull request with detailed description

### Translation Review Process
1. Initial translation by contributor
2. Technical review for accuracy
3. Cultural review by native speaker
4. Testing in development environment
5. Final approval and merge

## Troubleshooting

### Common Issues

#### Docker Issues
```bash
# Container not starting
docker-compose logs zabbix-web

# Permission issues
sudo chown -R $(id -u):$(id -g) ui/locale/

# Port conflicts
docker-compose down
sudo netstat -tulpn | grep :8098
```

#### Localization Issues
```bash
# Missing .mo files
cd ui/locale && ./make_mo.sh

# Character encoding issues
file ui/locale/uz_UZ/LC_MESSAGES/frontend.po
# Should show: UTF-8 Unicode text

# Language not appearing in UI
grep -n "uz_UZ" ui/include/locales.inc.php
```

### Debug Mode
Enable debug mode in Zabbix configuration:
```php
// In zabbix.conf.php
$ZBX_CONFIG['debug'] = true;
```

## Performance Considerations

### Optimization Tips
- Use compiled `.mo` files instead of `.po` files in production
- Enable PHP opcache for better performance
- Configure proper database indexing
- Use CDN for static assets

### Monitoring Performance
- Monitor translation loading times
- Check memory usage with different locales
- Benchmark UI response times

## Security

### Security Best Practices
- Regular security updates
- Secure database configuration
- Input validation for translated content
- Regular security audits

### Locale Security
- Validate translation file integrity
- Prevent code injection in translations
- Secure file permissions for locale files

## License

This project maintains the same license as Zabbix: **AGPL-3.0-only**

See [COPYING](COPYING) for full license text.

## Resources

### Documentation
- [Zabbix Official Documentation](https://www.zabbix.com/documentation/current/en/)
- [Zabbix Installation Manual](https://www.zabbix.com/documentation/current/en/manual/installation)
- [gettext Documentation](https://www.gnu.org/software/gettext/manual/)

### Community
- [Zabbix Community Forums](https://www.zabbix.com/forum/)
- [Zabbix GitHub Repository](https://github.com/zabbix/zabbix)
- Uzbek Localization Team: [Contact Information]

### Tools
- [Poedit](https://poedit.net/) - Translation editor
- [Weblate](https://weblate.org/) - Web-based translation platform
- [Crowdin](https://crowdin.com/) - Localization management platform

## Changelog

### Version History
- **v1.0.0**: Initial Uzbek localization setup
- **v1.1.0**: Docker integration completed
- **v1.2.0**: Translation workflow established
- **v2.0.0**: Full UI translation (target)

## Roadmap

### Short-term Goals (1-3 months)
- [ ] Complete core UI translations (90%+)
- [ ] Implement date/time localization
- [ ] Set up automated testing
- [ ] Create translation memory

### Medium-term Goals (3-6 months)
- [ ] Complete all UI translations (100%)
- [ ] Translate documentation
- [ ] Community feedback integration
- [ ] Performance optimization

### Long-term Goals (6+ months)
- [ ] Official Zabbix inclusion
- [ ] Maintenance and updates
- [ ] Regional dialect support
- [ ] Mobile app localization

---

**Note**: This project is actively maintained. For questions, issues, or contributions, please contact the development team or create an issue in the project repository.