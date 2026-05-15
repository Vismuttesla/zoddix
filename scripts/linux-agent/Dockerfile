# =============================================================================
# TAA Agent 2 — Linux (Alpine) uchun multi-stage Docker image
# -----------------------------------------------------------------------------
# Stage 1 (builder): Go yordamida statik binar yig'ish.
# Stage 2 (runtime): minimal alpine image ichida taa-agent foydalanuvchi ostida
#                    binar va configni joylab ishga tushirish.
# Build:   docker build -t taa/agent2:linux-latest -f scripts/linux-agent/Dockerfile .
# Run:     docker run --rm -p 10050:10050 taa/agent2:linux-latest
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: builder
# -----------------------------------------------------------------------------
FROM golang:1.22-alpine AS builder

# Build muhitiga kerakli paketlar (git — versiya uchun, ca-certificates — HTTPS)
RUN apk add --no-cache git ca-certificates build-base

WORKDIR /src

# Go modullarini avval ko'chirish (cache'dan foydalanish uchun)
COPY src/go/go.mod src/go/go.sum ./
RUN go mod download

# Qolgan manba kodi
COPY src/go/ ./

# Statik build (CGO_ENABLED=0), Linux/amd64; arxitekturani build-arg orqali o'zgartirish mumkin
ARG TARGETARCH=amd64
ARG GIT_COMMIT=unknown
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=${TARGETARCH}

RUN go build -trimpath \
        -ldflags "-s -w -X main.GitCommit=${GIT_COMMIT}" \
        -o /out/taa_agent2 \
        ./cmd/zabbix_agent2

# -----------------------------------------------------------------------------
# Stage 2: runtime
# -----------------------------------------------------------------------------
FROM alpine:3.19 AS runtime

# OCI labellar — image metadatasi
LABEL org.opencontainers.image.title="TAA Agent 2 (Linux)" \
      org.opencontainers.image.description="TAA monitoring agent (Linux) — TAA-brandlangan Zabbix Agent 2 forki" \
      org.opencontainers.image.vendor="TAA" \
      org.opencontainers.image.source="https://taa.local" \
      org.opencontainers.image.licenses="GPL-2.0"

# Runtime uchun minimal paketlar (CA root, vaqt zonalari, healthcheck uchun)
RUN apk add --no-cache ca-certificates tzdata \
 && addgroup -S taa-agent \
 && adduser -S -G taa-agent -H -s /sbin/nologin taa-agent \
 && mkdir -p /etc/taa/agent/taa_agent2.d \
             /var/log/taa/agent \
             /var/run/taa/agent \
             /var/lib/taa/agent \
 && chown -R taa-agent:taa-agent /etc/taa /var/log/taa /var/run/taa /var/lib/taa \
 && chmod 0750 /etc/taa/agent /var/log/taa/agent /var/run/taa/agent /var/lib/taa/agent

# Binar va config
COPY --from=builder /out/taa_agent2 /usr/sbin/taa_agent2
COPY scripts/linux-agent/taa_agent2.conf /etc/taa/agent/taa_agent2.conf

RUN chmod 0755 /usr/sbin/taa_agent2 \
 && chmod 0640 /etc/taa/agent/taa_agent2.conf \
 && chown root:root /usr/sbin/taa_agent2 \
 && chown taa-agent:taa-agent /etc/taa/agent/taa_agent2.conf

# Passiv tinglash porti
EXPOSE 10050

# Konteyner ichida root bo'lmagan foydalanuvchi
USER taa-agent

# Soddagina sog'liq tekshiruvi: agentdan o'ziga ping kalitini so'rash
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/sbin/taa_agent2 -t agent.ping -c /etc/taa/agent/taa_agent2.conf >/dev/null 2>&1 || exit 1

# Foreground rejimda ishga tushirish (systemd o'rniga konteyner PID 1)
ENTRYPOINT ["/usr/sbin/taa_agent2", "-f", "-c", "/etc/taa/agent/taa_agent2.conf"]
