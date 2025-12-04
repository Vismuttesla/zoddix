# AGENTS.md - Developer Guide for Zabbix/TAA Monitoring Platform

## Project Overview

This is a **Zabbix monitoring platform** that is being customized and rebranded as **TAA (Telecom Analytics & Automation / Tizimshunoslik va Analitik Asboblar)** with full Uzbek language localization support.

**Core Technology Stack:**
- **Backend (C)**: Core monitoring engine, server, proxy, and agent components
- **Backend (Go)**: Agent2 and web service components (Go 1.23.0+)
- **Backend (Java)**: Java gateway for JMX monitoring
- **Frontend (PHP)**: Web UI (requires PHP 8.0.0+)
- **Frontend (JavaScript)**: Rich client-side UI components
- **Database**: MySQL, PostgreSQL, SQLite3, TimescaleDB support
- **Build System**: GNU Autotools (autoconf, automake), Ant (Java)
- **Containerization**: Docker with docker-compose

**License:** AGPL-3.0-only

## Important Directories

### Source Code Structure

- `src/` - All source code
  - `src/zabbix_server/` - Main server daemon
  - `src/zabbix_proxy/` - Proxy daemon for distributed monitoring
  - `src/zabbix_agent/` - Legacy C-based agent
  - `src/go/` - Go-based components (agent2, web service)
  - `src/zabbix_sender/` - Command-line tool for sending data
  - `src/zabbix_get/` - Command-line tool for testing agents
  - `src/zabbix_js/` - JavaScript engine wrapper
  - `src/libs/` - Shared C libraries (zbxcommon, zbxdb, zbxjson, etc.)

### Frontend (PHP/JavaScript)

- `ui/` - Web interface root
  - `ui/include/` - PHP backend logic
    - `ui/include/classes/` - Object-oriented PHP classes
    - `ui/include/defines.inc.php` - System constants and definitions
    - `ui/include/locales.inc.php` - Language configuration
  - `ui/js/` - JavaScript application code
  - `ui/app/` - MVC structure (controllers, views, partials)
  - `ui/assets/` - Compiled CSS, images, fonts
  - `ui/widgets/` - Dashboard widget implementations
  - `ui/locale/` - Translation files (.po and .mo)
  - `ui/tests/` - PHP and Selenium tests

### Headers and Configuration

- `include/` - C header files for all components
- `conf/` - Example configuration files
- `database/` - Database schema files (MySQL, PostgreSQL, SQLite3)
- `templates/` - Monitoring templates (YAML format)

### Assets and Styling

- `sass/` - SASS source files for styling
- `css/` - Compiled CSS stylesheets
- `assets/` - TAA brand assets (logos, favicons)
- `branding/` - TAA branding resources (mentioned in docs)

### Testing

- `tests/` - C unit tests using CMocka framework
  - `tests/libs/` - Library unit tests
  - `tests/zabbix_server/` - Server component tests
  - `tests/mocks/` - Mock implementations for testing
- `ui/tests/` - Frontend tests (PHPUnit, Selenium)

### Build and Configuration

- `configure.ac` - Autoconf configuration
- `Makefile.am` - Automake build rules
- `build.xml` - Ant build file for Java components
- `docker-compose.yml` - Docker development setup
- `Dockerfile` - Container image definition

### Documentation

- `README.md` - Project overview
- `ZABBIX_TO_TAA_REBRANDING_DOCUMENTATION.md` - Rebranding guide
- `ZABBIX_UZBEK_LOCALIZATION.md` - Uzbek localization documentation
- `TAA_FRONTEND_REBRANDING_GUIDE.md` - Frontend branding guide
- `ZABBIX_DOCKER_BRANDING_DOCUMENTATION.md` - Docker branding guide
- `man/` - Manual pages for command-line tools

## Key Development Guidelines

### C Code Conventions

- Use tab indentation (consistent with existing code)
- Function documentation uses `/*` `*/` block comment style
- Header guards: `#ifndef INCLUDE_FILENAME_H` / `#define INCLUDE_FILENAME_H`
- Function blocks separated by `/******************************************************************************` markers
- Prefix all public functions with `zbx_` (e.g., `zbx_malloc`, `zbx_strdup`)
- Use `static` for private/internal functions
- Headers in `include/` directory, implementations in `src/libs/`
- Follow existing naming patterns: snake_case for functions and variables

### Go Code Conventions

- Standard Go formatting (`gofmt`)
- Package structure under `src/go/`
- Module: `golang.zabbix.com/agent2`
- Go version: 1.23.0+
- License header at top of each file
- Mockery for mock generation (`.mockery.yml`)
- golangci-lint for linting (`.golangci.yaml`)

### PHP Code Conventions

- Minimum PHP version: 8.0.0
- PSR-4 autoloading for classes
- Classes in `ui/include/classes/` with namespace-like directory structure
- File naming: PascalCase for classes (e.g., `CApiService.php`)
- Copyright header with AGPL-3.0-only license
- Use type hints and return types
- Follow existing class patterns (API services, validators, helpers, etc.)

### JavaScript Code Conventions

- ES6+ features supported
- Class-based components (e.g., `class.dashboard.js`, `class.widget.js`)
- Prefix core classes with package-like names (e.g., `class.`)
- jQuery is used throughout
- Event-driven architecture with custom event hub
- Widget system for dashboard components

### Database Conventions

- Schema files in `database/{mysql,postgresql,sqlite3}/`
- Support multiple database backends
- Use database abstraction layer in `src/libs/zbxdb/`
- Schema versioning tracked in code
- SQL files for initial data (images.sql)

### Testing Guidelines

- C tests use CMocka framework
- Test data in YAML format (e.g., `test_name.yaml`)
- PHP tests use PHPUnit
- Selenium for UI tests
- Mock implementations in `tests/mocks/`
- Test naming: `{function_name}.c` and `{function_name}.yaml`

### Localization (TAA Project Specific)

- Translation files: `ui/locale/{lang}/LC_MESSAGES/frontend.{po,mo}`
- Supported languages: 40+ including `uz` and `uz_UZ` for Uzbek
- Use `msgfmt` to compile .po to .mo files
- Scripts: `add_new_language.sh`, `make_mo.sh`, `update_po.sh`
- Language registration in `ui/include/locales.inc.php`
- All user-facing strings should be translatable

### Branding (TAA Project Specific)

- Replace "Zabbix" with "TAA" in:
  - PHP constants (`ui/include/defines.inc.php`)
  - CSS class names and styles
  - Page titles and meta tags
  - Translation files (all languages)
- Logo files to replace:
  - `ui/assets/img/logo.svg` (114x30px)
  - `ui/assets/img/logo-sidebar.svg` (91x24px)
  - `ui/assets/img/logo-compact.svg` (24x24px)
  - `ui/assets/favicon.ico`
- Brand assets stored in `assets/` and `branding/` directories
- Docker build copies assets to appropriate locations

## Building and Running

### Building from Source

```bash
# Configure the build
./configure --enable-server --enable-agent --enable-proxy \
  --with-mysql --with-postgresql --with-libcurl --with-libxml2

# Build
make

# Install
sudo make install
```

### Docker Development

```bash
# Build and start all services
docker-compose up -d --build

# View logs
docker-compose logs -f zabbix-web

# Access UI at http://localhost:8098
# Default credentials: Admin/zabbix (or Admin/taa for TAA version)
```

### Compiling Translations

```bash
cd ui/locale
./make_mo.sh  # Compiles all .po files to .mo
```

### Running Tests

```bash
# C unit tests
make check

# PHP tests
cd ui/tests
phpunit

# Specific test suite
phpunit --testsuite api_json
```

## Common Tasks

### Adding a New Language

1. Run `ui/locale/add_new_language.sh {lang_code}`
2. Register in `ui/include/locales.inc.php`
3. Translate `frontend.po` file
4. Compile with `make_mo.sh`
5. Test language switching in UI

### Creating a New Widget

1. Create directory: `ui/widgets/{widget_name}/`
2. Implement widget class extending base widget
3. Create views and assets
4. Register widget in system
5. Add translations

### Adding Database Schema Changes

1. Update schema files in `database/{backend}/`
2. Implement upgrade logic in `src/libs/zbxdbupgrade/`
3. Update version constants
4. Test with all supported databases

### Modifying C Libraries

1. Add/modify header in `include/`
2. Implement in `src/libs/zbx{library}/`
3. Update `Makefile.am` if adding new files
4. Write unit tests in `tests/libs/zbx{library}/`
5. Run `make check`

### Working with Frontend Classes

- API services: `ui/include/classes/api/services/`
- Validators: `ui/include/classes/validators/`
- HTML components: `ui/include/classes/html/`
- Helpers: `ui/include/classes/helpers/`
- Follow existing class structure and patterns

## Important Files

### Configuration

- `ui/include/defines.inc.php` - All PHP constants (event types, item types, styles, etc.)
- `ui/include/locales.inc.php` - Language definitions and mappings
- `include/version.h` - Version information
- `conf/zabbix_server.conf` - Server configuration template

### Entry Points

- `ui/index.php` - Main UI entry point
- `ui/api_jsonrpc.php` - JSON-RPC API endpoint
- `src/zabbix_server/server.c` - Server main()
- `src/go/cmd/zabbix_agent2/zabbix_agent2.go` - Agent2 main()

### Build Configuration

- `configure.ac` - Autoconf configuration (dependencies, features)
- `build.xml` - Java build configuration
- `src/go/go.mod` - Go dependencies
- `ui/composer.json` - PHP dependencies

## Troubleshooting

### Build Issues

- Ensure all dependencies installed (check `configure.ac` for requirements)
- Check autoconf/automake versions
- Review `config.log` for configuration errors
- Run `make clean` before rebuilding

### Docker Issues

- Clear volumes: `docker-compose down -v`
- Rebuild images: `docker-compose build --no-cache`
- Check logs: `docker-compose logs {service}`
- Verify mounted volumes in `docker-compose.yml`

### Localization Issues

- Ensure .po files have correct encoding (UTF-8)
- Recompile .mo files after .po changes
- Check file permissions in locale directories
- Verify language code in `locales.inc.php`

### Frontend Issues

- Clear PHP opcache
- Check browser console for JavaScript errors
- Verify asset paths (especially after rebranding)
- Check PHP error logs

## Code Review Checklist

- [ ] Code follows project conventions (indentation, naming)
- [ ] License header present in new files
- [ ] Unit tests added/updated for changes
- [ ] Documentation updated if API changed
- [ ] No hardcoded strings (use translatable messages)
- [ ] Database queries use proper abstraction
- [ ] Error handling implemented
- [ ] Memory management correct (C code: malloc/free)
- [ ] Security considerations addressed (input validation, SQL injection, XSS)
- [ ] Changes work with all supported databases (if applicable)
- [ ] Branding consistency maintained (TAA project)

## Additional Resources

- **Official Documentation**: https://www.zabbix.com/documentation/
- **API Documentation**: https://www.zabbix.com/documentation/current/en/manual/api
- **Git Repository**: Check commit history for examples
- **Community**: Zabbix forums and mailing lists

## Project-Specific Notes (TAA)

This is a **rebranding and localization project**. Key objectives:

1. **Uzbek Localization**: Complete translation to Uzbek (Latin and Cyrillic)
2. **TAA Rebranding**: Replace all Zabbix references with TAA branding
3. **Custom Identity**: Unique logos, icons, and visual identity
4. **Docker Deployment**: Containerized setup for easy deployment

**Current Status** (refer to project documentation):
- Language infrastructure: ✅ Complete
- Translation work: 🔄 In Progress
- Branding assets: 🔄 In Progress
- Docker integration: ✅ Complete

When making changes, ensure:
- Maintain compatibility with base Zabbix features
- Preserve upgradeability
- Document TAA-specific modifications
- Test with both Uzbek and other languages
- Verify branding consistency across all components
