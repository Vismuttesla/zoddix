#!/usr/bin/env bash
# =============================================================================
# TAA Agent 2 — Linux uchun kross-kompilyatsiya skripti
# -----------------------------------------------------------------------------
# Maqsad: Windows yoki Linux hostda Go yordamida `taa_agent2` Linux binarini
#         (amd64 yoki arm64) yig'ish.
# Foydalanish:
#   ./build.sh                         # default: amd64, dist/taa_agent2
#   ./build.sh --arch arm64            # ARM64 uchun
#   ./build.sh --static                # CGO_ENABLED=0 (statik bog'lanish)
#   ./build.sh --out /tmp/taa_agent2   # boshqa chiqish yo'li
# =============================================================================

set -euo pipefail

# --- Default parametrlar ---
ARCH="amd64"
OUT=""
STATIC="0"

# --- Skript joylashgan papkani aniqlash (loyiha ildiziga o'tish uchun) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GO_SRC_DIR="${PROJECT_ROOT}/src/go"
CMD_PKG="./cmd/zabbix_agent2"

# --- Log funksiyalari (sodda, rangsiz, log faylga ham mos) ---
log()  { printf '[build.sh] %s\n' "$*"; }
err()  { printf '[build.sh][XATO] %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

# --- Argumentlarni o'qish ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --arch)
            [[ $# -ge 2 ]] || die "--arch uchun qiymat kerak (amd64|arm64)"
            ARCH="$2"
            shift 2
            ;;
        --out)
            [[ $# -ge 2 ]] || die "--out uchun yo'l kerak"
            OUT="$2"
            shift 2
            ;;
        --static)
            STATIC="1"
            shift
            ;;
        -h|--help)
            grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            die "Noma'lum argument: $1"
            ;;
    esac
done

# --- Arxitekturani tekshirish ---
case "${ARCH}" in
    amd64|arm64) ;;
    *) die "Qo'llab-quvvatlanmaydigan arxitektura: ${ARCH} (faqat amd64|arm64)" ;;
esac

# --- Default chiqish yo'li ---
if [[ -z "${OUT}" ]]; then
    OUT="${SCRIPT_DIR}/dist/taa_agent2"
fi

# --- Boshlang'ich tekshirishlar ---
command -v go >/dev/null 2>&1 || die "Go topilmadi: avval Go o'rnating (>=1.20)"
[[ -d "${GO_SRC_DIR}" ]] || die "Go manba papkasi topilmadi: ${GO_SRC_DIR}"

OUT_DIR="$(dirname "${OUT}")"
mkdir -p "${OUT_DIR}"

# --- Git commit (agar mavjud bo'lsa) — versiyalashga foydali ---
GIT_COMMIT="unknown"
if command -v git >/dev/null 2>&1 && git -C "${PROJECT_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
    GIT_COMMIT="$(git -C "${PROJECT_ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

# --- LDFLAGS: hajmni qisqartirish (-s -w) + GitCommit (agar mos o'zgaruvchi bo'lsa) ---
LDFLAGS="-s -w"
# Eslatma: main.GitCommit o'zgaruvchisi mavjud bo'lmasa, Go bu flagni jimgina e'tiborsiz qoldiradi.
LDFLAGS="${LDFLAGS} -X main.GitCommit=${GIT_COMMIT}"

# --- Build muhitini sozlash ---
export GOOS="linux"
export GOARCH="${ARCH}"
if [[ "${STATIC}" == "1" ]]; then
    export CGO_ENABLED=0
    log "Statik build yoqildi (CGO_ENABLED=0)"
else
    # Saqlab qolish: foydalanuvchi muhitidagi qiymat (yoki default)
    export CGO_ENABLED="${CGO_ENABLED:-1}"
fi

log "Loyiha ildizi : ${PROJECT_ROOT}"
log "Go manbalari  : ${GO_SRC_DIR}"
log "Maqsad        : GOOS=${GOOS} GOARCH=${GOARCH} CGO_ENABLED=${CGO_ENABLED}"
log "Git commit    : ${GIT_COMMIT}"
log "Chiqish fayli : ${OUT}"

# --- Modullarni yuklash ---
log "go mod download bajarilmoqda..."
( cd "${GO_SRC_DIR}" && go mod download )

# --- Kompilyatsiya ---
log "go build boshlandi..."
( cd "${GO_SRC_DIR}" && go build -trimpath -ldflags "${LDFLAGS}" -o "${OUT}" "${CMD_PKG}" )

[[ -f "${OUT}" ]] || die "Build muvaffaqiyatsiz: ${OUT} topilmadi"

# --- Hajm va sha256 ---
SIZE_BYTES="$(wc -c < "${OUT}" | tr -d ' ')"
SIZE_HUMAN="$(awk -v b="${SIZE_BYTES}" 'BEGIN{ split("B KB MB GB",u); i=1; while(b>=1024 && i<4){b/=1024; i++} printf "%.2f %s", b, u[i] }')"

SHA256=""
if command -v sha256sum >/dev/null 2>&1; then
    SHA256="$(sha256sum "${OUT}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
    SHA256="$(shasum -a 256 "${OUT}" | awk '{print $1}')"
elif command -v certutil >/dev/null 2>&1; then
    # Windows (Git Bash) muhitida zaxira variant
    SHA256="$(certutil -hashfile "${OUT}" SHA256 | sed -n '2p' | tr -d ' \r\n')"
fi

if [[ -n "${SHA256}" ]]; then
    printf '%s  %s\n' "${SHA256}" "$(basename "${OUT}")" > "${OUT}.sha256"
    log "SHA256        : ${SHA256}"
    log "Sha256 fayl   : ${OUT}.sha256"
else
    log "OGOHLANTIRISH: sha256sum/shasum topilmadi, .sha256 yaratilmadi"
fi

log "Hajm          : ${SIZE_HUMAN} (${SIZE_BYTES} bayt)"
log "Build tugadi."
