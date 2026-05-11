#!/usr/bin/env bash
# =============================================================================
# TAA — alert/external skriptlarni o'rnatish (DL-160 Gen9, Ubuntu 22.04)
# -----------------------------------------------------------------------------
# Bajaradi:
#   1. /usr/lib/zabbix/{alertscripts,externalscripts} papkalarini yaratadi
#   2. scripts/alertscripts/* va scripts/externalscripts/* ni shu papkalarga
#      symlink qiladi (yoki --copy bilan ko'chiradi).
#   3. Egasini zabbix:zabbix qiladi, +x bayrog'ini qo'yadi.
#   4. scripts/requirements.txt mavjud bo'lsa, pip install bajaradi.
#   5. SQLite audit DB ni initsializatsiya qiladi (/var/lib/taa/audit.db).
#   6. /etc/zabbix/.env yo'q bo'lsa, .env.example dan ko'chiradi (chmod 600).
#
# Idempotent: qayta ishga tushirish xavfsiz, qayta yaratmaydi.
#
# Foydalanish:
#   sudo bash scripts/install.sh             # haqiqatan o'rnatadi
#   sudo bash scripts/install.sh --dry-run   # faqat nima qilinishini ko'rsatadi
#   sudo bash scripts/install.sh --copy      # symlink emas, fayllarni ko'chiradi
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# 0) Sozlamalar
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../scripts
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"                   # .../zoddix

ALERTSCRIPTS_DIR="/usr/lib/zabbix/alertscripts"
EXTSCRIPTS_DIR="/usr/lib/zabbix/externalscripts"
TAA_DATA_DIR="/var/lib/taa"
SQLITE_DB="${TAA_DATA_DIR}/audit.db"
ENV_TARGET="/etc/zabbix/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/docker/.env.example"
REQS_FILE="${SCRIPT_DIR}/requirements.txt"
SQLITE_SCHEMA="${SCRIPT_DIR}/sql/ipam_schema_sqlite.sql"
ZBX_USER="zabbix"
ZBX_GROUP="zabbix"

DRY_RUN=0
USE_COPY=0

# -----------------------------------------------------------------------------
# 1) Argumentlarni tahlil qilish
# -----------------------------------------------------------------------------
for arg in "$@"; do
    case "${arg}" in
        --dry-run) DRY_RUN=1 ;;
        --copy)    USE_COPY=1 ;;
        -h|--help)
            sed -n '2,30p' "$0"
            exit 0
            ;;
        *)
            echo "Noma'lum argument: ${arg}" >&2
            exit 2
            ;;
    esac
done

# -----------------------------------------------------------------------------
# 2) Yordamchi funksiyalar
# -----------------------------------------------------------------------------
log()  { printf '[install] %s\n' "$*"; }
warn() { printf '[install] WARN: %s\n' "$*" >&2; }
err()  { printf '[install] ERR: %s\n'  "$*" >&2; }

# run <command...> — DRY_RUN bo'lsa faqat chop etadi, aks holda bajaradi
run() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# -----------------------------------------------------------------------------
# 3) Root va OS tekshiruvi
# -----------------------------------------------------------------------------
if [[ "${DRY_RUN}" -eq 0 && "${EUID}" -ne 0 ]]; then
    err "Bu skript root huquqlarini talab qiladi (sudo bilan ishga tushiring)."
    exit 1
fi

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        warn "Tavsiya etilgan OS — Ubuntu 22.04. Hozirgi: ${PRETTY_NAME:-unknown}"
    fi
fi

# -----------------------------------------------------------------------------
# 4) zabbix foydalanuvchi mavjudligini tekshirish
# -----------------------------------------------------------------------------
if id "${ZBX_USER}" >/dev/null 2>&1; then
    log "Foydalanuvchi '${ZBX_USER}' mavjud."
else
    warn "Foydalanuvchi '${ZBX_USER}' topilmadi — egalik o'rnatish o'tkazib yuboriladi."
    ZBX_USER=""
    ZBX_GROUP=""
fi

# -----------------------------------------------------------------------------
# 5) Papkalarni yaratish
# -----------------------------------------------------------------------------
log "Papkalarni yaratish (mavjud bo'lsa o'tkazib yuboriladi)..."
run install -d -m 0750 "${ALERTSCRIPTS_DIR}"
run install -d -m 0750 "${EXTSCRIPTS_DIR}"
run install -d -m 0750 "${TAA_DATA_DIR}"
run install -d -m 0750 "$(dirname "${ENV_TARGET}")"

# -----------------------------------------------------------------------------
# 6) Skriptlarni o'rnatish (symlink yoki copy)
# -----------------------------------------------------------------------------
# install_one <src> <dst_dir>
install_one() {
    local src="$1"
    local dst_dir="$2"
    local name dst
    name="$(basename "${src}")"
    dst="${dst_dir}/${name}"

    if [[ "${USE_COPY}" -eq 1 ]]; then
        run install -m 0750 "${src}" "${dst}"
    else
        # Mavjud va to'g'ri ko'rsatayotgan symlinkni qaytadan yaratmaymiz
        if [[ -L "${dst}" && "$(readlink -f "${dst}" 2>/dev/null)" == "$(readlink -f "${src}")" ]]; then
            log "Symlink mavjud va to'g'ri: ${dst}"
        else
            run ln -sfn "${src}" "${dst}"
            run chmod 0750 "${src}"
        fi
    fi

    if [[ -n "${ZBX_USER}" ]]; then
        # symlink ham, fayl ham — egalikni manba faylga qo'yamiz
        run chown -h "${ZBX_USER}:${ZBX_GROUP}" "${dst}" || true
        run chown    "${ZBX_USER}:${ZBX_GROUP}" "${src}" || true
    fi
}

log "Alert skriptlarini o'rnatish: ${SCRIPT_DIR}/alertscripts -> ${ALERTSCRIPTS_DIR}"
if [[ -d "${SCRIPT_DIR}/alertscripts" ]]; then
    # Globni xavfsiz aylanmaga aylantirish (bo'sh papka bo'lsa muammo bo'lmaydi)
    shopt -s nullglob
    for f in "${SCRIPT_DIR}/alertscripts"/*; do
        [[ -f "${f}" ]] || continue
        install_one "${f}" "${ALERTSCRIPTS_DIR}"
    done
    shopt -u nullglob
else
    warn "Papka topilmadi: ${SCRIPT_DIR}/alertscripts"
fi

log "External skriptlarini o'rnatish: ${SCRIPT_DIR}/externalscripts -> ${EXTSCRIPTS_DIR}"
if [[ -d "${SCRIPT_DIR}/externalscripts" ]]; then
    shopt -s nullglob
    for f in "${SCRIPT_DIR}/externalscripts"/*; do
        [[ -f "${f}" ]] || continue
        install_one "${f}" "${EXTSCRIPTS_DIR}"
    done
    shopt -u nullglob
else
    warn "Papka topilmadi: ${SCRIPT_DIR}/externalscripts"
fi

# -----------------------------------------------------------------------------
# 7) Python bog'liqliklarini o'rnatish
# -----------------------------------------------------------------------------
if [[ -f "${REQS_FILE}" ]]; then
    if command -v pip3 >/dev/null 2>&1; then
        log "pip3 install -r ${REQS_FILE}"
        run pip3 install --upgrade -r "${REQS_FILE}"
    elif command -v pip >/dev/null 2>&1; then
        log "pip install -r ${REQS_FILE}"
        run pip install --upgrade -r "${REQS_FILE}"
    else
        warn "pip topilmadi — Python bog'liqliklari o'rnatilmadi. 'apt install python3-pip' bajaring."
    fi
else
    log "${REQS_FILE} topilmadi — Python bog'liqliklari o'tkazib yuborildi."
fi

# -----------------------------------------------------------------------------
# 8) SQLite audit DB ni initsializatsiya qilish
# -----------------------------------------------------------------------------
if [[ -f "${SQLITE_SCHEMA}" ]]; then
    if command -v sqlite3 >/dev/null 2>&1; then
        if [[ -f "${SQLITE_DB}" ]]; then
            log "SQLite DB mavjud: ${SQLITE_DB} — schema idempotent qo'llaniladi"
        else
            log "SQLite DB yaratilmoqda: ${SQLITE_DB}"
        fi
        # CREATE TABLE IF NOT EXISTS — mavjud DB ga ham xavfsiz qo'llanadi
        run sqlite3 "${SQLITE_DB}" ".read ${SQLITE_SCHEMA}"
        if [[ -n "${ZBX_USER}" ]]; then
            run chown "${ZBX_USER}:${ZBX_GROUP}" "${SQLITE_DB}" || true
        fi
        run chmod 0640 "${SQLITE_DB}" || true
    else
        warn "sqlite3 topilmadi — 'apt install sqlite3' bajaring va qayta urinib ko'ring."
    fi
else
    warn "Schema fayli topilmadi: ${SQLITE_SCHEMA}"
fi

# -----------------------------------------------------------------------------
# 9) .env ni joylash (faqat mavjud bo'lmasa)
# -----------------------------------------------------------------------------
if [[ -f "${ENV_TARGET}" ]]; then
    log ".env mavjud: ${ENV_TARGET} — tegmaymiz (idempotent)"
else
    if [[ -f "${ENV_EXAMPLE}" ]]; then
        log ".env yaratilmoqda: ${ENV_TARGET} (manba: ${ENV_EXAMPLE})"
        run install -m 0600 "${ENV_EXAMPLE}" "${ENV_TARGET}"
        if [[ -n "${ZBX_USER}" ]]; then
            run chown "${ZBX_USER}:${ZBX_GROUP}" "${ENV_TARGET}" || true
        fi
        warn "${ENV_TARGET} ichida REPLACE_WITH_* qiymatlarini o'zgartirishni unutmang!"
    else
        warn ".env.example topilmadi: ${ENV_EXAMPLE}"
    fi
fi

# -----------------------------------------------------------------------------
# 10) Yakuniy hisobot
# -----------------------------------------------------------------------------
log "Tugadi."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "Eslatma: bu --dry-run rejimi edi, hech qanday fayl o'zgartirilmadi."
fi
log "Tekshirish:"
log "  ls -l ${ALERTSCRIPTS_DIR}"
log "  ls -l ${EXTSCRIPTS_DIR}"
log "  sqlite3 ${SQLITE_DB} '.tables'"
log "  sudo -u ${ZBX_USER:-zabbix} test -r ${ENV_TARGET} && echo 'env: ok'"
