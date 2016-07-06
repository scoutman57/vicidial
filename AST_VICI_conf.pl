#!/usr/bin/perl

### Customized Variables
$SIP_user = 'SIP/test123';		# your phone id
$server_ip = '10.0.0.2';		# Asterisk server IP
$ASTmgrUSERNAME = 'cron';		# Asterisk Manager interface username
$ASTmgrSECRET = 'test';			# Asterisk Manager interface secret
$DB_server = '10.0.0.3';		# MySQL server IP
$DB_database = 'asterisk';		# MySQL database name
$DB_user = 'cron';				# MySQL user
$DB_pass = 'cron';				# MySQL pass

### Constants
$record_channel='';
$filename='';
$recording_id='';
$US = '_';
$MT[0] = '';
$park_on_extension = '8301';
$conf_on_extension = '8302';
$monitor_prefix = '8612';

### Optional Variables
$AGI_call_logging_enabled = 1;
$user_switching_enabled = 1;
$conferencing_enabled = 1;
$admin_hangup_enabled = 1;
$admin_monitor_enabled = 1;
$call_parking_enabled = 1;
$updater_check_enabled = 1;

return 1;