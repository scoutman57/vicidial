#!/usr/bin/perl

############################################
# install_server_files.pl - puts server files in the right places
#
# modify the variables below to customize for your system.
#
# path to home directory: (assumes it already exists)
$home =		'/home/cron';

# path to agi-bin directory: (assumes it already exists)
$agibin =	'/var/lib/asterisk/agi-bin';

# path to web root directory: (assumes it already exists)
$webroot =	'/usr/local/apache2/htdocs';

# path to asterisk sounds directory: (assumes it already exists)
$sounds =	'/var/lib/asterisk/sounds';

# path to asterisk recordings directory: (assumes it already exists)
$monitor =	'/var/spool/asterisk';

############################################


print "INSTALLING SERVER SIDE COMPONENTS...\n";

print "Creating cron/LOGS directory...\n";
`mkdir $home/LOGS/`;

print "setting LOGS directory to executable...\n";
`chmod 0766 $home/LOGS`;

print "Creating $home/VICIDIAL/LEADS_IN/DONE directory...\n";
`mkdir $home/VICIDIAL`;
`mkdir $home/VICIDIAL/LEADS_IN`;
`mkdir $home/VICIDIAL/LEADS_IN/DONE`;
`chmod -R 0766 $home/VICIDIAL`;

print "Creating $monitor directories...\n";
`mkdir $monitor/monitor`;
`mkdir $monitor/monitor/ORIG`;
`mkdir $monitor/monitor/DONE`;
`chmod -R 0766 $monitor/monitor`;

print "Copying cron scripts...\n";
`cp -f ./ADMIN_adjust_GMTnow_on_leads.pl $home/`;
`cp -f ./ADMIN_area_code_populate.pl $home/`;
`cp -f ./ADMIN_keepalive_AST_send_listen.pl $home/`;
`cp -f ./ADMIN_keepalive_send_listen.at $home/`;
`cp -f ./ADMIN_keepalive_AST_update.pl $home/`;
`cp -f ./ADMIN_keepalive_AST_VDautodial.pl $home/`;
`cp -f ./ADMIN_keepalive_AST_VDremote_agents.pl $home/`;
`cp -f ./ADMIN_restart_roll_logs.pl $home/`;
`cp -f ./AST_conf_update.pl $home/`;
`cp -f ./AST_CRON_mix_recordings.pl $home/`;
`cp -f ./AST_CRON_mix_recordings_BASIC.pl $home/`;
`cp -f ./AST_DB_optimize.pl $home/`;
`cp -f ./AST_flush_DBqueue.pl $home/`;
`cp -f ./AST_manager_kill_hung_congested.pl $home/`;
`cp -f ./AST_manager_listen.pl $home/`;
`cp -f ./AST_manager_send.pl $home/`;
`cp -f ./AST_reset_mysql_vars.pl $home/`;
`cp -f ./AST_send_action_child.pl $home/`;
`cp -f ./AST_SERVER_conf.pl $home/`;
`cp -f ./AST_update.pl $home/`;
`cp -f ./AST_VDauto_dial.pl $home/`;
`cp -f ./AST_VDhopper.pl $home/`;
`cp -f ./AST_VDremote_agents.pl $home/`;
`cp -f ./AST_vm_update.pl $home/`;
`cp -f ./phone_codes_GMT.txt $home/`;
`cp -f ./start_asterisk_boot.pl $home/`;
`cp -f ./VICIDIAL_IN_new_leads_file.pl $home/`;
`cp -f ./test_VICIDIAL_lead_file.txt $home/VICIDIAL/LEADS_IN/`;


print "setting cron scripts to executable...\n";
`chmod 0755 $home/*`;

print "Copying agi-bin scripts...\n";
`cp -f ./agi-dtmf.agi $agibin/`;
`cp -f ./agi-VDADtransfer.agi $agibin/`;
`cp -f ./agi-VDADcloser.agi $agibin/`;
`cp -f ./agi-VDADcloser_inbound.agi $agibin/`;
`cp -f ./agi-VDADcloser_inboundANI.agi $agibin/`;
`cp -f ./agi-VDADcloser_inboundCID.agi $agibin/`;
`cp -f ./agi-VDADcloser_inbound_NOCID.agi $agibin/`;
`cp -f ./agi-VDADcloser_inbound_5ID.agi $agibin/`;
`cp -f ./call_inbound.agi $agibin/`;
`cp -f ./call_log.agi $agibin/`;
`cp -f ./call_logCID.agi $agibin/`;
`cp -f ./call_park.agi $agibin/`;
`cp -f ./call_park_EXT.agi $agibin/`;
`cp -f ./call_park_I.agi $agibin/`;
`cp -f ./call_park_L.agi $agibin/`;
`cp -f ./call_park_W.agi $agibin/`;
`cp -f ./debug_speak.agi $agibin/`;
`cp -f ./invalid_speak.agi $agibin/`;


print "setting agi-bin scripts to executable...\n";
`chmod 0755 $agibin/*`;

print "Copying sounds...\n";
`cp -f ./DTMF_sounds/* $sounds/`;

print "Creating vicidial web directory...\n";
`mkdir $webroot/vicidial/`;
`mkdir $webroot/vicidial/ploticus/`;

print "Copying VICIDIALweb php files...\n";
`cp -f ./VICIDIAL_web/* $webroot/vicidial/`;

print "setting VICIDIALweb scripts to executable...\n";
`chmod 0755 -R $webroot/vicidial/`;
`chmod 0777 $webroot/vicidial/`;
`chmod 0777 $webroot/vicidial/ploticus/`;

print "Creating agc web directory...\n";
`mkdir $webroot/agc/`;

print "Copying agc php files...\n";
`cp -R -f ./agc/* $webroot/agc/`;

print "setting agc scripts to executable...\n";
`chmod 0755 -R $webroot/agc/`;
`chmod 0777 $webroot/agc/`;

print "Creating astguiclient web directory...\n";
`mkdir $webroot/astguiclient/`;

print "Copying astguiclient web php files...\n";
`cp -f ./astguiclient_web/* $webroot/astguiclient/`;

print "setting astguiclient web scripts to executable...\n";
`chmod 0755 -R $webroot/astguiclient/`;
`chmod 0777 $webroot/astguiclient/`;

print "DONE and EXITING\n";
