#!/usr/bin/perl

# AST_SERVER_conf.pl
# Some lines are commented out because they are now depricated

# Customized Variables
$server_ip = '10.10.10.15';		# Asterisk server IP
$DB_server = 'localhost';		# MySQL server IP
$DB_database = 'asterisk';		# MySQL database name
$DB_user = 'cron';			# MySQL user
$DB_pass = '1234';			# MySQL pass
$DB_port = '3306';			# MySQL connection port

$LOGfile = '/home/cron/LOG_AST_update.log';
$telnetlog = '/home/cron/telnetlog.log';
$MSLOGfile = '/home/cron/MSLOG_AST_update.log';
$MStelnetlog = '/home/cron/MStelnetlog.log';
$LILOGfile = '/home/cron/LILOG_AST_update.log';
$LItelnetlog = '/home/cron/LItelnetlog.log';
$KHLOGfile = '/home/cron/KHLOG_AST_update.log';
$VDADLOGfile = '/home/cron/VDLOG_AST_update.log';

#$telnet_host = 'localhost';	# Asterisk server address to connect to
#$telnet_port = '5038';			# Asterisk Manager port to connect to
#$ASTmgrUSERNAME = 'cron';		# Asterisk Manager interface username
#$ASTmgrSECRET = '1234';		# Asterisk Manager interface secret
#$ASTmgrUSERNAMEupdate = 'updatecron';	# specific login for update script
#$ASTmgrUSERNAMElisten = 'listencron';	# specific login for listen script
#$ASTmgrUSERNAMEsend = 'sendcron';		# specific login for send script
#$voicemail_dump_exten = '85026666666666'; # used for direct voicemail transfers
#$answer_transfer_agent = '8365';	# number dialed on Local Asterisk server that distributes auto_dial calls when they are answered
#$SERVER_GMT = '-5';			# local server GMT offset, DO NOT ADJUST FOR DST(Daylight Saving Time)!
#$AST_ver = '1.0.8';	# Asterisk server version (1.0.3, 1.0.7, 1.0.8, CVS, ...)
#$max_vicidial_trunks = '96';	# maximum number of outbound calls for VICIDIAL auto on this server
#$ext_context = 'default';		# context for Local extensions


return 1;
