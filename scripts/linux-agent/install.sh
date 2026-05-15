#!/usr/bin/env bash
# =============================================================================
# TAA Agent 2 — Linux o'rnatish skripti (DL-160 Gen9 / Ubuntu 22.04)
# -----------------------------------------------------------------------------
# Maqsad: kross-kompilyatsiya qilingan binar, config va systemd unitni
#         maqsadli serverga idempotent tarzda o'rnatish.
# Foydalanish:
#   sudo ./install.sh             # haqiqiy o'rnatish
#   sudo ./install.sh --dry-run   # faqat amallarni ko'rsatish (o'zgartirmasdan)
# =============================================================================

set -euo pipefail

DRY_RUN="0"

# --- Argumentlar ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN="1"; shift ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Noma'lum argument: $1" >&2; exit 1 ;;
    esac
done

# --- Skript joylashgan papka (manba fayllari uchun) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Konstantalar ---
TAA_USER="taa-agent"
TAA_GROUP="taa-agent"
BIN_SRC="${SCRIPT_DIR}/dist/taa_agent2"
BIN_DST="/usr/sbin/taa_agent2"
CONF_SRC="${SCRIPT_DIR}/taa_agent2.conf"
CONF_DST="/etc/taa/agent/taa_agent2.conf"
UNIT_SRC="${SCRIPT_DIR}/taa-agent2.service"
UNIT_DST="/etc/systemd/system/taa-agent2.service"

DIRS_750=(
    /etc/taa/agent
    /etc/taa/agent/taa_agent2.d
    /var/log/taa/agent
    /var/run/taa/agent
    /var/lib/taa/agent
)

# --- Yordamchilar ---
log()  { printf '[install.sh] %s\n' "$*"; }
warn() { printf '[install.sh][OGOH] %s\n' "$*" >&2; }
die()  { printf '[install.sh][XATO] %s\n' "$*" >&2; exit 1; }

# Buyruqni dry-run hisobga olib bajaradi
run() {
    if [[ "${DRY_RUN}" == "1" ]]; then
        printf '[dry-run] %s\n' "$*"
    else
        eval "$@"
    fi
}

# --- Root ekanligini tekshirish (dry-run da emas) ---
if [[ "${DRY_RUN}" != "1" && "$(id -u)" -ne 0 ]]; then
    die "Skript root sifatida ishga tushirilishi kerak (sudo ishlating)."
fi

# --- Manba fayllar mavjudligini tekshirish ---
[[ -f "${BIN_SRC}"  ]] || die "Binar topilmadi: ${BIN_SRC} (avval ./build.sh ni ishga tushiring)"
[[ -f "${CONF_SRC}" ]] || die "Config topilmadi: ${CONF_SRC}"
[[ -f "${UNIT_SRC}" ]] || die "Systemd unit topilmadi: ${UNIT_SRC}"

# -----------------------------------------------------------------------------
# 1) Guruh va foydalanuvchi yaratish (idempotent)
# -----------------------------------------------------------------------------
if getent group "${TAA_GROUP}" >/dev/null 2>&1; then
    log "Guruh allaqachon mavjud: ${TAA_GROUP}"
else
    log "Guruh yaratilmoqda: ${TAA_GROUP}"
    run "groupadd --system ${TAA_GROUP}"
fi

if id -u "${TAA_USER}" >/dev/null 2>&1; then
    log "Foydalanuvchi allaqachon mavjud: ${TAA_USER}"
else
    log "Foydalanuvchi yaratilmoqda: ${TAA_USER}"
    run "useradd --system --no-create-home --shell /usr/sbin/nologin --gid ${TAA_GROUP} ${TAA_USER}"
fi

# -----------------------------------------------------------------------------
# 2) Papkalarni yaratish va egasini sozlash
# -----------------------------------------------------------------------------
for d in "${DIRS_750[@]}"; do
    if [[ -d "${d}" ]]; then
        log "Papka mavjud: ${d}"
    else
        log "Papka yaratilmoqda: ${d}"
        run "install -d -m 0750 -o ${TAA_USER} -g ${TAA_GROUP} ${d}"
    fi
    # Egalik va ruxsatni har doim qayta tasdiqlash (idempotent)
    run "chown ${TAA_USER}:${TAA_GROUP} ${d}"
    run "chmod 0750 ${d}"
done

# -----------------------------------------------------------------------------
# 3) Binar fayl
# -----------------------------------------------------------------------------
log "Binar o'rnatilmoqda: ${BIN_DST}"
run "install -m 0755 -o root -g root ${BIN_SRC} ${BIN_DST}"

# -----------------------------------------------------------------------------
# 4) Config fayli (mavjud bo'lsa, ustiga yozmaslik; backup qilish)
# -----------------------------------------------------------------------------
if [[ -f "${CONF_DST}" ]]; then
    BACKUP="${CONF_DST}.bak.$(date +%Y%m%d-%H%M%S)"
    warn "Config allaqachon mavjud: ${CONF_DST}"
    log  "Backup yaratilmoqda: ${BACKUP}"
    run "cp -a ${CONF_DST} ${BACKUP}"
    log "Mavjud config saqlab qolindi; yangi config o'rnatilmadi."
else
    log "Config o'rnatilmoqda: ${CONF_DST}"
    run "install -m 0640 -o ${TAA_USER} -g ${TAA_GROUP} ${CONF_SRC} ${CONF_DST}"
fi

# -----------------------------------------------------------------------------
# 5) systemd unit
# -----------------------------------------------------------------------------
log "Systemd unit o'rnatilmoqda: ${UNIT_DST}"
run "install -m 0644 -o root -g root ${UNIT_SRC} ${UNIT_DST}"
run "systemctl daemon-reload"
run "systemctl enable taa-agent2"

# -----------------------------------------------------------------------------
# 6) Firewall (UFW)
# -----------------------------------------------------------------------------
if command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -qi "Status: active"; then
        log "UFW faol — 10050/tcp ochilmoqda"
        run "ufw allow 10050/tcp comment 'TAA agent'"
    else
        log "UFW o'rnatilgan, lekin faol emas — port qoidasi qo'shilmadi"
    fi
else
    log "UFW topilmadi — firewall sozlash o'tkazib yuborildi"
fi

# -----------------------------------------------------------------------------
# 7) SELinux (RHEL/CentOS muhitlarida foydali; Ubuntu'da odatda Disabled)
# -----------------------------------------------------------------------------
if command -v getenforce >/dev/null 2>&1; then
    SE_STATE="$(getenforce 2>/dev/null || echo Disabled)"
    if [[ "${SE_STATE}" == "Enforcing" ]]; then
        log "SELinux Enforcing — 10050/tcp porti uchun siyosat qo'shilmoqda"
        if command -v semanage >/dev/null 2>&1; then
            run "semanage port -a -t zabbix_agent_port_t -p tcp 10050 || true"
        else
            warn "semanage topilmadi — SELinux port siyosatini qo'lda qo'shing"
        fi
    else
        log "SELinux holati: ${SE_STATE} — siyosat o'zgartirilmadi"
    fi
fi

# -----------------------------------------------------------------------------
# Yakuniy xabar
# -----------------------------------------------------------------------------
log "==============================================================="
log "TAA Agent 2 o'rnatildi (yoki yangilandi)."
log "Boshlash:        sudo systemctl start taa-agent2"
log "Holatni ko'rish: systemctl status taa-agent2"
log "Loglar:          journalctl -u taa-agent2 -f"
log "                 tail -f /var/log/taa/agent/taa_agent2.log"
log "Config:          ${CONF_DST}"
log "==============================================================="
