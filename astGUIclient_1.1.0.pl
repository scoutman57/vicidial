#!/usr/local/ActivePerl-5.8/bin/perl -w
# 
# astGUIclient_1.1.0.pl version 1.1.0      for Perl/Tk
# by MattF <astguiclient@eflo.net> started 2003/10/29
#
# Description:
# - Grabs live call info from a DB updated every second
# - Displays live status of users phones and Zap/IAX/SIP/Local channels
# - Displays number of voicemail messages new and old
# - Allows calls to be placed from GUI and directed to phone
# - Allows blind internal, external, voicemail call transfers
# - Allows call recording by click of button
# - Allows conference calling of up to 6 channels through GUI
# - Administrative Hangup of any live Zap/IAX/SIP/Local channel
# - Administrative switch user function
# - Call Parking sends calls to park ext and then redirects to phone ext
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with Digium
# Zaptel T1 cards or IAX trunks and SIP VOIP hardphones or softphones as 
# extensions, it could be adapted to other functions, but I designed it 
# specifically for Zap/IAX/SIP users. The program will run on UNIX Xwindows and
# Win32 providing the following criteria are met:
# 
# Win32 - ActiveState Perl 5.8.0
# UNIX - Gnome or KDE with Tk/Tcl and perl Tk/Tcl modules loaded
#     ActiveState Perl is recommended on UNIX due to memory leak in generic perl
# Both - Net::MySQL and Net::Telnet perl modules loaded
#
# For this program to work you also need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# On the server side the AST_update.pl program must always be running on a 
# machine somewhere(it is recommended that AST_update be run on the Asterisk
# server locally) for the client app to receive live information and function
# properly, also there are Asterisk conf file settings and 
# MySQL databases that must be present for the client app to work. 
# Information on these is detailed in the README file
# 
# You now have the option for this program to send Action commands either 
# directly to the Asterisk machine, or have them entered into the central 
# queue system. It is recommended to use the central queue system and if this
# program will be heavily used it is strongly encouraged for you to use the 
# central queue system to avoid the problem of Manager buffer-overflow
# deadlocking that can occur with remote manager connections. You can find 
# directions on how to install the central queue system in the README.txt file
# To enable the central queue system for this client set:
#    $QUEUE_ACTION_enabled = 1;        in the AST_VICI_conf.pl file
# 
# Use this command to debug with ptkdb and uncomment Devel::ptkdb module below
# perl -d:ptkdb C:\AST_VICI\astGUIclient_1.1.0.pl  
#  
#
# Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#
# version changes:
# 50110-1040 - modified to add Zap and IAX2 clients (differentiate from trunks)
# 50120-0955 - modified to change configuration location to DB
# 50225-1829 - fixed Zap client recording bug
# 50311-1420 - optimized recently-dialed-numbers queries

# some script specific initial values
$build = '50311-1420';
$version = '1.1.0';
$VM_messages='0';
$VM_old_messages='0';
$DASH='-';
$USUS='__';
$SLASH='/';
$AMP='@';
$park_frame_list_refresh = 0;
$Default_window = 1;
$zap_frame_list_refresh = 1;   
$updater_duplicate_counter = 0;   
$updater_duplicate_value = '';   
$updater_warning_up=0;
$open_dialpad_window_again = 0;
$LookupID_and_log = '';


# DB table variables for testing
	$parked_channels =		'parked_channels';
	$live_channels =		'live_channels';
	$live_sip_channels =	'live_sip_channels';
	$server_updater =		'server_updater';
#	$parked_channels =		'TEST_parked_channels';
#	$live_channels =		'TEST_live_channels';
#	$live_sip_channels =	'TEST_live_sip_channels';
#	$server_updater =		'TEST_server_updater';

require 5.002;

### libs path, where the program looks for config files and perl libs
use lib ".\\",".\\libs", './', './libs', '../libs', '/usr/local/perl_TK/libs', 'C:\\AST_VICI\\libs', 'C:\\cygwin\\usr\\local\\perl_TK\\libs';

### Make sure this file is in a libs path or put the absolute path to it
require("AST_VICI_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

#use Devel::ptkdb;	# uncomment if you want to debug with ptkdb

use Net::MySQL;
use Net::Telnet ();

sub idcheck_connect;
sub connect_to_db;

&idcheck_connect;	### connect and define custom variables

if ($enable_persistant_mysql) {&connect_to_db;}

use English;
use Tk;
use Tk::DialogBox;
use Tk::BrowseEntry;
use Tk::Animation;

sub connect_to_db;
sub start_recording;
sub stop_recording;
sub get_online_sip_users;
sub get_online_channels;
sub get_parked_channels;

sub Open_Help ;
sub Dial_Number;
sub Local_Xfer;
sub Voicemail_Xfer;
sub Start_Conference;
sub Stop_Conference;
sub Switch_Your_ID;
sub Dial_Outside_Number;

sub Dial_Line;
sub Park_Line;
sub Join_Line;
sub Hangup_Line;
sub Hijack_Line;
sub Pickup_Line;
sub validate_conf_lines;
sub Join_Conference;
sub dtmf_dialpad_window;
sub conf_send_dtmf;
sub Zap_Hangup;
sub SIP_Hangup;
sub Zap_Monitor;
sub View_Parked;

### Create new Perl Tk window instance and name it
	my $MW = MainWindow->new;

	$MW->title("astGUIclient - $version");
	$MW->Label(-text => "Build $build          <astguiclient\@eflo.net>")->pack(-side => 'bottom');

	my $ans;

### Time/Date display at the top of the screen
	my $time_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $time_value = $time_frame->Entry(-width => '26', -relief => 'sunken')->pack(-side => 'top');

### config file defined phone ID
	my $login_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$login_frame->Label(-text => "your ID:")->pack(-side => 'left');
	my $login_value = $login_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
    $login_value->insert('0', $SIP_user);



### if enabled show the voicemail button bitmap frame
if ($voicemail_button_enabled)
	{
	my $voicemail_button_frame = $login_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
	$voicemail_button_frame->Label(-text => "     ")->pack(-side => 'left');

	my $vm_ind = "$install_directory/libs/vm_indicator_anim.gif";
    $vm_ind_anim = $voicemail_button_frame->Animation(-format => 'gif', -file => $vm_ind);
	$vm_ind_anim->set_image(0);
	$voicemail_button_frame->Label(-image => $vm_ind_anim)->pack(-side => 'left');
	$vm_ind_anim->start_animation(50);

	$vm_button = $voicemail_button_frame->Photo(-file => "$install_directory/libs/voicemail_up.gif");
	$vm_new = $voicemail_button_frame->Photo(-file => "$install_directory/libs/voicemail_new.gif");
	$vm_old = $voicemail_button_frame->Photo(-file => "$install_directory/libs/voicemail_old.gif");

	my $vm_digits = "$install_directory/libs/voicemail_digits.gif";
    $vm_new_1_anim = $voicemail_button_frame->Animation(-format => 'gif', -file => $vm_digits);
    $vm_new_2_anim = $voicemail_button_frame->Animation(-format => 'gif', -file => $vm_digits);
    $vm_new_3_anim = $voicemail_button_frame->Animation(-format => 'gif', -file => $vm_digits);
    $vm_old_1_anim = $voicemail_button_frame->Animation(-format => 'gif', -file => $vm_digits);
    $vm_old_2_anim = $voicemail_button_frame->Animation(-format => 'gif', -file => $vm_digits);
    $vm_old_3_anim = $voicemail_button_frame->Animation(-format => 'gif', -file => $vm_digits);
	$vm_new_1_anim->set_image(10);
	$vm_new_2_anim->set_image(10);
	$vm_new_3_anim->set_image(10);
	$vm_old_1_anim->set_image(10);
	$vm_old_2_anim->set_image(10);
	$vm_old_3_anim->set_image(10);

	$vm_ind_anim->stop_animation(0);


	### button below current phones box that allows user to change IDs
		my $voicemail_button = $voicemail_button_frame->Button(-text => 'VOICEMAIL', -width => -1, -image => $vm_button, -relief => 'flat',
					-command => sub 
					{
					$VM_button_dial=1;
					 Dial_Outside_Number;
					});
		$voicemail_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

	$voicemail_button_frame->Label(-image => $vm_new)->pack(-side => 'left', -anchor =>'w');
	$voicemail_button_frame->Label(-image => $vm_new_1_anim, -borderwidth => 0)->pack(-side => 'left', -anchor =>'w');
	$voicemail_button_frame->Label(-image => $vm_new_2_anim, -borderwidth => 0)->pack(-side => 'left', -anchor =>'w');
	$voicemail_button_frame->Label(-image => $vm_new_3_anim, -borderwidth => 0)->pack(-side => 'left', -anchor =>'w');
	$voicemail_button_frame->Label(-image => $vm_old)->pack(-side => 'left', -anchor =>'w');
	$voicemail_button_frame->Label(-image => $vm_old_1_anim, -borderwidth => 0)->pack(-side => 'left', -anchor =>'w');
	$voicemail_button_frame->Label(-image => $vm_old_2_anim, -borderwidth => 0)->pack(-side => 'left', -anchor =>'w');
	$voicemail_button_frame->Label(-image => $vm_old_3_anim, -borderwidth => 0)->pack(-side => 'left', -anchor =>'w');
	}


### Active outside channel if the phone is on one
	my $channel_value = $login_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'right');
    $channel_value->insert('0', '');
	$login_frame->Label(-text => "current channel:")->pack(-side => 'right');

### main frame for the buttons and list of the app
	my $main_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');




########################################################
### Frame for current enabled phones and optional switch ID button

		my $current_phones_frame = $main_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$current_phones_frame->Label(-text => "Live Extensions:")->pack(-side => 'top');

	### list box for current phones in system
		my $SIP_user_list = $current_phones_frame->Listbox(-relief => 'sunken', 
								 -width => -1, # Shrink to fit
								 -selectmode => 'single',
								 -exportselection => 0,
								 -height => 20,
								 -setgrid => 'yes');
		my @items = qw(One Two Three Four Five Six Seven
					   Eight Nine Ten Eleven Twelve);
		foreach (@items) {
		   $SIP_user_list->insert('end', $_);
		}
		my $scroll = $main_frame->Scrollbar(-command => ['yview', $SIP_user_list]);
		$SIP_user_list->configure(-yscrollcommand => ['set', $scroll]);
		$SIP_user_list->pack(-side => 'top', -fill => 'both', -expand => 'yes');
		$scroll->pack(-side => 'left', -fill => 'y');
		$SIP_user_list->selectionSet('0');

	if ($user_switching_enabled)
		{
		### button below current phones box that allows user to change IDs
			my $switch_your_id = $current_phones_frame->Button(-text => 'SWITCH YOUR ID', -width => -1,
						-command => sub 
						{
						 Switch_Your_ID;
						});
			$switch_your_id->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		}




########################################################
### Frame for current live phones, live Zap/IAX Channels(trunks) and live SIP/Local Channels(clients)

		my $live_phones_frame = $main_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'right');
		$live_phones_frame->Label(-text => "Busy:               Outside Lines:                Local Extensions:         ")->pack(-side => 'top');

		my $zap_frame = $live_phones_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'right');
		my $zap_list_frame = $zap_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### list box for current sips/locals that are on live calls right now
		my $live_sip = $zap_list_frame->Listbox(-relief => 'sunken', 
								 -width => 19, # Shrink to fit
								 -selectmode => 'single',
								 -exportselection => 0,
								 -height => 20,
								 -setgrid => 'yes');
		foreach (@items) {
		   $live_sip->insert('end', $_);
		}
		my $scrollS = $zap_list_frame->Scrollbar(-command => ['yview', $live_sip]);
		$live_sip->configure(-yscrollcommand => ['set', $scrollS]);
		$live_sip->pack(-side => 'right', -fill => 'both', -expand => 'yes');
		$scrollS->pack(-side => 'right', -fill => 'y');
		$live_sip->selectionSet('0');

	### list box for current Zaps/IAXs that are on live calls right now
		my $live_zap = $zap_list_frame->Listbox(-relief => 'sunken', 
								 -width => 15, # Shrink to fit
								 -selectmode => 'single',
								 -exportselection => 0,
								 -height => 20,
								 -setgrid => 'yes');
		foreach (@items) {
		   $live_zap->insert('end', $_);
		}
		my $scrollA = $zap_list_frame->Scrollbar(-command => ['yview', $live_zap]);
		$live_zap->configure(-yscrollcommand => ['set', $scrollA]);
		$live_zap->pack(-side => 'right', -fill => 'both', -expand => 'yes');
		$scrollA->pack(-side => 'left', -fill => 'y');
		$live_zap->selectionSet('0');

		if ($admin_hangup_enabled) 
			{
			my $hangup_buttons_frame = $zap_frame->Frame()->pack(-expand => 'no', -fill => 'x', -side => 'bottom');

			### button at the bottom of the Zap/IAX listbox to hangup Zap/IAX channels
			my $zap_hangup_button = $hangup_buttons_frame->Button(-text => 'Trunk Hangup', -width => -1,
						-command => sub 
						{
							$zap_frame_list_refresh = 1;
						 Zap_Hangup;
						});
			$zap_hangup_button->pack(-side => 'left', -expand => '1', -fill => 'both');

			### button at the bottom of the sip/local listbox to hangup sip channels
			my $sip_hangup_button = $hangup_buttons_frame->Button(-text => 'Local Hangup', -width => -1,
						-command => sub 
						{
							$sip_frame_list_refresh = 1;
						 SIP_Hangup;
						});
			$sip_hangup_button->pack(-side => 'right', -expand => '1', -fill => 'both');
			}

		my $ext_frame = $live_phones_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'right');
		my $ext_list_frame = $ext_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### list box for current live busy extensions that are on Zap/IAX calls
		my $live_ext = $ext_list_frame->Listbox(-relief => 'sunken', 
								 -width => 8, # Shrink to fit
								 -selectmode => 'single',
								 -exportselection => 0,
								 -height => 20,
								 -setgrid => 'yes');
		foreach (@items) {
		   $live_ext->insert('end', $_);
		}
		my $scrollB = $ext_list_frame->Scrollbar(-command => ['yview', $live_ext]);
		$live_ext->configure(-yscrollcommand => ['set', $scrollB]);
		$live_ext->pack(-side => 'right', -fill => 'both', -expand => 'yes');
		$scrollB->pack(-side => 'right', -fill => 'y');
		$live_ext->selectionSet('0');

		### button at the bottom of the busy extensions listbox to monitor Zap channels
		my $zap_monitor_button = $ext_frame->Button(-text => 'Monitor', -width => -1,
					-command => sub 
					{
					 Zap_Monitor;
					});
		$zap_monitor_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');




########################################################
### Frame for middle buttons and entries

		my $middle_bottons_frame = $main_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

		### button at the bottom to show parked channels
		my $view_park_gif = "$install_directory/libs/buttons.gif";
		$view_park_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $view_park_gif);
		my $view_park_button = $middle_bottons_frame->Button(-text => 'VIEW PARKED CALLS', -width => -1, -image => $view_park_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 View_Parked;
					});
		$view_park_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$view_park_gif_anim->set_image(14);
		$view_park_button->configure(-state => 'disabled');

		### display field that shows the line that was last parked
			my $last_parked_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'bottom');
			$last_parked_frame->Label(-text => "Parked:")->pack(-side => 'left');
			my $last_parked_value = $last_parked_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
			$last_parked_value->insert('0', '');
			my $last_parked_spacer_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
			$last_parked_spacer_frame->Label(-text => "-----     -----")->pack(-side => 'bottom');

		### button to put the current Zap/IAX channel you are on in Park
		my $call_park_gif = "$install_directory/libs/buttons.gif";
		$call_park_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $call_park_gif);
		my $call_park_button = $middle_bottons_frame->Button(-text => 'PARK THIS CALL', -width => -1, -image => $call_park_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 $main_call_park=1;
					$PARK = $channel_value->get;   
					$CHAN='';   
					$last_parked_value->delete('0', 'end');
					$last_parked_value->insert('0', "$PARK");
					Park_Line;
					 $main_call_park=0;
					});
		$call_park_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$call_park_gif_anim->set_image(12);
		$call_park_button->configure(-state => 'disabled');


	### button to blind transfer a call to an outside number
		my $xfer_out_gif = "$install_directory/libs/buttons.gif";
		$xfer_out_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $xfer_out_gif);
		my $xfer_outside_number = $middle_bottons_frame->Button(-text => 'XFER TO OUTSIDE NUM', -width => -1, -image => $xfer_out_gif_anim, -relief => 'flat',
					-command => sub 
					{
					$xfer_out_blind=1;
					 Dial_Outside_Number;
					});
		$xfer_outside_number->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$xfer_outside_number->configure(-state => 'disabled');
		$xfer_out_gif_anim->set_image(16);

	### button at the bottom to dial either a typed in number or a browsebox selected number
		my $dial_out_gif = "$install_directory/libs/buttons.gif";
		$dial_out_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $dial_out_gif);
		my $dial_outside_number = $middle_bottons_frame->Button(-text => 'DIAL OUTSIDE NUMBER', -width => -1, -image => $dial_out_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 Dial_Outside_Number;
					});
		$dial_outside_number->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$dial_out_gif_anim->set_image(1);

	if ($AGI_call_logging_enabled)
		{
			$recent_dial_listbox=$middle_bottons_frame->BrowseEntry(-background => '#CCCCCC',-label => "Recent:",-width => '2')->pack(-expand => '1', -fill => 'both', -side => 'bottom');
			$recent_dial_listbox->insert('end', '');
		}

		my $dial_number_frame = $middle_bottons_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

	#	$dial_number_frame->Label(-text => "-----     -----")->pack(-side => 'top');
		$dial_number_frame->Label(-text => "Outside number to dial:")->pack(-side => 'top');
		my $dial_number_value = $dial_number_frame->Entry(-width => '12', -relief => 'sunken')->pack(-side => 'bottom');

		
	### button for a popup HELP screen with user directions
		my $help_gif = "$install_directory/libs/buttons.gif";
		$help_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $help_gif);
		my $Open_Help = $middle_bottons_frame->Button(-text => 'HELP', -width => -1, -image => $help_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 Open_Help;
					});
		$Open_Help->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$Open_Help->configure(-state => 'normal');
		$help_gif_anim->set_image(9);

	
	### button for a blind transfer live call within asterisk to another extension 
		my $local_xfer_gif = "$install_directory/libs/buttons.gif";
		$local_xfer_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $local_xfer_gif);
		my $local_xfer = $middle_bottons_frame->Button(-text => 'blind int xfer', -width => -1, -image => $local_xfer_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 Local_Xfer;
					});
		$local_xfer->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$local_xfer->configure(-state => 'disabled');
		$local_xfer_gif_anim->set_image(18);


	### button for a blind transfer live call within asterisk to voicemailbox 
		my $vmail_xfer_gif = "$install_directory/libs/buttons.gif";
		$vmail_xfer_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $vmail_xfer_gif);
		my $vmail_xfer = $middle_bottons_frame->Button(-text => 'blind vmail xfer', -width => -1, -image => $vmail_xfer_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 Voicemail_Xfer;
					});
		$vmail_xfer->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$vmail_xfer->configure(-state => 'disabled');
		$vmail_xfer_gif_anim->set_image(20);


	### button for a local call within asterisk to another extension 
		my $local_call_gif = "$install_directory/libs/buttons.gif";
		$local_call_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $local_call_gif);
		my $local_conf = $middle_bottons_frame->Button(-text => 'Intrasystem Call', -width => -1, -image => $local_call_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 Dial_Number;
					});
		$local_conf->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$local_conf->configure(-state => 'normal');
		$local_call_gif_anim->set_image(7);


	### button to start recording, only activated if the phone is on an active outside line
		my $start_rec_gif = "$install_directory/libs/buttons.gif";
		$start_rec_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $start_rec_gif);
		my $start_recording = $middle_bottons_frame->Button(-text => 'START RECORDING', -width => -1, -image => $start_rec_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 start_recording;
					 $RECORD='-';
					});
		$start_recording->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$start_recording->configure(-state => 'disabled');
		$start_rec_gif_anim->set_image(4);

	### button to stop recording
		my $stop_rec_gif = "$install_directory/libs/buttons.gif";
		$stop_rec_gif_anim = $middle_bottons_frame->Animation(-format => 'gif', -file => $stop_rec_gif);
		my $stop_recording = $middle_bottons_frame->Button(-text => 'STOP RECORDING', -width => -1, -image => $stop_rec_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 stop_recording;
					});
		$stop_recording->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$stop_rec_gif_anim->set_image(5);

	### display field that shows -- RECORDING-- during recording active and the length of recording when recording is stopped
		my $rec_msg_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_msg_frame->Label(-text => "RECORDING MESSAGE:")->pack(-side => 'top');
		my $rec_msg_value = $rec_msg_frame->Entry(-width => '24', -relief => 'sunken')->pack(-side => 'top');
		$rec_msg_value->insert('0', '');

	### display field that shows the filename as soon as recording is started
		my $rec_fname_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_fname_frame->Label(-text => "RECORDING FILENAME:")->pack(-side => 'top');
		my $rec_fname_value = $rec_fname_frame->Entry(-width => '24', -relief => 'sunken')->pack(-side => 'top');
		$rec_fname_value->insert('0', '');

	### display field that shows the unique recording ID in the database only after the recording session is finished
		my $rec_recid_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_recid_frame->Label(-text => "RECORDING ID:")->pack(-side => 'left');
		my $rec_recid_value = $rec_recid_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
		$rec_recid_value->insert('0', '');
		my $rec_recid_spacer_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_recid_spacer_frame->Label(-text => "-----     -----")->pack(-side => 'bottom');







########################################################
### Frame for Conference control


	my $conf_frame_control = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

	### button at the bottom to enter a conference call with the current line
		my $start_conf_gif = "$install_directory/libs/buttons.gif";
		$start_conf_gif_anim = $conf_frame_control->Animation(-format => 'gif', -file => $start_conf_gif);
		my $initiate_conference = $conf_frame_control->Button(-text => 'START CONFERENCE', -width => -1, -image => $start_conf_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 Start_Conference;
					});
		$initiate_conference->pack(-side => 'right', -expand => 'no', -fill => 'both');
		$initiate_conference->configure(-state => 'disabled');
		$start_conf_gif_anim->set_image(22);

		my $stop_conf_gif = "$install_directory/libs/buttons.gif";
		$stop_conf_gif_anim = $conf_frame_control->Animation(-format => 'gif', -file => $stop_conf_gif);
		my $destroy_conference = $conf_frame_control->Button(-text => 'STOP CONFERENCE', -width => -1, -image => $stop_conf_gif_anim, -relief => 'flat',
					-command => sub 
					{
					 Stop_Conference;
					});
		$destroy_conference->pack(-side => 'right', -expand => 'no', -fill => 'both', -before => $initiate_conference);
		$destroy_conference->configure(-state => 'disabled');
		$stop_conf_gif_anim->set_image(24);








################################################################################################################
### Frame for Conferencing <initially hidden>


	### main frame for the conferencing part of the application
		my $conf_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$conf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner pixel


		### conf buttons at the bottom of the conf frame recording stop and recording channel
			my $button_conf_frame_two = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');
			my $stop_rec_conf = $button_conf_frame_two->Button(-text => 'STOP RECORDING', -width => -1,
						-command => sub {
							conf_stop_recording();
							});
			$stop_rec_conf->pack(-side => 'left', -expand => 'no', -fill => 'both');

			### display field that shows the Local channel that you are connected with for recording
			my $conf_rec_channel_frame = $button_conf_frame_two->Frame()->pack(-expand => '2', -fill => 'both', -side => 'right');
			$conf_rec_channel_frame->Label(-text => " Your Local Recording Channel: ")->pack(-side => 'left');
			my $conf_rec_channel_value = $conf_rec_channel_frame->Entry(-width => '33', -relief => 'sunken')->pack(-side => 'left');
			$conf_rec_channel_value->insert('0', '');


		### conf buttons at the bottom of the conf frame
			my $button_conf_frame = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');


			### Start Recording button for the conferencing frame
			my $start_rec_conf = $button_conf_frame->Button(-text => 'START RECORDING', -width => -1,
						-command => sub {
							conf_start_recording();
							});
			$start_rec_conf->pack(-side => 'left', -expand => 'no', -fill => 'both');



			### display field that shows the local conference extension that is being used
			my $conf_extension_frame = $button_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'right');
			$conf_extension_frame->Label(-text => " local conference extension: ")->pack(-side => 'left');
			my $conf_extension_value = $conf_extension_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
			$conf_extension_value->insert('0', '');


			### display field that shows the SIP channel that you are connected with
			my $conf_sip_channel_frame = $button_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'right');
			$conf_sip_channel_frame->Label(-text => " Your Local channel: ")->pack(-side => 'left');
			my $conf_sip_channel_value = $conf_sip_channel_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
			$conf_sip_channel_value->insert('0', '');


		### conf recording fields bottom of the page
			my $rec_fields_conf_frame = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom', -before => $button_conf_frame_two);

			### display field that shows -- RECORDING-- during recording active and the length of recording when recording is stopped
			my $conf_rec_msg_frame = $rec_fields_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'left');
			$conf_rec_msg_frame->Label(-text => "rec status: ")->pack(-side => 'left');
			my $conf_rec_msg_value = $conf_rec_msg_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
			$conf_rec_msg_value->insert('0', '');

			### display field that shows the filename as soon as recording is started
			my $conf_rec_fname_frame = $rec_fields_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'left');
			$conf_rec_fname_frame->Label(-text => " filename: ")->pack(-side => 'left');
			my $conf_rec_fname_value = $conf_rec_fname_frame->Entry(-width => '22', -relief => 'sunken')->pack(-side => 'left');
			$conf_rec_fname_value->insert('0', '');

			### display field that shows the unique recording ID in the database only after the recording session is finished
			my $conf_rec_recid_frame = $rec_fields_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'left');
			$conf_rec_recid_frame->Label(-text => " rec ID: ")->pack(-side => 'left');
			my $conf_rec_recid_value = $conf_rec_recid_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
			$conf_rec_recid_value->insert('0', '');


		### send dtmf button and field at the bottom of the page
			my $dtmf_conf_frame = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom', -before => $rec_fields_conf_frame);



			### dialpad DTMF button for the conferencing frame
			my $open_dialpad_conf = $dtmf_conf_frame->Button(-text => 'DIALPAD', -width => -1,
						-command => sub {
							dtmf_dialpad_window;
							});
			$open_dialpad_conf->pack(-side => 'left', -expand => 'no', -fill => 'both');

			### Send DTMF button for the conferencing frame
			my $stop_rec_conf = $dtmf_conf_frame->Button(-text => 'Send DTMF', -width => -1,
						-command => sub {
							conf_send_dtmf();
							});
			$stop_rec_conf->pack(-side => 'left', -expand => 'no', -fill => 'both');

			### display field that shows -- RECORDING-- during recording active and the length of recording when recording is stopped
			my $conf_dtmf_msg_frame = $dtmf_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'left');
			$conf_dtmf_msg_frame->Label(-text => "   DTMF to send: ")->pack(-side => 'left');
			my $xfer_dtmf_value = $conf_dtmf_msg_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
			$xfer_dtmf_value->insert('0', '');
			$conf_dtmf_msg_frame->Label(-text => "   (0-9 * # and a comma , for a 1 second pause)")->pack(-side => 'left');



		### login frame for the buttons and list of the app
			my $login_conf_frame = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			$login_conf_frame->Label(-text => "                                              Channel:                                        Number to Dial:")->pack(-side => 'left');
			$login_conf_frame->Label(-text => "Status:          ")->pack(-side => 'right');


		### line_A frame for the buttons and list of the app
			my $line_conf_frame_A = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_A = $line_conf_frame_A->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_A->insert('0', "");

			$line_conf_frame_A->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_A->Label(-text => "Channel A:")->pack(-side => 'left');
			my $conf_LIVE_channel_A = $line_conf_frame_A->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_LIVE_channel_A->insert('0', " - ");

			my $conf_line_hangup_A = $line_conf_frame_A->Button(-text => 'Hangup', -width => -1,
						-command => sub {
							$HANGUP = $conf_LIVE_channel_A->get;   
							$CHAN='A';   
							$conf_STATUS_channel_A->delete('0', 'end');
							$conf_STATUS_channel_A->insert('0', "HUNGUP $HANGUP");
							Hangup_Line();
							});
			$conf_line_hangup_A->pack(-side => 'left', -expand => 'no', -fill => 'both');

			my $conf_DIAL_channel_A = $line_conf_frame_A->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_DIAL_channel_A->insert('0', "");

			my $conf_line_dial_A = $line_conf_frame_A->Button(-text => 'Dial', -width => -1,
						-command => sub {
							$DIAL = $conf_DIAL_channel_A->get;   
							$CHAN='A';   
							$conf_STATUS_channel_A->delete('0', 'end');
							$conf_STATUS_channel_A->insert('0', "DIALING $DIAL");
							Dial_Line();
							});
			$conf_line_dial_A->pack(-side => 'left', -expand => 'no', -fill => 'both', -before=>$conf_DIAL_channel_A);
			$conf_line_dial_A->configure(-state => 'disabled');


			my $conf_line_park_A = $line_conf_frame_A->Button(-text => 'Park', -width => -1,
						-command => sub {
							$PARK = $conf_LIVE_channel_A->get;   
							$CHAN='A';   
							$conf_STATUS_channel_A->delete('0', 'end');
							$conf_STATUS_channel_A->insert('0', "$PARK PARKED");
							Park_Line();
							});
			$conf_line_park_A->pack(-side => 'left', -expand => 'no', -fill => 'both');

			my $conf_line_join_A = $line_conf_frame_A->Button(-text => 'Join', -width => -1,
						-command => sub {
							$JOIN = $conf_LIVE_channel_A->get;   
							$CHAN='A';   
							$conf_STATUS_channel_A->delete('0', 'end');
							$conf_STATUS_channel_A->insert('0', "$JOIN JOINED");
							Join_Line();
							});
			$conf_line_join_A->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_join_A->configure(-state => 'disabled');


		### line_B frame for the buttons and list of the app
			my $line_conf_frame_B = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_B = $line_conf_frame_B->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_B->insert('0', "");

			$line_conf_frame_B->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_B->Label(-text => "Channel B:")->pack(-side => 'left');
			my $conf_LIVE_channel_B = $line_conf_frame_B->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_LIVE_channel_B->insert('0', " - ");

			my $conf_line_hangup_B = $line_conf_frame_B->Button(-text => 'Hangup', -width => -1,
						-command => sub {
							$HANGUP = $conf_LIVE_channel_B->get;   
							$CHAN='B';   
							$conf_STATUS_channel_B->delete('0', 'end');
							$conf_STATUS_channel_B->insert('0', "HUNGUP $HANGUP");
							Hangup_Line();
							});
			$conf_line_hangup_B->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_hangup_B->configure(-state => 'disabled');

			my $conf_DIAL_channel_B = $line_conf_frame_B->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_DIAL_channel_B->insert('0', "");

			my $conf_line_dial_B = $line_conf_frame_B->Button(-text => 'Dial', -width => -1,
						-command => sub {
							$DIAL = $conf_DIAL_channel_B->get;   
							$CHAN='B';   
							$conf_STATUS_channel_B->delete('0', 'end');
							$conf_STATUS_channel_B->insert('0', "DIALING $DIAL");
							Dial_Line();
							});
			$conf_line_dial_B->pack(-side => 'left', -expand => 'no', -fill => 'both', -before=>$conf_DIAL_channel_B);


			my $conf_line_park_B = $line_conf_frame_B->Button(-text => 'Park', -width => -1,
						-command => sub {
							$PARK = $conf_LIVE_channel_B->get;   
							$CHAN='B';   
							$conf_STATUS_channel_B->delete('0', 'end');
							$conf_STATUS_channel_B->insert('0', "$PARK PARKED");
							Park_Line();
							});
			$conf_line_park_B->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_park_B->configure(-state => 'disabled');

			my $conf_line_join_B = $line_conf_frame_B->Button(-text => 'Join', -width => -1,
						-command => sub {
							$JOIN = $conf_LIVE_channel_B->get;   
							$CHAN='B';   
							$conf_STATUS_channel_B->delete('0', 'end');
							$conf_STATUS_channel_B->insert('0', "$JOIN JOINED");
							Join_Line();
							});
			$conf_line_join_B->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_join_B->configure(-state => 'disabled');


		### line_C frame for the buttons and list of the app
			my $line_conf_frame_C = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_C = $line_conf_frame_C->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_C->insert('0', "");

			$line_conf_frame_C->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_C->Label(-text => "Channel C:")->pack(-side => 'left');
			my $conf_LIVE_channel_C = $line_conf_frame_C->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_LIVE_channel_C->insert('0', " - ");

			my $conf_line_hangup_C = $line_conf_frame_C->Button(-text => 'Hangup', -width => -1,
						-command => sub {
							$HANGUP = $conf_LIVE_channel_C->get;   
							$CHAN='C';   
							$conf_STATUS_channel_C->delete('0', 'end');
							$conf_STATUS_channel_C->insert('0', "HUNGUP $HANGUP");
							Hangup_Line();
							});
			$conf_line_hangup_C->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_hangup_C->configure(-state => 'disabled');

			my $conf_DIAL_channel_C = $line_conf_frame_C->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_DIAL_channel_C->insert('0', "");

			my $conf_line_dial_C = $line_conf_frame_C->Button(-text => 'Dial', -width => -1,
						-command => sub {
							$DIAL = $conf_DIAL_channel_C->get;   
							$CHAN='C';   
							$conf_STATUS_channel_C->delete('0', 'end');
							$conf_STATUS_channel_C->insert('0', "DIALING $DIAL");
							Dial_Line();
							});
			$conf_line_dial_C->pack(-side => 'left', -expand => 'no', -fill => 'both', -before=>$conf_DIAL_channel_C);


			my $conf_line_park_C = $line_conf_frame_C->Button(-text => 'Park', -width => -1,
						-command => sub {
							$PARK = $conf_LIVE_channel_C->get;   
							$CHAN='C';   
							$conf_STATUS_channel_C->delete('0', 'end');
							$conf_STATUS_channel_C->insert('0', "$PARK PARKED");
							Park_Line();
							});
			$conf_line_park_C->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_park_C->configure(-state => 'disabled');

			my $conf_line_join_C = $line_conf_frame_C->Button(-text => 'Join', -width => -1,
						-command => sub {
							$JOIN = $conf_LIVE_channel_C->get;   
							$CHAN='C';   
							$conf_STATUS_channel_C->delete('0', 'end');
							$conf_STATUS_channel_C->insert('0', "$JOIN JOINED");
							Join_Line();
							});
			$conf_line_join_C->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_join_C->configure(-state => 'disabled');


		### line_D frame for the buttons and list of the app
			my $line_conf_frame_D = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_D = $line_conf_frame_D->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_D->insert('0', "");

			$line_conf_frame_D->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_D->Label(-text => "Channel D:")->pack(-side => 'left');
			my $conf_LIVE_channel_D = $line_conf_frame_D->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_LIVE_channel_D->insert('0', " - ");

			my $conf_line_hangup_D = $line_conf_frame_D->Button(-text => 'Hangup', -width => -1,
						-command => sub {
							$HANGUP = $conf_LIVE_channel_D->get;   
							$CHAN='D';   
							$conf_STATUS_channel_D->delete('0', 'end');
							$conf_STATUS_channel_D->insert('0', "HUNGUP $HANGUP");
							Hangup_Line();
							});
			$conf_line_hangup_D->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_hangup_D->configure(-state => 'disabled');

			my $conf_DIAL_channel_D = $line_conf_frame_D->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_DIAL_channel_D->insert('0', "");

			my $conf_line_dial_D = $line_conf_frame_D->Button(-text => 'Dial', -width => -1,
						-command => sub {
							$DIAL = $conf_DIAL_channel_D->get;   
							$CHAN='D';   
							$conf_STATUS_channel_D->delete('0', 'end');
							$conf_STATUS_channel_D->insert('0', "DIALING $DIAL");
							Dial_Line();
							});
			$conf_line_dial_D->pack(-side => 'left', -expand => 'no', -fill => 'both', -before=>$conf_DIAL_channel_D);


			my $conf_line_park_D = $line_conf_frame_D->Button(-text => 'Park', -width => -1,
						-command => sub {
							$PARK = $conf_LIVE_channel_D->get;   
							$CHAN='D';   
							$conf_STATUS_channel_D->delete('0', 'end');
							$conf_STATUS_channel_D->insert('0', "$PARK PARKED");
							Park_Line();
							});
			$conf_line_park_D->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_park_D->configure(-state => 'disabled');

			my $conf_line_join_D = $line_conf_frame_D->Button(-text => 'Join', -width => -1,
						-command => sub {
							$JOIN = $conf_LIVE_channel_D->get;   
							$CHAN='D';   
							$conf_STATUS_channel_D->delete('0', 'end');
							$conf_STATUS_channel_D->insert('0', "$JOIN JOINED");
							Join_Line();
							});
			$conf_line_join_D->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_join_D->configure(-state => 'disabled');


		### line_E frame for the buttons and list of the app
			my $line_conf_frame_E = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_E = $line_conf_frame_E->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_E->insert('0', "");

			$line_conf_frame_E->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_E->Label(-text => "Channel E:")->pack(-side => 'left');
			my $conf_LIVE_channel_E = $line_conf_frame_E->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_LIVE_channel_E->insert('0', " - ");

			my $conf_line_hangup_E = $line_conf_frame_E->Button(-text => 'Hangup', -width => -1,
						-command => sub {
							$HANGUP = $conf_LIVE_channel_E->get;   
							$CHAN='E';   
							$conf_STATUS_channel_E->delete('0', 'end');
							$conf_STATUS_channel_E->insert('0', "HUNGUP $HANGUP");
							Hangup_Line();
							});
			$conf_line_hangup_E->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_hangup_E->configure(-state => 'disabled');

			my $conf_DIAL_channel_E = $line_conf_frame_E->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_DIAL_channel_E->insert('0', "");

			my $conf_line_dial_E = $line_conf_frame_E->Button(-text => 'Dial', -width => -1,
						-command => sub {
							$DIAL = $conf_DIAL_channel_E->get;   
							$CHAN='E';   
							$conf_STATUS_channel_E->delete('0', 'end');
							$conf_STATUS_channel_E->insert('0', "DIALING $DIAL");
							Dial_Line();
							});
			$conf_line_dial_E->pack(-side => 'left', -expand => 'no', -fill => 'both', -before=>$conf_DIAL_channel_E);


			my $conf_line_park_E = $line_conf_frame_E->Button(-text => 'Park', -width => -1,
						-command => sub {
							$PARK = $conf_LIVE_channel_E->get;   
							$CHAN='E';   
							$conf_STATUS_channel_E->delete('0', 'end');
							$conf_STATUS_channel_E->insert('0', "$PARK PARKED");
							Park_Line();
							});
			$conf_line_park_E->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_park_E->configure(-state => 'disabled');

			my $conf_line_join_E = $line_conf_frame_E->Button(-text => 'Join', -width => -1,
						-command => sub {
							$JOIN = $conf_LIVE_channel_E->get;   
							$CHAN='E';   
							$conf_STATUS_channel_E->delete('0', 'end');
							$conf_STATUS_channel_E->insert('0', "$JOIN JOINED");
							Join_Line();
							});
			$conf_line_join_E->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_join_E->configure(-state => 'disabled');


		### line_F frame for the buttons and list of the app
			my $line_conf_frame_F = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_F = $line_conf_frame_F->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_F->insert('0', "");

			$line_conf_frame_F->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_F->Label(-text => "Channel F:")->pack(-side => 'left');
			my $conf_LIVE_channel_F = $line_conf_frame_F->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_LIVE_channel_F->insert('0', " - ");

			my $conf_line_hangup_F = $line_conf_frame_F->Button(-text => 'Hangup', -width => -1,
						-command => sub {
							$HANGUP = $conf_LIVE_channel_F->get;   
							$CHAN='F';   
							$conf_STATUS_channel_F->delete('0', 'end');
							$conf_STATUS_channel_F->insert('0', "HUNGUP $HANGUP");
							Hangup_Line();
							});
			$conf_line_hangup_F->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_hangup_F->configure(-state => 'disabled');

			my $conf_DIAL_channel_F = $line_conf_frame_F->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
				$conf_DIAL_channel_F->insert('0', "");

			my $conf_line_dial_F = $line_conf_frame_F->Button(-text => 'Dial', -width => -1,
						-command => sub {
							$DIAL = $conf_DIAL_channel_F->get;   
							$CHAN='F';   
							$conf_STATUS_channel_F->delete('0', 'end');
							$conf_STATUS_channel_F->insert('0', "DIALING $DIAL");
							Dial_Line();
							});
			$conf_line_dial_F->pack(-side => 'left', -expand => 'no', -fill => 'both', -before=>$conf_DIAL_channel_F);


			my $conf_line_park_F = $line_conf_frame_F->Button(-text => 'Park', -width => -1,
						-command => sub {
							$PARK = $conf_LIVE_channel_F->get;   
							$CHAN='F';   
							$conf_STATUS_channel_F->delete('0', 'end');
							$conf_STATUS_channel_F->insert('0', "$PARK PARKED");
							Park_Line();
							});
			$conf_line_park_F->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_park_F->configure(-state => 'disabled');

			my $conf_line_join_F = $line_conf_frame_F->Button(-text => 'Join', -width => -1,
						-command => sub {
							$JOIN = $conf_LIVE_channel_F->get;   
							$CHAN='F';   
							$conf_STATUS_channel_F->delete('0', 'end');
							$conf_STATUS_channel_F->insert('0', "$JOIN JOINED");
							Join_Line();
							});
			$conf_line_join_F->pack(-side => 'left', -expand => 'no', -fill => 'both');
			$conf_line_join_F->configure(-state => 'disabled');


###  END Frame for Conferencing <initially hidden>
################################################################################################################





################################################################################################################
### Frame for Zap/IAX(trunk) Hangup <initially hidden>


	### main frame for the Zap/IAX hangup part of the application
		my $main_zap_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$main_zap_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1); # hide the frame in the upper-left


		my $list_zap_frame = $main_zap_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### list box for current phones that are on live calls right now
		my $live_zap_hangup = $list_zap_frame->Listbox(-relief => 'sunken', 
								 -width => 17, # Shrink to fit
								 -selectmode => 'single',
								 -exportselection => 0,
								 -height => 20,
								 -setgrid => 'yes');
		foreach (@items) {
		   $live_zap->insert('end', $_);
		}
		my $scrollC = $list_zap_frame->Scrollbar(-command => ['yview', $live_zap_hangup]);
		$live_zap_hangup->configure(-yscrollcommand => ['set', $scrollC]);
		$live_zap_hangup->pack(-side => 'right', -fill => 'both', -expand => 'yes');
		$scrollC->pack(-side => 'left', -fill => 'y');
		$live_zap_hangup->selectionSet('0');


		### conf buttons at the bottom of the conf frame
			my $button_zap_frame = $main_zap_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

			### Button to kill the selected Zap/IAX line
			my $zap_hangup_button = $button_zap_frame->Button(-text => 'HANGUP OUTSIDE TRUNK LINE', -width => -1,
						-command => sub 
						{
						 $HANGUP = $live_zap_hangup->get('active');
						 $HANGUP =~ s/_.*//gi;
						print "Hanging up ZAP/IAX: $HANGUP\n";
						$zap_frame_list_refresh = 1;   
						$CHAN='';   
						 Hangup_Line;
						});
			$zap_hangup_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$zap_hangup_button->configure(-state => 'normal');

			if ($admin_hijack_enabled)
				{
				### Button to hijack the selected Zap/IAX line
				my $zap_hijack_button = $button_zap_frame->Button(-text => 'HIJACK LINE', -width => -1,
							-command => sub 
							{
							 $HIJACK = $live_zap_hangup->get('active');
							 $HIJACK =~ s/_.*//gi;
							print "Hijacking ZAP/IAX Line: $HIJACK\n";
							$zap_frame_list_refresh = 1;   
							$CHAN='';   
							 Hijack_Line;
							});
				$zap_hijack_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
				$zap_hijack_button->configure(-state => 'normal');
				}

		#	$button_conf_frame->Label(-text => "     -----     ")->pack(-side => 'bottom');

			### Refresh button to refresh the list of live Zap/IAX channels
			my $zap_hangup_refresh = $button_zap_frame->Button(-text => 'REFRESH LIST', -width => -1,
						-command => sub 
						{
						$zap_frame_list_refresh = 1;   
						});
			$zap_hangup_refresh->pack(-side => 'bottom', -expand => 'no', -fill => 'both');

			### Button to leave the Zap/IAX Hangup section
			my $zap_close_button = $button_zap_frame->Button(-text => 'BACK TO MAIN', -width => -1,
						-command => sub 
						{
						$main_zap_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1);

						$main_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
						$HANGUP='';
						});
			$zap_close_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');


### END Frame for Zap/IAX Hangup <initially hidden>
################################################################################################################





################################################################################################################
### Frame for SIP/Local Hangup <initially hidden>


	### main frame for the SIP/Local hangup part of the application
		my $main_sip_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$main_sip_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1); # hide the frame in the upper-left corner pixel


		my $list_sip_frame = $main_sip_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### list box for current live SIP/Local channels
		my $live_sip_hangup = $list_sip_frame->Listbox(-relief => 'sunken', 
								 -width => 19, # Shrink to fit
								 -selectmode => 'single',
								 -exportselection => 0,
								 -height => 20,
								 -setgrid => 'yes');
		foreach (@items) {
		   $live_sip->insert('end', $_);
		}
		my $scrollR = $list_sip_frame->Scrollbar(-command => ['yview', $live_sip_hangup]);
		$live_sip_hangup->configure(-yscrollcommand => ['set', $scrollR]);
		$live_sip_hangup->pack(-side => 'right', -fill => 'both', -expand => 'yes');
		$scrollR->pack(-side => 'left', -fill => 'y');
		$live_sip_hangup->selectionSet('0');


		### conf buttons at the bottom of the conf frame
			my $button_sip_frame = $main_sip_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

			### Button to kill the selected SIP/Local line
			my $sip_hangup_button = $button_sip_frame->Button(-text => 'HANGUP LOCAL LINE', -width => -1,
						-command => sub 
						{
						 $HANGUP = $live_sip_hangup->get('active');
						 $HANGUP =~ s/_.*//gi;
						print "Hanging up sip: $HANGUP\n";
						$sip_frame_list_refresh = 1;   
						$CHAN='';   
						 Hangup_Line;
						});
			$sip_hangup_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$sip_hangup_button->configure(-state => 'normal');

			if ($admin_hijack_enabled)
				{
				### Button to hijack the selected SIP/Local line
				my $sip_hijack_button = $button_sip_frame->Button(-text => 'HIJACK LINE', -width => -1,
							-command => sub 
							{
							 $HIJACK = $live_sip_hangup->get('active');
							 $HIJACK =~ s/_.*//gi;
							print "Hijacking SIP/Local Line: $HIJACK\n";
							$sip_frame_list_refresh = 1;   
							$CHAN='';   
							 Hijack_Line;
							});
				$sip_hijack_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
				$sip_hijack_button->configure(-state => 'normal');
				}


		#	$button_conf_frame->Label(-text => "     -----     ")->pack(-side => 'bottom');

			### Refresh button to refresh the list of live sip channels
			my $sip_hangup_refresh = $button_sip_frame->Button(-text => 'REFRESH LIST', -width => -1,
						-command => sub 
						{
						$sip_frame_list_refresh = 1;   
						});
			$sip_hangup_refresh->pack(-side => 'bottom', -expand => 'no', -fill => 'both');

			### Button to leave the sip Hangup section
			my $sip_close_button = $button_sip_frame->Button(-text => 'BACK TO MAIN', -width => -1,
						-command => sub 
						{
						$main_sip_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1);

						$main_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
						$HANGUP='';
						});
			$sip_close_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');


### END Frame for SIP Hangup <initially hidden>
################################################################################################################






################################################################################################################
### Frame for Parked Calls Display <initially hidden>


	### main frame for the park hangup part of the application
		my $main_park_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$main_park_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>4, -y=>1); # hide the frame in the upper-left corner pixel


		my $list_park_frame = $main_park_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### list box for current phones that are on live calls right now
		my $live_park_lines = $list_park_frame->Listbox(-relief => 'sunken', 
								 -width => 17, # Shrink to fit
								 -selectmode => 'single',
								 -exportselection => 0,
								 -height => 20,
								 -setgrid => 'yes');
		foreach (@items) {
		   $live_park_lines->insert('end', $_);
		}
		my $scrollD = $list_park_frame->Scrollbar(-command => ['yview', $live_park_lines]);
		$live_park_lines->configure(-yscrollcommand => ['set', $scrollD]);
		$live_park_lines->pack(-side => 'right', -fill => 'both', -expand => 'yes');
		$scrollD->pack(-side => 'left', -fill => 'y');
		$live_park_lines->selectionSet('0');


		### conf buttons at the bottom of the conf frame
			my $button_park_frame = $main_park_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

			### Button to kill the selected Zap/IAX line
			my $park_grab_button = $button_park_frame->Button(-text => 'GRAB PARKED LINE', -width => -1,
						-command => sub 
						{
						 $PICKUP = $live_park_lines->get('active');
						 $PICKUP =~ s/ .*//gi;
						print "Grabbing parked call: $PICKUP\n";
						$park_frame_list_refresh = 1;   
						$CHAN='';   
						 Pickup_Line;
						});
			$park_grab_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$park_grab_button->configure(-state => 'normal');


		#	$button_conf_frame->Label(-text => "     -----     ")->pack(-side => 'bottom');

			### Refresh button to refresh the list of live Zap/IAX channels
			my $park_hangup_refresh = $button_park_frame->Button(-text => 'REFRESH LIST', -width => -1,
						-command => sub 
						{
						$park_frame_list_refresh = 1;   
						});
			$park_hangup_refresh->pack(-side => 'bottom', -expand => 'no', -fill => 'both');

			### Button to leave the Parked Calls section
			my $park_close_button = $button_park_frame->Button(-text => 'BACK TO MAIN', -width => -1,
						-command => sub 
						{
						$main_park_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1);

						$main_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
						$HANGUP='';
						});
			$park_close_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');


### END Frame for Parked Calls Display <initially hidden>
################################################################################################################








################################################################################################################
### set various start and refresh routines at millisecond intervals
################################################################################################################
sub RefreshList
{
	$MW->after (1000, \&get_online_sip_users);
	if ($AGI_call_logging_enabled) {$MW->after (1000, \&get_recent_dialed_numbers);}
	if ($call_parking_enabled) {$MW->repeat (1000, \&get_parked_channels);}
	if ($enable_fast_refresh) {$MW->repeat ($fast_refresh_rate, \&get_online_channels);}
		else {$MW->repeat (1000, \&get_online_channels);}
	$MW->repeat (600000, \&get_online_sip_users);
	if ($AGI_call_logging_enabled) {$MW->repeat (360000, \&get_recent_dialed_numbers);}
	if ($conferencing_enabled) {$MW->repeat (1000, \&validate_conf_lines);}

			return;
}

get_parked_channels;

#get_online_channels;

get_online_sip_users;

RefreshList();

MainLoop();








##########­##########­##########­##########­##########­##########­##########­##########
##########­##########­##########­##########­##########­##########­##########­##########
### SUBROUTINES GO HERE
##########­##########­##########­##########­##########­##########­##########­##########
##########­##########­##########­##########­##########­##########­##########­##########


##########################################
### Open an internet browser window
##########################################
sub LaunchBrowser_New 
{
	$url =~ s/\s/+/g;
	print STDERR "OS: |$^O|\n";
   if ($^O =~ /MSWin32/i)
	   {
		eval '
	$url =~ s/\&/\^\&/g;
	   my $process;
#	print STDERR "SR: |$ENV{SYSTEMROOT}|\n";

	   use Win32::Process;
       Win32::Process::Create($process,
                                  "$ENV{SYSTEMROOT}\\\\system32\\\\cmd.exe",
                                  "cmd.exe /c start $url",
                                  0,DETACHED_PROCESS,".") ||
         printError("Unable to launch browser: " . Win32::FormatMessage(Win32::GetLastError()));
	   ';
		}
	else 
		{
		print STDERR "Starting Mozilla...\n";

		eval '
			$no_moz_found=0;
			$url =~ s/\&/\\\&/g;
		my $pid = fork;
		if ($pid == 0)
			{
			$no_moz_found = `$client_browser -remote ping\\\(\\\)`;
			$errcode = $?;
		print STDERR "|$no_moz_found|$?|$!|$errcode|\n";

			if ($errcode !~ /^0/i)
				{
				exec "$client_browser $url";
				print STDERR "|open new|\n";

				}
			else
				{
				exec "$client_browser -remote openURL\\\($url\\\)";
				print STDERR "|open exist|\n";
				}

			}';
	   }
}

##########################################
### Open a HELP window
##########################################
sub Open_Help
{
$subroutine = 'Open_Help';

	my $help_dialog = $MW->DialogBox( -title   => "Vici Phone HELP",
                                 -buttons => [ "OK" ],
				);
    $help_dialog->add("Label", -text => "WINphoneAPP HELP")->pack;
	my $help_window_text = $help_dialog->Text(-width => 78, 
        -height => 25, 
        -wrap => 'word', 
        -font => ['Courier','10'] 
		)->pack(-side => 'bottom', 
        -expand => 1, 
        -fill => 'both', 
		);
	$help_window_text->Insert("                           --- astGUIclient HELP --- \n\nDIALING FROM APP:\nMake sure that your phone is on hook, then type the number that you would like to dial in the entry field DIRECTLY below the \"Outside number to dial:\" text in the middle column using the proper format for where you want to call:\n     - Local calls in this area code dial only 7 digits (5551212)\n     - Long Distance calls in the US/Canada/Mexico/Central America\n       dial only 10 digits (3125551212)\n     - UK calls dial 8 + 10 digit number (81235551212)\n     - Australia dial only the 9 digit phone number (312555121), and click on the \"Dial Outside Number\" button.\n\nCONFERENCE CALLS:\nWhen on an active call, click on the \"START CONFERENCE\" button at the bottom of the main window. At this point you and your called party will now be in a conference room. If for any reason you are disconnected from your call you just need to dial into the conference by dialing the 7 digit number located next to the \"local conference extension\" field. At this point you must put your first call \"Channel A\" on hold by pressing the \"PARK\" button on the first row, then putting the next number you want to conference in into the \"Channel B\"  Dial field and clicking on the \"Dial\" button in the second row. After the Zap/IAX channel number appears in the \"Channel B\" field you can then park that call and make another or you can click on the \"JOIN\" button of the other call(s) you have on hold to bring them into the conference. When you are done with the conference call, just click on the \"Stop Conference\" button to hang up on the conference call lines\n\nCALL RECORDING:\nOnce you are on a live call with an outside line you will be able to click on the \"START RECORDING\" button. When you click on this button you will notice a filename appear in the \"RECORDING FILENAME:\" field and a message above that saying that recording has started. Once you are finished recording you can click on the \"STOP RECORDING\" button and the recording ID will appear. If the phone call ends before you stop recording, the recording is stopped automatically and you will not see the recording ID, Don't worry though because the recording can always be retrieved with the filename.\nNote for recording in a conference: Recording from within a conference call is limited to one hour per recording.\n\nHANGING UP A ZAP/IAX OR SIP/Local CHANNEL:\nIt may be necessary for you to hang up a live channel. to do this simply click on the \"Trunk Hangup\" or \"Local Hangup\" button, select the channel that you want to hangup from the list then click on the \"Hangup SIP Line\" or \"Hangup Zap/IAX Line\" button to hang up the line. If you want to hang up another line right away simply click the \"Refresh List\" button to refresh the channel list and then hangup another channel. To get back to the main window click on the \"BACK TO MAIN\" button\n\nMONITORING A ZAP CHANNEL FROM GUI:\nMake sure that your phone is on hook, then select the extension name of the phone you want to monitor and click on the \"Monitor\" button at the bottom of that column. The phone will then ring and you will be listening in on that conversation.\n\nSWITCHING PHONE IDs:\nSelect the extension name of the phone you want to assume control for in the \"Live Extensions\" column and click on the \"SWITCH YOUR ID\" button at the bottom of that column. You will then be in control of that phone and can dial number, start and stop recording and enter conferences for that phone.\n\nINTRASYSTEM CALL:\nTo call a phone listed in the \"Live Extensions\" listbox, simply click on one of them, make sure your phone is on-hook and click on the \"Intrasystem Call\" button. \n\nBLIND INTERNAL XFER:\nTo transfer the call that you are currently on directly to another internal extension simply click on one of the phones listed in the \"Live Extensions\" listbox that you want to transfer to the voicemail box of, and click on the \"Blind Internal Xfer\" button. \n\nBLIND VOICEMAIL XFER:\nTo transfer the call that you are currently on directly to a specific voicemail box simply click on one of the phones listed in the \"Live Extensions\" listbox that you want to transfer to the voicemail box of, and click on the \"Blind Voicemail Xfer\" button. \n\nBLIND EXTERNAL XFER:\nTo transfer the call that you are currently on directly to an external phone, then type the number that you would like to dial in the entry field DIRECTLY below the \"Outside number to dial:\" text in the middle column using the proper format for where you want to call:\n     - Local calls in this area code dial only 7 digits (5551212)\n     - Long Distance calls in the US/Canada/Mexico/Central America\n       dial only 10 digits (3125551212)\n     - UK calls dial 8 + 10 digit number (81235551212)\n     - Australia dial only the 9 digit phone number (312555121), and click on the \"Blind External Xfer\" button. \n\nPARKING A CALL:\nTo park a call in the GUI while you are on a live external line, simply click on the \"Park This Call\" button. Your call will then be directed to on-hold music and will be automatically hung up on when the on-hold loop is up on 30 minutes. \n\nRETRIEVING A PARKED CALL:\nTo retrieve a parked call that has been parked by the GUI make sure that your phone is on-hook and click on the \"View Parked Calls\" button to go to a screen of currently parked calls. Just select one of the calls by clicking on it and then click on the \"Grab Parked Line\" button to have the call directed to your phone.
	");
	my $help_scroll = $help_dialog->Scrollbar(-command => ['yview', $help_window_text]);
	$help_window_text->configure(-yscrollcommand => ['set', $help_scroll]);
	$help_window_text->pack(-side => 'right', -fill => 'both', -expand => '1');
	$help_scroll->pack(-side => 'right', -fill => 'y');
	$help_window_text->GotoLineNumber(1);

    $help_dialog->Show;  
}


##########################################
### Switch Login ID to select value in phone list box
##########################################
sub Switch_Your_ID 
{
$subroutine = 'Switch_Your_ID';

if (!$enable_persistant_mysql)	{&connect_to_db;}

	my $login = $login_value->get;
    my $new_ID = $SIP_user_list->get('active');
		$new_ID =~ s/ - .*//gi;
		$SIP_user = $new_ID;
		$protocol = '';
		$stmt = "SELECT protocol,fullname FROM phones where server_ip = '$server_ip' and extension = '$new_ID'";
		$dbh->query("$stmt");
				$event_string = "SUBRT|Switch_Your_ID|$stmt|";
			 event_logger;
		if ($dbh->has_selected_record)
			{
			$iter=$dbh->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$protocol = "$record->[0]";
				$USER_name = "$record->[1]";
				print STDERR "\n|$protocol|$USER_name|\n";
			   } 
			}

		if (!$enable_persistant_mysql)	{$dbh->close;}

			$login_value->delete('0', 'end');
			$login_value->insert('0', "$protocol/$new_ID");

	&get_recent_dialed_numbers;

	my $dialog = $MW->DialogBox( -title   => "Your ID Switch",
                                 -buttons => [ "OK" ],
				);
    $dialog->add("Label", -text => "your ID has been switched\n FROM: $login\n TO: $protocol/$new_ID  - $USER_name")->pack;
    $dialog->Show;
}







##########################################
### get the list of active online Zap T1 channels and IAX VOIP channels from the database(trunks)
##########################################
sub get_online_channels
{

if ($open_dialpad_window_again)
	{
	$open_dialpad_window_again = 0;
	&dtmf_dialpad_window;
	}

$subroutine = 'get_online_channels';

	$callerID_uniqueID='';
	$callerID_CallerID='';
	$callerID_Channel='';
	$callerID_Time='';
	$SIP_user = $login_value->get;
	$SIP_abb = $SIP_user;
	$IAX_user = $SIP_abb;
	$IAX_user =~ s/\@.*$//gi;
	$SIP_abb =~ s/SIP\/|IAX2\/|Zap\///gi;
		if ($SIP_user =~ /^SIP\//)  {$protocol = 'SIP';}
		if ($SIP_user =~ /^IAX2\//) {$protocol = 'IAX2';}
		if ($SIP_user =~ /^Zap\//)  {$protocol = 'Zap';}

	$conf_SIP_abb = $SIP_abb;
	if ($CONF_DIAL) {$SIP_abb = $NEW_conf;}

	$DBchannels[0]='';
	$channel_counter=0;

		&current_datetime;

		$time_value->delete('0', 'end');
		$time_value->insert('0', $displaydate);


if (!$enable_persistant_mysql)	{&connect_to_db;}

	##### CONF LINE UNIQUEID LOOKUP #####
	if ($LookupID_and_log =~ /[A-G]/)
	{
	$OUTuniqueid ='';
	$stmt = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$OUTqueryCID' and status='UPDATED' and (channel LIKE \"Zap%\" or channel LIKE \"IAX2%\")";
	$dbh->query("$stmt");
			$event_string = "SUBRT|call_next_number|CN|$stmt|";
		 event_logger;

	if ($dbh->has_selected_record)
		{
		$iter=$dbh->create_record_iterator;
		   while ( $record = $iter->each)
		   {
			$OUTcustomer_zap_channel = "$record->[0]";
			$OUTuniqueid = "$record->[1]";
			print STDERR "\n|$OUTuniqueid|$OUTcustomer_zap_channel|\n";
		   } 
		}
	$stmt = "SELECT channel,uniqueid FROM call_log where server_ip = '$server_ip' and caller_code = '$OUTqueryCID'";
	$dbh->query("$stmt");
			$event_string = "SUBRT|call_next_number|CN|$stmt|";
		 event_logger;

	if ($dbh->has_selected_record)
		{
		$iter=$dbh->create_record_iterator;
		   while ( $record = $iter->each)
		   {
			$LCuniqueid = "$record->[1]";
			print STDERR "\n|$LCuniqueid|call_log_entry|\n";
		   } 
		}

		if ($OUTuniqueid =~ /\d/)
		{
			@OUTuniqueid_DC = split(/\./, $OUTuniqueid); 
		if ($OUTuniqueid_DC[1] =~ /9$/) {$OUTuniqueid_DC[1] = ($OUTuniqueid_DC[1] + 1);}
		if ($OUTuniqueid_DC[1] =~ /1$/) {$OUTuniqueid_DC[1] = ($OUTuniqueid_DC[1] - 1);}
			@LCuniqueid_DC = split(/\./, $LCuniqueid); 
		if ($LCuniqueid_DC[1] =~ /9$/) {$LCuniqueid_DC[1] = ($LCuniqueid_DC[1] + 1);}
		if ($LCuniqueid_DC[1] =~ /1$/) {$LCuniqueid_DC[1] = ($LCuniqueid_DC[1] - 1);}
			$LC_diff = ($OUTuniqueid_DC[1] - $LCuniqueid_DC[1]);
			$half_LC_diff = ($LC_diff / 2);
		$NEWuniqueid_IT = ($OUTuniqueid_DC[1] - $half_LC_diff);
		$NEWuniqueid_DC = "$OUTuniqueid_DC[0].$NEWuniqueid_IT";
		print STDERR "\n|$LC_diff|$half_LC_diff|$NEWuniqueid_DC|\n";

		$OUTnumber_to_dial =~ s/^91|^9//gi;
		$stmt = "INSERT INTO call_log (uniqueid,channel,channel_group,type,server_ip,extension,number_dialed,caller_code,start_time,start_epoch,length_in_sec,length_in_min) values('$NEWuniqueid_DC','$OUTcustomer_zap_channel','Outbound CONF $LookupID_and_log','Zap','$server_ip','$conf_SIP_abb','$OUTnumber_to_dial','$OUTqueryCID','$SQLdate','$secX','60','1')";
			if($DB){print STDERR "\n|$stmt|\n";}
		$dbh->query($stmt)  or die  "Couldn't execute query: |$stmt|\n";
		}
	$LookupID_and_log = '';
	}

	##### CHECK VOICEMAIL MESSAGES #####
	if ($voicemail_button_enabled)
	{
	  $dbh->query("SELECT messages,old_messages FROM phones where server_ip='$server_ip' and extension='$SIP_abb' limit 1");
	   if ($dbh->has_selected_record)
		{
	   $iter=$dbh->create_record_iterator;
		$sipgrab_counter=0;
		   while ( $record = $iter->each)
			{
				$QWY_messages = "$record->[0]";
				$QWY_old_messages = "$record->[1]";
	#			print STDERR "VOICEMAIL     NEW: $QWY_messages     OLD: $QWY_old_messages\n";
				if ( ($QWY_messages eq $VM_messages) && ($QWY_old_messages eq $VM_old_messages) && ($VM_detech_run_first) )
					{
					# do nothing, messages agree
					}
				else
					{
					$VM_messages = $QWY_messages;
					$VM_old_messages = $QWY_old_messages;
					$QWY_messages = sprintf("%03s", $QWY_messages);	while (length($QWY_messages) > 3) {chop($QWY_messages);}
					$QWY_old_messages = sprintf("%03s", $QWY_old_messages);	while (length($QWY_old_messages) > 3) {chop($QWY_old_messages);}
					@VM_new_char = split(//, $QWY_messages); 
						if ($VM_new_char[1] eq ' ') {$VM_new_char[1]='0';}
						if ($VM_new_char[2] eq ' ') {$VM_new_char[2]='0';}
					@VM_old_char = split(//, $QWY_old_messages);
						if ($VM_old_char[1] eq ' ') {$VM_old_char[1]='0';}
						if ($VM_old_char[2] eq ' ') {$VM_old_char[2]='0';}

					if ($QWY_messages > 0)
						{
						$vm_ind_anim->start_animation(500);
						$vm_ind_anim->set_image(0);
						}
					else
						{
						$vm_ind_anim->stop_animation(0);
						$vm_ind_anim->set_image(0);
						}
					$vm_new_1_anim->set_image($VM_new_char[0]);
					$vm_new_2_anim->set_image($VM_new_char[1]);
					$vm_new_3_anim->set_image($VM_new_char[2]);
					$vm_old_1_anim->set_image($VM_old_char[0]);
					$vm_old_2_anim->set_image($VM_old_char[1]);
					$vm_old_3_anim->set_image($VM_old_char[2]);

					$VM_detech_run_first=1;
					}

#				print STDERR "New Incoming Call: $record->[2]|$callerID_uniqueID|\n\n";
			}
		}

	}



	if ($CallerID_popup_enabled)
	{
	  $dbh->query("SELECT uniqueid,channel,caller_id,start_time,phone_ext,server_ip,extension,inbound_number,comment_a,comment_b,comment_c,comment_d,comment_e FROM live_inbound where server_ip='$server_ip' and phone_ext='$SIP_abb' and acknowledged='N' order by start_time desc limit 1");
	   if ($dbh->has_selected_record)
		{
	   $iter=$dbh->create_record_iterator;
		$sipgrab_counter=0;
		   while ( $record = $iter->each)
			{
				$callerID_CallerID = "$record->[2]";
				$callerID_uniqueID = "$record->[0]";
				$callerID_Channel = "$record->[1]";
				$callerID_Time = "$record->[3]";
				$callerID_phone_ext = "$record->[4]";
				$callerID_server_ip = "$record->[5]";
				$callerID_extension = "$record->[6]";
				$callerID_inbound_number = "$record->[7]";
				$callerID_comment_a = "$record->[8]";
				$callerID_comment_b = "$record->[9]";
				$callerID_comment_c = "$record->[10]";
				$callerID_comment_d = "$record->[11]";
				$callerID_comment_e = "$record->[12]";
				print STDERR "New Incoming Call: $record->[2]|$callerID_uniqueID|\n\n";
			}
		}

	if (length($callerID_uniqueID)>0)
		{

		$callerID_areacode = substr($callerID_CallerID,0,3);
		$callerID_prefix = substr($callerID_CallerID,3,3);
		$callerID_last4 = substr($callerID_CallerID,6,4);

		$stmt = "UPDATE live_inbound set acknowledged='Y' where uniqueid='$callerID_uniqueID'";
		$dbh->query($stmt)  or die  "Couldn't execute query:\n";


		if (!$callerID_window_open)
			{
		#	$callerID_window_open=1;

			my $dialog_new_call = $MW->DialogBox( -title   => "New Incoming Call- FROM: $callerID_CallerID   TO: $callerID_inbound_number",
							 -buttons => [ "Close" ],
							 -background => '#CCCCFF',
			);

			my $list_CID_frame = $dialog_new_call->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			### list box for current phones that are on live calls right now
			my $CID_select_list = $list_CID_frame->Listbox(-relief => 'sunken', 
									 -width => 40, # Shrink to fit
									 -font => 'Courier',
									 -background => 'white',
									 -selectmode => 'single',
									 -exportselection => 0,
									 -height => 11,
									 -setgrid => 'yes');
			foreach (@items) {$CID_select_list->insert('end', $_);}
			my $scrollCID = $list_CID_frame->Scrollbar(-command => ['yview', $CID_select_list]);
			$CID_select_list->configure(-yscrollcommand => ['set', $scrollCID]);
			$CID_select_list->pack(-side => 'right', -fill => 'both', -expand => 'yes');
			$scrollCID->pack(-side => 'left', -fill => 'y');
			$CID_select_list->selectionSet('0');
			$CID_select_list->delete('0', 'end');

			$CID_select_list -> insert("0","FROM:      $callerID_CallerID");
			$CID_select_list -> insert("1","TO:        $callerID_inbound_number");
			$CID_select_list -> insert("2","CHANNEL:   $callerID_Channel");
			$CID_select_list -> insert("3","DATE/TIME: $callerID_Time");
			$CID_select_list -> insert("4","DID/EXTEN: $callerID_extension");
			$CID_select_list -> insert("5","PHONE/EXT: $callerID_phone_ext");
			$CID_select_list -> insert("6","$callerID_comment_a");
			$CID_select_list -> insert("7","$callerID_comment_b");
			$CID_select_list -> insert("8","$callerID_comment_c");
			$CID_select_list -> insert("9","$callerID_comment_d");
			$CID_select_list -> insert("10","$callerID_comment_e");
			$CID_select_list -> insert("11","UNIQUEID: $callerID_uniqueID");
			$CID_select_list -> insert("12","SERVERIP: $callerID_server_ip");


			my $button_CID_frame = $dialog_new_call->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $CID_internal_button = $button_CID_frame->Button(-text => 'INTERNAL', -width => -1,-background => '#FFCCCC',
						-command => sub {	
				$callerID_CallerID = $CID_select_list -> get('0');  $callerID_CallerID =~ s/^.*: *//gi;
					$callerID_areacode = substr($callerID_CallerID,0,3);
					$callerID_prefix = substr($callerID_CallerID,3,3);
					$callerID_last4 = substr($callerID_CallerID,6,4);
				$callerID_inbound_number = $CID_select_list -> get('1');  $callerID_inbound_number =~ s/^.*: *//gi;
				$callerID_Channel = $CID_select_list -> get('2');  $callerID_Channel =~ s/^.*: *//gi;
				$callerID_Time = $CID_select_list -> get('3');  $callerID_Time =~ s/.*TIME: *//gi;
				$callerID_extension = $CID_select_list -> get('4');  $callerID_extension =~ s/^.*: *//gi;
				$callerID_phone_ext = $CID_select_list -> get('5');  $callerID_phone_ext =~ s/^.*: *//gi;
				$callerID_uniqueID = $CID_select_list -> get('11');  $callerID_uniqueID =~ s/^.*: *//gi;
				$callerID_server_ip = $CID_select_list -> get('12');  $callerID_server_ip =~ s/^.*: *//gi;
				$callerID_comment_a = $CID_select_list -> get('6');
				$callerID_comment_b = $CID_select_list -> get('7');
				$callerID_comment_c = $CID_select_list -> get('8');
				$callerID_comment_d = $CID_select_list -> get('9');
				$callerID_comment_e = $CID_select_list -> get('10');

				&create_callerID_local_query_string;

				$url="$local_web_callerID_URL$local_web_callerID_QUERY_STRING";
				print STDERR "$url\n";
							LaunchBrowser_New();
							});
			$CID_internal_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

			my $CID_google_button = $button_CID_frame->Button(-text => 'GOOGLE', -width => -1,-background => '#FFCCCC',
						-command => sub {
				$callerID_CallerID = $CID_select_list -> get('0');  $callerID_CallerID =~ s/^.*: *//gi;
					$callerID_CallerID =~ s/^.*\<|\>.*$//gi;
					$callerID_areacode = substr($callerID_CallerID,0,3);
					$callerID_prefix = substr($callerID_CallerID,3,3);
					$callerID_last4 = substr($callerID_CallerID,6,4);
				$url="http://www.google.com/search?hl=en&lr=&ie=ISO-8859-1&q=$callerID_areacode $callerID_prefix $callerID_last4";
							LaunchBrowser_New();
							});
			$CID_google_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

			my $CID_phnnum_button = $button_CID_frame->Button(-text => "PHONE-\nNUMBER\n.COM", -width => -1,-background => '#FFCCCC',
						-command => sub {
				$callerID_CallerID = $CID_select_list -> get('0');  $callerID_CallerID =~ s/^.*: *//gi;
					$callerID_CallerID =~ s/^.*\<|\>.*$//gi;
					$callerID_areacode = substr($callerID_CallerID,0,3);
					$callerID_prefix = substr($callerID_CallerID,3,3);
					$callerID_last4 = substr($callerID_CallerID,6,4);
				$url="http://www.phonenumber.com/10006/search/Reverse_Phone?npa=$callerID_areacode&phone=$callerID_prefix$callerID_last4";
							LaunchBrowser_New();
							});
			$CID_phnnum_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

			my $CID_spwhite_button = $button_CID_frame->Button(-text => "S-PAGES\nWHITE", -width => -1,-background => '#FFCCCC',
						-command => sub {
				$callerID_CallerID = $CID_select_list -> get('0');  $callerID_CallerID =~ s/^.*: *//gi;
					$callerID_CallerID =~ s/^.*\<|\>.*$//gi;
					$callerID_areacode = substr($callerID_CallerID,0,3);
					$callerID_prefix = substr($callerID_CallerID,3,3);
					$callerID_last4 = substr($callerID_CallerID,6,4);
				$url="http://directory.superpages.com/wp/results.jsp?SRC=&STYPE=WR&PS=15&PI=1&A=$callerID_areacode&X=$callerID_prefix&P=$callerID_last4&search=Find";
							LaunchBrowser_New();
							});
			$CID_spwhite_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

			my $CID_spyellow_button = $button_CID_frame->Button(-text => "S-PAGES\nYELLOW", -width => -1,-background => '#FFCCCC',
						-command => sub {
				$callerID_CallerID = $CID_select_list -> get('0');  $callerID_CallerID =~ s/^.*: *//gi;
					$callerID_CallerID =~ s/^.*\<|\>.*$//gi;
					$callerID_areacode = substr($callerID_CallerID,0,3);
					$callerID_prefix = substr($callerID_CallerID,3,3);
					$callerID_last4 = substr($callerID_CallerID,6,4);
				$url="http://yellowpages.superpages.com/listings.jsp?SRC=&STYPE=AP&PG=L&PP=N&CB=&A=$callerID_areacode&X=$callerID_prefix&P=$callerID_last4&PS=45&search=Find+It";
							LaunchBrowser_New();
							});
			$CID_spyellow_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

			my $CID_anywho_button = $button_CID_frame->Button(-text => "ANYWHO", -width => -1,-background => '#FFCCCC',
						-command => sub {
				$callerID_CallerID = $CID_select_list -> get('0');  $callerID_CallerID =~ s/^.*: *//gi;
					$callerID_CallerID =~ s/^.*\<|\>.*$//gi;
					$callerID_areacode = substr($callerID_CallerID,0,3);
					$callerID_prefix = substr($callerID_CallerID,3,3);
					$callerID_last4 = substr($callerID_CallerID,6,4);
				$url="http://www.anywho.com/qry/wp_rl?npa=$callerID_areacode&telephone=$callerID_prefix$callerID_last4&btnsubmit.x=19&btnsubmit.y=8";
							LaunchBrowser_New();
							});
			$CID_anywho_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

			my $CID_result = $dialog_new_call->Show;
				if ($CID_result =~ /Close/i)
					{
					$callerID_window_open=0;
					print STDERR "CallerID window closed\n";
					}


			}


		}

	}


if($sip_frame_list_refresh)
	{
	$live_sip_hangup->delete('0', 'end');
	
	  $dbh->query("SELECT channel,extension FROM $live_sip_channels where server_ip = '$server_ip' order by channel desc");
	   if ($dbh->has_selected_record)
		{
	   $iter=$dbh->create_record_iterator;
		$sipgrab_counter=0;
		   while ( $record = $iter->each)
			{
			$DBsiplist[$sipgrab_counter] = "$record->[0]$US$record->[1]";
			$sipgrab_counter++;
			}
		}

		$backwards_count = $#DBsiplist;
		while ($backwards_count >= 0)
		{		
		$live_sip_hangup -> insert("0","$DBsiplist[$backwards_count]");
		$backwards_count--;
		}

		@DBsiplist = @MT;

		$sip_frame_list_refresh=0;
	}



if($zap_frame_list_refresh)		{$live_zap->delete('0', 'end');}
if($zap_frame_list_refresh)		{$live_ext->delete('0', 'end');}
		if ($zap_frame_list_refresh) {$live_zap_hangup->delete('0', 'end');}

			if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' order by extension desc|\n";}

	   $dbh->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' order by extension desc");
	   if ($dbh->has_selected_record)
		{
	   $iter=$dbh->create_record_iterator;
		$rec_count=0;
		$channel_set=0;
		   while ( $record = $iter->each)
			{
			   if($DB){print STDERR $record->[0],"|", $record->[1],"\n";}
			$DBchannels[$channel_counter] = "$record->[0]$US$record->[1]";
			$DBzaplist[$channel_counter] = "$record->[0]$US$record->[1]";
			$DBphonelist[$channel_counter] = "$record->[1]";

if($zap_frame_list_refresh)		{$live_zap->insert('0', "$DBchannels[$channel_counter]");}
if($zap_frame_list_refresh)		{$live_ext->insert('0', "$DBphonelist[$channel_counter]");}
				
			   if ($zap_frame_list_refresh) {$live_zap_hangup->insert('0', "$DBchannels[$channel_counter]");}
			   $LIVE_SIP_TEST = "/$record->[1]";	$DO = '-1';
			   $LIVE_Zap_TEST = "/$record->[1]$DO";
			   if ( ($LIVE_SIP_TEST =~ /\/$SIP_abb$|\/$SIP_abb\&|\/$SIP_abb\/|\/$SIP_abb\@$SIP_abb\//) 
				   or ( ($CONF_DIAL) && ($record->[1] =~ /$NEW_conf/) ) 
				   or ( ($protocol eq 'IAX2') && ($LIVE_SIP_TEST =~ /\/$IAX_user\//) )
				   or ( ($protocol eq 'Zap') && ($LIVE_Zap_TEST =~ /\/$SIP_abb$/) ) )
				{
				$channel_value->delete('0', 'end');
				$channel_value->insert('0', $record->[0]);
				$channel_set=1;
				if (!$record_channel)
					{
					$start_recording->configure(-state => 'normal');
					$start_rec_gif_anim->set_image(3);
					$dial_outside_number->configure(-state => 'disabled');
					$dial_out_gif_anim->set_image(2);
					$xfer_outside_number->configure(-state => 'normal');
					$xfer_out_gif_anim->set_image(15);
					$local_conf->configure(-state => 'disabled');
					$local_call_gif_anim->set_image(8);

					if ($admin_monitor_enabled)
						{
						$zap_monitor_button->configure(-state => 'disabled');
						}
					if ($conferencing_enabled)
						{
						$initiate_conference->configure(-state => 'normal');
						$start_conf_gif_anim->set_image(21);
						}
					if ($call_parking_enabled)
						{
						$view_park_button->configure(-state => 'disabled');
						$view_park_gif_anim->set_image(14);
						$call_park_button->configure(-state => 'normal');
						$call_park_gif_anim->set_image(11);
						$park_grab_button->configure(-state => 'disabled');
						$local_xfer->configure(-state => 'normal');
						$local_xfer_gif_anim->set_image(17);
						$vmail_xfer->configure(-state => 'normal');
						$vmail_xfer_gif_anim->set_image(19);
						}
					}
				if ($conf_dialing_mode)
					{
					if ($conf_dial_CHAN eq "A")
						{
						$conf_LIVE_channel_A->delete('0', 'end');
						$conf_LIVE_channel_A->insert('0', $record->[0]);
						$conf_dial_CHAN = '';
						}
					if ($conf_dial_CHAN eq "B")
						{
						$conf_LIVE_channel_B->delete('0', 'end');
						$conf_LIVE_channel_B->insert('0', $record->[0]);
						$conf_dial_CHAN = '';
						$LookupID_and_log = 'B';
						}
					if ($conf_dial_CHAN eq "C")
						{
						$conf_LIVE_channel_C->delete('0', 'end');
						$conf_LIVE_channel_C->insert('0', $record->[0]);
						$conf_dial_CHAN = '';
						$LookupID_and_log = 'C';
						}
					if ($conf_dial_CHAN eq "D")
						{
						$conf_LIVE_channel_D->delete('0', 'end');
						$conf_LIVE_channel_D->insert('0', $record->[0]);
						$conf_dial_CHAN = '';
						$LookupID_and_log = 'D';
						}
					if ($conf_dial_CHAN eq "E")
						{
						$conf_LIVE_channel_E->delete('0', 'end');
						$conf_LIVE_channel_E->insert('0', $record->[0]);
						$conf_dial_CHAN = '';
						$LookupID_and_log = 'E';
						}
					if ($conf_dial_CHAN eq "F")
						{
						$conf_LIVE_channel_F->delete('0', 'end');
						$conf_LIVE_channel_F->insert('0', $record->[0]);
						$conf_dial_CHAN = '';
						$LookupID_and_log = 'F';
						}

					}
				}

			$channel_counter++;
		   $rec_count++;
			} 
			   if (!$channel_set)
				{
				$channel_value->delete('0', 'end');
				$start_recording->configure(-state => 'disabled');
				$start_rec_gif_anim->set_image(4);
				$dial_outside_number->configure(-state => 'normal');
				$dial_out_gif_anim->set_image(1);
				$xfer_outside_number->configure(-state => 'disabled');
				$xfer_out_gif_anim->set_image(16);
				$local_conf->configure(-state => 'normal');
				$local_call_gif_anim->set_image(7);

				if ($admin_monitor_enabled)
					{
					$zap_monitor_button->configure(-state => 'normal');
					}
				else {$zap_monitor_button->configure(-state => 'disabled');}
				if ($conferencing_enabled)
					{
					$initiate_conference->configure(-state => 'disabled');
					$start_conf_gif_anim->set_image(22);
					}
				if ($call_parking_enabled)
					{
					$view_park_button->configure(-state => 'normal');
					$view_park_gif_anim->set_image(13);
					$call_park_button->configure(-state => 'disabled');
					$call_park_gif_anim->set_image(12);
					$park_grab_button->configure(-state => 'normal');
					$local_xfer->configure(-state => 'disabled');
					$local_xfer_gif_anim->set_image(18);
					$vmail_xfer->configure(-state => 'disabled');
					$vmail_xfer_gif_anim->set_image(20);
					}
				}
		}

		if ($updater_check_enabled)
			{
			$dbh->query("SELECT last_update FROM $server_updater where server_ip = '$server_ip'");
			if ($dbh->has_selected_record)
				{
			   $iter=$dbh->create_record_iterator;
				   while ( $record = $iter->each)
					{
						$new_updater = $record->[0];
						if ($updater_duplicate_value eq $new_updater) {$updater_duplicate_counter++;}
						else {$updater_duplicate_value = $new_updater;   $updater_duplicate_counter=0;   $updater_warning_up=0;}

					   if($DB){print STDERR "|$new_updater|$updater_duplicate_value|$updater_duplicate_counter|$updater_warning_up|\n";}

					} 
				}

			if ($updater_duplicate_counter > 20)
				{
				$time_value->delete('0', 'end');
				$time_value->insert('0', "SQL Updater DOWN!!!");

				if (!$updater_warning_up)
					{
					print STDERR "\n\nUpdater down!!!\n\n";
					$updater_warning_up=1;

					my $dialog_down = $MW->DialogBox( -title   => "ALERT !!!",
												 -buttons => [ "OK" ],
								);
					$dialog_down->add("Label", -text => "SQL Updater DOWN!!!   $updater_duplicate_value")->pack;
					$dialog_down->Show;  
					}

				}


			}


	######################################################################################
	##### validate and repopulate the phones listbox so that scrolling is unaffected #####
    $ACTIVE_phone = $live_ext->get('active');
	if (!$ACTIVE_phone) {$ACTIVE_phone = 'X';}
	$ACTIVE_phone_set=0;
	$ACTIVE_phone_count='';

	$ycount=0;
	$backwards_count = $#DBphonelist;
	while ($backwards_count >= 0)
	{
	
	$live_ext -> insert("$ycount","$DBphonelist[$backwards_count]");
	$live_ext -> delete(($ycount + 1));
	if ( ($DBphonelist[$backwards_count] eq $ACTIVE_phone) && (!$ACTIVE_phone_set) )
		{
		$ACTIVE_phone_set=1;
		$ACTIVE_phone_count="$ycount";
		}

	$ycount++;
	$backwards_count--;
	}

	@LBphonelist = $live_ext -> get('0','end');

	if ($#LBphonelist > $#DBphonelist)
		{
		$DELETE_phonelist_difference = ($#LBphonelist - $#DBphonelist);
		$live_ext -> delete("$ycount",($ycount + $DELETE_phonelist_difference));
		}

	if ($ACTIVE_phone_set)
		{
		$live_ext->activate("$ACTIVE_phone_count");
		$live_ext->selectionSet("$ACTIVE_phone_count");
	#	print "|$ACTIVE_phone|$ACTIVE_phone_set|$ACTIVE_phone_count|";

	#	$ACTIVE_phone = $live_ext->get('active');
	#	print "    |$ACTIVE_phone|\n";
		}
	else
		{
		$live_ext->selectionClear(0,'end');
		}

	@DBphonelist = @MT;
	@LBphonelist = @MT;


	########################################################################################
	##### validate and repopulate the channels listbox so that scrolling is unaffected #####
 #   $ACTIVE_zap = $live_zap->get('active');
    $ACTIVE_zap = '';
	$ACTIVE_zap_set=0;
	$ACTIVE_zap_count='';

	$ycount=0;
	$backwards_count = $#DBzaplist;
	while ($backwards_count >= 0)
	{
	
	$live_zap -> insert("$ycount","$DBzaplist[$backwards_count]");
	$live_zap -> delete(($ycount + 1));
	if ( ($DBzaplist[$backwards_count] eq $ACTIVE_zap) && (!$ACTIVE_zap_set) )
		{
		$ACTIVE_zap_set=1;
		$ACTIVE_zap_count="$ycount";
		}

	$ycount++;
	$backwards_count--;
	}

	@LBzaplist = $live_zap -> get('0','end');

	if ($#LBzaplist > $#DBzaplist)
		{
		$DELETE_zaplist_difference = ($#LBzaplist - $#DBzaplist);
		$live_zap -> delete("$ycount",($ycount + $DELETE_zaplist_difference));
		}

#	if ($ACTIVE_zap_set)
#		{
#		$live_zap->activate("$ACTIVE_zap_count");
#		$live_zap->selectionSet("$ACTIVE_zap_count");
	#	print "|$ACTIVE_zap|$ACTIVE_zap_set|$ACTIVE_zap_count|";

#		$ACTIVE_zap = $live_zap->get('active');
	#	print "    |$ACTIVE_zap|\n";
#		}
#	else
#		{
#		$live_zap->selectionClear(0,'end');
#		}

	@DBzaplist = @MT;
	@LBzaplist = @MT;


	$zap_frame_list_refresh=0;






	########################################################################################
	##### validate and repopulate the sips/locals listbox so that scrolling is unaffected #####

   $dbh->query("SELECT channel,extension FROM $live_sip_channels where server_ip = '$server_ip' order by channel desc");
   if ($dbh->has_selected_record)
	{
   $iter=$dbh->create_record_iterator;
	$sipgrab_counter=0;
	   while ( $record = $iter->each)
		{
		$DBsiplist[$sipgrab_counter] = "$record->[0]$US$record->[1]";
		$sipgrab_counter++;

		if ( ($CONFERENCE_RECORDING) && ($record->[1] =~ /$NEW_conf/) )
			{

				$conf_rec_channel_value->delete('0', 'end');

			if ($DB) {print STDERR "RECORDING: |$NEW_conf|$record->[0]|$record->[1]|\n";}
		   if ( ($record->[0] =~ /Local\/$NEW_conf\@/) && ($record->[1] =~ /$NEW_conf/) )
				{
				$conf_rec_channel_value->insert('0', "$record->[0]");
				$CONFERENCE_RECORDING_CHANNEL = "$record->[0]";
				}
			}


		}
	}

		if (!$enable_persistant_mysql)	{$dbh->close;}

	$ycount=0;
	$backwards_count = $#DBsiplist;
	while ($backwards_count >= 0)
	{
	
	$live_sip -> insert("$ycount","$DBsiplist[$backwards_count]");
	$live_sip -> delete(($ycount + 1));

	$ycount++;
	$backwards_count--;
	}

	@LBsiplist = $live_sip -> get('0','end');

	if ($#LBsiplist > $#DBsiplist)
		{
		$DELETE_siplist_difference = ($#LBsiplist - $#DBsiplist);
		$live_sip -> delete("$ycount",($ycount + $DELETE_siplist_difference));
		}

	@DBsiplist = @MT;
	@LBsiplist = @MT;

	$sip_frame_list_refresh=0;

}



##########################################
### Get the current list of parked channels from the database
##########################################
sub get_parked_channels
{
$subroutine = 'get_parked_channels';

if ($park_frame_list_refresh)
	{

	if (!$enable_persistant_mysql)	{&connect_to_db;}

	$live_park_lines->delete('0', 'end');

   $dbh->query("SELECT channel,extension,parked_time,parked_by FROM $parked_channels where server_ip = '$server_ip' order by channel desc");
   if ($dbh->has_selected_record)
		{
	   $iterA=$dbh->create_record_iterator;
		 $rec_countA=0;
		   while ( $recordA = $iterA->each)
			{
			   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}
				$Pchannel = sprintf("%-80s", $recordA->[0]);	while (length($Pchannel) > 80) {chop($Pchannel);}
				$Pexten   = sprintf("%-5s", $recordA->[1]);		while (length($Pexten) > 5) {chop($Pexten);}
				$Ptime    = sprintf("%-20s", $recordA->[2]);	while (length($Ptime) > 20) {chop($Ptime);}
				$Ppark_by = sprintf("%-15s", $recordA->[3]);	while (length($Ppark_by) > 15) {chop($Ppark_by);}

			   $live_park_lines->insert('0', "$Pchannel - $Ppark_by - $Pexten - $Ptime");

			$phone_counter++;
		   $rec_countA++;
			} 
		}

		if (!$enable_persistant_mysql)	{$dbh->close;}
		$park_frame_list_refresh = 0;
	}
}



##########################################
### Get the current list of online SIP users from the database(clients)
##########################################
sub get_online_sip_users
{
$subroutine = 'get_online_sip_users';

$zap_frame_list_refresh=1;

if ($Default_window)
	{

	$DBphones[0]='';
	$channel_counter=0;

		&current_datetime;

		$time_value->delete('0', 'end');
		$time_value->insert('0', $displaydate);


	if (!$enable_persistant_mysql)	{&connect_to_db;}

		$SIP_user_list->delete('0', 'end');

			if($DB){print STDERR "\n|SELECT extension,fullname FROM phones where server_ip = '$server_ip' order by extension desc|\n";}

	   $dbh->query("SELECT extension,fullname FROM phones where server_ip = '$server_ip' order by extension desc");
	   if ($dbh->has_selected_record)
		{
	   $iterA=$dbh->create_record_iterator;
		 $rec_countA=0;
		   while ( $recordA = $iterA->each)
			{
			   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}
			$DBphones[$phone_counter] = "$recordA->[0] - $recordA->[1]";
			   $SIP_user_list->insert('0', "$recordA->[0] - $recordA->[1]");

			$phone_counter++;
		   $rec_countA++;
			} 
		}

		if (!$enable_persistant_mysql)	{$dbh->close;}
	}
}




##########################################
### Get the list of recently dialed outside numbers from the database
##########################################
sub get_recent_dialed_numbers
{
$subroutine = 'get_recent_dialed_numbers';

if ($Default_window)
	{

	$SIP_user = $login_value->get;
	$SIP_abb = $SIP_user;
	$SIP_abb =~ s/SIP\/|IAX2\/|Zap\///gi;

	@DBnumbers = @MT;
	$number_counter=0;
	$maxlist_reached=0;

		$recent_dial_listbox->delete('0', 'end');


	if (!$enable_persistant_mysql)	{&connect_to_db;}

		$stmtA='';
	if ($SIP_user =~ /^Zap/)
		{
		$stmtA = "SELECT distinct number_dialed,start_epoch FROM call_log where server_ip = '$server_ip' and (channel = '$SIP_user') order by uniqueid desc limit 50;";
		}
	if ($SIP_user =~ /^IAX2/)
		{
		$stmtA = "SELECT distinct number_dialed,start_epoch FROM call_log where server_ip = '$server_ip' and (channel LIKE \"$SIP_user\@$SIP_abb%\") order by uniqueid desc limit 50;";
		}
	if ($SIP_user =~ /^SIP/)
		{
		$stmtA = "SELECT distinct number_dialed,start_epoch FROM call_log where server_ip = '$server_ip' and (channel LIKE \"$SIP_user%\") order by uniqueid desc limit 50;";
		}
	if (length($stmtA) < 1)
		{
		$stmtA = "SELECT distinct number_dialed,start_epoch FROM call_log where server_ip = '$server_ip' and (channel = '$SIP_user' or channel LIKE \"$SIP_user%\" or channel LIKE \"$SIP_user\@$SIP_abb%\") order by uniqueid desc limit 50;";
		}

		print STDERR "\n|$stmtA|";

	   $dbh->query("$stmtA");
	   if ($dbh->has_selected_record)
		{
	   $iterA=$dbh->create_record_iterator;
		 $rec_countA=0;
		   while ( ( $recordA = $iterA->each) && (!$maxlist_reached) )
			{
			   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}

				$DBresult_number = "$recordA->[0]";

				$DBnumber_loop_counter=0;
				$duplicate=0;
				foreach(@DBnumbers)
					{
					if ($DBresult_number eq $DBnumbers[$DBnumber_loop_counter])
						{$duplicate++;}
					$DBnumber_loop_counter++;
					}
				if (!$duplicate)
					{
					$DBnumbers[$number_counter] = "$DBresult_number";
					$recent_dial_listbox->insert('end', $DBresult_number);
					$number_counter++;
					if ($number_counter > 19)
						{$maxlist_reached++;}
					}
		   $rec_countA++;
			} 
		}

		print STDERR "     |$rec_countA|\n";

	   $dbh->query("SELECT voicemail_id,dialplan_number FROM phones where server_ip = '$server_ip' and extension = '$SIP_abb';");
	   if ($dbh->has_selected_record)
		{
	   $iterA=$dbh->create_record_iterator;
		 $rec_countA=0;
		   while ($recordA = $iterA->each)
			{
			   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}

				$VMAILbox = "$recordA->[0]";
				$DPLANnumber = "$recordA->[1]";
		   $rec_countA++;
			} 
		}


		if (!$enable_persistant_mysql)	{$dbh->close;}
	}
}



##########################################
### Monitor a local Zap channel by selecting an active extension
##########################################
sub Zap_Monitor
{
$subroutine = 'Zap_Monitor';

$ext_compare_monitor = $live_ext->get('active');

$monitor_channel = '';

foreach my $x (@DBchannels)
{
	if (!$monitor_channel)
		{
		if ( ($x =~ /\_$ext_compare_monitor$/) && ($x !~ /^IAX/) )
			{
			$monitor_channel = $x;
			$monitor_channel =~ s/Zap\///gi;
			$monitor_channel =~ s/\-.*//gi;
			$monitor_channel   = sprintf("%03s", $monitor_channel);	while (length($monitor_channel) > 3) {chop($monitor_channel);}
			$monitor_channel = "$monitor_prefix$monitor_channel";
			print "|$x|$monitor_channel|\n";
			}
		}
}

if (length($monitor_channel) > 0)
	{
if ($monitor_channel =~ /^IAX/)
		{
		print "Monitor error: |channel:$channel|\n";

		my $dialog = $MW->DialogBox( -title   => "Channel Monitor Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to monitor is not Zap\n   |$channel|")->pack;
		$dialog->Show;  
		}
	else
		{

		$ACTION = 'Originate';
		$CIDcode = 'ZM';
		$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
		while (length($queryCID)>20) {chop($queryCID);}

		$cmd_line_b = "Channel: $SIP_user";
		$cmd_line_c = "Context: $ext_context";
		$cmd_line_d = "Exten: $monitor_channel";
		$cmd_line_e = "Priority: 1";
		$cmd_line_f = "Callerid: $queryCID";
		$cmd_line_g = "";
		$cmd_line_h = "";
		$cmd_line_i = "";
		$cmd_line_j = "";
		$cmd_line_k = "";

		$originate_command  = '';
		$originate_command .= "Action: $ACTION\n";
		$originate_command .= "$cmd_line_b\n";
		$originate_command .= "$cmd_line_c\n";
		$originate_command .= "$cmd_line_d\n";
		$originate_command .= "$cmd_line_e\n";
		$originate_command .= "$cmd_line_f\n";
		$originate_command .= "\n";

		$PROMPT = 'Response.*';

			if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
			else {&telnet_connect_and_send;}

		}
	}
}




##########################################
### local intrasystem call to another extension
##########################################
sub Dial_Number
{
$subroutine = 'Dial_Number';

    $DB_SIP_to_call = $SIP_user_list->get('active');
	$DB_SIP_to_call =~ s/ - .*$//gi;

	if (!$enable_persistant_mysql)	{&connect_to_db;}

   $dbh->query("SELECT dialplan_number FROM phones where server_ip='$server_ip' and extension='$DB_SIP_to_call' limit 1");
	   if ($dbh->has_selected_record)
	   {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - extension call sent to\n";
		   $SIP_extension_to_call = "$record->[0]";
		   $rec_count++;
		   } 
	   }
	if (!$enable_persistant_mysql)	{$dbh->close;}

	$ACTION = 'Originate';
	$CIDcode = 'LC';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $SIP_user";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $SIP_extension_to_call";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}




}




##########################################
### transfer a live Zap/IAX call to a local extension
##########################################
sub Local_Xfer
{
$subroutine = 'Local_Xfer';
	$blind_internal_xfer=0;

    $DB_SIP_to_call = $SIP_user_list->get('active');
	$DB_SIP_to_call =~ s/ - .*$//gi;

if (!$LOCAL_XFER) {$LOCAL_XFER = '-';}
if (length($LOCAL_XFER)>4) {$channel = $LOCAL_XFER;}
else {$channel = $channel_value->get;}

	$channel =~ s/Zap\/Zap\///gi;
	$local_xfer_channel = $channel;

	if (!$enable_persistant_mysql)	{&connect_to_db;}

   $dbh->query("SELECT dialplan_number FROM phones where server_ip='$server_ip' and extension='$DB_SIP_to_call' limit 1");
	   if ($dbh->has_selected_record)
	   {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - extension call sent to\n";
		   $SIP_extension_to_call = "$record->[0]";
		   $rec_count++;
		   } 
	   }
	if (!$enable_persistant_mysql)	{$dbh->close;}

	$ACTION = 'Redirect';
	$CIDcode = 'RX';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $channel";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $SIP_extension_to_call";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}

}





##########################################
### transfer a live Zap/IAX call to voicemailbox
##########################################
sub Voicemail_Xfer
{
$subroutine = 'Voicemail_Xfer';
	$blind_internal_xfer=0;

    $DB_SIP_to_call = $SIP_user_list->get('active');
	$DB_SIP_to_call =~ s/ - .*$//gi;

if (!$LOCAL_XFER) {$LOCAL_XFER = '-';}
if (length($LOCAL_XFER)>4) {$channel = $LOCAL_XFER;}
else {$channel = $channel_value->get;}

	$channel =~ s/Zap\/Zap\///gi;
	$local_xfer_channel = $channel;

	if (!$enable_persistant_mysql)	{&connect_to_db;}

   $dbh->query("SELECT voicemail_id FROM phones where server_ip='$server_ip' and extension='$DB_SIP_to_call' limit 1");
	   if ($dbh->has_selected_record)
	   {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - extension call sent to\n";
		   $SIP_extension_to_call = "$record->[0]";
		   $rec_count++;
		   } 
	   }
	if (!$enable_persistant_mysql)	{$dbh->close;}

	$ACTION = 'Redirect';
	$CIDcode = 'VX';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $channel";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $voicemail_dump_exten$SIP_extension_to_call";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

#	print STDERR "|$originate_command|\n";

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}

}





##########################################
### Dial and outside number on the users phone
##########################################
# This subroutine assumes calling from North America and will need to be changed
# if you are using caller rules outside of North America
sub Dial_Outside_Number
{
$subroutine = 'Dial_Outside_Number';

	$SIP_user = $login_value->get;
	$number_to_dial = $dial_number_value->get;
	if ($VM_button_dial)
		{
		$number_to_dial = $voicemail_exten;
		}
	if (!$number_to_dial)
		{
		$number_to_dial = $recent_dial_listbox->get('active');
		}
	
	$number_to_dial =~ s/\D//gi;

	### error box if improperly formatted number is entered
	if ( (length($number_to_dial) ne 3) && (length($number_to_dial) ne 4) && (length($number_to_dial) ne 7) && (length($number_to_dial) ne 9) && (length($number_to_dial) ne 10) && (length($number_to_dial) ne 11) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Number Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "Outside number to dial must be:\n- 4 digits for speed-dial\n- 7 digits for a local number\n- 9 digits for an AUSTRALIA number \n- 10 digits for a USA long distance number \n or 11 digits for a UK number\n   |$number_to_dial|")->pack;
		$dialog->Show;  
	}

	### place the phone call through the Manager interface of Asterisk
	else
	{



		$recent_dial_listbox->insert('0', $number_to_dial);
		$dial_number_value->delete('0', 'end');

		if (length($number_to_dial) == 7) 
			{$number_to_dial = "9$number_to_dial";}
		if (length($number_to_dial) == 10) 
			{
			if ($number_to_dial =~ /^813|^727/)	# force 10 digit dialing for local area codes, 11 digit for others
				{$number_to_dial = "9$number_to_dial";} 
			else
				{$number_to_dial = "91$number_to_dial";}
			}
		if (length($number_to_dial) == 9) 
			{$number_to_dial = "7$number_to_dial";}

	if ($xfer_out_blind)
		{
		$ACTION = 'Redirect';
		$channel = $channel_value->get;
		$channel =~ s/Zap\/Zap\///gi;
		$dial_out_channel = $channel;
		}
	else
		{
		$ACTION = 'Originate';
		$dial_out_channel = $SIP_user;
		}
	$CIDcode = 'CN';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	if ($VM_button_dial)
		{
		$VM_button_dial=0;
		$queryCID = $VMAILbox;
		}

	$cmd_line_b = "Channel: $dial_out_channel";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $number_to_dial";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}

	}

	$xfer_out_blind=0;
}




##########################################
### get the current date and time
##########################################
sub current_datetime
{
$subroutine = 'current_datetime';

$secX = time();
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = ($year + 1900);
	$CIDyear=($year-2000);
	$mon++;
	if ($mon < 10) {$mon = "0$mon";}
	if ($mday < 10) {$mday = "0$mday";}
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}
	if ($sec < 10) {$sec = "0$sec";}
	$filedate = "$year$mon$mday$DASH$hour$min$sec";
	$SQLdate = "$year-$mon-$mday $hour:$min:$sec";
	$displaydate = "   $year/$mon/$mday           $hour:$min:$sec";
	$CIDdate = "$CIDyear$mon$mday$hour$min$sec";
	$LOGdate = "$year-$mon-$mday";
}



##########################################
### Start recording - clicked on start recording button
##########################################
sub start_recording
{
$subroutine = 'start_recording';

$SIP_user = $login_value->get;
$ext = $SIP_user;
$ext =~ s/SIP\/|IAX2\/|Zap\///gi;
$filename = "$filedate$US$ext";

if (!$RECORD) {$RECORD = '-';}
if (length($RECORD)>4) {$channel = $RECORD;}
else {$channel = $channel_value->get;}

if ($channel =~ /^IAX/)
	{
	print "Recording error: |channel:$channel|\n";

	my $dialog = $MW->DialogBox( -title   => "Channel Recording Error",
								 -buttons => [ "OK" ],
				);
	$dialog->add("Label", -text => "The channel you are trying to record is not Zap\n I suggest going into a conference if you have to record this conversation   |$channel|")->pack;
	$dialog->Show;  
	}
else
	{

	$start_recording->configure(-state => 'disabled');
	$start_rec_gif_anim->set_image(4);
	$stop_recording->configure(-state => 'normal');
	$stop_rec_gif_anim->set_image(5);
	$initiate_conference->configure(-state => 'disabled');
	$start_conf_gif_anim->set_image(22);

	$channel =~ s/Zap\///gi;
	$record_channel = $channel;

	$ACTION = 'Monitor';
	$CIDcode = 'RB';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: Zap/$channel";
	$cmd_line_c = "File: $filename";
	$cmd_line_d = "";
	$cmd_line_e = "";
	$cmd_line_f = "";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}



	$rec_msg_value->delete('0', 'end');
    $rec_msg_value->insert('0', " - RECORDING - ");
	$rec_fname_value->delete('0', 'end');
    $rec_fname_value->insert('0', "$filename");
	$rec_recid_value->delete('0', 'end');

	$conf_rec_msg_value->delete('0', 'end');
    $conf_rec_msg_value->insert('0', " - RECORDING - ");
	$conf_rec_fname_value->delete('0', 'end');
    $conf_rec_fname_value->insert('0', "$filename");
	$conf_rec_recid_value->delete('0', 'end');


	if (!$enable_persistant_mysql)	{&connect_to_db;}

		$stmt = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('Zap/$channel','$server_ip','$SIP_user','$SQLdate','$secX','$filename')";
			if($DB){print STDERR "\n|$stmt|\n";}
		$dbh->query($stmt)  or die  "Couldn't execute query: $stmt\n";

	   $dbh->query("SELECT recording_id FROM recording_log where filename='$filename'");
	   if ($dbh->has_selected_record) {
	   $iter=$dbh->create_record_iterator;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $rec_recid_value->insert('0', "$recording_id");
		   $conf_rec_recid_value->insert('0', "$recording_id");
		   } 
	   }

	if (!$enable_persistant_mysql)	{$dbh->close;}

	print "|channel:$channel|$filename|\n";
	}

}


##########################################
### Stop recording - clicked on stop recording button
##########################################
sub stop_recording
{
$subroutine = 'stop_recording';

$SIP_user = $login_value->get;

	$channel = $channel_value->get;
	$channel =~ s/Zap\///gi;
	$record_channel = $channel;

if (length($record_channel)<1)
	{
	   print STDERR "STOP RECORDING ERROR: You are not connected to a channel\n";
	}
else
	{
	$ACTION = 'StopMonitor';
	$CIDcode = 'RE';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: Zap/$record_channel";
	$cmd_line_c = "";
	$cmd_line_d = "";
	$cmd_line_e = "";
	$cmd_line_f = "";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}
	}


	if (!$enable_persistant_mysql)	{&connect_to_db;}

	   $dbh->query("SELECT recording_id,start_epoch FROM recording_log where filename='$filename'");
	   if ($dbh->has_selected_record) {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $start_time = "$record->[1]";
		   $rec_count++;
		   } 
	   }

	if ($rec_count)
		{
		$length_in_sec = ($secX - $start_time);
		$length_in_min = ($length_in_sec / 60);
		$length_in_min = sprintf("%8.2f", $length_in_min);

		# print STDERR "\nQUERY done: start time = $start_time | sec: $length_in_sec | min: $length_in_min |\n";

		$stmt = "UPDATE recording_log set end_time='$SQLdate',end_epoch='$secX',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename'";

		#print STDERR "\n|$stmt|\n";
		$dbh->query($stmt)  or die  "Couldn't execute query:\n";
		}
	if (!$enable_persistant_mysql)	{$dbh->close;}

	print "|channel:$channel|$record_channel|$filename|\n";

	$rec_msg_value->delete('0', 'end');
    $rec_msg_value->insert('0', "Length: $length_in_min Min.");
	$rec_recid_value->delete('0', 'end');
    $rec_recid_value->insert('0', "$recording_id");

	$conf_rec_msg_value->delete('0', 'end');
    $conf_rec_msg_value->insert('0', "Length: $length_in_min Min.");
	$conf_rec_recid_value->delete('0', 'end');
    $conf_rec_recid_value->insert('0', "$recording_id");

$record_channel='';

$start_recording->configure(-state => 'normal');
$start_rec_gif_anim->set_image(3);
$stop_recording->configure(-state => 'disabled');
$stop_rec_gif_anim->set_image(6);
if ($conferencing_enabled)
	{
	$initiate_conference->configure(-state => 'normal');
	$start_conf_gif_anim->set_image(21);
	}



$REC_CHAN='';

}



##########################################
### Zap/IAX Hangup subroutine, launches Zap/IAX hangup window
##########################################
sub Zap_Hangup
{
$subroutine = 'Zap_Hangup';

	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1);

	$main_zap_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

	$zap_frame_list_refresh = 1;   

}

##########################################
### SIP Hangup subroutine, launches SIP/Local hangup window
##########################################
sub SIP_Hangup
{
$subroutine = 'SIP_Hangup';

	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1);

	$main_sip_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

	$zap_frame_list_refresh = 1;   

}


##########################################
### View_Parked subroutine, launches view parked calls window
##########################################
sub View_Parked
{
$subroutine = 'View_Parked';

	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>4, -y=>1);

	$main_park_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

	$park_frame_list_refresh = 1;   



}



















####################################################################################
####################################################################################
### Conferencing Subroutines
####################################################################################


##########################################
### Initiate a conference call
##########################################
sub Start_Conference 
{
$subroutine = 'Start_Conference';

	$CONF_DIAL = 1;
	$Default_window = 0;
    $SIP_user = $login_value->get;
	$LIVE_channel_A = $channel_value->get;

#$join_conference->configure(-state => 'normal');
$destroy_conference->configure(-state => 'normal');
$stop_conf_gif_anim->set_image(23);
$initiate_conference->configure(-state => 'disabled');
$start_conf_gif_anim->set_image(22);

$conf_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1);

	$conf_LIVE_channel_A->delete('0', 'end');
	$conf_LIVE_channel_A->insert('0', "$LIVE_channel_A");


	if (!$enable_persistant_mysql)	{&connect_to_db;}

		$SQLtalk_channel='';
		if ($SIP_user =~ /^SIP\//) 
			{$SQLtalk_channel = "channel LIKE \"$SIP_user$DASH\%\"";}
		if ($SIP_user =~ /^IAX2\//) 
			{
			if ($SIP_user =~ /\@/)
				{
				 $IAX_user = $SIP_abb;
				 $IAX_user =~ s/\@.*$//gi;
				$SQLtalk_channel = "(channel LIKE \"$SIP_user$SLASH\%\" or channel LIKE \"IAX2/$IAX_user$SLASH\%\")";
				}
			else 
				{
				$SQLtalk_channel = "(channel LIKE \"$SIP_user$SLASH\%\" or channel LIKE \"$SIP_user$AMP$SIP_abb$SLASH\%\")";
				}
			}
		if ($SIP_user =~ /^Zap\//) 
			{$SQLtalk_channel = "channel = '$SIP_user'";}

		$stmt = "SELECT channel FROM $live_sip_channels where server_ip = '$server_ip' and $SQLtalk_channel limit 9";
	#	   print STDERR "$stmt\n";

		$dbh->query("$stmt");
		if ($dbh->has_selected_record)
			{
			$iter=$dbh->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$sip_channel_active = "$record->[0]";
				   print STDERR $record->[0],"\n";
			   } 
			}


	   $dbh->query("SELECT conf_exten FROM conferences where server_ip='$server_ip' and (extension='' or extension is NULL) limit 1");
	   if ($dbh->has_selected_record)
	   {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - conference room\n";
		   $NEW_conf = "$record->[0]";
		   $rec_count++;
		   } 
	   }

	if ($rec_count)
		{
		$stmt = "UPDATE conferences set extension='$SIP_user' where server_ip='$server_ip' and conf_exten='$NEW_conf'";

		#print STDERR "\n|$stmt|\n";
		$dbh->query($stmt)  or die  "Couldn't execute query:\n";
		}
	if (!$enable_persistant_mysql)	{$dbh->close;}

	$ACTION = 'Redirect';
	$CIDcode = 'SC';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $LIVE_channel_A";
	$cmd_line_c = "ExtraChannel: $sip_channel_active";
	$cmd_line_d = "Exten: $NEW_conf";
	$cmd_line_e = "Context: $ext_context";
	$cmd_line_f = "Priority: 1";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}



	$conf_extension_value->insert('0', "$NEW_conf");
	$conf_sip_channel_value->insert('0', "$sip_channel_active");

}



##########################################
### Destroy a conference call
##########################################
sub Stop_Conference 
{
$subroutine = 'Stop_Conference';

    $SIP_user = $login_value->get;
	$LIVE_channel_A = $channel_value->get;
	$CONF_DIAL = 0;

	&conf_stop_recording;

$conf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1);

$main_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

	$Default_window = 1;
	$conf_dialing_mode = 0;
	$RECORD = '';
	$HANGUP = '';
	$DIAL = '';
	$PARK = '';
	$CHAN = '';
	$REC_CHAN='';

$destroy_conference->configure(-state => 'disabled');
$stop_conf_gif_anim->set_image(24);
$initiate_conference->configure(-state => 'disabled');
$start_conf_gif_anim->set_image(22);

$HANGUP = $conf_LIVE_channel_A->get; 
$HCT = '1';
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_B->get; 
$HCT = '2';
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_C->get; 
$HCT = '3';
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_D->get; 
$HCT = '4';
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_E->get; 
$HCT = '5';
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_F->get; 
$HCT = '6';
	&Hangup_Line;

	$conf_LIVE_channel_A->delete('0', 'end');
	$conf_LIVE_channel_B->delete('0', 'end');
	$conf_LIVE_channel_C->delete('0', 'end');
	$conf_LIVE_channel_D->delete('0', 'end');
	$conf_LIVE_channel_E->delete('0', 'end');
	$conf_LIVE_channel_F->delete('0', 'end');

	$conf_DIAL_channel_A->delete('0', 'end');
	$conf_DIAL_channel_B->delete('0', 'end');
	$conf_DIAL_channel_C->delete('0', 'end');
	$conf_DIAL_channel_D->delete('0', 'end');
	$conf_DIAL_channel_E->delete('0', 'end');
	$conf_DIAL_channel_F->delete('0', 'end');

	$conf_STATUS_channel_A->delete('0', 'end');
	$conf_STATUS_channel_B->delete('0', 'end');
	$conf_STATUS_channel_C->delete('0', 'end');
	$conf_STATUS_channel_D->delete('0', 'end');
	$conf_STATUS_channel_E->delete('0', 'end');
	$conf_STATUS_channel_F->delete('0', 'end');

	$conf_line_hangup_B->configure(-state => 'disabled');
	$conf_line_park_B->configure(-state => 'disabled');
	$conf_line_join_B->configure(-state => 'disabled');
	$conf_line_dial_B->configure(-state => 'normal');
	$conf_line_hangup_C->configure(-state => 'disabled');
	$conf_line_park_C->configure(-state => 'disabled');
	$conf_line_join_C->configure(-state => 'disabled');
	$conf_line_dial_C->configure(-state => 'normal');
	$conf_line_hangup_D->configure(-state => 'disabled');
	$conf_line_park_D->configure(-state => 'disabled');
	$conf_line_join_D->configure(-state => 'disabled');
	$conf_line_dial_D->configure(-state => 'normal');
	$conf_line_hangup_E->configure(-state => 'disabled');
	$conf_line_park_E->configure(-state => 'disabled');
	$conf_line_join_E->configure(-state => 'disabled');
	$conf_line_dial_E->configure(-state => 'normal');
	$conf_line_hangup_F->configure(-state => 'disabled');
	$conf_line_park_F->configure(-state => 'disabled');
	$conf_line_join_F->configure(-state => 'disabled');
	$conf_line_dial_F->configure(-state => 'normal');

	$conf_line_park_A->configure(-state => 'normal');
	$conf_line_join_A->configure(-state => 'disabled');
	$conf_line_hangup_A->configure(-state => 'normal');

	if (!$enable_persistant_mysql)	{&connect_to_db;}

	$stmt = "UPDATE conferences set extension='' where server_ip='$server_ip' and conf_exten='$NEW_conf'";

	#print STDERR "\n|$stmt|\n";
	$dbh->query($stmt)  or die  "Couldn't execute query:\n";
	if (!$enable_persistant_mysql)	{$dbh->close;}

	$NEW_conf='';
	$HCT = '0';

	$conf_extension_value->delete('0', 'end');
	$conf_sip_channel_value->delete('0', 'end');

}





##########################################
### Dial and outside number on the users phone
##########################################
sub Dial_Line()
{
$subroutine = 'Dial_Line';

	$conf_dialing_mode = 1;
	$conf_dial_CHAN = "$CHAN";
	$SIP_user = $login_value->get;
	$number_to_dial = $DIAL;

	$number_to_dial =~ s/\D//gi;

	### error box if improperly formatted number is entered
	if ( (length($number_to_dial) ne 3) && (length($number_to_dial) ne 4) && (length($number_to_dial) ne 7) && (length($number_to_dial) ne 10) && (length($number_to_dial) ne 11) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Number Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "Outside number to dial must be:\n- 4 digits for speed-dial\n- 7 digits for a local number\n- 9 digits for an AUSTRALIA number \n- 10 digits for a USA long distance number \n or 11 digits for a UK number\n   |$number_to_dial|")->pack;
		$dialog->Show;  
	}

	### place the phone call through the Manager interface of Asterisk
	else
	{
		$recent_dial_listbox->insert('0', $number_to_dial);
		$dial_number_value->delete('0', 'end');

	if (length($number_to_dial) == 7) {$number_to_dial = "9$number_to_dial";}
	if (length($number_to_dial) == 10) {$number_to_dial = "91$number_to_dial";}
	if (length($number_to_dial) == 9) {$number_to_dial = "7$number_to_dial";}

	$ACTION = 'Originate';
	$CIDcode = 'DL';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	$OUTqueryCID = $queryCID;
	$OUTnumber_to_dial = $number_to_dial;
	while (length($queryCID)>20) {chop($queryCID);}


	if ($CONF_DIAL)
		{
		$local_DEF = 'Local/';
		$local_AMP = '@';
		$cmd_line_b = "Channel: $local_DEF$NEW_conf$local_AMP$ext_context";
		$cmd_line_c = "Context: $ext_context";
		$cmd_line_d = "Exten: $number_to_dial";
		$cmd_line_e = "Priority: 1";
		$cmd_line_f = "Callerid: $queryCID";
		$cmd_line_g = "";
		$cmd_line_h = "";
		$cmd_line_i = "";
		$cmd_line_j = "";
		$cmd_line_k = "";
		}
	else
		{
		$cmd_line_b = "Channel: $SIP_user";
		$cmd_line_c = "Context: $ext_context";
		$cmd_line_d = "Exten: $number_to_dial";
		$cmd_line_e = "Priority: 1";
		$cmd_line_f = "Callerid: $queryCID";
		$cmd_line_g = "";
		$cmd_line_h = "";
		$cmd_line_i = "";
		$cmd_line_j = "";
		$cmd_line_k = "";
		}

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}



		$conf_line_dial_A->configure(-state => 'disabled');
		$conf_line_dial_B->configure(-state => 'disabled');
		$conf_line_dial_C->configure(-state => 'disabled');
		$conf_line_dial_D->configure(-state => 'disabled');
		$conf_line_dial_E->configure(-state => 'disabled');
		$conf_line_dial_F->configure(-state => 'disabled');

	if ($CHAN eq 'A')
		{
		$conf_line_hangup_A->configure(-state => 'normal');
		$conf_line_park_A->configure(-state => 'normal');
		$conf_line_join_A->configure(-state => 'disabled');
		$conf_line_dial_A->configure(-state => 'disabled');
		}
	if ($CHAN eq 'B')
		{
		$conf_line_hangup_B->configure(-state => 'normal');
		$conf_line_park_B->configure(-state => 'normal');
		$conf_line_join_B->configure(-state => 'disabled');
		$conf_line_dial_B->configure(-state => 'disabled');
		}
	if ($CHAN eq 'C')
		{
		$conf_line_hangup_C->configure(-state => 'normal');
		$conf_line_park_C->configure(-state => 'normal');
		$conf_line_join_C->configure(-state => 'disabled');
		$conf_line_dial_C->configure(-state => 'disabled');
		}
	if ($CHAN eq 'D')
		{
		$conf_line_hangup_D->configure(-state => 'normal');
		$conf_line_park_D->configure(-state => 'normal');
		$conf_line_join_D->configure(-state => 'disabled');
		$conf_line_dial_D->configure(-state => 'disabled');
		}
	if ($CHAN eq 'E')
		{
		$conf_line_hangup_E->configure(-state => 'normal');
		$conf_line_park_E->configure(-state => 'normal');
		$conf_line_join_E->configure(-state => 'disabled');
		$conf_line_dial_E->configure(-state => 'disabled');
		}
	if ($CHAN eq 'F')
		{
		$conf_line_hangup_F->configure(-state => 'normal');
		$conf_line_park_F->configure(-state => 'normal');
		$conf_line_join_F->configure(-state => 'disabled');
		$conf_line_dial_F->configure(-state => 'disabled');
		}

	}


}




##########################################
### Park Line on park extension
##########################################
sub Park_Line()
{
$subroutine = 'Park_Line';

if (length($PARK)>4)
	{

	$ACTION = 'Redirect';
	$CIDcode = 'PL';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $PARK";
	$cmd_line_c = "Context: $ext_context";
	if ($main_call_park)
		{
		$cmd_line_d = "Exten: $park_on_extension";
		$park_extension = 'park';
		}
	else
		{
		$cmd_line_d = "Exten: $conf_on_extension";
		$park_extension = 'conf';
		}
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}



		### insert parked call into parked_channels table
		if (!$enable_persistant_mysql)	{&connect_to_db;}

		$stmt = "INSERT INTO $parked_channels values('$PARK','$server_ip','','$park_extension','$SIP_user','$SQLdate');";

		#print STDERR "\n|$stmt|\n";
		$dbh->query($stmt)  or die  "Couldn't execute query:\n";

		if (!$enable_persistant_mysql)	{$dbh->close;}


	if ($CHAN eq 'A')
		{
		$conf_line_hangup_A->configure(-state => 'normal');
		$conf_line_park_A->configure(-state => 'disabled');
		$conf_line_join_A->configure(-state => 'normal');
		$conf_line_dial_A->configure(-state => 'disabled');

		$conf_line_dial_B->configure(-state => 'normal');
		$conf_line_dial_C->configure(-state => 'normal');
		$conf_line_dial_D->configure(-state => 'normal');
		$conf_line_dial_E->configure(-state => 'normal');
		$conf_line_dial_F->configure(-state => 'normal');
		}
	if ($CHAN eq 'B')
		{
		$conf_line_hangup_B->configure(-state => 'normal');
		$conf_line_park_B->configure(-state => 'disabled');
		$conf_line_join_B->configure(-state => 'normal');
		$conf_line_dial_B->configure(-state => 'disabled');

		$conf_line_dial_C->configure(-state => 'normal');
		$conf_line_dial_D->configure(-state => 'normal');
		$conf_line_dial_E->configure(-state => 'normal');
		$conf_line_dial_F->configure(-state => 'normal');
		}
	if ($CHAN eq 'C')
		{
		$conf_line_hangup_C->configure(-state => 'normal');
		$conf_line_park_C->configure(-state => 'disabled');
		$conf_line_join_C->configure(-state => 'normal');
		$conf_line_dial_C->configure(-state => 'disabled');

		$conf_line_dial_D->configure(-state => 'normal');
		$conf_line_dial_E->configure(-state => 'normal');
		$conf_line_dial_F->configure(-state => 'normal');
		}
	if ($CHAN eq 'D')
		{
		$conf_line_hangup_D->configure(-state => 'normal');
		$conf_line_park_D->configure(-state => 'disabled');
		$conf_line_join_D->configure(-state => 'normal');
		$conf_line_dial_D->configure(-state => 'disabled');

		$conf_line_dial_E->configure(-state => 'normal');
		$conf_line_dial_F->configure(-state => 'normal');
		}
	if ($CHAN eq 'E')
		{
		$conf_line_hangup_E->configure(-state => 'normal');
		$conf_line_park_E->configure(-state => 'disabled');
		$conf_line_join_E->configure(-state => 'normal');
		$conf_line_dial_E->configure(-state => 'disabled');

		$conf_line_dial_F->configure(-state => 'normal');
		}
	if ($CHAN eq 'F')
		{
		$conf_line_hangup_F->configure(-state => 'normal');
		$conf_line_park_F->configure(-state => 'disabled');
		$conf_line_join_F->configure(-state => 'normal');
		$conf_line_dial_F->configure(-state => 'disabled');
		}

		&validate_conf_lines;
	}
}



##########################################
### Join Line to current conference
##########################################
sub Join_Line()
{
$subroutine = 'Join_Line';

	$ACTION = 'Redirect';
	$CIDcode = 'JC';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $JOIN";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $NEW_conf";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}



	### delete call from parked_channels table
	if (!$enable_persistant_mysql)	{&connect_to_db;}
	$stmt = "DELETE FROM $parked_channels where channel='$PICKUP' and server_ip = '$server_ip';";
	$dbh->query($stmt);
	if (!$enable_persistant_mysql)	{$dbh->close;}

	if ($CHAN eq 'A')
		{
		$conf_line_hangup_A->configure(-state => 'normal');
		$conf_line_park_A->configure(-state => 'normal');
		$conf_line_join_A->configure(-state => 'disabled');
		$conf_line_dial_A->configure(-state => 'disabled');
		}
	if ($CHAN eq 'B')
		{
		$conf_line_hangup_B->configure(-state => 'normal');
		$conf_line_park_B->configure(-state => 'normal');
		$conf_line_join_B->configure(-state => 'disabled');
		$conf_line_dial_B->configure(-state => 'disabled');
		}
	if ($CHAN eq 'C')
		{
		$conf_line_hangup_C->configure(-state => 'normal');
		$conf_line_park_C->configure(-state => 'normal');
		$conf_line_join_C->configure(-state => 'disabled');
		$conf_line_dial_C->configure(-state => 'disabled');
		}
	if ($CHAN eq 'D')
		{
		$conf_line_hangup_D->configure(-state => 'normal');
		$conf_line_park_D->configure(-state => 'normal');
		$conf_line_join_D->configure(-state => 'disabled');
		$conf_line_dial_D->configure(-state => 'disabled');
		}
	if ($CHAN eq 'E')
		{
		$conf_line_hangup_E->configure(-state => 'normal');
		$conf_line_park_E->configure(-state => 'normal');
		$conf_line_join_E->configure(-state => 'disabled');
		$conf_line_dial_E->configure(-state => 'disabled');
		}
	if ($CHAN eq 'F')
		{
		$conf_line_hangup_F->configure(-state => 'normal');
		$conf_line_park_F->configure(-state => 'normal');
		$conf_line_join_F->configure(-state => 'disabled');
		$conf_line_dial_F->configure(-state => 'disabled');
		}

}



##########################################
### Hangup Line
##########################################
sub Hangup_Line()
{
$subroutine = 'Hangup_Line';


if (length($HANGUP)>4)
	{

	$ACTION = 'Hangup';
	$CIDcode = 'HL';
	if ($HCT) {$CIDcode = "H$HCT";}
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $HANGUP";
	$cmd_line_c = "";
	$cmd_line_d = "";
	$cmd_line_e = "";
	$cmd_line_f = "";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}


		### delete call from parked_channels table
		if (!$enable_persistant_mysql)	{&connect_to_db;}
		$stmt = "DELETE FROM $parked_channels where channel='$HANGUP' and server_ip = '$server_ip';";
		$dbh->query($stmt);
		if (!$enable_persistant_mysql)	{$dbh->close;}


	if ($CHAN eq 'A')
		{
		$conf_line_hangup_A->configure(-state => 'disabled');
		$conf_line_park_A->configure(-state => 'disabled');
		$conf_line_join_A->configure(-state => 'disabled');
		$conf_line_dial_A->configure(-state => 'normal');
		}
	if ($CHAN eq 'B')
		{
		$conf_line_hangup_B->configure(-state => 'disabled');
		$conf_line_park_B->configure(-state => 'disabled');
		$conf_line_join_B->configure(-state => 'disabled');
		$conf_line_dial_B->configure(-state => 'normal');
		}
	if ($CHAN eq 'C')
		{
		$conf_line_hangup_C->configure(-state => 'disabled');
		$conf_line_park_C->configure(-state => 'disabled');
		$conf_line_join_C->configure(-state => 'disabled');
		$conf_line_dial_C->configure(-state => 'normal');
		}
	if ($CHAN eq 'D')
		{
		$conf_line_hangup_D->configure(-state => 'disabled');
		$conf_line_park_D->configure(-state => 'disabled');
		$conf_line_join_D->configure(-state => 'disabled');
		$conf_line_dial_D->configure(-state => 'normal');
		}
	if ($CHAN eq 'E')
		{
		$conf_line_hangup_E->configure(-state => 'disabled');
		$conf_line_park_E->configure(-state => 'disabled');
		$conf_line_join_E->configure(-state => 'disabled');
		$conf_line_dial_E->configure(-state => 'normal');
		}
	if ($CHAN eq 'F')
		{
		$conf_line_hangup_F->configure(-state => 'disabled');
		$conf_line_park_F->configure(-state => 'disabled');
		$conf_line_join_F->configure(-state => 'disabled');
		$conf_line_dial_F->configure(-state => 'normal');
		}
	}
}



##########################################
### Hijack Line Grab an active line and have it ring on your phone
##########################################
sub Hijack_Line()
{
$subroutine = 'Hijack_Line';

	$DB_SIP_USER = $SIP_user;
	$DB_SIP_USER =~ s/SIP\/|IAX2\/|Zap\///gi;

if (length($HIJACK)>4)
	{

	if (!$enable_persistant_mysql)	{&connect_to_db;}

   $dbh->query("SELECT dialplan_number FROM phones where server_ip='$server_ip' and extension='$DB_SIP_USER' limit 1");
	   if ($dbh->has_selected_record)
	   {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - extension call sent to\n";
		   $SIP_extension = "$record->[0]";
		   $rec_count++;
		   } 
	   }
	if (!$enable_persistant_mysql)	{$dbh->close;}

	$ACTION = 'Redirect';
	$CIDcode = 'HJ';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $HIJACK";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $SIP_extension";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";


	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}


		### delete call from parked_channels table
		if (!$enable_persistant_mysql)	{&connect_to_db;}
		$stmt = "DELETE FROM $parked_channels where channel='$HANGUP' and server_ip = '$server_ip';";
		$dbh->query($stmt);
		if (!$enable_persistant_mysql)	{$dbh->close;}

	}
}



##########################################
### Pickup Line on Parked Lines
##########################################
sub Pickup_Line()
{
$subroutine = 'Pickup_Line';

	$DB_SIP_USER = $SIP_user;
	$DB_SIP_USER =~ s/SIP\/|IAX2\/|Zap\///gi;

if (length($PICKUP)>4)
	{

	if (!$enable_persistant_mysql)	{&connect_to_db;}

   $dbh->query("SELECT dialplan_number FROM phones where server_ip='$server_ip' and extension='$DB_SIP_USER' limit 1");
	   if ($dbh->has_selected_record)
	   {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - extension call sent to\n";
		   $SIP_extension = "$record->[0]";
		   $rec_count++;
		   } 
	   }
	if (!$enable_persistant_mysql)	{$dbh->close;}

	$ACTION = 'Redirect';
	$CIDcode = 'PK';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $PICKUP";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $SIP_extension";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $queryCID";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}


	### delete call from parked_channels table
	if (!$enable_persistant_mysql)	{&connect_to_db;}
	$stmt = "DELETE FROM $parked_channels where channel='$PICKUP' and server_ip = '$server_ip';";
	$dbh->query($stmt);
	if (!$enable_persistant_mysql)	{$dbh->close;}


	}
}




##########################################
### VALIDATE THAT CONFERENCE LINES ARE STILL ONLINE
##########################################
sub validate_conf_lines
{
$subroutine = 'validate_conf_lines';

if (!$Default_window)
	{
		$CHAN_A_LIVE_CHECK = $conf_LIVE_channel_A->get; 
		$CHAN_B_LIVE_CHECK = $conf_LIVE_channel_B->get;
		$CHAN_C_LIVE_CHECK = $conf_LIVE_channel_C->get;
		$CHAN_D_LIVE_CHECK = $conf_LIVE_channel_D->get;
		$CHAN_E_LIVE_CHECK = $conf_LIVE_channel_E->get;
		$CHAN_F_LIVE_CHECK = $conf_LIVE_channel_F->get;


	if (!$enable_persistant_mysql)	{&connect_to_db;}

		if (length($CHAN_A_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_A_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_A_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_A->configure(-state => 'disabled');
				$conf_line_park_A->configure(-state => 'disabled');
				$conf_line_join_A->configure(-state => 'disabled');
				$conf_line_dial_A->configure(-state => 'normal');
				$conf_STATUS_channel_A->delete('0', 'end');
				$conf_STATUS_channel_A->insert('0', "$CHAN_A_LIVE_CHECK DIED");
				$conf_LIVE_channel_A->delete('0', 'end');
				$conf_LIVE_channel_A->insert('0', "BAD");
				}
			}
		if (length($CHAN_B_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_B_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_B_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_B->configure(-state => 'disabled');
				$conf_line_park_B->configure(-state => 'disabled');
				$conf_line_join_B->configure(-state => 'disabled');
				$conf_line_dial_B->configure(-state => 'normal');
				$conf_STATUS_channel_B->delete('0', 'end');
				$conf_STATUS_channel_B->insert('0', "$CHAN_B_LIVE_CHECK DIED");
				$conf_LIVE_channel_B->delete('0', 'end');
				$conf_LIVE_channel_B->insert('0', "BAD");
				}
			}

		if (length($CHAN_C_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_C_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_C_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_C->configure(-state => 'disabled');
				$conf_line_park_C->configure(-state => 'disabled');
				$conf_line_join_C->configure(-state => 'disabled');
				$conf_line_dial_C->configure(-state => 'normal');
				$conf_STATUS_channel_C->delete('0', 'end');
				$conf_STATUS_channel_C->insert('0', "$CHAN_C_LIVE_CHECK DIED");
				$conf_LIVE_channel_C->delete('0', 'end');
				$conf_LIVE_channel_C->insert('0', "BAD");
				}
			}

		if (length($CHAN_D_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_D_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_D_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_D->configure(-state => 'disabled');
				$conf_line_park_D->configure(-state => 'disabled');
				$conf_line_join_D->configure(-state => 'disabled');
				$conf_line_dial_D->configure(-state => 'normal');
				$conf_STATUS_channel_D->delete('0', 'end');
				$conf_STATUS_channel_D->insert('0', "$CHAN_D_LIVE_CHECK DIED");
				$conf_LIVE_channel_D->delete('0', 'end');
				$conf_LIVE_channel_D->insert('0', "BAD");
				}
			}

		if (length($CHAN_E_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_E_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_E_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_E->configure(-state => 'disabled');
				$conf_line_park_E->configure(-state => 'disabled');
				$conf_line_join_E->configure(-state => 'disabled');
				$conf_line_dial_E->configure(-state => 'normal');
				$conf_STATUS_channel_E->delete('0', 'end');
				$conf_STATUS_channel_E->insert('0', "$CHAN_E_LIVE_CHECK DIED");
				$conf_LIVE_channel_E->delete('0', 'end');
				$conf_LIVE_channel_E->insert('0', "BAD");
				}
			}

		if (length($CHAN_F_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_F_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip' and channel = '$CHAN_F_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_F->configure(-state => 'disabled');
				$conf_line_park_F->configure(-state => 'disabled');
				$conf_line_join_F->configure(-state => 'disabled');
				$conf_line_dial_F->configure(-state => 'normal');
				$conf_STATUS_channel_F->delete('0', 'end');
				$conf_STATUS_channel_F->insert('0', "$CHAN_F_LIVE_CHECK DIED");
				$conf_LIVE_channel_F->delete('0', 'end');
				$conf_LIVE_channel_F->insert('0', "BAD");
				}
			}

			if (!$enable_persistant_mysql)	{$dbh->close;}

	}

}





##########################################
### Conference Start recording - clicked on start recording button in conf
##########################################
sub conf_start_recording
{
$subroutine = 'conf_start_recording';

$CONFERENCE_RECORDING = 1;
$CONFERENCE_RECORDING_CHANNEL = '';

$SIP_user = $login_value->get;
$ext = $SIP_user;
$ext =~ s/SIP\/|IAX2\/|Zap\///gi;
$filename = "$filedate$US$ext";

$start_rec_conf->configure(-state => 'disabled');
$stop_rec_conf->configure(-state => 'normal');
$initiate_conference->configure(-state => 'disabled');
$start_conf_gif_anim->set_image(22);

	$channel =~ s/Zap\///gi;
	$record_channel = $channel;

	$ACTION = 'Originate';
	$CIDcode = 'CR';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$local_DEF = 'Local/';
	$local_AMP = '@';
	$cmd_line_b = "Channel: $local_DEF$NEW_conf$local_AMP$ext_context";
	$cmd_line_c = "Context: $ext_context";
	$cmd_line_d = "Exten: $recording_exten";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $filename";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}



	$rec_msg_value->delete('0', 'end');
    $rec_msg_value->insert('0', " - RECORDING - ");
	$rec_fname_value->delete('0', 'end');
    $rec_fname_value->insert('0', "$filename");
	$rec_recid_value->delete('0', 'end');

	$conf_rec_msg_value->delete('0', 'end');
    $conf_rec_msg_value->insert('0', " - RECORDING - ");
	$conf_rec_fname_value->delete('0', 'end');
    $conf_rec_fname_value->insert('0', "$filename");
	$conf_rec_recid_value->delete('0', 'end');


	if (!$enable_persistant_mysql)	{&connect_to_db;}

		$stmt = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('Zap/$channel','$server_ip','$SIP_user','$SQLdate','$secX','$filename')";
			if($DB){print STDERR "\n|$stmt|\n";}
		$dbh->query($stmt)  or die  "Couldn't execute query:\n";

	   $dbh->query("SELECT recording_id FROM recording_log where filename='$filename'");
	   if ($dbh->has_selected_record) {
	   $iter=$dbh->create_record_iterator;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $rec_recid_value->insert('0', "$recording_id");
		   $conf_rec_recid_value->insert('0', "$recording_id");
		   } 
	   }

	if (!$enable_persistant_mysql)	{$dbh->close;}

	print "|channel:$channel|$filename|\n";


}


##########################################
### Conference Stop recording - clicked on stop recording button
##########################################
sub conf_stop_recording
{
$subroutine = 'conf_stop_recording';

$SIP_user = $login_value->get;

if (length($CONFERENCE_RECORDING_CHANNEL) > 5)
	{

	$ACTION = 'Hangup';
	$CIDcode = 'CT';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Channel: $CONFERENCE_RECORDING_CHANNEL";
	$cmd_line_c = "";
	$cmd_line_d = "";
	$cmd_line_e = "";
	$cmd_line_f = "";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}



	if (!$enable_persistant_mysql)	{&connect_to_db;}

	   $dbh->query("SELECT recording_id,start_epoch FROM recording_log where filename='$filename'");
	   if ($dbh->has_selected_record) {
	   $iter=$dbh->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $start_time = "$record->[1]";
		   $rec_count++;
		   } 
	   }

	if ($rec_count)
		{
		$length_in_sec = ($secX - $start_time);
		$length_in_min = ($length_in_sec / 60);
		$length_in_min = sprintf("%8.2f", $length_in_min);

		# print STDERR "\nQUERY done: start time = $start_time | sec: $length_in_sec | min: $length_in_min |\n";

		$stmt = "UPDATE recording_log set end_time='$SQLdate',end_epoch='$secX',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename'";

		#print STDERR "\n|$stmt|\n";
		$dbh->query($stmt)  or die  "Couldn't execute query:\n";
		}
	if (!$enable_persistant_mysql)	{$dbh->close;}

	print "|channel:$CONFERENCE_RECORDING_CHANNEL|$record_channel|$filename|\n";

	$rec_msg_value->delete('0', 'end');
    $rec_msg_value->insert('0', "Length: $length_in_min Min.");
	$rec_recid_value->delete('0', 'end');
    $rec_recid_value->insert('0', "$recording_id");

	$conf_rec_msg_value->delete('0', 'end');
    $conf_rec_msg_value->insert('0', "Length: $length_in_min Min.");
	$conf_rec_recid_value->delete('0', 'end');
    $conf_rec_recid_value->insert('0', "$recording_id");
	$start_rec_conf->configure(-state => 'normal');
	$stop_rec_conf->configure(-state => 'disabled');

$record_channel='';

$start_recording->configure(-state => 'normal');
$start_rec_gif_anim->set_image(3);
$stop_recording->configure(-state => 'disabled');
$stop_rec_gif_anim->set_image(6);
if ($conferencing_enabled)
	{
	$initiate_conference->configure(-state => 'normal');
	$start_conf_gif_anim->set_image(21);
	}



$REC_CHAN='';
$CONFERENCE_RECORDING = 0;
$CONFERENCE_RECORDING_CHANNEL = '';
$conf_rec_channel_value->delete('0', 'end');

	}
}






##########################################
##########################################
### open dialpad for sendDTMF in conference window
##########################################
##########################################
sub dtmf_dialpad_window
{

	my $dialog_dtmf_dialpad = $MW->DialogBox( -title   => "DTMF dialpad",
					 -buttons => [ "SEND DTMF","Close" ],
	);

	my $dialpad_numbers_frame = $dialog_dtmf_dialpad->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $dialpad_header_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$dialpad_header_row_frame->Label(-text => "DTMF TONES TO SEND: ")->pack(-side => 'left');
	my $dialpad_dtmf_value = $dialpad_header_row_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
	$dialpad_dtmf_value->insert('0', '');
	my $dialpad_first_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

### keybindings for the popup DTMF dialpad
	$dialog_dtmf_dialpad->bind('<KeyRelease-1>', => [sub {$dialpad_dtmf_value->insert('end', "1");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-2>', => [sub {$dialpad_dtmf_value->insert('end', "2");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-3>', => [sub {$dialpad_dtmf_value->insert('end', "3");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-4>', => [sub {$dialpad_dtmf_value->insert('end', "4");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-5>', => [sub {$dialpad_dtmf_value->insert('end', "5");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-6>', => [sub {$dialpad_dtmf_value->insert('end', "6");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-7>', => [sub {$dialpad_dtmf_value->insert('end', "7");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-8>', => [sub {$dialpad_dtmf_value->insert('end', "8");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-9>', => [sub {$dialpad_dtmf_value->insert('end', "9");}]);
	$dialog_dtmf_dialpad->bind('<KeyRelease-0>', => [sub {$dialpad_dtmf_value->insert('end', "0");}]);
	$dialog_dtmf_dialpad->bind('<asterisk>', => [sub {$dialpad_dtmf_value->insert('end', '*');}]);
	$dialog_dtmf_dialpad->bind('<slash>', => [sub {$dialpad_dtmf_value->insert('end', '#');}]);
	$dialog_dtmf_dialpad->bind('<KP_1>', => [sub {$dialpad_dtmf_value->insert('end', "1");}]);
	$dialog_dtmf_dialpad->bind('<KP_2>', => [sub {$dialpad_dtmf_value->insert('end', "2");}]);
	$dialog_dtmf_dialpad->bind('<KP_3>', => [sub {$dialpad_dtmf_value->insert('end', "3");}]);
	$dialog_dtmf_dialpad->bind('<KP_4>', => [sub {$dialpad_dtmf_value->insert('end', "4");}]);
	$dialog_dtmf_dialpad->bind('<KP_5>', => [sub {$dialpad_dtmf_value->insert('end', "5");}]);
	$dialog_dtmf_dialpad->bind('<KP_6>', => [sub {$dialpad_dtmf_value->insert('end', "6");}]);
	$dialog_dtmf_dialpad->bind('<KP_7>', => [sub {$dialpad_dtmf_value->insert('end', "7");}]);
	$dialog_dtmf_dialpad->bind('<KP_8>', => [sub {$dialpad_dtmf_value->insert('end', "8");}]);
	$dialog_dtmf_dialpad->bind('<KP_9>', => [sub {$dialpad_dtmf_value->insert('end', "9");}]);
	$dialog_dtmf_dialpad->bind('<KP_0>', => [sub {$dialpad_dtmf_value->insert('end', "0");}]);
	$dialog_dtmf_dialpad->bind('<KP_Multiply>', => [sub {$dialpad_dtmf_value->insert('end', '*');}]);
	$dialog_dtmf_dialpad->bind('<KP_Divide>', => [sub {$dialpad_dtmf_value->insert('end', '#');}]);
### these are for the screwy Gnome handling of the number pad, not necessary for X11 which handles numbers just fine
   if ($^O !~ /MSWin32/i)
	   {
		eval '

		$dialog_dtmf_dialpad->bind("<KP_End>", => [sub {$dialpad_dtmf_value->insert("end", "1");}]);
		$dialog_dtmf_dialpad->bind("<KP_Down>", => [sub {$dialpad_dtmf_value->insert("end", "2");}]);
		$dialog_dtmf_dialpad->bind("<KP_Next>", => [sub {$dialpad_dtmf_value->insert("end", "3");}]);
		$dialog_dtmf_dialpad->bind("<KP_Left>", => [sub {$dialpad_dtmf_value->insert("end", "4");}]);
		$dialog_dtmf_dialpad->bind("<KP_Begin>", => [sub {$dialpad_dtmf_value->insert("end", "5");}]);
		$dialog_dtmf_dialpad->bind("<KP_Right>", => [sub {$dialpad_dtmf_value->insert("end", "6");}]);
		$dialog_dtmf_dialpad->bind("<KP_Home>", => [sub {$dialpad_dtmf_value->insert("end", "7");}]);
		$dialog_dtmf_dialpad->bind("<KP_Up>", => [sub {$dialpad_dtmf_value->insert("end", "8");}]);
		$dialog_dtmf_dialpad->bind("<KP_Prior>", => [sub {$dialpad_dtmf_value->insert("end", "9");}]);
		$dialog_dtmf_dialpad->bind("<KP_Insert>", => [sub {$dialpad_dtmf_value->insert("end", "0");}]);
		$dialog_dtmf_dialpad->bind("<KP_Enter>", => [sub 
			{
			$dialpad_DTMF = $dialpad_dtmf_value->get;
			$xfer_dtmf_value->delete("0", "end");
			$xfer_dtmf_value->insert("end","$dialpad_DTMF");
			conf_send_dtmf;
			print STDERR "DTMF SENT: |$dialpad_DTMF|\n";
			$dialpad_dtmf_value->delete("0", "end");
			}]);

		';
	   }

#	$hash_string = '#';
#	$dialog_dtmf_dialpad->bind("<$hash_string>", => [sub {$dialpad_dtmf_value->insert('end', '#');}]);
	$dialog_dtmf_dialpad->bind('<space>', => [sub {$dialpad_dtmf_value->insert('end', ',');}]);
	$dialog_dtmf_dialpad->bind('<comma>', => [sub {$dialpad_dtmf_value->insert('end', ',');}]);
	$dialog_dtmf_dialpad->bind('<Delete>', => [sub {$dialpad_dtmf_value->delete('0','end');}]);
	$dialog_dtmf_dialpad->bind('<BackSpace>', => [sub {
		$DTMF_string = $dialpad_dtmf_value->get;
		$DTMF_length = ( (length($DTMF_string)) - 1 );
		$dialpad_dtmf_value->delete("$DTMF_length");
		}]);


#1
	my $dialpad_1 = $dialpad_first_row_frame->Button(-text => " \n1\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "1");});
	$dialpad_1->pack(-side => 'left', -expand => '1', -fill => 'both');
#2
	my $dialpad_2 = $dialpad_first_row_frame->Button(-text => " \n2\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "2");});
	$dialpad_2->pack(-side => 'left', -expand => '1', -fill => 'both');
#3
	my $dialpad_3 = $dialpad_first_row_frame->Button(-text => " \n3\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "3");});
	$dialpad_3->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_second_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#4
	my $dialpad_4 = $dialpad_second_row_frame->Button(-text => " \n4\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "4");});
	$dialpad_4->pack(-side => 'left', -expand => '1', -fill => 'both');
#5
	my $dialpad_5 = $dialpad_second_row_frame->Button(-text => " \n5\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "5");});
	$dialpad_5->pack(-side => 'left', -expand => '1', -fill => 'both');
#6
	my $dialpad_6 = $dialpad_second_row_frame->Button(-text => " \n6\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "6");});
	$dialpad_6->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_third_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#7
	my $dialpad_7 = $dialpad_third_row_frame->Button(-text => " \n7\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "7");});
	$dialpad_7->pack(-side => 'left', -expand => '1', -fill => 'both');
#8
	my $dialpad_8 = $dialpad_third_row_frame->Button(-text => " \n8\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "8");});
	$dialpad_8->pack(-side => 'left', -expand => '1', -fill => 'both');
#9
	my $dialpad_9 = $dialpad_third_row_frame->Button(-text => " \n9\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "9");});
	$dialpad_9->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_fourth_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#*
	my $dialpad_star = $dialpad_fourth_row_frame->Button(-text => " \n*\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', '*');});
	$dialpad_star->pack(-side => 'left', -expand => '1', -fill => 'both');
#0
	my $dialpad_0 = $dialpad_fourth_row_frame->Button(-text => " \n0\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', "0");});
	$dialpad_0->pack(-side => 'left', -expand => '1', -fill => 'both');
##
	my $dialpad_hash = $dialpad_fourth_row_frame->Button(-text => " \n\#\n ", -width => -1, -font => 'Courier 14',
				-command => sub {$dialpad_dtmf_value->insert('end', '#');});
	$dialpad_hash->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_fifth_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#, (pause)
	my $dialpad_comma = $dialpad_fifth_row_frame->Button(-text => "one second pause", -width => -1,
				-command => sub {$dialpad_dtmf_value->insert('end', ',');});
	$dialpad_comma->pack(-side => 'left', -expand => '1', -fill => 'both');


	$dialpad_numbers_frame->Label(-text => " ")->pack(-side => 'top');


	my $dialpad_sixth_row_frame = $dialpad_numbers_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
#SUBMIT
	my $dialpad_submit = $dialpad_sixth_row_frame->Button(-text => "SEND DTMF", -width => -1,
				-command => sub {
#		$use_dialpad_DTMF=1;
		$dialpad_DTMF = $dialpad_dtmf_value->get;
		$xfer_dtmf_value->delete('0', 'end');
		$xfer_dtmf_value->insert('end',"$dialpad_DTMF");
		conf_send_dtmf;
		print STDERR "DTMF SENT: |$dialpad_DTMF|\n";
		$dialpad_dtmf_value->delete('0', 'end');
								});
	$dialpad_submit->pack(-side => 'left', -expand => '1', -fill => 'both');


	my $dialpad_result = $dialog_dtmf_dialpad->Show;
	if ($dialpad_result =~ /Close/i)
		{
		$open_dialpad_window_again=0;
		print STDERR "dialpad window closed\n";
		}
	if ($dialpad_result =~ /SEND/i)
		{
#		$use_dialpad_DTMF=1;
		$open_dialpad_window_again=1;
		$dialpad_DTMF = $dialpad_dtmf_value->get;
		$xfer_dtmf_value->delete('0', 'end');
		$xfer_dtmf_value->insert('end',"$dialpad_DTMF");
		conf_send_dtmf;
		print STDERR "DTMF SENT: |$dialpad_DTMF|\n";
		$dialpad_dtmf_value->delete('0', 'end');
		print STDERR "dialpad window closed\n";
		}
# DTMF
}





##########################################
##########################################
### send dtmf tones to conference
##########################################
##########################################
sub conf_send_dtmf
{
$subroutine = 'conf_send_dtmf';

$XFER_DTMF_CHAN = $NEW_conf;

if ($use_dialpad_DTMF)
	{
	$XFER_DTMF_DIGITS = $dialpad_DTMF;
	$use_dialpad_DTMF=0;
	}
else
	{
	$XFER_DTMF_DIGITS = $xfer_dtmf_value->get;
	}


	### error box if channel to hangup is not live
if ( (length($XFER_DTMF_CHAN)<5) or (length($XFER_DTMF_DIGITS)<1) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Xfer send DTMF Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "You are not sending any DTMF digits\n  |$XFER_DTMF_DIGITS|")->pack;
		$dialog->Show;  
	}
else
	{
	$ACTION = 'Originate';
	$CIDcode = 'DT';
	$queryCID = "$CIDcode$CIDdate$conf_SIP_abb";
	while (length($queryCID)>20) {chop($queryCID);}

	$cmd_line_b = "Exten: $XFER_DTMF_CHAN";
	$cmd_line_c = "Channel: $dtmf_send_extension";
	$cmd_line_d = "Context: $ext_context";
	$cmd_line_e = "Priority: 1";
	$cmd_line_f = "Callerid: $XFER_DTMF_DIGITS";
	$cmd_line_g = "";
	$cmd_line_h = "";
	$cmd_line_i = "";
	$cmd_line_j = "";
	$cmd_line_k = "";

	$originate_command  = '';
	$originate_command .= "Action: $ACTION\n";
	$originate_command .= "$cmd_line_b\n";
	$originate_command .= "$cmd_line_c\n";
	$originate_command .= "$cmd_line_d\n";
	$originate_command .= "$cmd_line_e\n";
	$originate_command .= "$cmd_line_f\n";
	$originate_command .= "\n";

	$PROMPT = 'Response.*';

		if ($QUEUE_ACTION_enabled) {&queue_connect_and_send;}
		else {&telnet_connect_and_send;}

	$xfer_dtmf_value->delete('0', 'end');

	}


}






##########################################
##########################################
### telnet connect to manager interface and send action
##########################################
##########################################
sub telnet_connect_and_send
{
$subroutine = 'telnet_connect_and_send';
@outside_dial = @MT;
@hangup = @MT;

if ($AFLogging_enabled)
	{
		$event_string = "SUBRT|TELNET_SEND|$subroutine|$originate_command|$PROMPT|";
	 &event_logger;
	}
$t = new Net::Telnet (Port => 5038,
					  Prompt => '/.*[\$%#>] $/',
					  Output_record_separator => '',
#					  Errmode    => Return,
					  );
#$fh = $t->dump_log("./telnet_log.txt");
$t->open("$server_ip");
$t->waitfor('/0\n$/');			# print login
$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
$t->waitfor('/Authentication.*/');		# print auth accepted

#	print "COMMAND:\n$originate_command\n";
#	print "RESPONSE:\n$PROMPT\n";

$t->print("$originate_command");

$t->print("Action: Logoff\n\n");


$t->buffer_empty;

$ok = $t->close;

}





##########################################
##########################################
### connect to DB and post action for execution on the central queue system
##########################################
##########################################
sub queue_connect_and_send
{
$subroutine = 'queue_connect_and_send';

	if (!$enable_persistant_mysql)	{&connect_to_db;}
### insert a NEW record to the vicidial_manager table to be processed
	$stmt = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','$ACTION','$queryCID','$cmd_line_b','$cmd_line_c','$cmd_line_d','$cmd_line_e','$cmd_line_f','$cmd_line_g','$cmd_line_h','$cmd_line_i','$cmd_line_j','$cmd_line_k')";

if ($AFLogging_enabled)
	{
		$event_string = "SUBRT|QUEUE_SEND|$queryCID|$ACTION|$subroutine|$stmt|";
	 &event_logger;
	}

	$dbh->query($stmt)  or die  "Couldn't execute query: |$stmt|\n";

	if (!$enable_persistant_mysql)	{$dbh->close;}

	$DB_donot_close=0;
	$DB_existing=0;
}





##########################################
##########################################
### write event to client logfile
##########################################
##########################################
sub event_logger {
	### open the log file for writing ###
	open(Lout, ">>./AFLog.$LOGdate")
			|| die "Can't open AFLog.$LOGdate: $!\n";

	print Lout "$SQLdate|$event_string|\n";

	close(Lout);

$event_string='';
}





##########################################
##########################################
### connect to idcheck database and fill in variables
##########################################
##########################################
sub idcheck_connect {

	$SIP_abb = $SIP_user;
	$SIP_abb =~ s/SIP\/|IAX2\/|Zap\///gi;


$dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
		or 	die "Couldn't connect to database: $DB_server - $DB_database\n";

if ($DB) {print STDERR "connecting to DB: $DB_server - $DB_database\n";}

   $dbhA->query("SELECT * FROM phones where server_ip = '$server_ip' and extension = '$SIP_abb';");
   if ($dbhA->has_selected_record)
	{
   $iterA=$dbhA->create_record_iterator;
	 $rec_countA=0;
	   while ($recordA = $iterA->each)
		{
		   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}

			$LOCAL_GMT = "$recordA->[17]";
			$ASTmgrUSERNAME	 = "$recordA->[18]";
			$ASTmgrSECRET = "$recordA->[19]";
			$login_user = "$recordA->[20]";
			$login_pass = "$recordA->[21]";
			$login_campaign = "$recordA->[22]";
			$park_on_extension = "$recordA->[23]";
			$conf_on_extension = "$recordA->[24]";
			$VICIDIAL_park_on_extension = "$recordA->[25]";
			$VICIDIAL_park_on_filename = "$recordA->[26]";
			$monitor_prefix = "$recordA->[27]";
			$recording_exten = "$recordA->[28]";
			$voicemail_exten = "$recordA->[29]";
			$voicemail_dump_exten = "$recordA->[30]";
			$ext_context = "$recordA->[31]";
			$dtmf_send_extension = "$recordA->[32]";
			$call_out_number_group = "$recordA->[33]";
			$client_browser = "$recordA->[34]";
			$install_directory = "$recordA->[35]";
			$local_web_callerID_URL = "$recordA->[36]";
			$VICIDIAL_web_URL = "$recordA->[37]";
			$AGI_call_logging_enabled = "$recordA->[38]";
			$user_switching_enabled = "$recordA->[39]";
			$conferencing_enabled = "$recordA->[40]";
			$admin_hangup_enabled = "$recordA->[41]";
			$admin_hijack_enabled = "$recordA->[42]";
			$admin_monitor_enabled = "$recordA->[43]";
			$call_parking_enabled = "$recordA->[44]";
			$updater_check_enabled = "$recordA->[45]";
			$AFLogging_enabled = "$recordA->[46]";
			$QUEUE_ACTION_enabled = "$recordA->[47]";
			$CallerID_popup_enabled = "$recordA->[48]";
			$voicemail_button_enabled = "$recordA->[49]";
			$enable_fast_refresh = "$recordA->[50]";
			$fast_refresh_rate = "$recordA->[51]";
			$enable_persistant_mysql = "$recordA->[52]";
			$auto_dial_next_number = "$recordA->[53]";
			$VDstop_rec_after_each_call = "$recordA->[54]";
			$DBX_server = "$recordA->[55]";
			$DBX_database = "$recordA->[56]";
			$DBX_user = "$recordA->[57]";
			$DBX_pass = "$recordA->[58]";
			$DBX_port = "$recordA->[59]";
			$DBY_server = "$recordA->[60]";
			$DBY_database = "$recordA->[61]";
			$DBY_user = "$recordA->[62]";
			$DBY_pass = "$recordA->[63]";
			$DBY_port = "$recordA->[64]";

		if (length($DBX_server)<4) {$DBX_server = $DB_server;}
		if (length($DBX_database)<2) {$DBX_database = $DB_database;}
	   $rec_countA++;
		} 
	}

	$dbhA->close;

}





##########################################
##########################################
### connect to the database
##########################################
##########################################
sub connect_to_db {

$dbh = Net::MySQL->new(hostname => "$DBX_server", database => "$DBX_database", user => "$DBX_user", password => "$DBX_pass", port => "$DBX_port") 
		or 	die "Couldn't connect to database: $DBX_server - $DBX_database\n";

if ($DB) {print STDERR "connecting to DB: $DBX_server - $DBX_database\n";}

}