-- =============================================================================
-- TAA — IPAM va audit jurnali (PostgreSQL schemasi)
-- -----------------------------------------------------------------------------
-- Bu schema ip_inventory.py, auto_remediation.py va stp_loop_parser.py
-- skriptlari uchun mo'ljallangan. DB: taa_ipam (yoki o'zgartirilgan nom).
--
-- Yaratish:
--   psql -U taa -d taa_ipam -f scripts/sql/ipam_schema.sql
--
-- Eslatma: barcha vaqt qiymatlari UTC da saqlanadi (TIMESTAMPTZ).
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) leases — DHCP snooping va MAC jadvalidan to'plangan binding ma'lumotlari
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS leases (
    mac         TEXT        NOT NULL PRIMARY KEY,
    ip          INET,
    vlan        INTEGER,
    port        TEXT,
    switch_ip   INET,
    first_seen  TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  leases               IS 'DHCP snooping + MAC jadvalidan to''plangan IP/MAC/port binding (TAA IPAM uchun)';
COMMENT ON COLUMN leases.mac           IS 'Qurilma MAC manzili (kichik harf, ":" yoki "." ajratuvchili) — birlamchi kalit';
COMMENT ON COLUMN leases.ip            IS 'Qurilmaga biriktirilgan IPv4/IPv6 manzili';
COMMENT ON COLUMN leases.vlan          IS 'VLAN ID (1..4094)';
COMMENT ON COLUMN leases.port          IS 'Switch port nomi (masalan: GigabitEthernet0/5)';
COMMENT ON COLUMN leases.switch_ip     IS 'Manba switch boshqaruv IP manzili';
COMMENT ON COLUMN leases.first_seen    IS 'Birinchi marta ko''rilgan vaqt (UTC)';
COMMENT ON COLUMN leases.last_seen     IS 'Oxirgi marta ko''rilgan vaqt (UPSERT da yangilanadi)';

CREATE INDEX IF NOT EXISTS idx_leases_ip            ON leases (ip);
CREATE INDEX IF NOT EXISTS idx_leases_switch_port   ON leases (switch_ip, port);

-- -----------------------------------------------------------------------------
-- 2) port_security_events — 3560G dan kelgan port-security violation hodisalari
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS port_security_events (
    id              SERIAL      PRIMARY KEY,
    ts              TIMESTAMPTZ NOT NULL DEFAULT now(),
    switch_ip       INET        NOT NULL,
    port            TEXT        NOT NULL,
    mac             TEXT,
    violation_type  TEXT,
    action_taken    TEXT
);

COMMENT ON TABLE  port_security_events                IS 'Port-security violation hodisalari (P2 muammosi: ruxsatsiz ulanish, scan, brute force)';
COMMENT ON COLUMN port_security_events.id             IS 'Avtomatik o''sadigan birlamchi kalit';
COMMENT ON COLUMN port_security_events.ts             IS 'Hodisa vaqti (UTC)';
COMMENT ON COLUMN port_security_events.switch_ip      IS 'Hodisa sodir bo''lgan switch boshqaruv IP manzili';
COMMENT ON COLUMN port_security_events.port           IS 'Switch porti (masalan: Gi0/5)';
COMMENT ON COLUMN port_security_events.mac            IS 'Buzg''unchi (yoki kutilmagan) MAC manzili';
COMMENT ON COLUMN port_security_events.violation_type IS 'Violation turi: shutdown / restrict / protect';
COMMENT ON COLUMN port_security_events.action_taken   IS 'Avtomatik bajarilgan harakat: shutdown, log, alert, none';

CREATE INDEX IF NOT EXISTS idx_psec_ts ON port_security_events (ts);

-- -----------------------------------------------------------------------------
-- 3) stp_events — STP loop / BPDU guard / topology change hodisalari
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stp_events (
    id           SERIAL      PRIMARY KEY,
    ts           TIMESTAMPTZ NOT NULL DEFAULT now(),
    switch_ip    INET        NOT NULL,
    port         TEXT,
    vlan         INTEGER,
    mac          TEXT,
    severity     TEXT,
    raw_message  TEXT
);

COMMENT ON TABLE  stp_events             IS 'STP halqa va topologiya o''zgarishi hodisalari (P3 muammosi: qaerda, qaysi VLAN, qaysi port, qaysi MAC)';
COMMENT ON COLUMN stp_events.id          IS 'Avtomatik o''sadigan birlamchi kalit';
COMMENT ON COLUMN stp_events.ts          IS 'Hodisa vaqti (UTC)';
COMMENT ON COLUMN stp_events.switch_ip   IS 'Hodisa sodir bo''lgan switch boshqaruv IP manzili';
COMMENT ON COLUMN stp_events.port        IS 'Hodisa sodir bo''lgan port';
COMMENT ON COLUMN stp_events.vlan        IS 'VLAN ID (agar topilgan bo''lsa)';
COMMENT ON COLUMN stp_events.mac         IS 'Manba MAC manzili (agar topilgan bo''lsa)';
COMMENT ON COLUMN stp_events.severity    IS 'Og''irlik darajasi: info / warning / critical / emergency';
COMMENT ON COLUMN stp_events.raw_message IS 'Asl syslog/snmp-trap matni (parser uchun arxiv)';

CREATE INDEX IF NOT EXISTS idx_stp_ts ON stp_events (ts);

-- -----------------------------------------------------------------------------
-- 4) hosts_inventory — qo'lda kiritiladigan IP/MAC/foydalanuvchi jadvali (P5)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS hosts_inventory (
    id        SERIAL      PRIMARY KEY,
    hostname  TEXT,
    ip        INET        NOT NULL UNIQUE,
    mac       TEXT,
    location  TEXT,
    owner     TEXT,
    contact   TEXT,
    added_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  hosts_inventory          IS 'Qo''lda kiritilgan IP manzil jurnali — Excel o''rnida (P5 muammosi)';
COMMENT ON COLUMN hosts_inventory.id       IS 'Avtomatik o''sadigan birlamchi kalit';
COMMENT ON COLUMN hosts_inventory.hostname IS 'Host nomi (FQDN yoki qisqa)';
COMMENT ON COLUMN hosts_inventory.ip       IS 'IP manzili — UNIQUE';
COMMENT ON COLUMN hosts_inventory.mac      IS 'MAC manzili (ixtiyoriy)';
COMMENT ON COLUMN hosts_inventory.location IS 'Joylashuvi (xona, qavat, kabinet)';
COMMENT ON COLUMN hosts_inventory.owner    IS 'Qurilma egasi (F.I.O. yoki bo''lim)';
COMMENT ON COLUMN hosts_inventory.contact  IS 'Bog''lanish ma''lumoti (telefon, email)';
COMMENT ON COLUMN hosts_inventory.added_at IS 'Yozuv qo''shilgan vaqt (UTC)';

-- -----------------------------------------------------------------------------
-- 5) v_active_leases — oxirgi 7 kun ichida ko'ringan leaselar (dashboard uchun)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_active_leases AS
SELECT
    l.mac,
    l.ip,
    l.vlan,
    l.port,
    l.switch_ip,
    l.first_seen,
    l.last_seen,
    h.hostname,
    h.owner,
    h.location
FROM leases l
LEFT JOIN hosts_inventory h ON h.ip = l.ip
WHERE l.last_seen >= (now() - INTERVAL '7 days');

COMMENT ON VIEW v_active_leases IS 'Oxirgi 7 kun ichida faol bo''lgan IP/MAC leaselar (TAA dashboard uchun)';

COMMIT;
