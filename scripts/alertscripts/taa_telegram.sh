#!/usr/bin/env bash
# =============================================================================
# TAA Media type: "Telegram-custom"
# -----------------------------------------------------------------------------
# Vazifa: TAA tomonidan kelgan alert xabarlarini Telegram botiga yuborish.
# Xabar Markdown formatda, "code block" ichida — matn buzilmaydi.
#
# Foydalanish (TAA Media type "Script parameters"):
#   $1 = chat_id       (Telegram chat ID, masalan: -1001234567890)
#   $2 = subject       (TAA da {ALERT.SUBJECT})
#   $3 = message       (TAA da {ALERT.MESSAGE})
#
# Majburiy environment o'zgaruvchisi:
#   TG_TOKEN  — BotFather bergan token.  Hech qachon skript ichida hardcode QILINMASIN.
#
# Joylashuv: /usr/lib/zabbix/alertscripts/taa_telegram.sh
# Egasi: zabbix:zabbix    Huquqlar: 0750
# =============================================================================

set -euo pipefail

# --- Argumentlarni tekshirish ------------------------------------------------
if [[ $# -lt 3 ]]; then
    echo "Foydalanish: $0 <chat_id> <subject> <message>" >&2
    exit 2
fi

CHAT_ID="$1"
SUBJECT="$2"
MESSAGE="$3"

# --- Token mavjudligini tekshirish -------------------------------------------
# Eslatma: ${VAR:?...} ichida apostrof bo'lmasligi kerak — bash uni single quote
# sifatida tokenizatsiya qiladi. Shuning uchun matn sodda ASCII.
: "${TG_TOKEN:?TG_TOKEN env variable required (Telegram bot token)}"

# --- Telegram API limit: bitta xabar uzunligi 4096 belgi ---------------------
# Subject + Markdown qoplama hisobga olinib, message qismini qisqartiramiz.
MAX_MSG_LEN=3500
if (( ${#MESSAGE} > MAX_MSG_LEN )); then
    MESSAGE="${MESSAGE:0:MAX_MSG_LEN}"$'\n...[qisqartirildi]'
fi

# --- Markdown formatda matn tayyorlash ---------------------------------------
# Sarlavha *bold*, asosiy xabar uchburchak (```) ichida — Markdown maxsus
# belgilari (`*`, `_`, `[` va h.k.) "code block" ichida xavfsiz ko'rinadi.
TEXT="$(printf '*TAA: %s*\n```\n%s\n```' "$SUBJECT" "$MESSAGE")"

# --- API chaqiruvi -----------------------------------------------------------
# --fail-with-body: HTTP 4xx/5xx bo'lsa exit code !=0, lekin javob tanasi
# stdout/stderr ga chiqadi (debug uchun).
API_URL="https://api.telegram.org/bot${TG_TOKEN}/sendMessage"

RESPONSE=$(
    curl -sS \
        --fail-with-body \
        --max-time 15 \
        -X POST "${API_URL}" \
        --data-urlencode "chat_id=${CHAT_ID}" \
        --data-urlencode "parse_mode=Markdown" \
        --data-urlencode "text=${TEXT}" \
        2>&1
) || {
    echo "[taa_telegram] Telegram API xatosi: ${RESPONSE}" >&2
    exit 1
}

# Muvaffaqiyatli yuborish — log uchun bitta qator
echo "[taa_telegram] OK: chat_id=${CHAT_ID} subject=\"${SUBJECT}\""
