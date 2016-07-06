#!/usr/bin/perl
# ADMIN_restart_roll_logs.pl - script to roll the Asterisk logs on machine restart
# have this run on the astersik server 

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = ($year + 1900);
$mon++;
if ($mon < 10) {$mon = "0$mon";}
if ($mday < 10) {$mday = "0$mday";}
if ($hour < 10) {$Fhour = "0$hour";}
if ($min < 10) {$min = "0$min";}
if ($sec < 10) {$sec = "0$sec";}

$now_date_epoch = time();
$now_date = "$year-$mon-$mday---$hour$min$sec";


print "rolling AST_update log...\n";
`mv -f /home/cron/LOG_AST_update.log /home/cron/LOG_AST_update.log.$now_date`;

print "rolling MSAST_update log...\n";
`mv -f /home/cron/MSLOG_AST_update.log /home/cron/MSLOG_AST_update.log.$now_date`;

print "rolling LIAST_update log...\n";
`mv -f /home/cron/LILOG_AST_update.log /home/cron/LILOG_AST_update.log.$now_date`;

print "rolling Asterisk debug log...\n";
`mv -f /var/log/asterisk/messages /var/log/asterisk/messages.$now_date`;

print "rolling Asterisk screen log...\n";
`mv -f /screenlog.0 /screenlog.0.$now_date`;


print "FINISHED... EXITING\n";

exit;
