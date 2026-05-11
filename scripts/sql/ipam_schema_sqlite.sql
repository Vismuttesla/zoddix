-- =============================================================================
-- TAA — IPAM va audit jurnali (SQLite varianti)
-- -----------------------------------------------------------------------------
-- PostgreSQL schemaning SQLite versiyasi. Asosan DL-160 da yengilroq cron
-- skriptlar (auto_remediation.py audit jurnali) uchun ishlatiladi.
--
-- O'zgarishlar (Postgres -> SQLite):
--   - SERIAL              -> INTEGER PRIMARY KEY AUTOINCREMENT
--   - TIMESTAMPTZ/TIMESTAMP -> DATETIME (matn, ISO 8601 UTC)
--   - INET                -> TEXT
--   - COMMENT ON ...      -> "-- " inline izohlar (SQLite COMMENT'ni qo'llab-quvvatlamaydi)
--
-- Yaratish:
--   sqlite3 /var/lib/taa/audit.db < scripts/sql/ipam_schema_sqlite.sql
-- =============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

BEGIN TRANSACTION;

-- -----------------------------------------------------------------------------
-- 1) leases — DHCP snooping va MAC jadvalidan to'plangan binding
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS leases (
    mac         TEXT     NOT NULL PRIMARY KEY, -- MAC manzili (kichik harf), birlamchi kalit
    ip          TEXT,                          -- IP manzili (matn ko'rinishida saqlanadi)
    vlan        INTEGER,                       -- VLAN ID (1..4094)
    port        TEXT,                          -- Switch porti (masalan: Gi0/5)
    switch_ip   TEXT,                          -- Manba switch boshqaruv IP manzili
    first_seen  DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')), -- Birinchi ko'rilgan vaqt (UTC)
    last_seen   DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))  -- Oxirgi ko'rilgan vaqt (UPSERT da yangilanadi)
);

CREATE INDEX IF NOT EXISTS idx_leases_ip          ON leases (ip);
CREATE INDEX IF NOT EXISTS idx_leases_switch_port ON leases (switch_ip, port);

-- -----------------------------------------------------------------------------
-- 2) port_security_events — port-security violation hodisalari
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS port_security_events (
    id              INTEGER  PRIMARY KEY AUTOINCREMENT,                                  -- Avtomatik o'sadigan kalit
    ts              DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),    -- Hodisa vaqti (UTC)
    switch_ip       TEXT     NOT NULL,                                                   -- Hodisa sodir bo'lgan switch IP
    port            TEXT     NOT NULL,                                                   -- Switch porti
    mac             TEXT,                                                                -- Buzg'unchi MAC
    violation_type  TEXT,                                                                -- Violation turi: shutdown/restrict/protect
    action_taken    TEXT                                                                 -- Avtomatik harakat: shutdown/log/alert/none
);

CREATE INDEX IF NOT EXISTS idx_psec_ts ON port_security_events (ts);

-- -----------------------------------------------------------------------------
-- 3) stp_events — STP loop / BPDU guard / topology change hodisalari
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stp_events (
    id           INTEGER  PRIMARY KEY AUTOINCREMENT,                                  -- Avtomatik o'sadigan kalit
    ts           DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),    -- Hodisa vaqti (UTC)
    switch_ip    TEXT     NOT NULL,                                                   -- Hodisa sodir bo'lgan switch IP
    port         TEXT,                                                                -- Hodisa sodir bo'lgan port
    vlan         INTEGER,                                                             -- VLAN ID (agar topilgan bo'lsa)
    mac          TEXT,                                                                -- Manba MAC (agar topilgan bo'lsa)
    severity     TEXT,                                                                -- info/warning/critical/emergency
    raw_message  TEXT                                                                 -- Asl syslog/snmp-trap matni
);

CREATE INDEX IF NOT EXISTS idx_stp_ts ON stp_events (ts);

-- -----------------------------------------------------------------------------
-- 4) hosts_inventory — qo'lda kiritiladigan IP/MAC/foydalanuvchi jadvali (P5)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS hosts_inventory (
    id        INTEGER  PRIMARY KEY AUTOINCREMENT,                                  -- Avtomatik o'sadigan kalit
    hostname  TEXT,                                                                -- Host nomi (FQDN yoki qisqa)
    ip        TEXT     NOT NULL UNIQUE,                                            -- IP manzili — UNIQUE
    mac       TEXT,                                                                -- MAC (ixtiyoriy)
    location  TEXT,                                                                -- Joylashuvi (xona, qavat)
    owner     TEXT,                                                                -- Qurilma egasi (F.I.O./bo'lim)
    contact   TEXT,                                                                -- Bog'lanish (telefon/email)
    added_at  DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))     -- Yozuv qo'shilgan vaqt (UTC)
);

-- -----------------------------------------------------------------------------
-- 5) v_active_leases — oxirgi 7 kun ichida ko'ringan leaselar (dashboard uchun)
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_active_leases;
CREATE VIEW v_active_leases AS
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
WHERE l.last_seen >= datetime('now', '-7 days');

COMMIT;
