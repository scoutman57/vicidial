#!/usr/bin/perl

# AST_SERVER_conf.pl

# Customized Variables
$server_ip = '10.0.0.2';		# Asterisk server IP
$telnet_host = 'localhost';		# Asterisk server address to connect to
$ASTmgrUSERNAME = 'cron';		# Asterisk Manager interface username
$ASTmgrSECRET = 'test';			# Asterisk Manager interface secret
$DB_server = '10.0.0.10';		# MySQL server IP
$DB_database = 'asterisk';		# MySQL database name
$DB_user = 'cron';			# MySQL user
$DB_pass = 'test';			# MySQL pass
$LOGfile = '/home/cron/LOG_AST_update.log';
$telnetlog = '/home/cron/telnetlog.log';
$MSLOGfile = '/home/cron/MSLOG_AST_update.log';
$MStelnetlog = '/home/cron/MStelnetlog.log';
$LILOGfile = '/home/cron/LILOG_AST_update.log';
$LItelnetlog = '/home/cron/LItelnetlog.log';

return 1;