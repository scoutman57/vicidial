#!/usr/local/ActivePerl-5.8/bin/perl -w
# 
# AST_VICIDIAL_0.3.pl version 0.3      for Perl/Tk
# by Matt Florell mattf@vicimarketing.com started 2004/01/06
#
# Description:
#
# SUMMARY:
# This program was designed for 
# 
# Win32 - ActiveState Perl 5.8.0
# UNIX - Gnome or KDE with Tk/Tcl and perl Tk/Tcl modules loaded
# Both - Net::MySQL and Net::Telnet perl modules loaded
#
# For this program to work you also need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# On the server side the AST_update.pl program must always be 
# running on a machine somewhere for the client app to receive live information
# and function properly, also there are Asterisk conf file settings and 
# MySQL databases that must be present for the client app to work. 
# Information on these is detailed in the README file
# 
# Use this command to debug with ptkdb and uncomment Devel::ptkdb module below
# perl -d:ptkdb C:\AST_VICI\AST_VICIDIAL_0.3.pl  
#  
#
# version 2 will no longer have direct interaction with the manager interface
# this leads to way too many crashes of the Asterisk server. Instead this
# program will submit manager commands to a table in the MySQL DB for a command
# running program to blindly execute, and then a listen-only program will update
# the status of the command in the table This is called the Asterisk Central 
# Queue System(ACQS)
# 
# Distributed with no waranty under the GNU Public License
#

# some script specific initial values
$DB=1;
$DASH='-';
$USUS='__';
$park_frame_list_refresh = 0;
$Default_window = 1;
$zap_frame_list_refresh = 1;   
$updater_duplicate_counter = 0;   
$updater_duplicate_value = '';   
$updater_warning_up=0;
$session_id = '';
$START_DIALING=0;
$call_length_in_seconds=0;
$INCALL=0;
$zap_validation_count=0;
$CONF_RING_MONITOR_on = 0;
$LOGfile="VICIDIAL.log";
$local_DEF = 'Local/';
$local_AMP = '@';


	$SI_manager_command_sent = 0;


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

sub current_datetime;

sub login_system;
sub logout_system;

sub start_dialing;
sub stop_dialing;
sub start_recording;
sub stop_recording;
sub hangup_customer;
sub transfer_call;

### Create new Perl Tk window instance and name it
	my $MW = MainWindow->new;

	$MW->title("VICIDIAL App - 0.3");
	$MW->Label(-text => "Written by Matt Florell <mattf\@vicimarketing.com>")->pack(-side => 'bottom');

	my $ans;

### Time/Date display and sessionID at the top of the screen
	my $time_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
	$time_frame->Label(-text => "Time:")->pack(-side => 'left');
	my $time_value = $time_frame->Entry(-width => '26', -relief => 'sunken')->pack(-side => 'left');
	my $system_ext_value = $time_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
	$time_frame->Label(-text => "     Session ID:")->pack(-side => 'right');

### config file defined phone ID
	$time_frame->Label(-text => "     Phone ID:")->pack(-side => 'left');
	my $login_value = $time_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
    $login_value->insert('0', $SIP_user);


	my $login_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

	### login into the system frame
		my $login_system_frame = $login_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');

		### user ID entry field
		my $user_frame = $login_system_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$user_frame->Label(-text => "           User ID:")->pack(-side => 'left');
		my $user_value = $user_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$user_value->insert('0', $login_user);

		### password entry field
		my $pass_frame = $login_system_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$pass_frame->Label(-text => "     Password:")->pack(-side => 'left');
		my $pass_value = $pass_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$pass_value->insert('0', $login_pass);

		### campaign entry field
		my $campaign_frame = $login_system_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$campaign_frame->Label(-text => "     Campaign:")->pack(-side => 'left');
		my $campaign_value = $campaign_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$campaign_value->insert('0', $login_campaign);

		### login button frame, initially viewed
		my $login_button_frame = $login_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		my $login_system_button = $login_button_frame->Button(-text => 'LOGIN', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|login_system_button|||";
					 &event_logger();
					 login_system;
					});
		$login_system_button->pack(-side => 'right', -expand => 'no', -fill => 'both');

		### logout button frame, initially hidden
		my $logout_button_frame = $login_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
	$logout_button_frame->place(-in=>$login_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner
		### button at the bottom of the zap listbox to hangup zap channels
		my $logout_system_button = $logout_button_frame->Button(-text => 'LOGOUT', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|logout_system_button|||";
					 &event_logger();
					 logout_system;
					});
		$logout_system_button->pack(-side => 'right', -expand => 'no', -fill => 'both');


	my $status_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');
		### status display field
		my $status_display_frame = $status_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'left');
		$status_display_frame->Label(-text => "STATUS:")->pack(-side => 'left');
		my $status_value = $status_display_frame->Entry(-width => '70', -relief => 'sunken')->pack(-side => 'left');
		$status_value->insert('0', "READY");


########################################################
### main frame for the dialer app
	my $main_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top');

#		$main_frame->Label(-text => "  ")->pack(-side => 'top');
	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner

	########################################################
	### buttons at the left side of the main dialer frame
		my $dial_buttons_frame = $main_frame->Frame()->pack(-expand => '0', -fill => 'y', -side => 'left');
		my $start_dialing_button = $dial_buttons_frame->Button(-text => 'DIAL NEXT NUMBER', -width => -1,
					-command => sub 
					{
						$status_value->delete('0', 'end');
						$status_value->insert('0', "Dialing next number ---- DO NOT CLOSE WINDOW");


						$event_string = "CLICK|start_dialing_button|||";
					 &event_logger();
					 start_dialing;
					});
		$start_dialing_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
	#	$start_dialing_button->configure(-state => 'normal');

		my $start_recording_button = $dial_buttons_frame->Button(-text => 'START RECORDING', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|start_recording_button|||";
					 &event_logger();
					 start_recording;
					});
		$start_recording_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
	#	$start_recording_button->configure(-state => 'disabled');

		my $stop_recording_button = $dial_buttons_frame->Button(-text => 'STOP RECORDING', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|stop_recording_button|||";
					 &event_logger();
					 stop_recording;
					});
		$stop_recording_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$stop_recording_button->configure(-state => 'disabled');

	### display field that shows the filename as soon as recording is started
		my $rec_fname_frame = $dial_buttons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_fname_frame->Label(-text => "RECORDING FILENAME:")->pack(-side => 'top');
		my $rec_fname_value = $rec_fname_frame->Entry(-width => '25', -relief => 'sunken')->pack(-side => 'top');
		$rec_fname_value->insert('0', '');

	### display field that shows the unique recording ID in the database only after the recording session is finished
		my $rec_recid_frame = $dial_buttons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_recid_frame->Label(-text => "RECORDING ID:")->pack(-side => 'left');
		my $rec_recid_value = $rec_recid_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
		$rec_recid_value->insert('0', '');

		my $rec_recid_spacer_frame = $dial_buttons_frame->Frame()->pack(-expand => '2', -fill => 'both', -side => 'top');
		$rec_recid_spacer_frame->Label(-text => "-----     -----")->pack(-side => 'bottom');

		my $customer_hungup_button = $dial_buttons_frame->Button(-text => 'CUSTOMER HUNGUP ', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|customer_hungup_button|||";
					 &event_logger();
					 customer_hungup();
					});
		$customer_hungup_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$customer_hungup_button->configure(-state => 'disabled');

		my $hangup_customer_button = $dial_buttons_frame->Button(-text => 'HANGUP CUSTOMER', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|hangup_customer_button|||";
					 &event_logger();
					$customer_hungup_button->configure(-state => 'normal');
					 hangup_customer;
					});
		$hangup_customer_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$hangup_customer_button->configure(-state => 'disabled');

		my $transfer_call_button = $dial_buttons_frame->Button(-text => 'TRANSFER - CONF', -width => -1,
					-command => sub 
					{
						$event_string = "CLICK|transfer_call_button|||";
					 &event_logger();
					 transfer_call;
					});
		$transfer_call_button->pack(-side => 'top', -expand => 'no', -fill => 'both');
		$transfer_call_button->configure(-state => 'disabled');

	########################################################
	### spacer frome of the main dialer frame
		my $middle_spacer_frame = $main_frame->Frame()->pack(-expand => '0', -fill => 'none', -side => 'left');

		$middle_spacer_frame->Label(-text => "  ")->pack(-side => 'top');


	########################################################
	### call info at the right side of the main dialer frame
		my $dial_info_frame = $main_frame->Frame()->pack(-expand => '1', -fill => 'none', -side => 'right', -anchor   => "nw");

		$dial_info_frame->Label(-text => " ")->pack(-side => 'top');

		### call system display-only fields
		my $call_sys_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$call_sys_frame->Label(-text => "Dial Code:")->pack(-side => 'left');
		my $dial_code_value = $call_sys_frame->Entry(-width => '6', -relief => 'sunken')->pack(-side => 'left');
		$dial_code_value->insert('0', '');
		$call_sys_frame->Label(-text => "  Call Length:")->pack(-side => 'left');
		my $call_length_value = $call_sys_frame->Entry(-width => '5', -relief => 'sunken')->pack(-side => 'left');
		$call_length_value->insert('0', '');
		$call_sys_frame->Label(-text => "  Zap:")->pack(-side => 'left');
		my $zap_channel_value = $call_sys_frame->Entry(-width => '12', -relief => 'sunken')->pack(-side => 'left');
		$zap_channel_value->insert('0', '');

#		$dial_info_frame->Label(-text => " ")->pack(-side => 'top');
		$dial_info_frame->Label(-text => "Customer Information:")->pack(-side => 'top');

		### full name entry fields
		my $full_name_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$full_name_frame->Label(-text => "Title:     ")->pack(-side => 'left');
		my $title_name_value = $full_name_frame->Entry(-width => '4', -relief => 'sunken')->pack(-side => 'left');
		$title_name_value->insert('0', '');
		$full_name_frame->Label(-text => " First:")->pack(-side => 'left');
		my $first_name_value = $full_name_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$first_name_value->insert('0', '');
		$full_name_frame->Label(-text => " MI:")->pack(-side => 'left');
		my $middle_name_value = $full_name_frame->Entry(-width => '1', -relief => 'sunken')->pack(-side => 'left');
		$middle_name_value->insert('0', '');
		$full_name_frame->Label(-text => " Last:")->pack(-side => 'left');
		my $last_name_value = $full_name_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$last_name_value->insert('0', '');

		### address a entry field
		my $address_a_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$address_a_frame->Label(-text => "Address 1:")->pack(-side => 'left');
		my $address_a_value = $address_a_frame->Entry(-width => '30', -relief => 'sunken')->pack(-side => 'left');
		$address_a_value->insert('0', '');

		### address b entry field
		my $address_b_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$address_b_frame->Label(-text => "Address 2:")->pack(-side => 'left');
		my $address_b_value = $address_b_frame->Entry(-width => '30', -relief => 'sunken')->pack(-side => 'left');
		$address_b_value->insert('0', '');

		### address c entry field
		my $address_c_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$address_c_frame->Label(-text => "Address 3:")->pack(-side => 'left');
		my $address_c_value = $address_c_frame->Entry(-width => '30', -relief => 'sunken')->pack(-side => 'left');
		$address_c_value->insert('0', '');

		### city state entry fields
		my $city_state_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$city_state_frame->Label(-text => "City:     ")->pack(-side => 'left');
		my $city_value = $city_state_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$city_value->insert('0', '');
		$city_state_frame->Label(-text => "   State:")->pack(-side => 'left');
		my $state_value = $city_state_frame->Entry(-width => '2', -relief => 'sunken')->pack(-side => 'left');
		$state_value->insert('0', '');

		### province postal code entry fields
		my $prov_post_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$prov_post_frame->Label(-text => "Province:")->pack(-side => 'left');
		my $province_value = $prov_post_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$province_value->insert('0', '');
		$prov_post_frame->Label(-text => "   Post Code:")->pack(-side => 'left');
		my $post_value = $prov_post_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$post_value->insert('0', '');

		### phone number entry field
		my $phone_number_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$phone_number_frame->Label(-text => "Phone:")->pack(-side => 'left');
		my $phone_value = $phone_number_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$phone_value->insert('0', '');

		### vendor_id entry field
		$phone_number_frame->Label(-text => "           Vendor ID:")->pack(-side => 'left');
		my $vendor_id_value = $phone_number_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$vendor_id_value->insert('0', '');


		### alt phone number entry field
		my $alt_phone_number_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$alt_phone_number_frame->Label(-text => "Alt Phone:")->pack(-side => 'left');
		my $alt_phone_value = $alt_phone_number_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$alt_phone_value->insert('0', '');

		### security entry field
		$alt_phone_number_frame->Label(-text => " Security:")->pack(-side => 'left');
		my $security_value = $alt_phone_number_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$security_value->insert('0', '');

		### email entry field
		$alt_phone_number_frame->Label(-text => " Email:")->pack(-side => 'left');
		my $email_value = $alt_phone_number_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'left');
		$email_value->insert('0', '');


		$dial_info_frame->Label(-text => " ")->pack(-side => 'top');

		### comments entry fields
		my $comments_frame = $dial_info_frame->Frame()->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$comments_frame->Label(-text => "Comments:")->pack(-side => 'left');
		my $comments_value = $comments_frame->Entry(-width => '45', -relief => 'sunken')->pack(-side => 'left');
		$comments_value->insert('0', '');





	########################################################
	### disposition frame for the dialer app
		my $dispo_frame = $MW->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'bottom');

			$dispo_frame->Label(-text => "  ", -background => '#FFFFCC')->pack(-side => 'top');
		$dispo_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left

		### disposition entry fields
		my $dispo_entry_frame = $dispo_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$dispo_entry_frame->Label(-text => "Disposition:", -background => '#FFFFCC')->pack(-side => 'left');
		my $dispo_value = $dispo_entry_frame->Entry(-width => '8', -relief => 'sunken')->pack(-side => 'left');
		$dispo_value->insert('0', '');
		$dispo_entry_frame->Label(-text => " ", -background => '#FFFFCC')->pack(-side => 'left');
		my $dispo_ext_value = $dispo_entry_frame->Entry(-width => '20', -relief => 'sunken')->pack(-side => 'left');
		$dispo_ext_value->insert('0', '');
		$dispo_entry_frame->Label(-text => "             Stop Dialing:", -background => '#FFFFCC')->pack(-side => 'left');
		my $stopdial_value = $dispo_entry_frame->Entry(-width => '4', -relief => 'sunken')->pack(-side => 'left');
		$stopdial_value->insert('0', 'NO');

		my $stop_dial_yes_button = $dispo_entry_frame->Button(-text => 'YES', -width => -1, -background => '#FFFFCC',
					-command => sub 
					{
						$event_string = "CLICK|stop_dial_yes_button|||";
					 &event_logger();
					$stopdial_value->delete('0', 'end');
					$stopdial_value->insert('0', 'YES');
					});
		$stop_dial_yes_button->pack(-side => 'left', -expand => 'no', -fill => 'both');

		my $stop_dial_no_button = $dispo_entry_frame->Button(-text => 'NO', -width => -1, -background => '#FFFFCC',
					-command => sub 
					{
						$event_string = "CLICK|stop_dial_no_button|||";
					 &event_logger();
					$stopdial_value->delete('0', 'end');
					$stopdial_value->insert('0', 'NO');
					});
		$stop_dial_no_button->pack(-side => 'left', -expand => 'no', -fill => 'both');

			$dispo_frame->Label(-text => " ", -background => '#FFFFCC')->pack(-side => 'top');

		### OK button at the bottom to leave the dispo section
		my $dispo_OK_button_frame = $dispo_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'bottom');

		my $dispo_OK_button = $dispo_OK_button_frame->Button(-text => 'OK', -width => -1, -background => '#FFFFCC',
					-command => sub 
					{
						$event_string = "CLICK|dispo_OK_button|||";
					 &event_logger();
					commit_customer_info_to_db();

					$start_dialing_button->configure(-state => 'normal');
					$stopdial_value->delete('0', 'end');
					$stopdial_value->insert('0', 'NO');

					$dispo_value->delete('0', 'end');
					$dispo_ext_value->delete('0', 'end');

					$dispo_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
					});
		$dispo_OK_button->pack(-side => 'left', -expand => 'yes', -fill => 'both');
		$dispo_OK_button->configure(-state => 'disabled');

			$dispo_frame->Label(-text => " ", -background => '#FFFFCC')->pack(-side => 'bottom');

		### disposition select list
		my $dispo_list_frame = $dispo_frame->Frame(-background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");

		$dispo_listbox=$dispo_list_frame->BrowseEntry(-label => "Choose a Disposition from the list:",-width => '2', -background => '#FFFFCC')->pack(-expand => '1', -fill => 'both', -side => 'left');
		$dispo_listbox->insert('end', '');

		my $select_from_dispo_list = $dispo_list_frame->Button(-text => 'Select', -width => -1, -background => '#FFFFCC',
					-command => sub 
					{
					$selected_dispo = $dispo_listbox->get('active');
					@selected_dispo_elements = split(/ -- /, $selected_dispo);
					$dispo_value->delete('0', 'end');
					$dispo_value->insert('0', "$selected_dispo_elements[0]");
					$dispo_ext_value->delete('0', 'end');
					$dispo_ext_value->insert('0', "$selected_dispo_elements[1]");
					$dispo_OK_button->configure(-state => 'normal');
						$event_string = "CLICK|select_from_dispo_list|$selected_dispo||";
					 &event_logger();
					});
		$select_from_dispo_list->pack(-side => 'left', -expand => 'no', -fill => 'both');





	########################################################
	### transfer - conference frame for the dialer app
		my $xferconf_frame = $MW->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'bottom');

			$xferconf_frame->Label(-text => "  ", -background => '#CCCCFF')->pack(-side => 'top');
		$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left

		my $xferconf_call_frame = $xferconf_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'left');

		### xferconf entry fields
		my $xfer_number_entry_frame = $xferconf_call_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");
		$xfer_number_entry_frame->Label(-text => "Number to call:", -background => '#CCCCFF')->pack(-side => 'left');
		my $xfer_number_value = $xfer_number_entry_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$xfer_number_value->insert('0', '');
		$xfer_number_entry_frame->Label(-text => " Length:", -background => '#CCCCFF')->pack(-side => 'left');
		my $xfer_length_value = $xfer_number_entry_frame->Entry(-width => '5', -relief => 'sunken')->pack(-side => 'left');
		$xfer_length_value->insert('0', '');
		$xfer_number_entry_frame->Label(-text => " Zap:", -background => '#CCCCFF')->pack(-side => 'left');
		my $xfer_channel_value = $xfer_number_entry_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'left');
		$xfer_channel_value->insert('0', '');

		### xferconf dial buttons
		my $xfer_dial_buttons_frame = $xferconf_call_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");


		my $dial_with_cust_button = $xfer_dial_buttons_frame->Button(-text => 'DIAL WITH CUSTOMER', -width => -1, -background => '#CCCCFF',
					-command => sub 
					{
						$event_string = "CLICK|dial_with_cust_button|||";
					 &event_logger();
					conf_dial_number();
					});
		$dial_with_cust_button->pack(-side => 'left', -expand => 'no', -fill => 'both');


		my $dial_park_cust_button = $xfer_dial_buttons_frame->Button(-text => 'PARK CUSTOMER DIAL', -width => -1, -background => '#CCCCFF',
					-command => sub 
					{
						$event_string = "CLICK|dial_park_cust_button|||";
					 &event_logger();
					conf_park_customer();
					conf_dial_number();
					});
		$dial_park_cust_button->pack(-side => 'left', -expand => 'no', -fill => 'both');


		my $dial_blind_xfer_button = $xfer_dial_buttons_frame->Button(-text => 'DIAL BLIND TRANSFER', -width => -1, -background => '#CCCCFF',
					-command => sub 
					{
						$event_string = "CLICK|dial_blind_xfer_button|||";
					 &event_logger();
					conf_blind_xfer_customer();
					});
		$dial_blind_xfer_button->pack(-side => 'left', -expand => 'no', -fill => 'both');



		### xferconf conference buttons
		my $xfer_conf_buttons_frame = $xferconf_call_frame->Frame(-background => '#CCCCFF')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "nw");


		my $grab_park_cust_button = $xfer_conf_buttons_frame->Button(-text => 'GRAB PARK CUSTOMER', -width => -1, -background => '#CCCCFF',
					-command => sub 
					{
						$event_string = "CLICK|grab_park_cust_button|||";
					 &event_logger();
					conf_grab_park_customer();
					});
		$grab_park_cust_button->pack(-side => 'left', -expand => 'no', -fill => 'both');
		$grab_park_cust_button->configure(-state => 'disabled');


		my $hangup_xfer_line_button = $xfer_conf_buttons_frame->Button(-text => 'HANGUP XFER LINE  ', -width => -1, -background => '#CCCCFF',
					-command => sub 
					{
						$event_string = "CLICK|hangup_xfer_line_button|||";
					 &event_logger();
					conf_hangup_xfer_line();
					});
		$hangup_xfer_line_button->pack(-side => 'left', -expand => 'no', -fill => 'both');
		$hangup_xfer_line_button->configure(-state => 'disabled');


		my $hangup_both_lines_button = $xfer_conf_buttons_frame->Button(-text => 'HANGUP BOTH LINES  ', -width => -1, -background => '#CCCCFF',
					-command => sub 
					{
						$event_string = "CLICK|hangup_both_lines_button|||";
					 &event_logger();
					conf_hangup_xfer_line();
					hangup_customer();
					});
		$hangup_both_lines_button->pack(-side => 'left', -expand => 'no', -fill => 'both');


			$xferconf_call_frame->Label(-text => " ", -background => '#CCCCFF')->pack(-side => 'top');



		my $xferconf_dtmf_frame = $xferconf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'right', -anchor   => "ne");

		### xferconf send DTMF entry fields
		my $xfer_number_dtmf_entry_frame = $xferconf_dtmf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "ne");
		$xfer_number_dtmf_entry_frame->Label(-text => "DTMF to send:", -background => '#FFCCCC')->pack(-side => 'top');
		my $xfer_dtmf_value = $xfer_number_dtmf_entry_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'top');
		$xfer_dtmf_value->insert('0', '');

		my $send_dtmf_button = $xferconf_dtmf_frame->Button(-text => 'SEND DTMF', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|send_dtmf_button|||";
					 &event_logger();
					conf_send_dtmf();
					});
		$send_dtmf_button->pack(-side => 'top', -expand => 'no', -fill => 'both');

		my $xfer_preset_dtmf_frame = $xferconf_dtmf_frame->Frame(-background => '#FFCCCC')->pack(-expand => '1', -fill => 'both', -side => 'top', -anchor   => "ne");

		my $pop_dtmf_ukone_button = $xfer_preset_dtmf_frame->Button(-text => 'UK1', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_ukone_button|8172775772|7261,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', '7261,,,,1,,,2900,,,1');
					});
		$pop_dtmf_ukone_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

		my $pop_dtmf_uktwo_button = $xfer_preset_dtmf_frame->Button(-text => 'UK2', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_uktwo_button|8172775772|7411,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', '7411,,,,1,,,2900,,,1');
					});
		$pop_dtmf_uktwo_button->pack(-side => 'left', -expand => 'no', -fill => 'none');

		my $pop_dtmf_ausone_button = $xfer_preset_dtmf_frame->Button(-text => 'AUS1', -width => -1, -background => '#FFCCCC',
					-command => sub 
					{
						$event_string = "CLICK|pop_dtmf_ausone_button|8172775772|7412,,,,1,,,2900,,,1|";
					 &event_logger();
					
					$xfer_number_value->delete('0', 'end');
					$xfer_number_value->insert('0', '8172775772');
					$xfer_dtmf_value->delete('0', 'end');
					$xfer_dtmf_value->insert('0', '7412,,,,1,,,2900,,,1');
					});
		$pop_dtmf_ausone_button->pack(-side => 'left', -expand => 'no', -fill => 'none');




		


################################################################################################################
### set various start and refresh routines at millisecond intervals
################################################################################################################
sub RefreshList
{
	$MW->after (1000, \&current_datetime);
#	$MW->after (1000, \&get_dispo_list);
	$MW->repeat (1000, \&current_datetime);
	$MW->repeat (1000, \&validate_live_channels);

			return;
}

#get_parked_channels;

#get_online_channels;

#get_online_sip_users;

RefreshList();

MainLoop();








##########­##########­##########­##########­##########­##########­##########­##########
##########­##########­##########­##########­##########­##########­##########­##########
### SUBROUTINES GO HERE
##########­##########­##########­##########­##########­##########­##########­##########
##########­##########­##########­##########­##########­##########­##########­##########



sub start_dialing {&call_next_number;}
sub stop_dialing {}
sub start_recording {}
sub stop_recording {}


sub transfer_call {

	$transfer_call_button->configure(-state => 'disabled');
	$hangup_customer_button->configure(-state => 'disabled');

	$xferconf_frame->pack(-expand => '1', -fill => 'both', -side => 'top');


}


################################################################################
################################################################################
### time based or recurring subroutines
################################################################################
################################################################################

##########################################
### get the current date and time
##########################################
sub current_datetime
{

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
	$CIDdate = "$CIDyear$mon$mday$hour$min$sec";
	$filedate = "$year$mon$mday$DASH$hour$min$sec";
	$SQLdate = "$year-$mon-$mday $hour:$min:$sec";
	$epochdate = "$secX";
	$displaydate = "   $year/$mon/$mday           $hour:$min:$sec";

		$time_value->delete('0', 'end');
		$time_value->insert('0', $displaydate);

my $LIVE_CHANNEL = $zap_channel_value->get;
if (length($LIVE_CHANNEL)> 4)
	{
	$call_length_in_seconds++;
		$call_length_value->delete('0', 'end');
		$call_length_value->insert('0', $call_length_in_seconds);

	}
my $XFER_CHANNEL = $xfer_channel_value->get;
if (length($XFER_CHANNEL)> 4)
	{
	$xfer_length_in_seconds++;
		$xfer_length_value->delete('0', 'end');
		$xfer_length_value->insert('0', $xfer_length_in_seconds);

	}


}
##########################################
### get the current date and time
##########################################
sub validate_live_channels
{

	$cust_channel = $zap_channel_value->get;
	$xfer_channel = $xfer_channel_value->get;

if ( (length($cust_channel)>4) && ($call_length_in_seconds > 5) )
	{

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	$dbhA->query("SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$cust_channel' and extension IN('$session_id','conf','ring')");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
	     $rec_countH=0;
		   while ( $record = $iter->each)
		   {
		   $rec_countH = "$record->[0]";
		   } 
	   }
	#$dbhA->close;

	if ($rec_countH)	### if channel active set inactivity counter to zero
		{
		$zap_validation_count=0;
		}
	else
		{
		$zap_validation_count++;
		print "Zap channel down : |$cust_channel|$zap_validation_count|";
		if ($zap_validation_count > 1) 
			{

			$zap_channel_value->delete('0', 'end');
		#	$start_recording_button->configure(-state => 'disabled');
			$transfer_call_button->configure(-state => 'disabled');

			$zap_validation_count=0;

			$event_string = "SUBRT|validate_live_channels|Zap channel down : |$cust_channel|$zap_validation_count|";
			event_logger;

			}
		}

	}

if ( (length($xfer_channel)>4) && ($xfer_length_in_seconds > 5) )
	{

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	$dbhA->query("SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$xfer_channel' and extension IN('$session_id','conf','ring')");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
	     $rec_countH=0;
		   while ( $record = $iter->each)
		   {
		   $rec_countH = "$record->[0]";
		   } 
	   }
	#$dbhA->close;

	if ($rec_countH)	### if channel active set inactivity counter to zero
		{
		$zap_xfer_validation_count=0;
		}
	else
		{
		$zap_xfer_validation_count++;
		print "Zap channel down : |$xfer_channel|$zap_xfer_validation_count|";
		if ($zap_xfer_validation_count > 1) 
			{

			$xfer_channel_value->delete('0', 'end');

			$zap_xfer_validation_count=0;

			$event_string = "SUBRT|validate_live_channels|Xfer channel down : |$xfer_channel|$zap_xfer_validation_count|";
			event_logger;

			}
		}

	}

if ($CONFERENCE_RECORDING)
	{
	$conf_silent_prefix = '7';

	   $dbhA->query("SELECT channel,extension FROM live_sip_channels where server_ip = '$server_ip' and extension = '$session_id' order by channel desc");
		$rec_val_counter=0;
	   if ($dbhA->has_selected_record)
		{
	   $iter=$dbhA->create_record_iterator;
		   while ( $record = $iter->each)
			{
			#	if ($DB) {print STDERR "RECORDING: |$session_id|$record->[0]|$record->[1]|\n";}
			   if ( ($record->[0] =~ /Local\/$conf_silent_prefix$session_id\@/) && ($record->[1] =~ /$session_id/) )
					{
		   			$status_value->delete('0', 'end');
					$status_value->insert('0', "$record->[0]");
					$CONFERENCE_RECORDING_CHANNEL = "$record->[0]";
					$rec_val_counter++;
					}


			}
		}

	if ($rec_val_counter)	### if channel active set inactivity counter to zero
		{
		$recording_validation_count=0;
		}
	else
		{
		$recording_validation_count++;
		print "Recording channel down : |$CONFERENCE_RECORDING_CHANNEL|$recording_validation_count|";
		if ($recording_validation_count > 1) 
			{
			$event_string = "SUBRT|validate_rec_channels|Rec channel down : |$CONFERENCE_RECORDING_CHANNEL|$recording_validation_count|";
			event_logger;

			$status_value->delete('0', 'end');
			$CONFERENCE_RECORDING_CHANNEL = "";

			$recording_validation_count=0;
			$start_recording_button->configure(-state => 'normal');
			$stop_recording_button->configure(-state => 'disabled');

			$CONFERENCE_RECORDING = 0;
			}
		}

	}

}





################################################################################
################################################################################
### event or button based subroutines
################################################################################
################################################################################

##########################################
##########################################
### write event to client logfile
##########################################
##########################################
sub event_logger {
	### open the log file for writing ###
	open(Lout, ">>$LOGfile")
			|| die "Can't open $LOGfile: $!\n";

	print Lout "$SQLdate|$event_string|\n";

	close(Lout);

$event_string='';
}





##########################################
##########################################
### login to the system
##########################################
##########################################
sub login_system {
    my $Luser = $user_value->get;
    my $Lpass = $pass_value->get;
    my $Lcampaign = $campaign_value->get;
	$user = $Luser;
	$campaign = $Lcampaign;

	print STDERR "LOGGING IN as |$Luser|$Lpass| on campaign |$Lcampaign|\n";

		$event_string = "SUBRT|login_system|LOGGING IN as |$Luser|$Lpass| on campaign |$Lcampaign|";
	 event_logger;

	my $login_dialog = $MW->DialogBox( -title   => "System Login Status:",
                                 -buttons => [ "OK" ],
				);

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	$dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";


	### check to see if campaign entered exists and is active
	   $dbhA->query("SELECT count(*) FROM vicidial_campaigns where campaign_id='$campaign' and active='Y'");
	   if ($dbhA->has_selected_record)
	   {
	   $iter=$dbhA->create_record_iterator;
	     $rec_countG=0;
		   while ( $record = $iter->each)
		   {
		   $rec_countG = "$record->[0]";
		   } 
	   }

	if ($rec_countG)	### if campaign active continue with login process
		{
		   $dbhA->query("SELECT count(*) FROM vicidial_users where user='$Luser' and pass='$Lpass'");
		   if ($dbhA->has_selected_record)
		   {
		   $iter=$dbhA->create_record_iterator;
			 $rec_count=0;
			   while ( $record = $iter->each)
			   {
		#	   print STDERR $record->[0]," - conference room\n";
			   $rec_count = "$record->[0]";
			   } 
		   }

		if ($rec_count)
			{

			&get_dispo_list;

			&get_number_of_leads_to_call_in_campaign;

			if ($campaign_leads_to_call > 0)
				{
			### insert an entry into the user log for the login event
				$stmtA = "INSERT INTO vicidial_user_log values('','$Luser','LOGIN','$Lcampaign','$SQLdate','$epochdate')";
				$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";


				### check to see if the user has a conf extension already, this happens if they previously exited uncleanly
				$dbhA->query("SELECT conf_exten FROM vicidial_conferences where extension='$SIP_user' and server_ip = '$server_ip' LIMIT 1");
				if ($dbhA->has_selected_record)
					{
					$iter=$dbhA->create_record_iterator;
					 $recB_count=0;
					   while ( $record = $iter->each)
					   {
					#	   print STDERR $record->[0]," - conference room\n";
					   $session_id = "$record->[0]";
					   $recB_count++;
					   } 
					}
				if ($recB_count)
					{
					print STDERR "USING PREVIOUS MEETME ROOM - $session_id - $SQLdate\n";
					}
				else
					{
					$dbhA->query("SELECT conf_exten FROM vicidial_conferences where server_ip = '$server_ip' and extension='' LIMIT 1");
					if ($dbhA->has_selected_record)
						{
						$iter=$dbhA->create_record_iterator;
						 $recC_count=0;
						   while ( $record = $iter->each)
						   {
						   $session_id = "$record->[0]";
						   $recC_count++;
						   } 
						}

					$stmtA = "UPDATE vicidial_conferences set extension='$SIP_user' where server_ip='$server_ip' and conf_exten='$session_id'";
					$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
					}

					print STDERR $session_id," - conference room - $SQLdate\n";
					$system_ext_value->delete('0', 'end');
					$system_ext_value->insert('0', $session_id);


					$stmtA = "UPDATE vicidial_list set status='N', user='' where status IN('QUEUE','INCALL') and user ='$user'";

					print STDERR "|$stmtA|\n";

				   $dbhA->query("$stmtA");
					my $affected_rows = $dbhA->get_affected_rows_length;

					print STDERR "old QUEUE and INCALL reverted: |$affected_rows|\n";

					#$dbhA->close;


				##### popup a message window saying that login was successful
				$login_dialog->add("Label", -text => "you have logged in as\n user: $Luser \n on phone: $SIP_user \n\n campaign: $campaign\n\n PLEASE ANSWER YOUR PHONE WHEN IT RINGS")->pack;
				$login_dialog->Show;


				$login_button_frame->place(-in=>$login_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner pixel
				$logout_button_frame->pack(-expand => '1', -fill => 'both', -side => 'top');


			### use manager middleware-app to connect the phone to the user
				$SIqueryCID = "SI$CIDdate$session_id";

			### insert a NEW record to the vicidial_manager table to be processed
				$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$SIqueryCID','Channel: $SIP_user','Context: $ext_context','Exten: $session_id','Priority: 1','Callerid: $SIqueryCID','','','','','')";
				$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

				$SI_manager_command_sent = 1;

					$event_string = "SUBRT|login_system|SI|$SIqueryCID|$stmtA|";
				 event_logger;

				$status_value->delete('0', 'end');
				$status_value->insert('0', "You have logged in to campaign $campaign  with $campaign_leads_to_call leads to call");

				$start_dialing_button->configure(-state => 'normal');

				##### events to trigger after login successful go here


				$main_frame->pack(-expand => '1', -fill => 'both', -side => 'top');


				}

			else
				{
#				#$dbhA->close;

				$status_value->delete('0', 'end');
				$status_value->insert('0', "Login failed, no leads to dial in this campaign");

				$login_dialog->add("Label", -text => "login failed: no leads to dial in this campaign: $Lcampaign")->pack;
				$login_dialog->Show;
				}

			}
		else
			{
			#$dbhA->close;

			$status_value->delete('0', 'end');
			$status_value->insert('0', "Login failed, bad user, try again");

			$login_dialog->add("Label", -text => "login failed for user: $Luser pass: $Lpass")->pack;
			$login_dialog->Show;
			}

		}	### end campaign exists loop
	else
		{
		#$dbhA->close;

		$status_value->delete('0', 'end');
		$status_value->insert('0', "Login failed, bad campaign, try again");

		$login_dialog->add("Label", -text => "login failed campaign is not active: $Lcampaign")->pack;
		$login_dialog->Show;
		}

}





##########################################
##########################################
### logout of the system
##########################################
##########################################
sub logout_system {

    my $Luser = $user_value->get;
    my $Lcampaign = $campaign_value->get;
    my $OLD_session_id = $system_ext_value->get;

		$event_string = "SUBRT|logout_system|LOGGING OUT as |$Luser| on campaign |$Lcampaign| with session_id |$OLD_session_id|";
	 event_logger;

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";
		$stmtA = "INSERT INTO vicidial_user_log values('','$Luser','LOGOUT','$Lcampaign','$SQLdate','$epochdate')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

	$stmtA = "UPDATE vicidial_conferences set extension='' where server_ip='$server_ip' and conf_exten='$OLD_session_id'";
	$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";


	@sip_chan_hangup=@MT;

		$stmtA = "SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and channel LIKE \"$SIP_user$DASH\%\" limit 9";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|logout_system|HX|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			 $recH_count=0;
			   while ( $record = $iter->each)
			   {
				$sip_chan_hangup[$recH_count] = "$record->[0]";
			   $recH_count++;
			   } 
			}

	$recH_count=0;
	foreach(@sip_chan_hangup)
		{

				$HSqueryCID = "H$recH_count$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$SIqueryCID','Channel: $sip_chan_hangup[$recH_count]','','','','','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$HX_manager_command_sent = 1;

				$event_string = "SUBRT|logout_system|HX|$HSqueryCID|$stmtA|";
			 event_logger;

			$recH_count++;
		}



	$dbhA->close;

		$status_value->delete('0', 'end');
		$status_value->insert('0', "You are now logged out");

	$system_ext_value->delete('0', 'end');

	my $login_dialog = $MW->DialogBox( -title   => "System Logout Status:",
                                 -buttons => [ "OK" ],
				);

    $login_dialog->add("Label", -text => "you have logged out of the system")->pack;
    $login_dialog->Show;

	$main_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner

	$logout_button_frame->place(-in=>$login_frame, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left corner pixel
	$login_button_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

}






##########################################
##########################################
### get the list of dispositions from the system
##########################################
##########################################
sub get_dispo_list {

	$dispo_listbox->delete('0', 'end');


#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

   $dbhA->query("SELECT status,status_name FROM vicidial_statuses WHERE selectable='Y' order by status limit 50;");
   if ($dbhA->has_selected_record)
	{
   $iterA=$dbhA->create_record_iterator;
	 $rec_countY=0;
	   while ($recordA = $iterA->each)
		{
		   if($DB){print STDERR $recordA->[0],"|", $recordA->[1],"\n";}

			$DBstatus[$rec_countY] = "$recordA->[0] -- $recordA->[1]";
			$dispo_listbox->insert('end', $DBstatus[$rec_countY]);

			$rec_countY++;
		} 
	}

	#$dbhA->close;

		$event_string = "SUBRT|get_dispo_list|Getting DISPO LIST|$rec_countY dispositions|";
	 event_logger;

}




##########################################
##########################################
### get the count of available leads to call in the active campaign
##########################################
##########################################
sub get_number_of_leads_to_call_in_campaign {

		$event_string = "SUBRT|get_number_of_leads_to_call_in_campaign|START|";
	 event_logger;

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";


   $dbhA->query("SELECT dial_status_a,dial_status_b,dial_status_c,dial_status_d,dial_status_e FROM vicidial_campaigns where campaign_id = '$campaign';");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	   while ( $record = $iter->each)
	   {
	   $status_A = "$record->[0]";
	   $status_B = "$record->[1]";
	   $status_C = "$record->[2]";
	   $status_D = "$record->[3]";
	   $status_E = "$record->[4]";
	   } 
   }

   $dbhA->query("SELECT list_id FROM vicidial_lists where campaign_id = '$campaign' and active='Y';");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_countLISTS=0;
	 $camp_lists = '';
	   while ( $record = $iter->each)
	   {
		   $camp_lists .= "'$record->[0]',";
		$rec_countLISTS++;
	   } 
	   chop($camp_lists);
   }

   $dbhA->query("SELECT count(*) FROM vicidial_list where called_since_last_reset='N' and status IN('$status_A','$status_B','$status_C','$status_D','$status_E') and list_id IN($camp_lists)");

 	   print STDERR "|SELECT count(*) FROM vicidial_list where called_since_last_reset='N' and status IN('$status_A','$status_B','$status_C','$status_D','$status_E') and list_id IN($camp_lists)|\n";

  if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_count=0;
	   while ( $record = $iter->each)
	   {
	   print STDERR $record->[0]," - leads left to call\n";

	   $campaign_leads_to_call = "$record->[0]";
	   } 
   }

	#$dbhA->close;

		$event_string = "SUBRT|get_number_of_leads_to_call_in_campaign|END|$campaign_leads_to_call leads to call|";
	 event_logger;


}





##########################################
##########################################
### grabs the next number to call from the database and reserves it
### then it selects the details and posts them to the Entry fields
### and initiates the Originate call
##########################################
##########################################
sub call_next_number {

		$event_string = "SUBRT|call_next_number|START|";
	 event_logger;

	$start_dialing_button->configure(-state => 'disabled');

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

   $dbhA->query("SELECT dial_status_a,dial_status_b,dial_status_c,dial_status_d,dial_status_e,lead_order FROM vicidial_campaigns where campaign_id = '$campaign';");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	   while ( $record = $iter->each)
	   {
	   $status_A = "$record->[0]";
	   $status_B = "$record->[1]";
	   $status_C = "$record->[2]";
	   $status_D = "$record->[3]";
	   $status_E = "$record->[4]";
	   $lead_order = "$record->[5]";
	   } 
   }

   $dbhA->query("SELECT list_id FROM vicidial_lists where campaign_id = '$campaign' and active='Y';");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_countLISTS=0;
	 $camp_lists = '';
	   while ( $record = $iter->each)
	   {
		   $camp_lists .= "'$record->[0]',";
		$rec_countLISTS++;
	   } 
	   chop($camp_lists);
   }

	$order_stmt = '';
	if ($lead_order eq "UP") {$order_stmt = 'order by lead_id desc';}
	if ($lead_order eq "UP LAST NAME") {$order_stmt = 'order by last_name desc';}
	if ($lead_order eq "DOWN LAST NAME") {$order_stmt = 'order by last_name';}
	if ($lead_order eq "UP PHONE") {$order_stmt = 'order by phone_number desc';}
	if ($lead_order eq "DOWN PHONE") {$order_stmt = 'order by phone_number';}

	$stmtA = "UPDATE vicidial_list set status='QUEUE', user='$user' where called_since_last_reset='N' and status IN('$status_A','$status_B','$status_C','$status_D','$status_E') and list_id IN($camp_lists) $order_stmt LIMIT 1";

	print STDERR "|$stmtA|\n";

   $dbhA->query("$stmtA");
	my $affected_rows = $dbhA->get_affected_rows_length;

	print STDERR "rows updated to QUEUE: |$affected_rows|\n";

if ($affected_rows)
	{

	$stmtA = "SELECT * FROM vicidial_list where status='QUEUE' and user='$user' LIMIT 1";

	print STDERR "|$stmtA|\n";

   $dbhA->query("$stmtA");
   if ($dbhA->has_selected_record)
   {
   $iter=$dbhA->create_record_iterator;
	 $rec_countCUSTDATA=0;
	   while ( $record = $iter->each)
	   {
		   $lead_id			= "$record->[0]";
		   $vendor_id		= "$record->[5]";
		   $list_id			= "$record->[7]";
		   $phone_code		= "$record->[10]";
		   $phone_number	= "$record->[11]";
		   $title			= "$record->[12]";
		   $first_name		= "$record->[13]";
		   $middle_initial	= "$record->[14]";
		   $last_name		= "$record->[15]";
		   $address1		= "$record->[16]";
		   $address2		= "$record->[17]";
		   $address3		= "$record->[18]";
		   $city			= "$record->[19]";
		   $state			= "$record->[20]";
		   $province		= "$record->[21]";
		   $postal_code		= "$record->[22]";
		   $country_code	= "$record->[23]";
		   $gender			= "$record->[24]";
		   $date_of_birth	= "$record->[25]";
		   $alt_phone		= "$record->[26]";
		   $email			= "$record->[27]";
		   $security		= "$record->[28]";
		   $comments		= "$record->[29]";

		$rec_countCUSTDATA++;
	   } 
   }

	if ($rec_countCUSTDATA)
	{
		$dial_code_value->delete('0', 'end');
		$dial_code_value->insert('0', $phone_code);
		$title_name_value->delete('0', 'end');
		$title_name_value->insert('0', $title);
		$first_name_value->delete('0', 'end');
		$first_name_value->insert('0', $first_name);
		$middle_name_value->delete('0', 'end');
		$middle_name_value->insert('0', $middle_name);
		$last_name_value->delete('0', 'end');
		$last_name_value->insert('0', $last_name);
		$address_a_value->delete('0', 'end');
		$address_a_value->insert('0', $address1);
		$address_b_value->delete('0', 'end');
		$address_b_value->insert('0', $address2);
		$address_c_value->delete('0', 'end');
		$address_c_value->insert('0', $address3);
		$city_value->delete('0', 'end');
		$city_value->insert('0', $city);
		$state_value->delete('0', 'end');
		$state_value->insert('0', $state);
		$province_value->delete('0', 'end');
		$province_value->insert('0', $province);
		$post_value->delete('0', 'end');
		$post_value->insert('0', $postal_code);
		$phone_value->delete('0', 'end');
		$phone_value->insert('0', $phone_number);
		$vendor_id_value->delete('0', 'end');
		$vendor_id_value->insert('0', $vendor_id);
		$alt_phone_value->delete('0', 'end');
		$alt_phone_value->insert('0', $alt_phone);
		$security_value->delete('0', 'end');
		$security_value->insert('0', $security);
		$email_value->delete('0', 'end');
		$email_value->insert('0', $email);
		$comments_value->delete('0', 'end');
		$comments_value->insert('0', $comments);

		$stmtA = "UPDATE vicidial_list set status='INCALL', called_since_last_reset='Y' where lead_id='$lead_id'";

		print STDERR "|$stmtA|\n";

	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;

		print STDERR "rows updated to INCALL: |$affected_rows|\n";

	}

	#$dbhA->close;


	$silent_prefix = '7';


	### use manager middleware-app to connect the next call to the meetme room
		$CNqueryCID = "CN$CIDdate$session_id";

	### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$CNqueryCID','Exten: 9$phone_code$phone_number','Context: $ext_context','Channel: $local_DEF$silent_prefix$session_id$local_AMP$ext_context','Priority: 1','Callerid: $CNqueryCID','','','','','')";
#		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$CNqueryCID','Exten: 7$session_id','Context: $ext_context','Channel: $call_out_number_group$phone_code$phone_number','Priority: 1','Callerid: $CNqueryCID','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

		$CN_manager_command_sent = 1;

			$event_string = "SUBRT|call_next_number|CN|$CNqueryCID|$stmtA|";
		 event_logger;

	$status_value->delete('0', 'end');
	$status_value->insert('0', "Calling $phone_code$phone_number     Waiting for connect: 0");

		

	$get_channel_of_new_call_loop=0;
	$customer_zap_channel='';
	while ( ($get_channel_of_new_call_loop < 30) && (length($customer_zap_channel)<4) )
		{
		sleep(1);
		print STDERR "Called $phone_code$phone_number     waiting for ring: $get_channel_of_new_call_loop seconds\r";
		$get_channel_of_new_call_loop++;
		$status_value->delete('0', 'end');
		$status_value->insert('0', "Called $phone_code$phone_number     Time until ring was: $get_channel_of_new_call_loop seconds");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$CNqueryCID' and status='UPDATED' and channel LIKE \"Zap%\"";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|call_next_number|CN|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$customer_zap_channel = "$record->[0]";
				$uniqueid = "$record->[1]";
			   } 
			}
		}

	if ($get_channel_of_new_call_loop > 29)
		{
		$status_value->delete('0', 'end');
		$status_value->insert('0', "ERROR ----- Please contact your phone system administrator and hangup this call.");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$CNqueryCID' and status='SENT'";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|call_next_number|CN|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$customer_zap_channel = "$record->[0]";
				$uniqueid = "$record->[1]";
			   } 
			}

		}

#	$customer_zap_channel =~ s/Channel: |^ *| *$//gi;
#	$customer_zap_channel =~ s/^ *| *$//gi;

	$SIPexten = $SIP_user;
	$SIPexten =~ s/sip\///gi;

	$zap_channel_value->delete('0', 'end');
	$zap_channel_value->insert('0', $customer_zap_channel);

	if ($phone_code eq '') {$channel_group='Outbound Local';   $number_dialed=$phone_number;}
	if ($phone_code eq '1') {$channel_group='Outbound Long Distance';   $number_dialed=$phone_number;}
	if ($phone_code eq '01161') {$channel_group='Outbound AUS';   $number_dialed="$phone_code$phone_number";}
	if ($phone_code eq '01144') {$channel_group='Outbound UK';   $number_dialed="$phone_code$phone_number";}

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";
	if (length($customer_zap_channel)>5)
		{
		$stmtA = "INSERT INTO vicidial_log (uniqueid,lead_id,list_id,campaign_id,call_date,start_epoch,status,phone_code,phone_number,user,processed) values('$uniqueid','$lead_id','$list_id','$campaign','$SQLdate','$secX','INCALL','$phone_code','$phone_number','$user','N')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query: |$stmtA|\n";

		$stmtA = "INSERT INTO call_log (uniqueid,channel,channel_group,type,server_ip,extension,number_dialed,caller_code,start_time,start_epoch) values('$uniqueid','$customer_zap_channel','$channel_group','Zap','$server_ip','$SIPexten','$number_dialed','VD $user $lead_id','$SQLdate','$secX')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query: |$stmtA|\n";

		}

	#$dbhA->close;

	$INCALL=1;

#	$start_recording_button->configure(-state => 'normal');
#	$stop_recording_button->configure(-state => 'disabled');

	$hangup_customer_button->configure(-state => 'normal');
	$transfer_call_button->configure(-state => 'normal');

	}

else
	{
	#$dbhA->close;

	$status_value->delete('0', 'end');
	$status_value->insert('0', "Logging you out, no more leads to dial in this campaign");

	my $dialog = $MW->DialogBox( -title   => "Leads error",
								 -buttons => [ "OK" ],
				);

	$dialog->add("Label", -text => "Logging out: no more leads to dial in this campaign: $Lcampaign")->pack;
	$dialog->Show;

	&logout_system;

	}

		$event_string = "SUBRT|call_next_number|END|Dial string |$call_out_number_group$phone_code$phone_number|";
	 event_logger;

}




##########################################
##########################################
### hangup the customer Zap channel dialed, the 1st outbound line
##########################################
##########################################
sub hangup_customer {

    my $HANGUP = $zap_channel_value->get;

		$event_string = "SUBRT|hangup_customer|$HANGUP|";
	 event_logger;

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

		$stmtA = "UPDATE vicidial_log set end_epoch='$secX', length_in_sec='$call_length_in_seconds',status='DONE' where uniqueid='$uniqueid'";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

	#$dbhA->close;

	### error box if channel to park is not live
if (length($HANGUP)<5)
	{
	
		$customer_hungup_button->configure(-state => 'normal');

		my $dialog = $MW->DialogBox( -title   => "Channel Hangup Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to Hangup is not live\n   |$HANGUP|")->pack;
		$dialog->Show;  
	}
else
	{
		$HUqueryCID = $CNqueryCID;
		$HUqueryCID =~ s/^../HU/gi;

		### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$HUqueryCID','Channel: $HANGUP','','','','','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$event_string = "SUBRT|hangup_customer|HC|$CNqueryCID|$stmtA|";
		 event_logger;


	$zap_channel_value->delete('0', 'end');

	$INCALL=0;

#	$start_recording_button->configure(-state => 'disabled');
	$hangup_customer_button->configure(-state => 'disabled');
	$transfer_call_button->configure(-state => 'disabled');

	$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

	}
}






##########################################
##########################################
### customer hungup the Zap channel before user did
##########################################
##########################################
sub customer_hungup {


	$zap_channel_value->delete('0', 'end');

	$customer_hungup_button->configure(-state => 'disabled');
#	$start_recording_button->configure(-state => 'disabled');
	$hangup_customer_button->configure(-state => 'disabled');
	$transfer_call_button->configure(-state => 'disabled');

	$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

}






##########################################
##########################################
### commits the information that is in the fields to the database
##########################################
##########################################
sub commit_customer_info_to_db {

    my $disposition		 = $dispo_value->get;
    my $title			 = $title_name_value->get;
    my $first_name		 = $first_name_value->get;
    my $middle_initial	 = $middle_name_value->get;
    my $last_name		 = $last_name_value->get;
    my $address1		 = $address_a_value->get;
    my $address2		 = $address_b_value->get;
    my $address3		 = $address_c_value->get;
    my $city			 = $city_value->get;
    my $state			 = $state_value->get;
    my $province		 = $province_value->get;
    my $postal_code		 = $post_value->get;
    my $phone			 = $phone_value->get;
    my $alt_phone		 = $alt_phone_value->get;
    my $security		 = $security_value->get;
    my $email			 = $email_value->get;
    my $comments		 = $comments_value->get;

		$event_string = "SUBRT|commit_customer_info_to_db|$disposition|$title|$first_name|$middle_initial|$last_name|$address1|$address2|$address3|$city|$state|$province|$postal_code|$alt_phone|$comments|";
	 event_logger;

if ($phone_number eq "$alt_phone") {$alt_phone = '';}

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	$stmtA = "UPDATE vicidial_list set status='$disposition', title='$title', first_name='$first_name', middle_initial='$middle_initial', last_name='$last_name', address1='$address1', address2='$address2', address3='$address3', city='$city', state='$state', province='$province', postal_code='$postal_code', alt_phone='$alt_phone', security_phrase='$security', email='$email', comments='$comments' where lead_id='$lead_id'";

	print STDERR "|$stmtA|\n";

   $dbhA->query("$stmtA");
	my $affected_rows = $dbhA->get_affected_rows_length;

	print STDERR "rows updated with modified data: |$affected_rows|\n";


	$stmtA = "UPDATE vicidial_log set status='$disposition' where uniqueid='$uniqueid'";
		if($DB){print STDERR "\n|$stmtA|\n";}
	$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";


	#$dbhA->close;


if ($stopdial_value eq 'YES') {$START_DIALING=0;}


	$dispo_value->delete('0', 'end');
	$dial_code_value->delete('0', 'end');
	$title_name_value->delete('0', 'end');
	$first_name_value->delete('0', 'end');
	$middle_name_value->delete('0', 'end');
	$last_name_value->delete('0', 'end');
	$address_a_value->delete('0', 'end');
	$address_b_value->delete('0', 'end');
	$address_c_value->delete('0', 'end');
	$city_value->delete('0', 'end');
	$state_value->delete('0', 'end');
	$province_value->delete('0', 'end');
	$post_value->delete('0', 'end');
	$phone_value->delete('0', 'end');
	$vendor_id_value->delete('0', 'end');
	$alt_phone_value->delete('0', 'end');
	$security_value->delete('0', 'end');
	$email_value->delete('0', 'end');
	$comments_value->delete('0', 'end');

	$call_length_in_seconds=0;
	$call_length_value->delete('0', 'end');


	$dispo_OK_button->configure(-state => 'disabled');
	$customer_hungup_button->configure(-state => 'disabled');

}





##########################################
##########################################
### dials the transfer-conference number
##########################################
##########################################
sub conf_dial_number {

	my $conf_number_to_dial = $xfer_number_value->get;

	$xfer_length_in_seconds=0;

		$event_string = "SUBRT|conf_dial_number|$conf_number_to_dial|";
	 &event_logger;

	### error box if improperly formatted number is entered
	if ( (length($conf_number_to_dial) ne 3) && (length($conf_number_to_dial) ne 4) && (length($conf_number_to_dial) ne 9) && (length($conf_number_to_dial) ne 10) && (length($conf_number_to_dial) ne 11) )
	{
	
		my $dialog = $MW->DialogBox( -title   => "Number Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "Outside number to dial must be:\n- 3 or 4 digits for local speed-dial\n- 9 digits for Australia\n- 10 digits for US long distance \n or 11 digits for a UK number\n   |$conf_number_to_dial|")->pack;
		$dialog->Show;  
	}

	else
	{
		if ( (length($conf_number_to_dial) eq 3) or (length($conf_number_to_dial) eq 4) ) {$CNTD_prefix = '';}
		if (length($conf_number_to_dial) eq 9) {$CNTD_prefix = '01161';}
		if (length($conf_number_to_dial) eq 10) {$CNTD_prefix = '1';}
		if ( (length($conf_number_to_dial) eq 10) && ($conf_number_to_dial =~ /^727|^813/i) ) {$CNTD_prefix = '1';}
		if (length($conf_number_to_dial) eq 11) {$conf_number_to_dial =~ s/^.//gi;   $CNTD_prefix = '01144';}
		

	### use manager middleware-app to connect the next call to the meetme room
		$XDqueryCID = "XD$CIDdate$session_id";

	### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$XDqueryCID','Exten: $session_id','Context: $ext_context','Channel: $call_out_number_group$CNTD_prefix$conf_number_to_dial','Priority: 1','Callerid: $XDqueryCID','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

		$CN_manager_command_sent = 1;

			$event_string = "SUBRT|conf_dial_number|XD|$XDqueryCID|$stmtA|";
		 &event_logger;

	$get_channel_of_new_xcall_loop=0;
	$xferconf_zap_channel='';
	while ( ($get_channel_of_new_xcall_loop < 30) && (length($xferconf_zap_channel)<4) )
		{
		sleep(1);
		print STDERR "Called $CNTD_prefix$conf_number_to_dial     waiting for ring: $get_channel_of_new_xcall_loop seconds\r";
		$get_channel_of_new_xcall_loop++;
		$status_value->delete('0', 'end');
		$status_value->insert('0', "Called $CNTD_prefix$conf_number_to_dial     Time until ring was: $get_channel_of_new_xcall_loop seconds");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$XDqueryCID' and status='UPDATED'";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|conf_dial_number|XD|$stmtA|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$xferconf_zap_channel = "$record->[0]";
				$xfer_uniqueid = "$record->[1]";
			   } 
			}
		}

	if ($get_channel_of_new_xcall_loop > 29)
		{
		$status_value->delete('0', 'end');
		$status_value->insert('0', "ERROR ----- Please contact your phone system administrator and hangup this call.");

		$stmtA = "SELECT channel,uniqueid FROM vicidial_manager where server_ip = '$server_ip' and callerid = '$XDqueryCID' and status='SENT'";
		$dbhA->query("$stmtA");
				$event_string = "SUBRT|conf_dial_number|XD|$stmtA|FAIL|";
			 event_logger;

		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			   while ( $record = $iter->each)
			   {
				$xferconf_zap_channel = "$record->[0]";
				$xfer_uniqueid = "$record->[1]";
			   } 
			}

		}


	$SIPexten = $SIP_user;
	$SIPexten =~ s/sip\///gi;

	$xfer_channel_value->delete('0', 'end');
	$xfer_channel_value->insert('0', $xferconf_zap_channel);

	if ($CNTD_prefix eq '') {$channel_group='Outbound Local';   $number_dialed=$conf_number_to_dial;}
	if ($CNTD_prefix eq '1') {$channel_group='Outbound Long Distance';   $number_dialed=$conf_number_to_dial;}
	if ($CNTD_prefix eq '01161') {$channel_group='Outbound AUS';   $number_dialed="$CNTD_prefix$conf_number_to_dial";}
	if ($CNTD_prefix eq '01144') {$channel_group='Outbound UK';   $number_dialed="$CNTD_prefix$conf_number_to_dial";}

#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

	if (length($xferconf_zap_channel)>5)
		{
		$stmtA = "INSERT INTO call_log (uniqueid,channel,channel_group,type,server_ip,extension,number_dialed,caller_code,start_time,start_epoch) values('$xfer_uniqueid','$xferconf_zap_channel','$channel_group','Zap','$server_ip','$SIPexten','$number_dialed','VD $user XFER','$SQLdate','$secX')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
		}
	#$dbhA->close;


	$hangup_customer_button->configure(-state => 'disabled');
	$transfer_call_button->configure(-state => 'disabled');
	$hangup_xfer_line_button->configure(-state => 'normal');

	}

}





##########################################
##########################################
### parks the customer
##########################################
##########################################
sub conf_park_customer {

my $PARK = $zap_channel_value->get;

		$event_string = "SUBRT|conf_park_customer|$PARK|";
	 event_logger;

	### error box if channel to park is not live
if (length($PARK)<5)
	{
	
		my $dialog = $MW->DialogBox( -title   => "Channel Park Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to park is not live\n   |$PARK|")->pack;
		$dialog->Show;  
	}
else
	{

	### use manager middleware-app to connect the next call to the meetme room
		$RDqueryCID = "RD$CIDdate$session_id";

	### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$RDqueryCID','Channel: $PARK','Context: $ext_context','Exten: $conf_on_extension','Priority: 1','Callerid: $RDqueryCID','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

		$park_extension = 'conf';
		$CN_manager_command_sent = 1;

			$event_string = "SUBRT|conf_park_customer|RD|$RDqueryCID|$stmtA|";
		 &event_logger;



		### insert parked call into parked_channels table
#		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#		or 	die "Couldn't connect to database: \n";

		$stmtA = "INSERT INTO parked_channels values('$PARK','$server_ip','','$park_extension','$SIP_user','$SQLdate');";

		#print STDERR "\n|$stmtA|\n";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

		#$dbhA->close;

		$grab_park_cust_button->configure(-state => 'normal');

	}

}





##########################################
##########################################
### blind transfers the customer to another number
##########################################
##########################################
sub conf_blind_xfer_customer {

my $XFER = $zap_channel_value->get;
my $conf_number_to_dial = $xfer_number_value->get;

		$event_string = "SUBRT|conf_blind_xfer_customer|$XFER|$conf_number_to_dial|";
	 event_logger;

### error box if improperly formatted number is entered
if ( (length($conf_number_to_dial) ne 3) && (length($conf_number_to_dial) ne 4) && (length($conf_number_to_dial) ne 9) && (length($conf_number_to_dial) ne 10) && (length($conf_number_to_dial) ne 11) )
{

	my $dialog = $MW->DialogBox( -title   => "Number Error",
								 -buttons => [ "OK" ],
				);
	$dialog->add("Label", -text => "Outside number to dial must be:\n- 3 or 4 digits for local speed-dial\n- 9 digits for Australia\n- 10 digits for US long distance \n or 11 digits for a UK number\n   |$conf_number_to_dial|")->pack;
	$dialog->Show;  
}

else
{
	if ( (length($conf_number_to_dial) eq 3) or (length($conf_number_to_dial) eq 4) ) {$CNTD_prefix = '';}
	if (length($conf_number_to_dial) eq 9) {$CNTD_prefix = '901161';}
	if (length($conf_number_to_dial) eq 10) {$CNTD_prefix = '91';}
	if ( (length($conf_number_to_dial) eq 10) && ($conf_number_to_dial =~ /^727|^813/i) ) {$CNTD_prefix = '91';}
	if (length($conf_number_to_dial) eq 11) {$CNTD_prefix = '';}

		### error box if channel to transfer is not live
	if (length($XFER)<5)
		{
		
			my $dialog = $MW->DialogBox( -title   => "Channel transfer Error",
										 -buttons => [ "OK" ],
						);
			$dialog->add("Label", -text => "The channel you are trying to transfer is not live\n   |$XFER|")->pack;
			$dialog->Show;  
		}
	else
		{


		### use manager middleware-app to connect the next call to the meetme room
			$BXqueryCID = "BX$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$BXqueryCID','Channel: $XFER','Context: $ext_context','Exten: $CNTD_prefix$conf_number_to_dial','Priority: 1','Callerid: $BXqueryCID','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|conf_blind_xfer_customer|BX|$BXqueryCID|$stmtA|";
			 &event_logger;




	$zap_channel_value->delete('0', 'end');

	$xferconf_frame->place(-in=>$MW, -width=>1, -height=>1, -x=>1, -y=>1); # hide the frame in the upper-left
	$dispo_frame->pack(-expand => '1', -fill => 'both', -side => 'top');

		}

	}

}





##########################################
##########################################
### grabs the customer that is parked
##########################################
##########################################
sub conf_grab_park_customer {

my $PICKUP = $zap_channel_value->get;

		$event_string = "SUBRT|conf_grab_park_customer|$PICKUP|";
	 event_logger;

	### error box if channel to park is not live
if (length($PICKUP)<5)
	{
	
		my $dialog = $MW->DialogBox( -title   => "Channel Pickup Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to park is not live\n   |$PICKUP|")->pack;
		$dialog->Show;  
	}
else
	{


		### use manager middleware-app to connect the next call to the meetme room
			$GPqueryCID = "GP$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Redirect','$GPqueryCID','Channel: $PICKUP','Context: $ext_context','Exten: $session_id','Priority: 1','Callerid: $GPqueryCID','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|conf_grab_park_customer|GP|$GPqueryCID|$stmtA|";
			 &event_logger;

	

		### delete call from parked_channels table
#		my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#		or 	die "Couldn't connect to database: \n";
		$stmtA = "DELETE FROM parked_channels where channel='$PICKUP' and server_ip = '$server_ip';";
		$dbhA->query($stmtA);
#		$dbhA->close;

	}

}







##########################################
##########################################
### hangs up the conference line
##########################################
##########################################
sub conf_hangup_xfer_line {

my $XFER_HANGUP = $xfer_channel_value->get;

		$event_string = "SUBRT|conf_hangup_xfer_line|$XFER_HANGUP|";
	 event_logger;

	### error box if channel to hangup is not live
if (length($XFER_HANGUP)<5)
	{
	
		my $dialog = $MW->DialogBox( -title   => "Xfer Channel Hangup Error",
									 -buttons => [ "OK" ],
					);
		$dialog->add("Label", -text => "The channel you are trying to hangup is not live\n   |$XFER_HANGUP|")->pack;
		$dialog->Show;  
	}
else
	{

		### insert a NEW record to the vicidial_manager table to be processed
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$XDqueryCID','Channel: $XFER_HANGUP','','','','','','','','','')";
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$event_string = "SUBRT|conf_hangup_xfer_line|XH|$XDqueryCID|$stmtA|";
		 event_logger;



	

	$xfer_channel_value->delete('0', 'end');


	}

}






##########################################
##########################################
### starts recording locally on the customer-connected line
##########################################
##########################################
sub start_recording
{

$CONFERENCE_RECORDING = 1;
$CONFERENCE_RECORDING_CHANNEL = '';


$SIP_user = $login_value->get;
$ext = $SIP_user;
$ext =~ s/SIP\///gi;
$filename = "$filedate$US$ext";

$start_recording_button->configure(-state => 'disabled');
$stop_recording_button->configure(-state => 'normal');

#if (!$RECORD) {$RECORD = '-';}
#if (length($RECORD)>4) {$channel = $RECORD;}
#else {$channel = $zap_channel_value->get;}
	$channel = $zap_channel_value->get;

	$channel =~ s/Zap\///gi;
	$record_channel = $channel;

		$event_string = "SUBRT|start_recording|START|$filename|$record_channel|";
	 event_logger;

	$local_DEF = 'Local/';
	$local_AMP = '@';
	$conf_silent_prefix = '7';

		### use manager middleware-app to connect the next call to the meetme room
			$RBqueryCID = "RB$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$RBqueryCID','Channel: $local_DEF$conf_silent_prefix$session_id$local_AMP$ext_context','Context: $ext_context','Exten: $recording_exten','Priority: 1','Callerid: $filename','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|start_recording|RB|$RBqueryCID|$stmtA|";
			 &event_logger;

	

	$status_value->delete('0', 'end');
    $status_value->insert('0', " - RECORDING - ");
	$rec_fname_value->delete('0', 'end');
    $rec_fname_value->insert('0', "$filename");
	$rec_recid_value->delete('0', 'end');


#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

		$stmtA = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('Zap/$channel','$server_ip','$SIP_user','$SQLdate','$secX','$filename')";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

	   $dbhA->query("SELECT recording_id FROM recording_log where filename='$filename'");
	   if ($dbhA->has_selected_record) {
	   $iter=$dbhA->create_record_iterator;
	     $rec_count=0;
		   while ( $record = $iter->each) {
		   print STDERR $record->[0],"|", $record->[1],"\n";
		   $recording_id = "$record->[0]";
		   $rec_count++;
		   $rec_recid_value->insert('0', "$recording_id");
		   } 
	   }


	#$dbhA->close;

	print "|channel:$channel|$filename|\n";

		$event_string = "SUBRT|start_recording|END|$filename|$channel|$recording_id|";
	 event_logger;

}






##########################################
##########################################
### starts recording locally on the customer-connected line
##########################################
##########################################
sub stop_recording
{
$SIP_user = $login_value->get;

if (length($CONFERENCE_RECORDING_CHANNEL) > 5)
	{

		$event_string = "SUBRT|stop_recording|$SIP_user|$record_channel|";
	 event_logger;


		### use manager middleware-app to connect the next call to the meetme room
			$REqueryCID = "RE$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$REqueryCID','Channel: $CONFERENCE_RECORDING_CHANNEL','','','','','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|stop_recording|RE|$REqueryCID|$stmtA|";
			 &event_logger;

	


#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

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
	#$dbhA->close;

	print "|channel:$CONFERENCE_RECORDING_CHANNEL|$record_channel|$filename|\n";

	$status_value->delete('0', 'end');
    $status_value->insert('0', "Length: $length_in_min Min.");
  #  $rec_recid_value->insert('0', "$recording_id");


$record_channel='';

$start_recording_button->configure(-state => 'normal');
$stop_recording_button->configure(-state => 'disabled');

$CONFERENCE_RECORDING = 0;
$CONFERENCE_RECORDING_CHANNEL = '';

	}
}






##########################################
##########################################
### starts recording locally on the customer-connected line
##########################################
##########################################
sub hangup_ring_monitor
{
$SIP_user = $login_value->get;

if (length($monitor_channel) > 50)
	{

		$event_string = "SUBRT|stop_recording|$SIP_user|$record_channel|";
	 event_logger;


		### use manager middleware-app to connect the next call to the meetme room
			$REqueryCID = "RE$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Hangup','$REqueryCID','Channel: $CONFERENCE_RECORDING_CHANNEL','','','','','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|stop_recording|RE|$REqueryCID|$stmtA|";
			 &event_logger;

	


#	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
#	or 	die "Couldn't connect to database: \n";

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
	#$dbhA->close;

	print "|channel:$CONFERENCE_RECORDING_CHANNEL|$record_channel|$filename|\n";

	$status_value->delete('0', 'end');
    $status_value->insert('0', "Length: $length_in_min Min.");
  #  $rec_recid_value->insert('0', "$recording_id");


$record_channel='';

$start_recording_button->configure(-state => 'normal');
$stop_recording_button->configure(-state => 'disabled');

$CONFERENCE_RECORDING = 0;
$CONFERENCE_RECORDING_CHANNEL = '';

	}
}





##########################################
##########################################
### send dtmf tones to conference zap channel
##########################################
##########################################
sub conf_send_dtmf
{

my $XFER_DTMF_CHAN = $session_id;
my $XFER_DTMF_DIGITS = $xfer_dtmf_value->get;

		$event_string = "SUBRT|conf_send_dtmf|$XFER_DTMF_CHAN|$XFER_DTMF_DIGITS|";
	 event_logger;

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


		### use manager middleware-app to connect the next call to the meetme room
			$DTqueryCID = "DT$CIDdate$session_id";

		### insert a NEW record to the vicidial_manager table to be processed
			$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','$DTqueryCID','Exten: 7$session_id','Channel: $dtmf_send_extension','Context: $ext_context','Priority: 1','Callerid: $XFER_DTMF_DIGITS','','','','','')";
			$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";

			$CN_manager_command_sent = 1;

				$event_string = "SUBRT|conf_send_dtmf|DT|$DTqueryCID|$stmtA|";
			 &event_logger;

	



	$xfer_dtmf_value->delete('0', 'end');


	}


}


