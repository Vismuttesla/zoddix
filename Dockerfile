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
COPY ui/include/gettextwrapper.inc.php /usr/share/zabbix/include/gettextwrapper.inc.php

# gettext (PO -> MO uchun)
RUN apk add --no-cache gettext
RUN apk add --no-cache musl-locales musl-locales-lang

# Alpine Linux uchun locale sozlash
ENV LANG=uz_UZ.UTF-8
ENV LC_ALL=uz_UZ.UTF-8
ENV LC_MESSAGES=uz_UZ.UTF-8
# uz_UZ locale alias yaratish
RUN echo "uz_UZ uz_UZ.UTF-8" >> /etc/locale.alias
RUN ln -sf uz_UZ /usr/share/locale/uz_UZ.UTF-8

# uz_UZ locale fayl yaratish (Alpine da manual)
RUN mkdir -p /usr/share/locale/uz_UZ/LC_MESSAGES
COPY ui/locale/uz_UZ/LC_MESSAGES/frontend.po /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.po

# PO dan MO kompilatsiya qilish (Docker ichida)
RUN msgfmt /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.po \
    -o /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo

RUN cp /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo
# Create branding directories
RUN install -d -o root -g root /usr/share/zabbix/ui/local/conf /usr/share/zabbix/local/conf

COPY ui/locale/uz_UZ/LC_MESSAGES/frontend.po /tmp/frontend.po
RUN msgfmt /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.po \
    -o /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo \
 && cp /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo \
        /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo


# Copy branding config and logos (served via /usr/share/zabbix/ui)
COPY ui/local/conf/brand.conf.php /usr/share/zabbix/local/conf/brand.conf.php

# PO dan MO yig'amiz (uz va uz_UZ uchun)
RUN msgfmt /tmp/frontend.po -o /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo \
 && cp /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo \
 && chown zabbix:zabbix /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo \
 && chmod 644        /usr/share/zabbix/locale/uz/LC_MESSAGES/frontend.mo /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/frontend.mo

# LOGO va FAVICON (yangi yondashuv - assets papkasiga copy qilish)
COPY ui/local/img/logo.svg /usr/share/zabbix/assets/img/logo.svg
COPY ui/local/img/logo-compact.svg /usr/share/zabbix/assets/img/logo-compact.svg
COPY ui/local/img/logo-sidebar.svg /usr/share/zabbix/assets/img/logo-sidebar.svg
COPY ui/local/img/favicon.ico /usr/share/zabbix/favicon.ico

# Local papkaga ham copy qilish (backup uchun)
COPY ui/local/img/logo.svg /usr/share/zabbix/ui/local/img/logo.svg
COPY ui/local/img/logo-compact.svg /usr/share/zabbix/ui/local/img/logo-compact.svg
COPY ui/local/img/logo-sidebar.svg /usr/share/zabbix/ui/local/img/logo-sidebar.svg
COPY ui/assets/styles/ /usr/share/zabbix/assets/styles/

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
        echo 'div.zabbix-logo{background:url("assets/img/logo.svg") no-repeat !important;background-size:contain !important;width:114px !important;height:30px !important;}'; \
        echo 'div.zabbix-logo-sidebar{background:url("assets/img/logo-sidebar.svg") no-repeat !important;background-size:contain !important;width:91px !important;height:24px !important;}'; \
        echo 'div.zabbix-logo-sidebar-compact{background:url("assets/img/logo-compact.svg") no-repeat !important;background-size:contain !important;width:24px !important;height:24px !important;}'; \
        echo '.signin-logo .zabbix-logo {background:url("assets/img/logo.svg") no-repeat center !important;background-size:contain !important;width:200px !important;min-height:60px !important;}'; \
      } >> "$css"; \
    fi; \
  done

RUN sed -i 's/en_US/uz_UZ/' /usr/share/zabbix/include/defines.inc.php

# Ish muhitini sozlash va default userga qaytish
WORKDIR /usr/share/zabbix
USER zabbix
