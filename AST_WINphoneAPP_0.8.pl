#!/usr/local/ActivePerl-5.8/bin/perl -w
# 
# AST_WINphoneAPP_0.8.pl version 0.8      for Perl/Tk
# by Matt Florell mattf@vicimarketing.com started 2003/10/29
#
# Description:
# - Grabs live call info from a DB updated every second
# - Displays live status of users phones and Zap channels
# - Allows calls to be placed from GUI and directed to phone
# - Allows call recording by click of button
# - Allows conference calling of up to 6 Zap channels through GUI
# - Administrative Hangup of any live Zap channel
# - Administrative switch user function
# - Administrative live monitoring of calls on Zap channels
# - Call Parking sends calls to park ext and then redirects to phone ext
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with Digium
# Zaptel T1 cards and SIP VOIP hardphones or softphones as extensions, it
# could be adapted to other functions, but I designed it specifically for 
# Zap/SIP users. The program will run on UNIX Xwindows and Win32 providing
# the following criteria are met:
# 
# Win32 - ActiveState Perl 5.8.0
# UNIX - Gnome or KDE with Tk/Tcl and perl Tk/Tcl modules loaded
#        + ActiveState 5.8.0 is recommended for Linux due to Perl/Tk memory leak
# Both - Net::MySQL and Net::Telnet perl modules loaded
#
# For this program to work you also need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# On the server side the AST_SQL_update_channels.pl program must always be 
# running on a machine somewhere for the client app to receive live information
# and function properly, also there are Asterisk conf file settings and 
# MySQL databases that must be present for the client app to work. 
# Information on these is detailed in the README file
# 
# Use this command to debug with ptkdb and uncomment Devel::ptkdb module below
# perl -d:ptkdb C:\AST_VICI\AST_WINphoneAPP_0.8.pl  
#  
#
# Distributed with no waranty under the GNU Public License
#

# some script specific initial values
$DASH='-';
$USUS='__';
$park_frame_list_refresh = 0;
$Default_window = 1;
$zap_frame_list_refresh = 1;   
$updater_duplicate_counter = 0;   
$updater_duplicate_value = '';   
$updater_warning_up=0;

require 5.002;

use lib ".\\",".\\libs", './', './libs', '../libs', '/usr/local/perl_TK/libs', 'C:\\AST_VICI\\libs', 'C:\\cygwin\\usr\\local\\perl_TK\\libs';

### Make sure this file is in a libs path or put the absolute path to it
require("AST_VICI_conf.pl");	# local configuration file

#use Devel::ptkdb;	# uncomment if you want to debug with ptkdb

use Net::MySQL;
use Net::Telnet ();

use English;
use Tk;
use Tk::DialogBox;
use Tk::BrowseEntry;

sub start_recording;
sub stop_recording;
sub get_online_sip_users;
sub get_online_channels;
sub get_parked_channels;

sub LaunchBrowser_New ;
sub Dial_Number;
sub Start_Conference;
sub Stop_Conference;
sub Switch_Your_ID;
sub Dial_Outside_Number;

sub Dial_Line;
sub Park_Line;
sub Hangup_Line;
sub Pickup_Line;
sub validate_conf_lines;
sub Join_Conference;
sub Zap_Hangup;
sub Zap_Monitor;
sub View_Parked;

### Create new Perl Tk window instance and name it
	my $MW = MainWindow->new;

	$MW->title("VICI Phone App - 0.8");
	$MW->Label(-text => "Written by Matt Florell <mattf\@vicimarketing.com>")->pack(-side => 'bottom');

	my $ans;

### Time/Date display at the top of the screen
	my $time_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	my $time_value = $time_frame->Entry(-width => '26', -relief => 'sunken')->pack(-side => 'top');

### config file defined phone ID
	my $login_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$login_frame->Label(-text => "your ID:")->pack(-side => 'left');
	my $login_value = $login_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
    $login_value->insert('0', $SIP_user);

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
### Frame for current live phones and live Zap Channels

		my $live_phones_frame = $main_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'right');
		$live_phones_frame->Label(-text => "Busy:            Outside Lines:")->pack(-side => 'top');

		my $zap_frame = $live_phones_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'right');
		my $zap_list_frame = $zap_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### list box for current phones that are on live calls right now
		my $live_zap = $zap_list_frame->Listbox(-relief => 'sunken', 
								 -width => 17, # Shrink to fit
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
			### button at the bottom of the zap listbox to hangup zap channels
			my $zap_hangup_button = $zap_frame->Button(-text => 'Zap Hangup', -width => -1,
						-command => sub 
						{
						 $Zap_Hangup_admin=1;
						 Zap_Hangup;
						});
			$zap_hangup_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
			}

		my $ext_frame = $live_phones_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'right');
		my $ext_list_frame = $ext_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### list box for current live lines that are active and what phones are on them
		my $live_ext = $ext_list_frame->Listbox(-relief => 'sunken', 
								 -width => 9, # Shrink to fit
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

		### button at the bottom of the zap listbox to hangup zap channels
		my $zap_monitor_button = $ext_frame->Button(-text => 'Monitor', -width => -1,
					-command => sub 
					{
					 Zap_Monitor;
					});
		$zap_monitor_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');




########################################################
### Frame for middle buttons and entries

		my $middle_bottons_frame = $main_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

		### button at the bottom of the zap listbox to hangup zap channels
		my $view_park_button = $middle_bottons_frame->Button(-text => 'VIEW PARKED CALLS', -width => -1,
					-command => sub 
					{
					 View_Parked;
					});
		$view_park_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$view_park_button->configure(-state => 'disabled');

		### display field that shows the line that was last parked
			my $last_parked_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'bottom');
			$last_parked_frame->Label(-text => "Parked:")->pack(-side => 'left');
			my $last_parked_value = $last_parked_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
			$last_parked_value->insert('0', '');
			my $last_parked_spacer_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
			$last_parked_spacer_frame->Label(-text => "-----     -----")->pack(-side => 'bottom');

		### button at the bottom of the zap listbox to hangup zap channels
		my $call_park_button = $middle_bottons_frame->Button(-text => 'PARK THIS CALL', -width => -1,
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
		$call_park_button->configure(-state => 'disabled');


	### button at the bottom to dial either a typed in number or a browsebox selected number
		my $dial_outside_number = $middle_bottons_frame->Button(-text => 'DIAL OUTSIDE NUMBER', -width => -1,
					-command => sub 
					{
					 Dial_Outside_Number;
					});
		$dial_outside_number->pack(-side => 'bottom', -expand => 'no', -fill => 'both');

	if ($AGI_call_logging_enabled)
		{
			$recent_dial_listbox=$middle_bottons_frame->BrowseEntry(-background => '#CCCCCC',-label => "Recent:",-width => '2')->pack(-expand => '1', -fill => 'both', -side => 'bottom');
			$recent_dial_listbox->insert('end', '');
		}

		my $dial_number_frame = $middle_bottons_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

		$dial_number_frame->Label(-text => "-----     -----")->pack(-side => 'top');
		$dial_number_frame->Label(-text => "Outside number to dial:")->pack(-side => 'top');
		my $dial_number_value = $dial_number_frame->Entry(-width => '12', -relief => 'sunken')->pack(-side => 'bottom');

		
	### button for a popup internet browser <DEACTIVATED>
		my $LaunchBrowser_New = $middle_bottons_frame->Button(-text => 'popup test', -width => -1,
					-command => sub 
					{
					 LaunchBrowser_New;
					});
		$LaunchBrowser_New->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$LaunchBrowser_New->configure(-state => 'disabled');

	### button for a local call within asterisk to another extension <DEACTIVATED>
		my $local_conf = $middle_bottons_frame->Button(-text => 'intrasystem call', -width => -1,
					-command => sub 
					{
					 Dial_Number;
					});
		$local_conf->pack(-side => 'bottom', -expand => 'no', -fill => 'both');
		$local_conf->configure(-state => 'disabled');


	### button to start recording, only activated if the phone is on an active outside line
		my $start_recording = $middle_bottons_frame->Button(-text => 'START RECORDING', -width => -1,
					-command => sub 
					{
					 start_recording;
					 $RECORD='-';
					});
		$start_recording->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$start_recording->configure(-state => 'disabled');

	### button to stop recording
		my $stop_recording = $middle_bottons_frame->Button(-text => 'STOP RECORDING', -width => -1,
					-command => sub 
					{
					 stop_recording;
					});
		$stop_recording->pack(-side => 'top', -expand => 'no', -fill => 'both');

	### display field that shows -- RECORDING-- during recording active and the length of recording when recording is stopped
		my $rec_msg_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_msg_frame->Label(-text => "RECORDING MESSAGE:")->pack(-side => 'top');
		my $rec_msg_value = $rec_msg_frame->Entry(-width => '25', -relief => 'sunken')->pack(-side => 'top');
		$rec_msg_value->insert('0', '');

	### display field that shows the filename as soon as recording is started
		my $rec_fname_frame = $middle_bottons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_fname_frame->Label(-text => "RECORDING FILENAME:")->pack(-side => 'top');
		my $rec_fname_value = $rec_fname_frame->Entry(-width => '25', -relief => 'sunken')->pack(-side => 'top');
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
		my $initiate_conference = $conf_frame_control->Button(-text => 'START CONFERENCE', -width => -1,
					-command => sub 
					{
					 Start_Conference;
					});
		$initiate_conference->pack(-side => 'right', -expand => 'no', -fill => 'both');
		$initiate_conference->configure(-state => 'disabled');

		my $destroy_conference = $conf_frame_control->Button(-text => 'STOP CONFERENCE', -width => -1,
					-command => sub 
					{
					 Stop_Conference;
					});
		$destroy_conference->pack(-side => 'right', -expand => 'no', -fill => 'both', -before => $initiate_conference);
		$destroy_conference->configure(-state => 'disabled');












################################################################################################################
### Frame for Conferencing <initially hidden>


	### main frame for the conferencing part of the application
		my $conf_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$conf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner pixel

		### conf buttons at the bottom of the conf frame
			my $button_conf_frame = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom');

			my $join_conference = $button_conf_frame->Button(-text => 'JOIN CONFERENCE', -width => -1,
						-command => sub 
						{
						 Join_Conference;
						});
			$join_conference->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$join_conference->configure(-state => 'disabled');

			### Stop Recording button for the conferencing frame

			my $stop_rec_conf = $button_conf_frame->Button(-text => 'Stop Recording', -width => -1,
						-command => sub {
							stop_recording();
							});
			$stop_rec_conf->pack(-side => 'left', -expand => 'no', -fill => 'both');


			### display field that shows the local conference extension that is being used
			my $conf_extension_frame = $button_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'right');
			$conf_extension_frame->Label(-text => "     local conference extension: ")->pack(-side => 'left');
			my $conf_extension_value = $conf_extension_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
			$conf_extension_value->insert('0', '');


		### conf recording fields bottom of the page
			my $rec_fields_conf_frame = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'bottom', -before => $button_conf_frame);

			### display field that shows -- RECORDING-- during recording active and the length of recording when recording is stopped
			my $conf_rec_msg_frame = $rec_fields_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'left');
			$conf_rec_msg_frame->Label(-text => "rec status: ")->pack(-side => 'left');
			my $conf_rec_msg_value = $conf_rec_msg_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
			$conf_rec_msg_value->insert('0', '');

			### display field that shows the filename as soon as recording is started
			my $conf_rec_fname_frame = $rec_fields_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'left');
			$conf_rec_fname_frame->Label(-text => "     filename: ")->pack(-side => 'left');
			my $conf_rec_fname_value = $conf_rec_fname_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
			$conf_rec_fname_value->insert('0', '');

			### display field that shows the unique recording ID in the database only after the recording session is finished
			my $conf_rec_recid_frame = $rec_fields_conf_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'left');
			$conf_rec_recid_frame->Label(-text => "     rec ID: ")->pack(-side => 'left');
			my $conf_rec_recid_value = $conf_rec_recid_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
			$conf_rec_recid_value->insert('0', '');


		### login frame for the buttons and list of the app
			my $login_conf_frame = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			$login_conf_frame->Label(-text => "                                              Channel:                                        Number to Dial:")->pack(-side => 'left');
			$login_conf_frame->Label(-text => "Status:          ")->pack(-side => 'right');


		### line_A frame for the buttons and list of the app
			my $line_conf_frame_A = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_A = $line_conf_frame_A->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_A->insert('0', "");

			$line_conf_frame_A->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_A->Label(-text => "Conference channel A:")->pack(-side => 'left');
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
							$conf_STATUS_channel_A->insert('0', "DIALING $DAIL");
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

			my $conf_line_rec_A = $line_conf_frame_A->Button(-text => 'Record', -width => -1,
						-command => sub {
							$RECORD = $conf_LIVE_channel_A->get;   
							$REC_CHAN='A';   
							$CHAN='A';   
							$conf_STATUS_channel_A->delete('0', 'end');
							$conf_STATUS_channel_A->insert('0', "$RECORD RECORDING");
							start_recording();
							});
			$conf_line_rec_A->pack(-side => 'right', -expand => 'no', -fill => 'both');


		### line_B frame for the buttons and list of the app
			my $line_conf_frame_B = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_B = $line_conf_frame_B->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_B->insert('0', "");

			$line_conf_frame_B->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_B->Label(-text => "Conference channel A:")->pack(-side => 'left');
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
							$conf_STATUS_channel_B->insert('0', "DIALING $DAIL");
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

			my $conf_line_rec_B = $line_conf_frame_B->Button(-text => 'Record', -width => -1,
						-command => sub {
							$RECORD = $conf_LIVE_channel_B->get;   
							$REC_CHAN='B';   
							$CHAN='B';   
							$conf_STATUS_channel_B->delete('0', 'end');
							$conf_STATUS_channel_B->insert('0', "$RECORD RECORDING");
							start_recording();
							});
			$conf_line_rec_B->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$conf_line_rec_B->configure(-state => 'disabled');

		### line_C frame for the buttons and list of the app
			my $line_conf_frame_C = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_C = $line_conf_frame_C->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_C->insert('0', "");

			$line_conf_frame_C->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_C->Label(-text => "Conference channel A:")->pack(-side => 'left');
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
							$conf_STATUS_channel_C->insert('0', "DIALING $DAIL");
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

			my $conf_line_rec_C = $line_conf_frame_C->Button(-text => 'Record', -width => -1,
						-command => sub {
							$RECORD = $conf_LIVE_channel_C->get;   
							$REC_CHAN='C';   
							$CHAN='C';   
							$conf_STATUS_channel_C->delete('0', 'end');
							$conf_STATUS_channel_C->insert('0', "$RECORD RECORDING");
							start_recording();
							});
			$conf_line_rec_C->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$conf_line_rec_C->configure(-state => 'disabled');

		### line_D frame for the buttons and list of the app
			my $line_conf_frame_D = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_D = $line_conf_frame_D->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_D->insert('0', "");

			$line_conf_frame_D->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_D->Label(-text => "Conference channel A:")->pack(-side => 'left');
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
							$conf_STATUS_channel_D->insert('0', "DIALING $DAIL");
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

			my $conf_line_rec_D = $line_conf_frame_D->Button(-text => 'Record', -width => -1,
						-command => sub {
							$RECORD = $conf_LIVE_channel_D->get;   
							$REC_CHAN='D';   
							$CHAN='D';   
							$conf_STATUS_channel_D->delete('0', 'end');
							$conf_STATUS_channel_D->insert('0', "$RECORD RECORDING");
							start_recording();
							});
			$conf_line_rec_D->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$conf_line_rec_D->configure(-state => 'disabled');


		### line_E frame for the buttons and list of the app
			my $line_conf_frame_E = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_E = $line_conf_frame_E->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_E->insert('0', "");

			$line_conf_frame_E->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_E->Label(-text => "Conference channel A:")->pack(-side => 'left');
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
							$conf_STATUS_channel_E->insert('0', "DIALING $DAIL");
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

			my $conf_line_rec_E = $line_conf_frame_E->Button(-text => 'Record', -width => -1,
						-command => sub {
							$RECORD = $conf_LIVE_channel_E->get;   
							$REC_CHAN='E';   
							$CHAN='E';   
							$conf_STATUS_channel_E->delete('0', 'end');
							$conf_STATUS_channel_E->insert('0', "$RECORD RECORDING");
							start_recording();
							});
			$conf_line_rec_E->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$conf_line_rec_E->configure(-state => 'disabled');


		### line_F frame for the buttons and list of the app
			my $line_conf_frame_F = $conf_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

			my $conf_STATUS_channel_F = $line_conf_frame_F->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'right');
				$conf_STATUS_channel_F->insert('0', "");

			$line_conf_frame_F->Label(-text => "   ")->pack(-side => 'right');

			$line_conf_frame_F->Label(-text => "Conference channel A:")->pack(-side => 'left');
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
							$conf_STATUS_channel_F->insert('0', "DIALING $DAIL");
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

			my $conf_line_rec_F = $line_conf_frame_F->Button(-text => 'Record', -width => -1,
						-command => sub {
							$RECORD = $conf_LIVE_channel_F->get;   
							$REC_CHAN='F';   
							$CHAN='F';   
							$conf_STATUS_channel_F->delete('0', 'end');
							$conf_STATUS_channel_F->insert('0', "$RECORD RECORDING");
							start_recording();
							});
			$conf_line_rec_F->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$conf_line_rec_F->configure(-state => 'disabled');

###  END Frame for Conferencing <initially hidden>
################################################################################################################





################################################################################################################
### Frame for Zap Hangup <initially hidden>


	### main frame for the zap hangup part of the application
		my $main_zap_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$main_zap_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1); # hide the frame in the upper-left corner pixel


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

			### Button to kill the selected Zap line
			my $zap_hangup_button = $button_zap_frame->Button(-text => 'HANGUP ZAP LINE', -width => -1,
						-command => sub 
						{
						 $HANGUP = $live_zap_hangup->get('active');
						 $HANGUP =~ s/_.*//gi;
						print "Hanging up ZAP: $HANGUP\n";
						$zap_frame_list_refresh = 1;   
						$CHAN='';   
						 Hangup_Line;
						});
			$zap_hangup_button->pack(-side => 'right', -expand => 'no', -fill => 'both');
			$zap_hangup_button->configure(-state => 'normal');


		#	$button_conf_frame->Label(-text => "     -----     ")->pack(-side => 'bottom');

			### Refresh button to refresh the list of live Zap channels
			my $zap_hangup_refresh = $button_zap_frame->Button(-text => 'REFRESH LIST', -width => -1,
						-command => sub 
						{
						$zap_frame_list_refresh = 1;   
						});
			$zap_hangup_refresh->pack(-side => 'bottom', -expand => 'no', -fill => 'both');

			### Button to leave the Zap Hangup section
			my $zap_close_button = $button_zap_frame->Button(-text => 'BACK TO MAIN', -width => -1,
						-command => sub 
						{
						$main_zap_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1);

						$main_frame->pack(-expand => '1', -fill => 'both', -side => 'top');
						$HANGUP='';
						});
			$zap_close_button->pack(-side => 'bottom', -expand => 'no', -fill => 'both');


### END Frame for Zap Hangup <initially hidden>
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

			### Button to kill the selected Zap line
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

			### Refresh button to refresh the list of live Zap channels
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
	$MW->repeat (1000, \&get_online_channels);
	$MW->repeat (600000, \&get_online_sip_users);
	if ($AGI_call_logging_enabled) {$MW->repeat (60000, \&get_recent_dialed_numbers);}
	if ($conferencing_enabled) {$MW->repeat (1000, \&validate_conf_lines);}

			return;
}

get_parked_channels;

get_online_channels;

get_online_sip_users;

RefreshList();

MainLoop();








##########­##########­##########­##########­##########­##########­##########­##########
##########­##########­##########­##########­##########­##########­##########­##########
### SUBROUTINES GO HERE
##########­##########­##########­##########­##########­##########­##########­##########
##########­##########­##########­##########­##########­##########­##########­##########



##########################################
### Open a new browser window WINDOWS ONLY
##########################################
sub LaunchBrowser_New {
    my $login = $login_value->get;
    my $pass = $SIP_user_list->get('active');

	my $dialog = $MW->DialogBox( -title   => "Vici Phone app",
                                 -buttons => [ "OK" ],
				);
    $dialog->add("Label", -text => "$login $pass ")->pack;
    $dialog->Show;  
}


##########################################
### Switch Login ID to select value in phone list box
##########################################
sub Switch_Your_ID {
    my $login = $login_value->get;
    my $new_ID = $SIP_user_list->get('active');
		$new_ID =~ s/ - .*//gi;
		$SIP_user = $new_ID;

			$login_value->delete('0', 'end');
			$login_value->insert('0', "SIP/$new_ID");

	&get_recent_dialed_numbers;

	my $dialog = $MW->DialogBox( -title   => "Your ID Switch",
                                 -buttons => [ "OK" ],
				);
    $dialog->add("Label", -text => "your ID has been switched\n FROM: $login\n TO: SIP/$new_ID")->pack;
    $dialog->Show;
}







##########################################
### get the list of active online Zap T1 channels from the database
##########################################
sub get_online_channels
{

	$SIP_user = $login_value->get;
	$DBchannels[0]='';
	$channel_counter=0;

		&current_datetime;

		$time_value->delete('0', 'end');
		$time_value->insert('0', $displaydate);


		my $dbh = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
		or 	die "Couldn't connect to database: \n";

#		$live_zap->delete('0', 'end');
#		$live_ext->delete('0', 'end');
if($zap_frame_list_refresh)		{$live_zap->delete('0', 'end');}
if($zap_frame_list_refresh)		{$live_ext->delete('0', 'end');}
		if ($zap_frame_list_refresh) {$live_zap_hangup->delete('0', 'end');}

			if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip' order by extension desc|\n";}

	   $dbh->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip' order by extension desc");
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

#			   $live_zap->insert('0', "$DBchannels[$channel_counter]");
#			   $live_ext->insert('0', "$DBphonelist[$channel_counter]");
if($zap_frame_list_refresh)		{$live_zap->insert('0', "$DBchannels[$channel_counter]");}
if($zap_frame_list_refresh)		{$live_ext->insert('0', "$DBphonelist[$channel_counter]");}

			   if ($zap_frame_list_refresh) {$live_zap_hangup->insert('0', "$DBchannels[$channel_counter]");}
			   if ($SIP_user eq "SIP/$record->[1]")
				{
				$channel_value->delete('0', 'end');
				$channel_value->insert('0', $record->[0]);
				$channel_set=1;
				if (!$record_channel)
					{
					$start_recording->configure(-state => 'normal');
					$dial_outside_number->configure(-state => 'disabled');
					if ($admin_monitor_enabled)
						{
						$zap_monitor_button->configure(-state => 'disabled');
						}
					if ($conferencing_enabled)
						{
						$initiate_conference->configure(-state => 'normal');
						}
					if ($call_parking_enabled)
						{
						$view_park_button->configure(-state => 'disabled');
						$call_park_button->configure(-state => 'normal');
						$park_grab_button->configure(-state => 'disabled');
						}
					}
				if ($conf_dialing_mode)
					{
					if ($conf_dial_CHAN eq "A")
						{
						$conf_LIVE_channel_A->delete('0', 'end');
						$conf_LIVE_channel_A->insert('0', $record->[0]);
						}
					if ($conf_dial_CHAN eq "B")
						{
						$conf_LIVE_channel_B->delete('0', 'end');
						$conf_LIVE_channel_B->insert('0', $record->[0]);
						}
					if ($conf_dial_CHAN eq "C")
						{
						$conf_LIVE_channel_C->delete('0', 'end');
						$conf_LIVE_channel_C->insert('0', $record->[0]);
						}
					if ($conf_dial_CHAN eq "D")
						{
						$conf_LIVE_channel_D->delete('0', 'end');
						$conf_LIVE_channel_D->insert('0', $record->[0]);
						}
					if ($conf_dial_CHAN eq "E")
						{
						$conf_LIVE_channel_E->delete('0', 'end');
						$conf_LIVE_channel_E->insert('0', $record->[0]);
						}
					if ($conf_dial_CHAN eq "F")
						{
						$conf_LIVE_channel_F->delete('0', 'end');
						$conf_LIVE_channel_F->insert('0', $record->[0]);
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
				$dial_outside_number->configure(-state => 'normal');
				if ($admin_monitor_enabled)
					{
					$zap_monitor_button->configure(-state => 'normal');
					}
				else {$zap_monitor_button->configure(-state => 'disabled');}
				if ($conferencing_enabled)
					{
					$initiate_conference->configure(-state => 'disabled');
					}
				if ($call_parking_enabled)
					{
					$view_park_button->configure(-state => 'normal');
					$call_park_button->configure(-state => 'disabled');
					$park_grab_button->configure(-state => 'normal');
					}
				}
		}

	### This section of code is to check if the updater script has been updating the live_channels table
	### if the timestamp hasn't changed for 6 seconds then a popup alert window is opended to let the 
	### user know that the updater is down

		if ($updater_check_enabled)
			{
			$dbh->query("SELECT last_update FROM server_updater where server_ip = '$server_ip'");
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

			if ($updater_duplicate_counter > 5)
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

		$dbh->close;

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
}



##########################################
### Get the current list of parked channels from the database
##########################################
sub get_parked_channels
{

if ($park_frame_list_refresh)
	{

	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

	$live_park_lines->delete('0', 'end');

   $dbhA->query("SELECT channel,extension,parked_time,parked_by FROM parked_channels where server_ip = '$server_ip' order by channel desc");
   if ($dbhA->has_selected_record)
		{
	   $iterA=$dbhA->create_record_iterator;
		 $rec_countA=0;
		   while ( $recordA = $iterA->each)
			{
			   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}
				$Pchannel = sprintf("%-15s", $recordA->[0]);	while (length($Pchannel) > 15) {chop($Pchannel);}
				$Pexten   = sprintf("%-5s", $recordA->[1]);		while (length($Pexten) > 5) {chop($Pexten);}
				$Ptime    = sprintf("%-20s", $recordA->[2]);	while (length($Ptime) > 20) {chop($Ptime);}
				$Ppark_by = sprintf("%-15s", $recordA->[3]);	while (length($Ppark_by) > 15) {chop($Ppark_by);}

			   $live_park_lines->insert('0', "$Pchannel - $Ppark_by - $Pexten - $Ptime");

			$phone_counter++;
		   $rec_countA++;
			} 
		}

		$dbhA->close;
		$park_frame_list_refresh = 0;
	}
}



##########################################
### Get the current list of online SIP users from the database
##########################################
sub get_online_sip_users
{

$zap_frame_list_refresh=1;

if ($Default_window)
	{

	$DBphones[0]='';
	$channel_counter=0;

		&current_datetime;

		$time_value->delete('0', 'end');
		$time_value->insert('0', $displaydate);


		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
		or 	die "Couldn't connect to database: \n";

		$SIP_user_list->delete('0', 'end');

			if($DB){print STDERR "\n|SELECT extension,fullname FROM phones where server_ip = '$server_ip' order by extension desc|\n";}

	   $dbhA->query("SELECT extension,fullname FROM phones where server_ip = '$server_ip' order by extension desc");
	   if ($dbhA->has_selected_record)
		{
	   $iterA=$dbhA->create_record_iterator;
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

		$dbhA->close;
	}
}




##########################################
### Get the list of recently dialed outside numbers from the database
##########################################
sub get_recent_dialed_numbers
{

if ($Default_window)
	{

	$SIP_user = $login_value->get;
	@DBnumbers = @MT;
	$number_counter=0;
	$maxlist_reached=0;

		$recent_dial_listbox->delete('0', 'end');


		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
		or 	die "Couldn't connect to database: \n";

			if($DB){print STDERR "\n|SELECT distinct number_dialed,start_epoch FROM call_log where server_ip = '$server_ip' and channel = '$SIP_user' order by start_epoch desc limit 50|\n";}

	   $dbhA->query("SELECT distinct number_dialed,start_epoch FROM call_log where server_ip = '$server_ip' and channel = '$SIP_user' order by start_epoch desc limit 50;");
	   if ($dbhA->has_selected_record)
		{
	   $iterA=$dbhA->create_record_iterator;
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

		$dbhA->close;
	}
}



##########################################
### Monitor a local Zap channel by selecting an extension
##########################################
sub Zap_Monitor
{

$ext_compare_monitor = $live_ext->get('active');

$monitor_channel = '';

foreach my $x (@DBchannels)
{
	if (!$monitor_channel)
		{
		if ($x =~ /\_$ext_compare_monitor$/)
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

		@outside_dial = @MT;

		$t = new Net::Telnet (Port => 5038,
							  Prompt => '/.*[\$%#>] $/',
							  Output_record_separator => '',);
		#$fh = $t->dump_log("./telnet_log.txt");
		$t->open("$server_ip");
		$t->waitfor('/0\n$/');			# print login
		$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
		$t->waitfor('/Authentication accepted/');		# print auth accepted

			$originate_command  = '';
			$originate_command .= "Action: Originate\n";
			$originate_command .= "Channel: $SIP_user\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $monitor_channel\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk_Monitor\n";
			$originate_command .= "\n";

#	print "\n$originate_command";

		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

		$t->print("Action: Logoff\n\n");

		$ok = $t->close;
	}
}




##########################################
### local conference
##########################################
sub Dial_Number
{
	@place_call = @MT;

   my $first = $SIP_user;
   my $second = $SIP_user_list->get('active');

print "\n./AST_place_call.pl  --channel_1=$first --channel2=$second\n";

    @place_call = $t->cmd("./AST_place_call.pl  --channel_1=$first --channel2=$second");

}


##########################################
### Dial and outside number on the users phone
##########################################
sub Dial_Outside_Number
{
	$SIP_user = $login_value->get;
	$number_to_dial = $dial_number_value->get;

	if (!$number_to_dial)
		{
		$number_to_dial = $recent_dial_listbox->get('active');
		}
	
	$number_to_dial =~ s/\D//gi;

	### error box if improperly formatted number is entered
	if ( (length($number_to_dial) ne 3) && (length($number_to_dial) ne 4) && (length($number_to_dial) ne 7) && (length($number_to_dial) ne 10) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Number Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "Outside number to dial must be:\n- 4 digits for speed-dial\n- 7 digits for a local number\n- 10 digits for a long distance number \n   |$number_to_dial|")->pack;
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

		@outside_dial = @MT;

		$t = new Net::Telnet (Port => 5038,
							  Prompt => '/.*[\$%#>] $/',
							  Output_record_separator => '',);
		#$fh = $t->dump_log("./telnet_log.txt");
		$t->open("$server_ip");
		$t->waitfor('/0\n$/');			# print login
		$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
		$t->waitfor('/Authentication accepted/');		# print auth accepted

			$originate_command  = '';
			$originate_command .= "Action: Originate\n";
			$originate_command .= "Channel: $SIP_user\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $number_to_dial\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "CallerID: Asterisk Client dial\n";
			$originate_command .= "\n";

#	print "\n$originate_command";

		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

		$t->print("Action: Logoff\n\n");

		$ok = $t->close;
	}
}




##########################################
### get the current date and time
##########################################
sub current_datetime
{

$secX = time();
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = ($year + 1900);
	$mon++;
	if ($mon < 10) {$mon = "0$mon";}
	if ($mday < 10) {$mday = "0$mday";}
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}
	if ($sec < 10) {$sec = "0$sec";}
	$filedate = "$year$mon$mday$DASH$hour$min$sec";
	$SQLdate = "$year-$mon-$mday $hour:$min:$sec";
	$displaydate = "   $year/$mon/$mday           $hour:$min:$sec";

}



##########################################
### Start recording - clicked on start recording button
##########################################
sub start_recording
{

$SIP_user = $login_value->get;
$ext = $SIP_user;
$ext =~ s/SIP\///gi;
$filename = "$filedate$US$ext";

$start_recording->configure(-state => 'disabled');
$stop_recording->configure(-state => 'normal');
$initiate_conference->configure(-state => 'disabled');

if (!$RECORD) {$RECORD = '-';}
if (length($RECORD)>4) {$channel = $RECORD;}
else {$channel = $channel_value->get;}

	$channel =~ s/Zap\///gi;
	$record_channel = $channel;


	$t = new Net::Telnet (Port => 5038,
						  Prompt => '/.*[\$%#>] $/',
						  Output_record_separator => '',);
	#$fh = $t->dump_log("./telnet_log.txt");
	$t->open("$server_ip");
	$t->waitfor('/0\n$/');			# print login
	$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
	$t->waitfor('/Authentication accepted/');		# print auth accepted

		$originate_command  = '';
		$originate_command .= "Action: Monitor\n";
		$originate_command .= "Channel: Zap/$channel\n";
		$originate_command .= "File: $filename\n";
		$originate_command .= "\n";

	#	print "\n$originate_command";

	@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

	$t->print("Action: Logoff\n\n");

	$ok = $t->close;


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


	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

		$stmtA = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('Zap/$channel','$server_ip','$SIP_user','$SQLdate','$secX','$filename')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

	$dbhA->close;

	print "|channel:$channel|$filename|\n";

	if (!$REC_CHAN) {$REC_CHAN = '';}
	if ($REC_CHAN =~ /A|B|C|D|E|F/i)
		{
		$conf_line_rec_A->configure(-state => 'disabled');
		$conf_line_rec_B->configure(-state => 'disabled');
		$conf_line_rec_C->configure(-state => 'disabled');
		$conf_line_rec_D->configure(-state => 'disabled');
		$conf_line_rec_E->configure(-state => 'disabled');
		$conf_line_rec_F->configure(-state => 'disabled');
		}

}


##########################################
### Stop recording - clicked on stop recording button
##########################################
sub stop_recording
{

$SIP_user = $login_value->get;

if (!$record_channel)
	{
	if (!$RECORD) {$RECORD = '-';}
	if (length($RECORD)>4) {$channel = $RECORD;}
	else {$channel = $channel_value->get;}
	$channel =~ s/Zap\///gi;
	$record_channel = $channel;
	}

	$t = new Net::Telnet (Port => 5038,
						  Prompt => '/.*[\$%#>] $/',
						  Output_record_separator => '',);
	#$fh = $t->dump_log("./telnet_log.txt");
	$t->open("$server_ip");
	$t->waitfor('/0\n$/');			# print login
	$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
	$t->waitfor('/Authentication accepted/');		# print auth accepted

		$originate_command  = '';
		$originate_command .= "Action: StopMonitor\n";
		$originate_command .= "Channel: Zap/$record_channel\n";
		$originate_command .= "\n";

	#	print "\n$originate_command";

	@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

	$t->print("Action: Logoff\n\n");

	$ok = $t->close;



	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

	   $dbhA->query("SELECT recording_id,start_epoch FROM recording_log where filename='$filename'");
	   if ($dbhA->has_selected_record) {
	   $iter=$dbhA->create_record_iterator;
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

		$stmtA = "UPDATE recording_log set end_time='$SQLdate',end_epoch='$secX',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename'";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
		}
	$dbhA->close;

	print "|channel:$channel|$record_channel|$filename|\n";

	$rec_msg_value->delete('0', 'end');
    $rec_msg_value->insert('0', "Length: $length_in_min Min.");
    $rec_recid_value->insert('0', "$recording_id");

	$conf_rec_msg_value->delete('0', 'end');
    $conf_rec_msg_value->insert('0', "Length: $length_in_min Min.");
    $conf_rec_recid_value->insert('0', "$recording_id");

$record_channel='';

$start_recording->configure(-state => 'normal');
$stop_recording->configure(-state => 'disabled');
if ($conferencing_enabled)
	{
	$initiate_conference->configure(-state => 'normal');
	}

	if (!$REC_CHAN) {$REC_CHAN = '';}
	if ($REC_CHAN =~ /A|B|C|D|E|F/i)
		{
		$conf_line_rec_A->configure(-state => 'normal');
		$conf_line_rec_B->configure(-state => 'normal');
		$conf_line_rec_C->configure(-state => 'normal');
		$conf_line_rec_D->configure(-state => 'normal');
		$conf_line_rec_E->configure(-state => 'normal');
		$conf_line_rec_F->configure(-state => 'normal');
		}
	if ($REC_CHAN =~ /A/i)
		{
		$conf_STATUS_channel_A->delete('0', 'end');
		$conf_STATUS_channel_A->insert('0', "$RECORD STOP REC");
		}
	if ($REC_CHAN =~ /B/i)
		{
		$conf_STATUS_channel_B->delete('0', 'end');
		$conf_STATUS_channel_B->insert('0', "$RECORD STOP REC");
		}
	if ($REC_CHAN =~ /C/i)
		{
		$conf_STATUS_channel_C->delete('0', 'end');
		$conf_STATUS_channel_C->insert('0', "$RECORD STOP REC");
		}
	if ($REC_CHAN =~ /D/i)
		{
		$conf_STATUS_channel_D->delete('0', 'end');
		$conf_STATUS_channel_D->insert('0', "$RECORD STOP REC");
		}
	if ($REC_CHAN =~ /E/i)
		{
		$conf_STATUS_channel_E->delete('0', 'end');
		$conf_STATUS_channel_E->insert('0', "$RECORD STOP REC");
		}
	if ($REC_CHAN =~ /F/i)
		{
		$conf_STATUS_channel_F->delete('0', 'end');
		$conf_STATUS_channel_F->insert('0', "$RECORD STOP REC");
		}

$REC_CHAN='';

}



##########################################
### Zap Hangup subroutine, launches zap hangup window
##########################################
sub Zap_Hangup
{

	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>2, -y=>1);

	$main_zap_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

	$zap_frame_list_refresh = 1;   

}


##########################################
### View_Parked subroutine, launches view parked calls window
##########################################
sub View_Parked
{

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
sub Start_Conference {
	$Default_window = 0;
    $SIP_user = $login_value->get;
	$LIVE_channel_A = $channel_value->get;

$join_conference->configure(-state => 'normal');
$destroy_conference->configure(-state => 'normal');
$initiate_conference->configure(-state => 'disabled');

$conf_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1);

	$conf_LIVE_channel_A->delete('0', 'end');
	$conf_LIVE_channel_A->insert('0', "$LIVE_channel_A");


	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

	   $dbhA->query("SELECT conf_exten FROM conferences where server_ip='$server_ip' and extension='' limit 1");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
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
		$stmtA = "UPDATE conferences set extension='$SIP_user' where server_ip='$server_ip' and conf_exten='$NEW_conf'";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
		}
	$dbhA->close;

	$conf_extension_value->insert('0', "$NEW_conf");

}



##########################################
### Destroy a conference call
##########################################
sub Stop_Conference {
    $SIP_user = $login_value->get;
	$LIVE_channel_A = $channel_value->get;

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
$initiate_conference->configure(-state => 'disabled');

$HANGUP = $conf_LIVE_channel_A->get; 
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_B->get; 
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_C->get; 
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_D->get; 
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_E->get; 
	&Hangup_Line;
$HANGUP = $conf_LIVE_channel_F->get; 
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

	$conf_line_park_A->configure(-state => 'normal');
	$conf_line_hangup_A->configure(-state => 'normal');

	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

	$stmtA = "UPDATE conferences set extension='' where server_ip='$server_ip' and conf_exten='$NEW_conf'";

	#print STDERR "\n|$stmtA|\n";
	$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
	$dbhA->close;

	$NEW_conf='';

	$conf_extension_value->delete('0', 'end');

}





##########################################
### Dial and outside number on the users phone
##########################################
sub Dial_Line()
{

	$conf_dialing_mode = 1;
	$conf_dial_CHAN = "$CHAN";
	$SIP_user = $login_value->get;
	$number_to_dial = $DIAL;

	$number_to_dial =~ s/\D//gi;

	### error box if improperly formatted number is entered
	if ( (length($number_to_dial) ne 3) && (length($number_to_dial) ne 4) && (length($number_to_dial) ne 7) && (length($number_to_dial) ne 10) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Number Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "Outside number to dial must be:\n- 4 digits for speed-dial\n- 7 digits for a local number\n- 10 digits for a long distance number \n   |$number_to_dial|")->pack;
		$dialog->Show;  
	}

	### place the phone call through the Manager interface of Asterisk
	else
	{
		$recent_dial_listbox->insert('0', $number_to_dial);
		$dial_number_value->delete('0', 'end');

		if (length($number_to_dial) == 7) {$number_to_dial = "9$number_to_dial";}
		if (length($number_to_dial) == 10) {$number_to_dial = "91$number_to_dial";}

		@outside_dial = @MT;

		$t = new Net::Telnet (Port => 5038,
							  Prompt => '/.*[\$%#>] $/',
							  Output_record_separator => '',);
		#$fh = $t->dump_log("./telnet_log.txt");
		$t->open("$server_ip");
		$t->waitfor('/0\n$/');			# print login
		$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
		$t->waitfor('/Authentication accepted/');		# print auth accepted

			$originate_command  = '';
			$originate_command .= "Action: Originate\n";
			$originate_command .= "Channel: $SIP_user\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $number_to_dial\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "CallerID: Asterisk Client dial\n";
			$originate_command .= "\n";

#	print "\n$originate_command";

		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

		$t->print("Action: Logoff\n\n");

		$ok = $t->close;

	if ($CHAN eq 'A')
		{
		$conf_line_hangup_A->configure(-state => 'normal');
		$conf_line_park_A->configure(-state => 'normal');
		$conf_line_dial_A->configure(-state => 'disabled');
		if (!$REC_CHAN) {$conf_line_rec_A->configure(-state => 'normal');}
		}
	if ($CHAN eq 'B')
		{
		$conf_line_hangup_B->configure(-state => 'normal');
		$conf_line_park_B->configure(-state => 'normal');
		$conf_line_dial_B->configure(-state => 'disabled');
		if (!$REC_CHAN) {$conf_line_rec_B->configure(-state => 'normal');}
		}
	if ($CHAN eq 'C')
		{
		$conf_line_hangup_C->configure(-state => 'normal');
		$conf_line_park_C->configure(-state => 'normal');
		$conf_line_dial_C->configure(-state => 'disabled');
		if (!$REC_CHAN) {$conf_line_rec_C->configure(-state => 'normal');}
		}
	if ($CHAN eq 'D')
		{
		$conf_line_hangup_D->configure(-state => 'normal');
		$conf_line_park_D->configure(-state => 'normal');
		$conf_line_dial_D->configure(-state => 'disabled');
		if (!$REC_CHAN) {$conf_line_rec_D->configure(-state => 'normal');}
		}
	if ($CHAN eq 'E')
		{
		$conf_line_hangup_E->configure(-state => 'normal');
		$conf_line_park_E->configure(-state => 'normal');
		$conf_line_dial_E->configure(-state => 'disabled');
		if (!$REC_CHAN) {$conf_line_rec_E->configure(-state => 'normal');}
		}
	if ($CHAN eq 'F')
		{
		$conf_line_hangup_F->configure(-state => 'normal');
		$conf_line_park_F->configure(-state => 'normal');
		$conf_line_dial_F->configure(-state => 'disabled');
		if (!$REC_CHAN) {$conf_line_rec_F->configure(-state => 'normal');}
		}

	}


}




##########################################
### Park Line on MusicOnHold
##########################################
sub Park_Line()
{

		@outside_dial = @MT;

if (length($PARK)>4)
	{

		$t = new Net::Telnet (Port => 5038,
							  Prompt => '/.*[\$%#>] $/',
							  Output_record_separator => '',);
		#$fh = $t->dump_log("./telnet_log.txt");
		$t->open("$server_ip");
		$t->waitfor('/0\n$/');			# print login
		$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
		$t->waitfor('/Authentication accepted/');		# print auth accepted

			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $PARK\n";
			$originate_command .= "Context: demo\n";
			if ($main_call_park)
				{
				$originate_command .= "Exten: $park_on_extension\n";
				$park_extension = 'park';
				}
			else
				{
				$originate_command .= "Exten: $conf_on_extension\n";
				$park_extension = 'conf';
				}
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk park\n";
			$originate_command .= "\n";

#	print "\n$originate_command";

		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

		$t->print("Action: Logoff\n\n");

		$ok = $t->close;
	


		### insert parked call into parked_channels table
		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
		or 	die "Couldn't connect to database: \n";

		$stmtA = "INSERT INTO parked_channels values('$PARK','$server_ip','','$park_extension','$SIP_user','$SQLdate');";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

		$dbhA->close;


	if ($CHAN eq 'A')
		{
		$conf_line_hangup_A->configure(-state => 'normal');
		$conf_line_park_A->configure(-state => 'disabled');
		$conf_line_dial_A->configure(-state => 'disabled');
		}
	if ($CHAN eq 'B')
		{
		$conf_line_hangup_B->configure(-state => 'normal');
		$conf_line_park_B->configure(-state => 'disabled');
		$conf_line_dial_B->configure(-state => 'disabled');
		}
	if ($CHAN eq 'C')
		{
		$conf_line_hangup_C->configure(-state => 'normal');
		$conf_line_park_C->configure(-state => 'disabled');
		$conf_line_dial_C->configure(-state => 'disabled');
		}
	if ($CHAN eq 'D')
		{
		$conf_line_hangup_D->configure(-state => 'normal');
		$conf_line_park_D->configure(-state => 'disabled');
		$conf_line_dial_D->configure(-state => 'disabled');
		}
	if ($CHAN eq 'E')
		{
		$conf_line_hangup_E->configure(-state => 'normal');
		$conf_line_park_E->configure(-state => 'disabled');
		$conf_line_dial_E->configure(-state => 'disabled');
		}
	if ($CHAN eq 'F')
		{
		$conf_line_hangup_F->configure(-state => 'normal');
		$conf_line_park_F->configure(-state => 'disabled');
		$conf_line_dial_F->configure(-state => 'disabled');
		}

		&validate_conf_lines;
	}
}



##########################################
### Hangup Line
##########################################
sub Hangup_Line()
{

		@outside_dial = @MT;

if (length($HANGUP)>4)
	{
		$t = new Net::Telnet (Port => 5038,
							  Prompt => '/.*[\$%#>] $/',
							  Output_record_separator => '',);
		#$fh = $t->dump_log("./telnet_log.txt");
		$t->open("$server_ip");
		$t->waitfor('/0\n$/');			# print login
		$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
		$t->waitfor('/Authentication accepted/');		# print auth accepted

			$originate_command  = '';
			$originate_command .= "Action: Hangup\n";
			$originate_command .= "Channel: $HANGUP\n";
			$originate_command .= "\n";

#	print "\n$originate_command";

		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

		$t->print("Action: Logoff\n\n");

		$ok = $t->close;
	
		### delete call from parked_channels table
		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
		or 	die "Couldn't connect to database: \n";
		$stmtA = "DELETE FROM parked_channels where channel='$HANGUP' and server_ip = '$server_ip';";
		$dbhA->query($stmtA);
		$dbhA->close;


	if ($CHAN eq 'A')
		{
		$conf_line_hangup_A->configure(-state => 'disabled');
		$conf_line_park_A->configure(-state => 'disabled');
		$conf_line_dial_A->configure(-state => 'normal');
		$conf_line_rec_A->configure(-state => 'disabled');
		}
	if ($CHAN eq 'B')
		{
		$conf_line_hangup_B->configure(-state => 'disabled');
		$conf_line_park_B->configure(-state => 'disabled');
		$conf_line_dial_B->configure(-state => 'normal');
		$conf_line_rec_B->configure(-state => 'disabled');
		}
	if ($CHAN eq 'C')
		{
		$conf_line_hangup_C->configure(-state => 'disabled');
		$conf_line_park_C->configure(-state => 'disabled');
		$conf_line_dial_C->configure(-state => 'normal');
		$conf_line_rec_C->configure(-state => 'disabled');
		}
	if ($CHAN eq 'D')
		{
		$conf_line_hangup_D->configure(-state => 'disabled');
		$conf_line_park_D->configure(-state => 'disabled');
		$conf_line_dial_D->configure(-state => 'normal');
		$conf_line_rec_D->configure(-state => 'disabled');
		}
	if ($CHAN eq 'E')
		{
		$conf_line_hangup_E->configure(-state => 'disabled');
		$conf_line_park_E->configure(-state => 'disabled');
		$conf_line_dial_E->configure(-state => 'normal');
		$conf_line_rec_E->configure(-state => 'disabled');
		}
	if ($CHAN eq 'F')
		{
		$conf_line_hangup_F->configure(-state => 'disabled');
		$conf_line_park_F->configure(-state => 'disabled');
		$conf_line_dial_F->configure(-state => 'normal');
		$conf_line_rec_F->configure(-state => 'disabled');
		}
	}
}



##########################################
### Pickup Line on Parked Lines
##########################################
sub Pickup_Line()
{

		@outside_dial = @MT;

	$DB_SIP_USER = $SIP_user;
	$DB_SIP_USER =~ s/SIP\///gi;

if (length($PICKUP)>4)
	{

	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

   $dbhA->query("SELECT dialplan_number FROM phones where server_ip='$server_ip' and extension='$DB_SIP_USER' limit 1");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each)
		   {
		   print STDERR $record->[0]," - extension cal sent to\n";
		   $SIP_extension = "$record->[0]";
		   $rec_count++;
		   } 
	   }
	$dbhA->close;


		$t = new Net::Telnet (Port => 5038,
							  Prompt => '/.*[\$%#>] $/',
							  Output_record_separator => '',);
		#$fh = $t->dump_log("./telnet_log.txt");
		$t->open("$server_ip");
		$t->waitfor('/0\n$/');			# print login
		$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
		$t->waitfor('/Authentication accepted/');		# print auth accepted

			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $PICKUP\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $SIP_extension\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk pickup\n";
			$originate_command .= "\n";

#	print "\n$originate_command";

		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response: Success.*/'); 

		$t->print("Action: Logoff\n\n");

		$ok = $t->close;
	

		### delete call from parked_channels table
		my $dbhB = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
		or 	die "Couldn't connect to database: \n";
		$stmtB = "DELETE FROM parked_channels where channel='$PICKUP' and server_ip = '$server_ip';";
		$dbhB->query($stmtB);
		$dbhB->close;


	}
}




##########################################
### VALIDATE THAT CONFERENCE LINES ARE STILL ONLINE
##########################################
sub validate_conf_lines
{
if (!$Default_window)
	{
		$CHAN_A_LIVE_CHECK = $conf_LIVE_channel_A->get; 
		$CHAN_B_LIVE_CHECK = $conf_LIVE_channel_B->get;
		$CHAN_C_LIVE_CHECK = $conf_LIVE_channel_C->get;
		$CHAN_D_LIVE_CHECK = $conf_LIVE_channel_D->get;
		$CHAN_E_LIVE_CHECK = $conf_LIVE_channel_E->get;
		$CHAN_F_LIVE_CHECK = $conf_LIVE_channel_F->get;


		my $dbh = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
		or 	die "Couldn't connect to database: \n";

		if (length($CHAN_A_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_A_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_A_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_A->configure(-state => 'disabled');
				$conf_line_park_A->configure(-state => 'disabled');
				$conf_line_dial_A->configure(-state => 'normal');
				$conf_line_rec_A->configure(-state => 'disabled');
				$conf_STATUS_channel_A->delete('0', 'end');
				$conf_STATUS_channel_A->insert('0', "$CHAN_A_LIVE_CHECK DIED");
				$conf_LIVE_channel_A->delete('0', 'end');
				$conf_LIVE_channel_A->insert('0', "BAD");
				}
			}
		if (length($CHAN_B_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_B_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_B_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_B->configure(-state => 'disabled');
				$conf_line_park_B->configure(-state => 'disabled');
				$conf_line_dial_B->configure(-state => 'normal');
				$conf_line_rec_B->configure(-state => 'disabled');
				$conf_STATUS_channel_B->delete('0', 'end');
				$conf_STATUS_channel_B->insert('0', "$CHAN_B_LIVE_CHECK DIED");
				$conf_LIVE_channel_B->delete('0', 'end');
				$conf_LIVE_channel_B->insert('0', "BAD");
				}
			}

		if (length($CHAN_C_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_C_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_C_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_C->configure(-state => 'disabled');
				$conf_line_park_C->configure(-state => 'disabled');
				$conf_line_dial_C->configure(-state => 'normal');
				$conf_line_rec_C->configure(-state => 'disabled');
				$conf_STATUS_channel_C->delete('0', 'end');
				$conf_STATUS_channel_C->insert('0', "$CHAN_C_LIVE_CHECK DIED");
				$conf_LIVE_channel_C->delete('0', 'end');
				$conf_LIVE_channel_C->insert('0', "BAD");
				}
			}

		if (length($CHAN_D_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_D_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_D_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_D->configure(-state => 'disabled');
				$conf_line_park_D->configure(-state => 'disabled');
				$conf_line_dial_D->configure(-state => 'normal');
				$conf_line_rec_D->configure(-state => 'disabled');
				$conf_STATUS_channel_D->delete('0', 'end');
				$conf_STATUS_channel_D->insert('0', "$CHAN_D_LIVE_CHECK DIED");
				$conf_LIVE_channel_D->delete('0', 'end');
				$conf_LIVE_channel_D->insert('0', "BAD");
				}
			}

		if (length($CHAN_E_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_E_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_E_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_E->configure(-state => 'disabled');
				$conf_line_park_E->configure(-state => 'disabled');
				$conf_line_dial_E->configure(-state => 'normal');
				$conf_line_rec_E->configure(-state => 'disabled');
				$conf_STATUS_channel_E->delete('0', 'end');
				$conf_STATUS_channel_E->insert('0', "$CHAN_E_LIVE_CHECK DIED");
				$conf_LIVE_channel_E->delete('0', 'end');
				$conf_LIVE_channel_E->insert('0', "BAD");
				}
			}

		if (length($CHAN_F_LIVE_CHECK)>4)
			{
			if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_F_LIVE_CHECK';|\n";}

			$dbh->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip' and channel = '$CHAN_F_LIVE_CHECK';");
			$rec_count=0;
			if ($dbh->has_selected_record)
			{$iter=$dbh->create_record_iterator;   while ( $record = $iter->each) {$rec_count++;} }
			if (!$rec_count) 
				{
				$conf_line_hangup_F->configure(-state => 'disabled');
				$conf_line_park_F->configure(-state => 'disabled');
				$conf_line_dial_F->configure(-state => 'normal');
				$conf_line_rec_F->configure(-state => 'disabled');
				$conf_STATUS_channel_F->delete('0', 'end');
				$conf_STATUS_channel_F->insert('0', "$CHAN_F_LIVE_CHECK DIED");
				$conf_LIVE_channel_F->delete('0', 'end');
				$conf_LIVE_channel_F->insert('0', "BAD");
				}
			}

			$dbh->close;

	}

}



##########################################
### Join Conference
##########################################
sub Join_Conference()
{

		$CHAN_A_JOIN_CHECK = $conf_LIVE_channel_A->get; 
		$CHAN_B_JOIN_CHECK = $conf_LIVE_channel_B->get;
		$CHAN_C_JOIN_CHECK = $conf_LIVE_channel_C->get;
		$CHAN_D_JOIN_CHECK = $conf_LIVE_channel_D->get;
		$CHAN_E_JOIN_CHECK = $conf_LIVE_channel_E->get;
		$CHAN_F_JOIN_CHECK = $conf_LIVE_channel_F->get;

		@outside_dial = @MT;

		$t = new Net::Telnet (Port => 5038,
							  Prompt => '/.*[\$%#>] $/',
							  Output_record_separator => '',);
		#$fh = $t->dump_log("./telnet_log.txt");
		$t->open("$server_ip");
		$t->waitfor('/0\n$/');			# print login
		$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
		$t->waitfor('/Authentication accepted/');		# print auth accepted

		if (length($SIP_user)>4)
			{
			$originate_command  = '';
			$originate_command .= "Action: Originate\n";
			$originate_command .= "Channel: $SIP_user\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $NEW_conf\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk conf\n";
			$originate_command .= "\n";
		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response:.*/'); 
			}
		if (length($CHAN_A_LIVE_CHECK)>4)
			{
			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $CHAN_A_JOIN_CHECK\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $NEW_conf\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk conf\n";
			$originate_command .= "\n";
		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response:.*/'); 
			}
		if (length($CHAN_B_LIVE_CHECK)>4)
			{
			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $CHAN_B_JOIN_CHECK\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $NEW_conf\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk conf\n";
			$originate_command .= "\n";
		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response:.*/'); 
			}
		if (length($CHAN_C_LIVE_CHECK)>4)
			{
			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $CHAN_C_JOIN_CHECK\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $NEW_conf\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk conf\n";
			$originate_command .= "\n";
		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response:.*/'); 
			}
		if (length($CHAN_D_LIVE_CHECK)>4)
			{
			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $CHAN_D_JOIN_CHECK\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $NEW_conf\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk conf\n";
			$originate_command .= "\n";
		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response:.*/'); 
			}
		if (length($CHAN_E_LIVE_CHECK)>4)
			{
			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $CHAN_E_JOIN_CHECK\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $NEW_conf\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk conf\n";
			$originate_command .= "\n";
		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response:.*/'); 
			}
		if (length($CHAN_F_LIVE_CHECK)>4)
			{
			$originate_command  = '';
			$originate_command .= "Action: Redirect\n";
			$originate_command .= "Channel: $CHAN_F_JOIN_CHECK\n";
			$originate_command .= "Context: demo\n";
			$originate_command .= "Exten: $NEW_conf\n";
			$originate_command .= "Priority: 1\n";
			$originate_command .= "Callerid: Asterisk conf\n";
			$originate_command .= "\n";
		@outside_dial = $t->cmd(String => "$originate_command", Prompt => '/Response:.*/'); 
			}


		$t->print("Action: Logoff\n\n");

		$ok = $t->close;
	
}




