#!/usr/bin/env bash
# =============================================================================
# TAA Agent 2 — Linux o'chirish skripti
# -----------------------------------------------------------------------------
# install.sh natijasini bekor qiladi:
#   - servisni to'xtatadi va o'chiradi
#   - binar va systemd unit faylini olib tashlaydi
#   - config va data papkalariga TEGMAYDI (xavfsizlik uchun)
#   - foydalanuvchi/guruh: faqat --purge-user bilan o'chiriladi
#
# Foydalanish:
#   sudo ./uninstall.sh
#   sudo ./uninstall.sh --purge-user   # taa-agent foydalanuvchini ham olib tashlash
# =============================================================================

set -euo pipefail

PURGE_USER="0"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge-user) PURGE_USER="1"; shift ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Noma'lum argument: $1" >&2; exit 1 ;;
    esac
done

TAA_USER="taa-agent"
TAA_GROUP="taa-agent"
BIN_DST="/usr/sbin/taa_agent2"
UNIT_DST="/etc/systemd/system/taa-agent2.service"

log()  { printf '[uninstall.sh] %s\n' "$*"; }
warn() { printf '[uninstall.sh][OGOH] %s\n' "$*" >&2; }
die()  { printf '[uninstall.sh][XATO] %s\n' "$*" >&2; exit 1; }

# --- Root tekshiruvi ---
if [[ "$(id -u)" -ne 0 ]]; then
    die "Skript root sifatida ishga tushirilishi kerak (sudo ishlating)."
fi

# --- Servisni to'xtatish va o'chirish (idempotent) ---
if systemctl list-unit-files 2>/dev/null | grep -q '^taa-agent2\.service'; then
    log "taa-agent2 servisi to'xtatilmoqda..."
    systemctl stop taa-agent2 2>/dev/null || true
    log "taa-agent2 servisi avtoboshlash ro'yxatidan olib tashlanmoqda..."
    systemctl disable taa-agent2 2>/dev/null || true
else
    log "taa-agent2 servisi topilmadi — o'tkazib yuborildi"
fi

# --- Unit faylini o'chirish ---
if [[ -f "${UNIT_DST}" ]]; then
    log "Unit fayli olib tashlanmoqda: ${UNIT_DST}"
    rm -f "${UNIT_DST}"
    systemctl daemon-reload || true
else
    log "Unit fayli topilmadi: ${UNIT_DST}"
fi

# --- Binar fayl ---
if [[ -f "${BIN_DST}" ]]; then
    log "Binar olib tashlanmoqda: ${BIN_DST}"
    rm -f "${BIN_DST}"
else
    log "Binar topilmadi: ${BIN_DST}"
fi

# --- Config va data papkalariga tegmaslik ---
warn "/etc/taa/agent/, /var/log/taa/agent/, /var/lib/taa/agent/ va /var/run/taa/agent/ olib tashlanmadi."
warn "To'liq tozalash uchun ularni qo'lda o'chiring (ehtiyot bo'ling — backup oling!)"

# --- Foydalanuvchini olib tashlash (faqat so'ralganda) ---
if [[ "${PURGE_USER}" == "1" ]]; then
    if id -u "${TAA_USER}" >/dev/null 2>&1; then
        log "Foydalanuvchi olib tashlanmoqda: ${TAA_USER}"
        userdel "${TAA_USER}" 2>/dev/null || warn "userdel xato berdi (foydalanuvchi band bo'lishi mumkin)"
    fi
    if getent group "${TAA_GROUP}" >/dev/null 2>&1; then
        log "Guruh olib tashlanmoqda: ${TAA_GROUP}"
        groupdel "${TAA_GROUP}" 2>/dev/null || warn "groupdel xato berdi"
    fi
else
    log "Foydalanuvchi ${TAA_USER} qoldirildi (--purge-user bilan o'chirish mumkin)."
fi

log "Uninstall tugadi."
