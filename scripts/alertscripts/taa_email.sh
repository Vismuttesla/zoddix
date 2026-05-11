#!/usr/bin/env bash
# =============================================================================
# TAA Media type: "Email-custom"
# -----------------------------------------------------------------------------
# Vazifa: TAA tomonidan kelgan alertlarni msmtp orqali SMTP serverga yuborish.
# UTF-8 sarlavha RFC 2047 (base64) ko'rinishida kodlanadi — kirillcha va
# o'zbekcha matnlar to'g'ri ko'rinadi.
#
# Foydalanish (TAA Media type "Script parameters"):
#   $1 = to        (qabul qiluvchi email, {ALERT.SENDTO})
#   $2 = subject   ({ALERT.SUBJECT})
#   $3 = body      ({ALERT.MESSAGE})
#
# Majburiy environment o'zgaruvchilari:
#   SMTP_HOST   — SMTP server xosti (masalan: smtp.gmail.com)
#   SMTP_PORT   — SMTP port (587 — STARTTLS, 465 — SMTPS)
#   SMTP_USER   — SMTP autentifikatsiya foydalanuvchisi
#   SMTP_PASS   — SMTP autentifikatsiya paroli (sekret!)
#   FROM_ADDR   — "From:" maydoni uchun manzil
#
# Bog'liqlik: msmtp (apt install msmtp ca-certificates)
# Joylashuv: /usr/lib/zabbix/alertscripts/taa_email.sh
# Egasi: zabbix:zabbix    Huquqlar: 0750
# =============================================================================

set -euo pipefail

# --- Argumentlarni tekshirish ------------------------------------------------
if [[ $# -lt 3 ]]; then
    echo "Foydalanish: $0 <to> <subject> <body>" >&2
    exit 2
fi

TO_ADDR="$1"
SUBJECT="$2"
BODY="$3"

# --- Env mavjudligini tekshirish (sekretlar hech qachon hardcode emas) -------
: "${SMTP_HOST:?SMTP_HOST env majburiy}"
: "${SMTP_PORT:?SMTP_PORT env majburiy}"
: "${SMTP_USER:?SMTP_USER env majburiy}"
: "${SMTP_PASS:?SMTP_PASS env majburiy}"
: "${FROM_ADDR:?FROM_ADDR env majburiy}"

# --- msmtp mavjudligini tekshirish -------------------------------------------
if ! command -v msmtp >/dev/null 2>&1; then
    echo "[taa_email] msmtp o'rnatilmagan. apt install msmtp ca-certificates" >&2
    exit 3
fi

# --- RFC 2047 UTF-8 sarlavha kodlash -----------------------------------------
# Subject ichida kirillcha/o'zbekcha bo'lsa, "=?UTF-8?B?<base64>?=" formatida
# uzatamiz. ASCII bo'lsa ham xavfsiz — har doim kodlaymiz.
encode_subject() {
    local raw="$1"
    local b64
    b64=$(printf '%s' "${raw}" | base64 -w 0)
    printf '=?UTF-8?B?%s?=' "${b64}"
}

ENC_SUBJECT="$(encode_subject "${SUBJECT}")"

# --- Vaqtinchalik msmtp konfiguratsiyasini tuzish ----------------------------
# Sekretlarni argv orqali emas, balki cheklangan huquqli faylda saqlaymiz.
# TLS rejimi portga qarab tanlanadi:
#   587 — STARTTLS (tls=on, tls_starttls=on)
#   465 — implicit TLS (tls=on, tls_starttls=off)
MSMTP_CONF="$(mktemp /tmp/msmtp.XXXXXX)"
trap 'rm -f "${MSMTP_CONF}"' EXIT
chmod 600 "${MSMTP_CONF}"

if [[ "${SMTP_PORT}" == "465" ]]; then
    TLS_STARTTLS="off"
else
    TLS_STARTTLS="on"
fi

cat >"${MSMTP_CONF}" <<EOF
defaults
auth           on
tls            on
tls_starttls   ${TLS_STARTTLS}
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/zabbix/msmtp.log

account taa
host     ${SMTP_HOST}
port     ${SMTP_PORT}
from     ${FROM_ADDR}
user     ${SMTP_USER}
password ${SMTP_PASS}

account default : taa
EOF

# --- Email matnini yig'ish (header + body) -----------------------------------
# Content-Type: UTF-8 charset, Date — RFC 5322 formatda.
DATE_HDR="$(date -R)"
MSG_ID="$(printf '<%s.%s@taa>' "$(date +%s)" "$$")"

{
    printf 'From: %s\r\n'                        "${FROM_ADDR}"
    printf 'To: %s\r\n'                          "${TO_ADDR}"
    printf 'Subject: %s\r\n'                     "${ENC_SUBJECT}"
    printf 'Date: %s\r\n'                        "${DATE_HDR}"
    printf 'Message-ID: %s\r\n'                  "${MSG_ID}"
    printf 'MIME-Version: 1.0\r\n'
    printf 'Content-Type: text/plain; charset=UTF-8\r\n'
    printf 'Content-Transfer-Encoding: 8bit\r\n'
    printf 'X-Mailer: TAA (taa_email.sh)\r\n'
    printf '\r\n'
    printf '%s\r\n'                              "${BODY}"
} | msmtp --file="${MSMTP_CONF}" -t -- "${TO_ADDR}" || {
    echo "[taa_email] msmtp yuborish xatoligi (to=${TO_ADDR})" >&2
    exit 1
}

echo "[taa_email] OK: to=${TO_ADDR} subject=\"${SUBJECT}\""
