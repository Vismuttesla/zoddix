# Zabbix veb imageni asos qilib olish
FROM zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest

# Rootga o'tamiz (papkalar/COPY uchun)
USER root

# Kerakli kataloglar
RUN install -d -o root -g root /etc/zabbix/conf \
 && install -d -o root -g root /usr/share/zabbix/ui/assets/img \
 && install -d -o root -g root /usr/share/zabbix/assets/img \
 && install -d -o root -g root /usr/share/zabbix/locale/uz/LC_MESSAGES \
 && install -d -o root -g root /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES

# Konfiguratsiya fayllari (to'g'ri yo'l: /etc/zabbix/conf/)
COPY ui/conf/zabbix.conf.php /etc/zabbix/conf/zabbix.conf.php
COPY ui/include/locales.inc.php /usr/share/zabbix/include/locales.inc.php

# gettext (PO -> MO uchun)
RUN apk add --no-cache gettext

# PO fayl (senda shu yo'lda)
# Create branding directories
RUN install -d -o root -g root /usr/share/zabbix/ui/local/conf /usr/share/zabbix/ui/local/img

COPY ui/locale/uz/LC_MESSAGES/frontend.po /tmp/frontend.po
# Copy branding config and logos (served via /usr/share/zabbix/ui)
COPY ui/local/conf/brand.conf.php /usr/share/zabbix/ui/local/conf/brand.conf.php

# PO dan MO yig'amiz (uz va uz_UZ uchun)
RUN msgfmt /tmp/frontend.po -o /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo \
 && cp /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo \
 && chown zabbix:zabbix /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo \
 && chmod 644        /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo

# LOGO va FAVICON (brandsiz, build bilan)
COPY assets/logo.svg /usr/share/zabbix/ui/assets/img/logo.svg
COPY assets/logo.svg /usr/share/zabbix/assets/img/logo.svg
COPY assets/logo.svg /usr/share/zabbix/ui/assets/img/logo-sidebar.svg
COPY assets/logo.svg /usr/share/zabbix/ui/assets/img/logo-compact.svg
COPY assets/favicon.ico  /usr/share/zabbix/ui/favicon.ico

# CSS oxiriga override — CSS ichidagi base64 logo'ni bosib ketish va yangi logoni qo'yish
RUN set -eux; \
  for css in /usr/share/zabbix/assets/styles/blue-theme.css \
             /usr/share/zabbix/assets/styles/dark-theme.css \
             /usr/share/zabbix/assets/styles/hc-light.css \
             /usr/share/zabbix/assets/styles/hc-dark.css; do \
    if [ -f "$css" ]; then \
      { \
        echo ''; \
        echo '/* Custom logo override - replace all default Zabbix logos */'; \
        echo 'div.zabbix-logo{background:url("../ui/assets/img/logo.svg") no-repeat !important;background-size:contain !important;width:auto !important;height:auto !important;}'; \
        echo 'div.zabbix-logo-sidebar{background:url("../ui/assets/img/logo-sidebar.svg") no-repeat !important;background-size:contain !important;width:auto !important;height:auto !important;}'; \
        echo 'div.zabbix-logo-sidebar-compact{background:url("../ui/assets/img/logo-compact.svg") no-repeat !important;background-size:contain !important;width:auto !important;height:auto !important;}'; \
        echo '.zabbix-logo, .zabbix-logo-sidebar, .zabbix-logo-sidebar-compact {background-image:url("../ui/assets/img/logo.svg") !important;}'; \
        echo '.signin-logo .zabbix-logo {background:url("../ui/assets/img/logo.svg") no-repeat center !important;background-size:contain !important;min-height:60px !important;}'; \
      } >> "$css"; \
    fi; \
  done

# Ish muhitini sozlash va default userga qaytish
WORKDIR /usr/share/zabbix
USER zabbix
