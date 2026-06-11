# =============================================================================
# TAA Server (custom) — Zabbix Server + Python + msmtp + TAA skriptlar
# -----------------------------------------------------------------------------
# Maqsad: docker compose up -d qilingan zahoti TAA Action'lar ichidan
#         scripts/ ichidagi Python va Bash skriptlar to'g'ridan-to'g'ri ishlasin.
#
# Build: avtomatik (docker-compose.yml dagi `build:` orqali)
# Image: taa/server:custom
# =============================================================================

FROM zabbix/zabbix-server-pgsql:alpine-7.0-latest

# Root sifatida paket o'rnatish
USER root

# Bog'liqliklarni o'rnatish:
#   - python3, py3-pip  : auto_remediation.py, ip_inventory.py, stp_loop_parser.py
#   - bash, curl        : taa_telegram.sh
#   - msmtp             : taa_email.sh
#   - ca-certificates   : TLS uchun
#   - tzdata            : Asia/Tashkent vaqt zonasi
RUN apk add --no-cache \
      python3 \
      py3-pip \
      bash \
      curl \
      msmtp \
      ca-certificates \
      tzdata \
 && pip3 install --no-cache-dir --break-system-packages \
      "netmiko>=4.0" \
      "psycopg2-binary>=2.9" \
      "jinja2>=3.0" \
      "pyyaml>=6.0"

# Skript papkalarini yaratish va TAA skriptlarini ko'chirish
COPY scripts/alertscripts/    /usr/lib/zabbix/alertscripts/
COPY scripts/externalscripts/ /usr/lib/zabbix/externalscripts/

# Egasi va huquqlar
RUN chmod 750 /usr/lib/zabbix/alertscripts/*    /usr/lib/zabbix/externalscripts/* \
 && chown -R zabbix:zabbix /usr/lib/zabbix/alertscripts /usr/lib/zabbix/externalscripts \
 && install -d -o zabbix -g zabbix -m 0750 /var/lib/taa \
 && install -d -o zabbix -g zabbix -m 0750 /var/log/taa

# Vaqt zonasi
ENV TZ=Asia/Tashkent

# zabbix foydalanuvchisi sifatida ishlash
USER zabbix
