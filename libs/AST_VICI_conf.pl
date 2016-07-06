#!/usr/bin/perl

### Customized Variables
$SIP_user = 'SIP/gs102';		# your phone id
$server_ip = '10.10.10.15';		# Asterisk server IP
$ASTmgrUSERNAME = 'cron';		# Asterisk Manager interface username
$ASTmgrSECRET = '1234';			# Asterisk Manager interface secret
$DB_server = '10.10.10.15';		# MySQL server IP
$DB_database = 'asterisk';		# MySQL database name
$DB_user = 'cron';			# MySQL user
$DB_pass = '1234';			# MySQL pass

### VICIDIAL Variables
$login_user = '100001';			# VICIDIAL user (optional)
$login_pass = 'sales';			# VICIDIAL password (optional)
$login_campaign = 'TESTCAMP';	# VICIDIAL campaign (optional)

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
$voicemail_exten = '8501';
$ext_context = 'default';
$dtmf_send_extension = 'local/8500998@demo';
$call_out_number_group ='Zap/g2/';
$client_browser ='/usr/bin/mozilla'; # only used for UNIX
#$install_directory ='C:\AST_VICI'; # absolute path for install (Win32)
$install_directory ='/usr/local/perl_TK'; # absolute path for install (unix)
$local_web_callerID_URL ='http://astguiclient.sf.net/test_callerid_output.php';

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
$CallerID_popup_enabled = 1;	# enable callerID popup window notices 
$voicemail_button_enabled = 1;	# enables voicemail button and counter 

return 1;


# this subroutine is to be used with the callerID function to customize the
# variables that are passed in the URL string and the way that they are passed,
# these are the variables you have to work with:
#   $callerID_areacode
#   $callerID_prefix
#   $callerID_last4
#   $callerID_Time
#   $callerID_Channel
#   $callerID_uniqueID
#   $callerID_phone_ext
#	$callerID_server_ip
#	$callerID_extension
#	$callerID_inbound_number
#	$callerID_comment_a
#	$callerID_comment_b
#	$callerID_comment_c
#	$callerID_comment_d
#	$callerID_comment_e

sub create_callerID_local_query_string
{
$local_web_callerID_QUERY_STRING ='';
$local_web_callerID_QUERY_STRING.="?callerID_areacode=$callerID_areacode";
$local_web_callerID_QUERY_STRING.="&callerID_prefix=$callerID_prefix";
$local_web_callerID_QUERY_STRING.="&callerID_last4=$callerID_last4";
$local_web_callerID_QUERY_STRING.="&callerID_Time=$callerID_Time";
$local_web_callerID_QUERY_STRING.="&callerID_Channel=$callerID_Channel";
$local_web_callerID_QUERY_STRING.="&callerID_uniqueID=$callerID_uniqueID";
$local_web_callerID_QUERY_STRING.="&callerID_phone_ext=$callerID_phone_ext";
$local_web_callerID_QUERY_STRING.="&callerID_server_ip=$callerID_server_ip";
$local_web_callerID_QUERY_STRING.="&callerID_extension=$callerID_extension";
$local_web_callerID_QUERY_STRING.="&callerID_inbound_number=$callerID_inbound_number";
$local_web_callerID_QUERY_STRING.="&callerID_comment_a=$callerID_comment_a";
$local_web_callerID_QUERY_STRING.="&callerID_comment_b=$callerID_comment_b";
$local_web_callerID_QUERY_STRING.="&callerID_comment_c=$callerID_comment_c";
$local_web_callerID_QUERY_STRING.="&callerID_comment_d=$callerID_comment_d";
$local_web_callerID_QUERY_STRING.="&callerID_comment_e=$callerID_comment_e";
}