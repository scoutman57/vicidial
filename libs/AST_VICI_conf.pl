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
$recording_exten = '8309';
$ext_context = 'demo';
$dtmf_send_extension = 'local/8500998@demo';
$call_out_number_group ='Zap/g2/';

### Optional Variables
$AGI_call_logging_enabled = 1;	# Asterisk uses AGI call logging
$user_switching_enabled = 1;	# allow user to switch identities
$conferencing_enabled = 1;		# allow conferenging of up to 6 Zap lines
$admin_hangup_enabled = 1;		# allow force hangup of Zap and SIP
$admin_monitor_enabled = 1;		# allow monitoring of Zap channels
$call_parking_enabled = 1;		# use GUI call parking
$updater_check_enabled = 1;		# popup message is SQL updater goes down
$AFLogging_enabled = 1;			# ADVANCED FILE LOGGING on or off
$QUEUE_ACTION_enabled = 1;		# USE Asterisk Action Queue system 
								# instead of direct Manager connection

return 1;