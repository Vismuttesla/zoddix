# Zabbix veb imageni asos qilib olish
FROM zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest

# O'zgartirilgan fayllarni ko'chirish
COPY ui/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php
COPY ui/include/locales.inc.php /usr/share/zabbix/include/locales.inc.php
COPY ui/locale/uz_UZ.po /usr/share/zabbix/locale/uz_UZ.po

COPY /css/stylesheets/sass/dark-theme.css /usr/share/zabbix/assets/styles/dark-theme.css

# gettext o'rnatish (po faylini mo ga kompilyatsiya qilish uchun)
RUN apk add --no-cache gettext

# uz_UZ.po faylini zabbix.mo ga kompilyatsiya qilish
RUN mkdir -p /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES && \
    msgfmt /usr/share/zabbix/locale/uz_UZ.po -o /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/zabbix.mo && \
    chown zabbix:zabbix /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/zabbix.mo && \
    chmod 644 /usr/share/zabbix/locale/uz_UZ/LC_MESSAGES/zabbix.mo

# Ish muhitini sozlash
WORKDIR /usr/share/zabbix
