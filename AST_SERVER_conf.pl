#!/usr/bin/perl

# AST_SERVER_conf.pl

# Customized Variables
$server_ip = '10.10.10.15';		# Asterisk server IP
$telnet_host = 'localhost';		# Asterisk server address to connect to
$ASTmgrUSERNAME = 'cron';		# Asterisk Manager interface username
$ASTmgrSECRET = '1234';			# Asterisk Manager interface secret
$ASTmgrUSERNAMEupdate = 'updatecron';	# specific login for update script
$ASTmgrUSERNAMElisten = 'listencron';	# specific login for listen script
$ASTmgrUSERNAMEsend = 'sendcron';		# specific login for send script
$DB_server = 'localhost';		# MySQL server IP
$DB_database = 'asterisk';		# MySQL database name
$DB_user = 'cron';			# MySQL user
$DB_pass = '1234';			# MySQL pass
$DB_port = '3306';			# MySQL connection port
$voicemail_dump_exten = '85026666666666'; # used for direct voicemail transfers
$answer_transfer_agent = '8365';	# number dialed on Local Asterisk server that 
					# distributes auto_dial calls when they are answered
$SERVER_GMT = '-5';			# local server GMT offset, DO NOT ADJUST FOR DST(Daylight Saving Time)!

$ext_context = 'default';		# context for Local extensions
$LOGfile = '/home/cron/LOG_AST_update.log';
$telnetlog = '/home/cron/telnetlog.log';
$MSLOGfile = '/home/cron/MSLOG_AST_update.log';
$MStelnetlog = '/home/cron/MStelnetlog.log';
$LILOGfile = '/home/cron/LILOG_AST_update.log';
$LItelnetlog = '/home/cron/LItelnetlog.log';
$KHLOGfile = '/home/cron/KHLOG_AST_update.log';
$VDADLOGfile = '/home/cron/VDLOG_AST_update.log';

return 1;
