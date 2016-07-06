#!/usr/bin/perl
# ADMIN_listener_restart.pl - script to kill the Asterisk listener and sender processes and restart them

print "killing listener...\n";
`cp /home/cron/KILL/listenmgr.kill /home/cron/listenmgr.kill`;



sleep(1);
print "starting up listener...\n";

`/usr/bin/screen -d -L -m /home/cron/AST_manager_listen.pl`;

print "starting up sender...\n";

`/usr/bin/screen -d -L -m /home/cron/AST_manager_send.pl`;

print "FINISHED... EXITING\n";

exit;
