#!/usr/bin/perl

print "INSTALLING SERVER SIDE COMPONENTS...\n";


print "Copying cron scripts...\n";
`cp ./ADMIN_keepalive_AST_send_listen.pl /home/cron/`;
`cp ./ADMIN_keepalive_AST_update.pl /home/cron/`;
`cp ./ADMIN_restart_roll_logs.pl /home/cron/`;
`cp ./AST_CRON_mix_recordings.pl /home/cron/`;
`cp ./AST_CRON_mix_recordings_BASIC.pl /home/cron/`;
`cp ./AST_SERVER_conf.pl /home/cron/`;
`cp ./AST_manager_kill_hung_congested.pl /home/cron/`;
`cp ./AST_manager_listen.pl /home/cron/`;
`cp ./AST_manager_send.pl /home/cron/`;
`cp ./AST_reset_mysql_vars.pl /home/cron/`;
`cp ./AST_send_action_child.pl /home/cron/`;
`cp ./AST_update.pl /home/cron/`;
`cp ./AST_vm_update.pl /home/cron/`;
`cp ./start_asterisk_boot.pl /home/cron/`;
`cp ./VICIDIAL_IN_new_leads_file.pl /home/cron/`;

print "setting cron scripts to executable...\n";
`chmod 0755 /home/cron/*`;

print "Copying agi-bin scripts...\n";
`cp ./agi-dtmf.agi /var/lib/asterisk/agi-bin/`;
`cp ./call_inbound.agi /var/lib/asterisk/agi-bin/`;
`cp ./call_log.agi /var/lib/asterisk/agi-bin/`;

print "setting agi-bin scripts to executable...\n";
`chmod 0755 /var/lib/asterisk/agi-bin/*`;

print "Copying sounds...\n";
`cp ./DTMF_sounds/* /var/lib/asterisk/sounds/`;

print "Creating vicidial web directory...\n";
`mkdir /usr/local/apache2/htdocs/vicidial/`;

print "Copying VICIDIALweb php files...\n";
`cp ./VICIDIAL_web/* /usr/local/apache2/htdocs/vicidial/`;

print "setting VICIDIALweb scripts to executable...\n";
`chmod 0755 -R /usr/local/apache2/htdocs/vicidial/`;
`chmod 0777 /usr/local/apache2/htdocs/vicidial/`;

print "Creating astguiclient web directory...\n";
`mkdir /usr/local/apache2/htdocs/astguiclient/`;

print "Copying astguiclient web php files...\n";
`cp ./astguiclient_web/* /usr/local/apache2/htdocs/astguiclient/`;

print "setting astguiclient web scripts to executable...\n";
`chmod 0755 -R /usr/local/apache2/htdocs/astguiclient/`;
`chmod 0777 /usr/local/apache2/htdocs/astguiclient/`;

print "DONE and EXITING\n";
