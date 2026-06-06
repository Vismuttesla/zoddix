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
UPDATE usrgrp SET name = CASE name
	WHEN 'Zabbix administrators' THEN 'TAA administratorlari'
	WHEN 'TAA administrators' THEN 'TAA administratorlari'
	WHEN 'Guests' THEN 'Mehmonlar'
	WHEN 'Disabled' THEN 'O''chirilgan'
	WHEN 'Enabled debug mode' THEN 'Nosozliklarni tuzatish rejimi yoqilgan'
	WHEN 'No access to the frontend' THEN 'Frontendga kirish yo''q'
	WHEN 'Internal' THEN 'Ichki'
	ELSE name
  END
  WHERE name IN (
	'Zabbix administrators', 'TAA administrators', 'Guests', 'Disabled',
	'Enabled debug mode', 'No access to the frontend', 'Internal'
  );

UPDATE users SET name = 'TAA',
                 surname = 'Administratori'
  WHERE username = 'Admin' AND name = 'Zabbix' AND surname = 'Administrator';

UPDATE role SET name = CASE name
	WHEN 'User role' THEN 'Foydalanuvchi roli'
	WHEN 'Admin role' THEN 'Administrator roli'
	WHEN 'Super admin role' THEN 'Super administrator roli'
	WHEN 'Guest role' THEN 'Mehmon roli'
	ELSE name
  END
  WHERE name IN ('User role', 'Admin role', 'Super admin role', 'Guest role');

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

-- Template nomlari: "Name by SNMP" -> "Name (SNMP orqali)".
UPDATE hosts SET name = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name,
		' by Zabbix agent 2 active', ' (TAA agent 2 aktiv orqali)'),
		' by Zabbix agent active', ' (TAA agent aktiv orqali)'),
		' by Zabbix agent 2', ' (TAA agent 2 orqali)'),
		' by Zabbix agent', ' (TAA agent orqali)'),
		' by Browser', ' (Brauzer orqali)'),
		' by HTTP', ' (HTTP orqali)'),
		' by SNMP', ' (SNMP orqali)'),
		' by JMX', ' (JMX orqali)'),
		' by IPMI', ' (IPMI orqali)'),
		' by ODBC', ' (ODBC orqali)'),
		' by Prom', ' (Prom orqali)')
  WHERE status = 3 AND name LIKE '% by %';

UPDATE hosts SET name_upper = upper(name)
  WHERE status = 3;

UPDATE hosts SET host = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(host,
		' by Zabbix agent 2 active', ' (TAA agent 2 aktiv orqali)'),
		' by Zabbix agent active', ' (TAA agent aktiv orqali)'),
		' by Zabbix agent 2', ' (TAA agent 2 orqali)'),
		' by Zabbix agent', ' (TAA agent orqali)'),
		'Remote Zabbix server health', 'Masofadagi TAA server holati'),
		'Remote Zabbix proxy health', 'Masofadagi TAA proksi holati'),
		'Zabbix server health', 'TAA server holati'),
		'Zabbix proxy health', 'TAA proksi holati')
  WHERE status = 3 AND host LIKE '%Zabbix%';

UPDATE hosts SET host = 'TAA agent'
  WHERE status = 3 AND host = 'Zabbix agent';

UPDATE hosts SET host = 'TAA agent aktiv'
  WHERE status = 3 AND host = 'Zabbix agent active';

-- Suffix almashtirilgandan keyin qolishi mumkin bo'lgan health/agent nomlari.
UPDATE hosts SET name = REPLACE(REPLACE(REPLACE(REPLACE(name,
		'Remote Zabbix server health', 'Masofadagi TAA server holati'),
		'Remote Zabbix proxy health', 'Masofadagi TAA proksi holati'),
		'Zabbix server health', 'TAA server holati'),
		'Zabbix proxy health', 'TAA proksi holati')
  WHERE status = 3 AND name LIKE '%Zabbix%';

UPDATE hosts SET name = 'TAA agent'
  WHERE status = 3 AND name = 'Zabbix agent';

UPDATE hosts SET name = 'TAA agent aktiv'
  WHERE status = 3 AND name = 'Zabbix agent active';

UPDATE hosts SET name_upper = upper(name)
  WHERE status = 3;

-- Standalone agent templatelar
UPDATE hosts SET name = 'TAA agent aktiv',
                 name_upper = 'TAA AGENT AKTIV'
  WHERE name = 'Zabbix agent active' AND status = 3;

UPDATE hosts SET name = 'TAA agent',
                 name_upper = 'TAA AGENT'
  WHERE name = 'Zabbix agent' AND status = 3;

-- Template vendor metadata.
UPDATE hosts SET vendor_name = 'TAA'
  WHERE status = 3 AND vendor_name = 'Zabbix';

-- ============================================================
-- 5. TEMPLATE TAGS
-- ============================================================
UPDATE host_tag SET value = CASE lower(value)
    WHEN 'zabbix' THEN 'taa'
    WHEN 'zabbix-agent' THEN 'taa-agent'
    ELSE value
  END
  WHERE lower(tag) = 'target' AND lower(value) IN ('zabbix', 'zabbix-agent');

UPDATE event_tag SET value = 'taa'
  WHERE lower(tag) = 'target' AND lower(value) = 'zabbix';

UPDATE problem_tag SET value = 'taa'
  WHERE lower(tag) = 'target' AND lower(value) = 'zabbix';

-- ============================================================
-- 6. TRIGGERS — foydalanuvchiga ko'rinadigan xabarlar
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
-- 7. ITEMS — display nomlari
-- ============================================================
UPDATE items SET name = REPLACE(name, 'Zabbix server', 'TAA server')
  WHERE name LIKE 'Zabbix server%' AND flags IN (0, 4);

UPDATE items SET name = REPLACE(name, 'Zabbix proxy', 'TAA proksi')
  WHERE name LIKE 'Zabbix proxy%' AND flags IN (0, 4);

UPDATE items SET name = REPLACE(name, 'Zabbix agent', 'TAA agent')
  WHERE name LIKE 'Zabbix agent%' AND flags IN (0, 4);

-- ============================================================
-- 8. HOST GROUPS — guruh nomlari
-- ============================================================
UPDATE hstgrp SET name = CASE name
	WHEN 'Templates' THEN 'Shablonlar'
	WHEN 'Linux servers' THEN 'Linux serverlari'
	WHEN 'Zabbix servers' THEN 'TAA serverlari'
	WHEN 'Discovered hosts' THEN 'Aniqlangan hostlar'
	WHEN 'Virtual machines' THEN 'Virtual mashinalar'
	WHEN 'Hypervisors' THEN 'Gipervizorlar'
	WHEN 'Templates/Network devices' THEN 'Shablonlar/Tarmoq qurilmalari'
	WHEN 'Templates/Operating systems' THEN 'Shablonlar/Operatsion tizimlar'
	WHEN 'Templates/Server hardware' THEN 'Shablonlar/Server uskunalari'
	WHEN 'Templates/Applications' THEN 'Shablonlar/Ilovalar'
	WHEN 'Templates/Databases' THEN 'Shablonlar/Ma''lumotlar bazalari'
	WHEN 'Templates/Virtualization' THEN 'Shablonlar/Virtualizatsiya'
	WHEN 'Templates/Telephony' THEN 'Shablonlar/Telefoniya'
	WHEN 'Templates/SAN' THEN 'Shablonlar/SAN'
	WHEN 'Templates/Video surveillance' THEN 'Shablonlar/Video kuzatuv'
	WHEN 'Templates/Power' THEN 'Shablonlar/Quvvat'
	WHEN 'Applications' THEN 'Ilovalar'
	WHEN 'Databases' THEN 'Ma''lumotlar bazalari'
	WHEN 'Templates/Cloud' THEN 'Shablonlar/Bulut'
	ELSE name
  END
  WHERE name IN (
	'Templates', 'Linux servers', 'Zabbix servers', 'Discovered hosts', 'Virtual machines', 'Hypervisors',
	'Templates/Network devices', 'Templates/Operating systems', 'Templates/Server hardware',
	'Templates/Applications', 'Templates/Databases', 'Templates/Virtualization', 'Templates/Telephony',
	'Templates/SAN', 'Templates/Video surveillance', 'Templates/Power', 'Applications', 'Databases',
	'Templates/Cloud'
  );

-- ============================================================
-- 9. TEMPLATE DESCRIPTIONS — tavsiflar
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
-- 10. MEDIA TYPES — bildirishnoma nomlari
-- ============================================================
UPDATE media_type SET name = REPLACE(name, 'Zabbix', 'TAA')
  WHERE name LIKE '%Zabbix%';

-- ============================================================
-- 11. FINAL DISPLAY TEXT CLEANUP
--    Internal {$ZABBIX.*} macros and zabbix.com URLs are intentionally
--    not modified by these case-sensitive replacements.
-- ============================================================
UPDATE dashboard SET name = REPLACE(name, 'Zabbix', 'TAA')
  WHERE name LIKE '%Zabbix%';

UPDATE actions SET name = REPLACE(name, 'Zabbix', 'TAA')
  WHERE name LIKE '%Zabbix%';

UPDATE usrgrp SET name = REPLACE(name, 'Zabbix', 'TAA')
  WHERE name LIKE '%Zabbix%';

UPDATE hosts SET description = REPLACE(description, 'Zabbix', 'TAA')
  WHERE description LIKE '%Zabbix%';

UPDATE hosts SET description = replace(replace(description, 'zbx_monitor', 'taa_monitor'), 'zbx_mon', 'taa_mon')
  WHERE description LIKE '%zbx%';

UPDATE items SET name = REPLACE(name, 'Zabbix', 'TAA')
  WHERE name LIKE '%Zabbix%';

UPDATE items SET description = REPLACE(description, 'Zabbix', 'TAA')
  WHERE description LIKE '%Zabbix%';

UPDATE triggers SET description = REPLACE(description, 'Zabbix', 'TAA')
  WHERE description LIKE '%Zabbix%';

UPDATE triggers SET event_name = REPLACE(event_name, 'Zabbix', 'TAA')
  WHERE event_name LIKE '%Zabbix%';

UPDATE valuemap_mapping SET newvalue = CASE newvalue
	WHEN 'Unknown' THEN 'Noma''lum'
	WHEN 'Up' THEN 'Ishlayapti'
	WHEN 'Down' THEN 'Ishlamayapti'
	WHEN 'Available' THEN 'Mavjud'
	WHEN 'Unavailable' THEN 'Mavjud emas'
	WHEN 'Not available' THEN 'Mavjud emas'
	WHEN 'Running' THEN 'Ishlamoqda'
	WHEN 'Stopped' THEN 'To''xtagan'
	WHEN 'Disabled' THEN 'O''chirilgan'
	WHEN 'Enabled' THEN 'Yoqilgan'
	WHEN 'Active' THEN 'Faol'
	WHEN 'Inactive' THEN 'Nofaol'
	ELSE newvalue
  END
  WHERE newvalue IN (
	'Unknown', 'Up', 'Down', 'Available', 'Unavailable', 'Not available',
	'Running', 'Stopped', 'Disabled', 'Enabled', 'Active', 'Inactive'
  );

-- Common default-template display phrases. Product/protocol names, item keys,
-- macros and URLs are intentionally left intact.
CREATE TEMP TABLE tmp_taa_display_phrase_map (
	source text PRIMARY KEY,
	target text NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_taa_display_phrase_map (source, target) VALUES
	('Local network', 'Mahalliy tarmoq'),
	('/etc/passwd has been changed', '/etc/passwd fayli o''zgartirildi'),
	(' on {HOST.NAME}', ' ({HOST.NAME} da)'),
	('Number of installed packages has been changed', 'O''rnatilgan paketlar soni o''zgartirildi'),
	('has been changed', 'o''zgartirildi'),
	('has changed', 'o''zgardi'),
	('has been restarted', 'qayta ishga tushirildi'),
	('has been replaced', 'almashtirildi'),
	('High ICMP ping response time', 'ICMP ping javob vaqti yuqori'),
	('High ICMP ping loss', 'ICMP ping yo''qotilishi yuqori'),
	('High bandwidth usage', 'Tarmoq o''tkazuvchanligidan foydalanish yuqori'),
	('High CPU utilization', 'CPU yuklanishi yuqori'),
	('High memory utilization', 'Xotira ishlatilishi yuqori'),
	('High swap space usage', 'Swap maydoni ishlatilishi yuqori'),
	('Lack of available memory', 'Mavjud xotira yetishmayapti'),
	('Load average is too high', 'O''rtacha yuklama juda yuqori'),
	('Running out of free inodes', 'Bo''sh inode''lar tugab bormoqda'),
	('Space is critically low', 'Bo''sh joy kritik darajada kam'),
	('Space is low', 'Bo''sh joy kam'),
	('Disk space is critically low', 'Disk bo''sh joyi kritik darajada kam'),
	('Disk space is low', 'Disk bo''sh joyi kam'),
	('Link down', 'Aloqa uzilgan'),
	('No SNMP data collection', 'SNMP ma''lumot yig''ish yo''q'),
	('Template does not match hardware', 'Shablon apparatga mos emas'),
	('Operating system description', 'Operatsion tizim tavsifi'),
	('System name', 'Tizim nomi'),
	('System description', 'Tizim tavsifi'),
	('System location', 'Tizim joylashuvi'),
	('System object ID', 'Tizim obyekt IDsi'),
	('System contact details', 'Tizim aloqa ma''lumotlari'),
	('Firmware', 'Mikrodastur'),
	('Device', 'Qurilma'),
	('Temperature is above critical threshold', 'Harorat kritik chegaradan yuqori'),
	('Temperature is above warning threshold', 'Harorat ogohlantirish chegarasidan yuqori'),
	('Temperature is too low', 'Harorat juda past'),
	('is above critical threshold', 'kritik chegaradan yuqori'),
	('is above warning threshold', 'ogohlantirish chegarasidan yuqori'),
	('is in critical state', 'kritik holatda'),
	('is not running', 'ishlamayapti'),
	('is on battery', 'batareyada ishlamoqda'),
	('Battery needs replacement', 'Batareyani almashtirish kerak'),
	('Battery has high temperature', 'Batareya harorati yuqori'),
	('Battery has low capacity', 'Batareya sig''imi past'),
	('Battery is Low', 'Batareya past'),
	('Output load is high', 'Chiqish yuklamasi yuqori'),
	('Unacceptable input voltage', 'Kirish kuchlanishi qabul qilinmaydi'),
	('Unacceptable phase', 'Faza qabul qilinmaydi'),
	('Sensor has status Critical', 'Sensor holati kritik'),
	('Sensor has status Warning', 'Sensor holati ogohlantirish'),
	('Sensor has status Not Applicable', 'Sensor holati qo''llanilmaydi'),
	('Mode', 'Rejim'),
	('Volume size', 'Tom hajmi'),
	('Quota', 'Kvota'),
	('limit', 'chegara'),
	('Leader', 'Yetakchi'),
	('Version', 'Versiya'),
	('Storage version', 'Saqlash versiyasi'),
	('Configuration', 'Konfiguratsiya'),
	('SNMP agent availability', 'SNMP agent mavjudligi'),
	('Hardware model name', 'Apparat modeli nomi'),
	('Hardware serial number', 'Apparat seriya raqami'),
	('ICMP loss', 'ICMP yo''qotilishi'),
	('ICMP response time', 'ICMP javob vaqti'),
	('Network interfaces discovery', 'Tarmoq interfeyslarini aniqlash'),
	('Network interface discovery', 'Tarmoq interfeysini aniqlash'),
	('Inbound packets discarded', 'Kiruvchi paketlar tashlab yuborildi'),
	('Outbound packets discarded', 'Chiquvchi paketlar tashlab yuborildi'),
	('Inbound packets with errors', 'Xatoli kiruvchi paketlar'),
	('Outbound packets with errors', 'Xatoli chiquvchi paketlar'),
	('Operational status', 'Ish holati'),
	('Bits sent', 'Yuborilgan bitlar'),
	('Bits received', 'Qabul qilingan bitlar'),
	('Interface type', 'Interfeys turi'),
	('Memory utilization', 'Xotira ishlatilishi'),
	('Operating system', 'Operatsion tizim'),
	('Total memory', 'Jami xotira'),
	('Used memory', 'Ishlatilgan xotira'),
	('Available memory', 'Mavjud xotira'),
	('CPU discovery', 'CPU aniqlash'),
	('CPU utilization', 'CPU yuklanishi'),
	('Storage discovery', 'Saqlash qurilmalarini aniqlash'),
	('Temperature sensor discovery', 'Harorat sensorlarini aniqlash'),
	('Temperature discovery', 'Haroratni aniqlash'),
	('SNMP walk mounted filesystems', 'Ulangan fayl tizimlarini SNMP walk qilish'),
	('SNMP walk network interfaces', 'Tarmoq interfeyslarini SNMP walk qilish'),
	('SNMP walk wireless interfaces', 'Simsiz interfeyslarni SNMP walk qilish'),
	('Mounted filesystem discovery', 'Ulangan fayl tizimlarini aniqlash'),
	('Physical disk discovery', 'Fizik disklarni aniqlash'),
	('Virtual disk discovery', 'Virtual disklarni aniqlash'),
	('Array controller discovery', 'Massiv kontrollerlarini aniqlash'),
	('Memory discovery', 'Xotirani aniqlash'),
	('Fan discovery', 'Ventilyatorlarni aniqlash'),
	('FAN Discovery', 'Ventilyatorlarni aniqlash'),
	('FAN discovery', 'Ventilyatorlarni aniqlash'),
	('PSU discovery', 'Quvvat bloklarini aniqlash'),
	('PSU Discovery', 'Quvvat bloklarini aniqlash'),
	('Overall system health status', 'Umumiy tizim salomatligi holati'),
	('Host name', 'Host nomi'),
	('Serial number', 'Seriya raqami'),
	('Get data', 'Ma''lumot olish'),
	('Uptime (hardware)', 'Ishlash vaqti (apparat)'),
	('Uptime (network)', 'Ishlash vaqti (tarmoq)'),
	('Uptime', 'Ishlash vaqti'),
	('Speed', 'Tezlik'),
	('Duplex status', 'Duplex holati'),
	('AP registered clients', 'AP ro''yxatdan o''tgan mijozlari'),
	('AP authenticated clients', 'AP autentifikatsiyadan o''tgan mijozlari'),
	('AP interface', 'AP interfeys'),
	('AP band', 'AP diapazoni'),
	('AP state', 'AP holati'),
	('AP noise floor', 'AP shovqin darajasi'),
	('AP channel discovery', 'AP kanalini aniqlash'),
	('AP channel', 'AP kanali'),
	('LTE modem discovery', 'LTE modemni aniqlash'),
	('Total space', 'Jami joy'),
	('Used space', 'Ishlatilgan joy'),
	('Space utilization', 'Joy ishlatilishi'),
	('Checksum of /etc/passwd', '/etc/passwd checksum qiymati'),
	('Template', 'Shablon'),
	('Overview', 'Umumiy ko''rinish'),
	('General', 'Umumiy'),
	('Network interfaces', 'Tarmoq interfeyslari'),
	('System performance', 'Tizim samaradorligi'),
	('performance', 'samaradorligi'),
	('overview', 'umumiy ko''rinish'),
	('databases', 'ma''lumotlar bazalari'),
	('database', 'ma''lumotlar bazasi'),
	('stat', 'statistika');

DO $$
DECLARE
	phrase record;
BEGIN
	FOR phrase IN SELECT source, target FROM tmp_taa_display_phrase_map LOOP
		UPDATE sysmaps SET name = replace(name, phrase.source, phrase.target)
			WHERE position(phrase.source in name) > 0;

		UPDATE triggers SET description = replace(description, phrase.source, phrase.target)
			WHERE position(phrase.source in description) > 0;

		UPDATE triggers SET event_name = replace(event_name, phrase.source, phrase.target)
			WHERE position(phrase.source in event_name) > 0;

		UPDATE items SET name = replace(name, phrase.source, phrase.target)
			WHERE position(phrase.source in name) > 0;

		UPDATE items SET description = replace(description, phrase.source, phrase.target)
			WHERE position(phrase.source in description) > 0;

		UPDATE dashboard SET name = replace(name, phrase.source, phrase.target)
			WHERE position(phrase.source in name) > 0;

	END LOOP;
END $$;

UPDATE valuemap_mapping SET newvalue = CASE newvalue
	WHEN 'unknown' THEN 'noma''lum'
	WHEN 'available' THEN 'mavjud'
	WHEN 'not available' THEN 'mavjud emas'
	WHEN 'up' THEN 'ishlayapti'
	WHEN 'down' THEN 'ishlamayapti'
	WHEN 'other' THEN 'boshqa'
	WHEN 'dormant' THEN 'kutish holatida'
	ELSE newvalue
  END
  WHERE newvalue IN ('unknown', 'available', 'not available', 'up', 'down', 'other', 'dormant');

-- ============================================================
-- 12. CONFIG — default_lang o'zbek tilida ekanligini tasdiqlash
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
