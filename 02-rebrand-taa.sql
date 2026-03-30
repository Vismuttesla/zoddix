-- ============================================================
-- TAA Rebranding SQL Script
-- Zabbix display nomlarini TAA ga o'zgartirish
-- FAQAT UI display nomlari o'zgartiriladi
-- Internal key, macro va DB owner TEGLANMAYDI
-- ============================================================

BEGIN;

-- ============================================================
-- 1. ACTIONS (Harakatlar)
-- ============================================================
UPDATE actions SET name = 'TAA administratorlariga muammolarni xabar qilish'
  WHERE name = 'Report problems to Zabbix administrators';

-- ============================================================
-- 2. USER GROUPS (Foydalanuvchi guruhlari)
-- ============================================================
UPDATE usrgrp SET name = 'TAA administratorlari'
  WHERE name = 'Zabbix administrators';

-- ============================================================
-- 3. DASHBOARDS (Boshqaruv panellari)
-- ============================================================
UPDATE dashboard SET name = 'TAA server holati'
  WHERE name = 'Zabbix server health';

UPDATE dashboard SET name = 'TAA proksi holati'
  WHERE name = 'Zabbix proxy health';

UPDATE dashboard SET name = 'TAA server'
  WHERE name = 'Zabbix server';

UPDATE dashboard SET name = 'TAA agent: Umumiy ko''rinish'
  WHERE name = 'Zabbix agent: Overview';

UPDATE dashboard SET name = 'TAA agent aktiv: Umumiy ko''rinish'
  WHERE name = 'Zabbix agent active: Overview';

UPDATE dashboard SET name = 'Masofadagi TAA server holati'
  WHERE name = 'Remote Zabbix server health';

UPDATE dashboard SET name = 'Masofadagi TAA proksi holati'
  WHERE name = 'Remote Zabbix proxy health';

-- ============================================================
-- 4. HOSTS / TEMPLATES — display nomlari (name ustuni)
-- ============================================================

-- Server va proxy health template nomlari
UPDATE hosts SET name = 'TAA server holati',
                 name_upper = 'TAA SERVER HOLATI'
  WHERE host = 'TAA serveri holati' OR name = 'Zabbix server health';

UPDATE hosts SET name = 'TAA proksi holati',
                 name_upper = 'TAA PROKSI HOLATI'
  WHERE name = 'Zabbix proxy health';

UPDATE hosts SET name = 'Masofadagi TAA server holati',
                 name_upper = 'MASOFADAGI TAA SERVER HOLATI'
  WHERE name = 'Remote Zabbix server health';

UPDATE hosts SET name = 'Masofadagi TAA proksi holati',
                 name_upper = 'MASOFADAGI TAA PROKSI HOLATI'
  WHERE name = 'Remote Zabbix proxy health';

-- Agent templatelar — "by Zabbix agent" → "TAA agent orqali"
UPDATE hosts SET name = REPLACE(name, 'by Zabbix agent active', 'TAA agent aktiv orqali'),
                 name_upper = REPLACE(name_upper, 'BY ZABBIX AGENT ACTIVE', 'TAA AGENT AKTIV ORQALI')
  WHERE name LIKE '%by Zabbix agent active%' AND status = 3;

UPDATE hosts SET name = REPLACE(name, 'by Zabbix agent', 'TAA agent orqali'),
                 name_upper = REPLACE(name_upper, 'BY ZABBIX AGENT', 'TAA AGENT ORQALI')
  WHERE name LIKE '%by Zabbix agent%' AND status = 3;

-- Standalone agent templatelar
UPDATE hosts SET name = 'TAA agent aktiv',
                 name_upper = 'TAA AGENT AKTIV'
  WHERE name = 'Zabbix agent active' AND status = 3;

UPDATE hosts SET name = 'TAA agent',
                 name_upper = 'TAA AGENT'
  WHERE name = 'Zabbix agent' AND status = 3;

-- ============================================================
-- 5. TRIGGERS — foydalanuvchiga ko'rinadigan xabarlar
-- ============================================================
UPDATE triggers SET description = REPLACE(description, 'Zabbix agent is not available', 'TAA agent mavjud emas')
  WHERE description LIKE '%Zabbix agent is not available%';

UPDATE triggers SET description = REPLACE(description, 'Zabbix server is not running', 'TAA server ishlamayapti')
  WHERE description LIKE '%Zabbix server is not running%';

UPDATE triggers SET description = REPLACE(description, 'Zabbix proxy is not running', 'TAA proksi ishlamayapti')
  WHERE description LIKE '%Zabbix proxy is not running%';

UPDATE triggers SET description = REPLACE(description, 'Zabbix value cache', 'TAA qiymat keshi')
  WHERE description LIKE '%Zabbix value cache%';

UPDATE triggers SET description = REPLACE(description, 'More than 100 items having missing data for more than 10 minutes', 'TAA: 10 daqiqadan ortiq ma''lumot yo''q — 100 dan ortiq element')
  WHERE description LIKE '%More than 100 items having missing data%';

-- event_name ichidagi Zabbix ham
UPDATE triggers SET event_name = REPLACE(event_name, 'Zabbix agent is not available', 'TAA agent mavjud emas')
  WHERE event_name LIKE '%Zabbix agent is not available%';

UPDATE triggers SET event_name = REPLACE(event_name, 'Zabbix server is not running', 'TAA server ishlamayapti')
  WHERE event_name LIKE '%Zabbix server is not running%';

UPDATE triggers SET event_name = REPLACE(event_name, 'Zabbix proxy is not running', 'TAA proksi ishlamayapti')
  WHERE event_name LIKE '%Zabbix proxy is not running%';

-- ============================================================
-- 6. ITEMS — display nomlari
-- ============================================================
UPDATE items SET name = REPLACE(name, 'Zabbix server', 'TAA server')
  WHERE name LIKE 'Zabbix server%' AND flags IN (0, 4);

UPDATE items SET name = REPLACE(name, 'Zabbix proxy', 'TAA proksi')
  WHERE name LIKE 'Zabbix proxy%' AND flags IN (0, 4);

UPDATE items SET name = REPLACE(name, 'Zabbix agent', 'TAA agent')
  WHERE name LIKE 'Zabbix agent%' AND flags IN (0, 4);

-- ============================================================
-- 7. HOST GROUPS — guruh nomlari
-- ============================================================
UPDATE hstgrp SET name = 'TAA serverlar'
  WHERE name = 'Zabbix servers';

-- ============================================================
-- 8. TEMPLATE DESCRIPTIONS — tavsiflar
--    Faqat "designed to monitor internal Zabbix" kabi UI text
-- ============================================================
UPDATE hosts SET description = REPLACE(description, 'internal Zabbix metrics', 'TAA ichki ko''rsatkichlari')
  WHERE description LIKE '%internal Zabbix metrics%' AND status = 3;

UPDATE hosts SET description = REPLACE(description, 'Zabbix server', 'TAA server')
  WHERE description LIKE '%Zabbix server%' AND status = 3;

UPDATE hosts SET description = REPLACE(description, 'Zabbix proxy', 'TAA proksi')
  WHERE description LIKE '%Zabbix proxy%' AND status = 3;

UPDATE hosts SET description = REPLACE(description, 'Zabbix agent', 'TAA agent')
  WHERE description LIKE '%Zabbix agent%' AND status = 3;

UPDATE hosts SET description = REPLACE(description, 'Zabbix bulk data', 'TAA to''plam ma''lumotlar')
  WHERE description LIKE '%Zabbix bulk data%' AND status = 3;

-- ============================================================
-- 9. MEDIA TYPES — bildirishnoma nomlari
-- ============================================================
UPDATE media_type SET name = REPLACE(name, 'Zabbix', 'TAA')
  WHERE name LIKE '%Zabbix%';

-- ============================================================
-- 10. CONFIG — default_lang o'zbek tilida ekanligini tasdiqlash
-- ============================================================
UPDATE config SET default_lang = 'uz_UZ'
  WHERE default_lang != 'uz_UZ';

COMMIT;

-- ============================================================
-- ESLATMA: Quyidagilar TEGLANMAGAN (xavfsizlik sabab):
--   - OWNER TO zabbix (DB user)
--   - {$ZABBIX.*} makrolar (backend hardcoded)
--   - zabbix_agent, zabbix_server (item key fragmentlar)
--   - Zabbix.log(), zabbixLogPrefix (JS preprocessing)
--   - timeout_zabbix_agent (DB column nomi)
-- ============================================================
