<?php
// Zabbix GUI configuration file.
global $DB;

$DB['TYPE']     = 'POSTGRESQL';
$DB['SERVER']   = 'postgres';
$DB['PORT']     = '5432';
$DB['DATABASE'] = 'zabbix';
$DB['USER']     = 'zabbix';
$DB['PASSWORD'] = 'zabbix_password';

// Schema name. Used for PostgreSQL.
$DB['SCHEMA'] = '';

$ZBX_SERVER      = 'zabbix-server';
$ZBX_SERVER_PORT = '10051';
$ZBX_SERVER_NAME = 'TAA Monitoring';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
