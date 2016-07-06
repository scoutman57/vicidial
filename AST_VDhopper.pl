#!/usr/bin/perl
#
# AST_VDhopper.pl version 0.2
#
# DESCRIPTION:
# uses Net::MySQL to update the VICIDIAL leads hopper for the new streamlined 
# approach of allocating leads to client machines. 
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with VICIDIAL
#
# For the client to use VICIDIAL, this program must be in the cron running 
# every minute
# 
# For this program to work you need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# It is recommended that you run this program on the local Asterisk machine
#
# If this script is run ever minute and you are getting close to no leads after
# a minute, you may want to play with the variables below to streamline for 
# your usage
#
# Distributed with no waranty under the GNU Public License
#

# constants
$DB=0;  # Debug flag, set to 0 for no debug messages, On an active system this will generate lots of lines of output per minute
$US='__';
$MT[0]='';

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = ($year + 1900);
$mon++;
if ($mon < 10) {$mon = "0$mon";}
if ($mday < 10) {$mday = "0$mday";}
if ($hour < 10) {$Fhour = "0$hour";}
if ($min < 10) {$min = "0$min";}
if ($sec < 10) {$sec = "0$sec";}
$now_date = "$year-$mon-$mday $hour:$min:$sec";

if (!$VDHLOGfile) {$VDHLOGfile = "/home/cron/hopper.$year-$mon-$mday";}

### begin parsing run-time options ###
if (length($ARGV[0])>1)
{
	$i=0;
	while ($#ARGV >= $i)
	{
	$args = "$args $ARGV[$i]";
	$i++;
	}

	if ($args =~ /--help/i)
	{
	print "allowed run time options(must stay in this order):\n  [--debug] = debug\n [--dbgmt] = show GMT offset of records as they are inserted into hopper\n  [-t] = test\n  [--level=XXX] = force a hopper_level of XXX\n  [--campaign=XXX] = run for campaign XXX only\n\n";
	}
	else
	{
		if ($args =~ /--campaign=/i)
		{
		#	print "\n|$ARGS|\n\n";
		@data_in = split(/--campaign=/,$args);
			$CLIcampaign = $data_in[1];
		}
		else
			{$CLIcampaign = '';}
		if ($args =~ /--level=/i)
		{
		@data_in = split(/--level=/,$args);
			$CLIlevel = $data_in[1];
			$CLIlevel =~ s/ .*$//gi;
			$CLIlevel =~ s/\D//gi;
		print "\n-----HOPPER LEVEL OVERRIDE: $CLIlevel -----\n\n";
		}
		else
			{$CLIlevel = '';}
		if ($args =~ /--debug/i)
		{
		$DB=1;
		print "\n-----DEBUG -----\n\n";
		}
		if ($args =~ /--dbgmt/i)
		{
		$DB_show_offset=1;
		print "\n-----DEBUG GMT -----\n\n";
		}
		if ($args =~ /-t/i)
		{
		$T=1;   $TEST=1;
		print "\n-----TESTING -----\n\n";
		}
		if ($args =~ /--wipe-hopper-clean/i)
		{
		$wipe_hopper_clean=1;
		}
	}
}
else
{
print "no command line options set\n";
}

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

$secX = time();
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($secX);
	$LOCAL_GMT_OFF = $SERVER_GMT;
	$LOCAL_GMT_OFF_STD = $SERVER_GMT;
	if ($isdst) {$LOCAL_GMT_OFF++;} 


$GMT_now = ($secX - ($LOCAL_GMT_OFF * 3600));
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($GMT_now);
	$mon++;
	$year = ($year + 1900);
	if ($mon < 10) {$mon = "0$mon";}
	if ($mday < 10) {$mday = "0$mday";}
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}
	if ($sec < 10) {$sec = "0$sec";}


	if ($DB) {print "TIME DEBUG: $LOCAL_GMT_OFF_STD|$LOCAL_GMT_OFF|$isdst|   GMT: $hour:$min\n";}

sleep(1);	### sleep for 5 seconds to stagger cron script load

use lib './lib', '../lib';
use Net::MySQL;
	  

	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";


if ($wipe_hopper_clean)
	{
	$stmtA = "DELETE from vicidial_hopper;";
	$dbhA->query("$stmtA");
	my $affected_rows = $dbhA->get_affected_rows_length;
	if ($DB) {print "Hopper Wiped Clean:  $affected_rows\n";}
		$event_string = "|HOPPER WIPE CLEAN|";
		&event_logger;

	exit;
	}

@campaign_id=@MT; 

if ($CLIcampaign)
	{
	$stmtA = "SELECT * from vicidial_campaigns where campaign_id='$CLIcampaign'";
	}
else
	{
	$stmtA = "SELECT * from vicidial_campaigns where active='Y'";
	}

$dbhA->query("$stmtA");
if ($dbhA->has_selected_record)
   {
	$iter=$dbhA->create_record_iterator;
	$rec_count=0;
	while ( $record = $iter->each)
		{
		$campaign_id[$rec_count] =		 "$record->[0]";
		$dial_status_a[$rec_count] =	 "$record->[3]";
		$dial_status_b[$rec_count] =	 "$record->[4]";
		$dial_status_c[$rec_count] =	 "$record->[5]";
		$dial_status_d[$rec_count] =	 "$record->[6]";
		$dial_status_e[$rec_count] =	 "$record->[7]";
		$lead_order[$rec_count] =		 "$record->[8]";
		if (!$CLIlevel) 
			{$hopper_level[$rec_count] = "$record->[13]";}
		else
			{$hopper_level[$rec_count] = "$CLIlevel";}
		$local_call_time[$rec_count] =	 "$record->[16]";
		$rec_count++;
		}
   }

$i=0;
foreach(@campaign_id)
	{
	##### calculate what gmt_offset_now values are within the allowed local_call_time setting
	$GMT_allowed = '';

	if ($local_call_time[$i] =~ /24hours/)
		{
		$p='13';
		while ($p > -13)
			{
			$tz = sprintf("%.2f", $p);	$GMT_allowed .= "'$tz',";
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time[$i] =~ /9am-9pm/)
		{
		$p='13';
		while ($p > -13)
			{
			$GMT_test = ($GMT_now + ($p * 3600));
				($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($GMT_test);
			if ( ($hour >= 9) && ($hour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed .= "'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time[$i] =~ /9am-5pm/)
		{
		$p='13';
		while ($p > -13)
			{
			$GMT_test = ($GMT_now + ($p * 3600));
				($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($GMT_test);
			if ( ($hour >= 9) && ($hour <= 16) ){$tz = sprintf("%.2f", $p);	$GMT_allowed .= "'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time[$i] =~ /12pm-5pm/)
		{
		$p='13';
		while ($p > -13)
			{
			$GMT_test = ($GMT_now + ($p * 3600));
				($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($GMT_test);
			if ( ($hour >= 12) && ($hour <= 16) ){$tz = sprintf("%.2f", $p);	$GMT_allowed .= "'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time[$i] =~ /12pm-9pm/)
		{
		$p='13';
		while ($p > -13)
			{
			$GMT_test = ($GMT_now + ($p * 3600));
				($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($GMT_test);
			if ( ($hour >= 12) && ($hour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed .= "'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time[$i] =~ /5pm-9pm/)
		{
		$p='13';
		while ($p > -13)
			{
			$GMT_test = ($GMT_now + ($p * 3600));
				($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($GMT_test);
			if ( ($hour >= 17) && ($hour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed .= "'$tz',";}
			$p = ($p - 0.25);
			}
		}

	$GMT_allowed .= "'99'";


	if ($DB) {print "Starting hopper run for $campaign_id[$i] campaign: GMT: $local_call_time[$1] $GMT_allowed   HOPPER: $hopper_level[$i] \n";}

	$stmtA = "DELETE from vicidial_hopper where campaign_id='$campaign_id[$i]' and status IN('DONE');";
	$dbhA->query("$stmtA");
	my $affected_rows = $dbhA->get_affected_rows_length;
	if ($DB) {print "     hopper DONE cleared:  $affected_rows\n";}

	$hopper_ready_count=0;
	$dbhA->query("SELECT count(*) from vicidial_hopper where campaign_id='$campaign_id[$i]' and status='READY';");
	if ($dbhA->has_selected_record)
		{
		$iter=$dbhA->create_record_iterator;
		$rec_countA=0;
		while ( $record = $iter->each)
			{
			$hopper_ready_count = $record->[0];
			if ($DB) {print "     hopper READY count:   $hopper_ready_count\n";}
			$rec_countA++;
			}
		}
		$event_string = "|$campaign_id[$i]|$hopper_level[$i]|$hopper_ready_count|$local_call_time[$i]|$GMT_allowed|";
		&event_logger;

	##### IF hopper level is below set minimum, then try to add more leads #####
	if ($hopper_ready_count < $hopper_level[$i])
		{
		if ($DB) {print "     hopper too low ($hopper_ready_count|$hopper_level[$i]) starting hopper dump\n";}

		$dbhA->query("SELECT list_id FROM vicidial_lists where campaign_id='$campaign_id[$i]' and active='Y';");
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
		if ($DB) {print "     campaign lists count: $rec_countLISTS | $camp_lists\n";}

		$dbhA->query("SELECT count(*) FROM vicidial_list where called_since_last_reset='N' and status IN('$dial_status_a[$i]','$dial_status_b[$i]','$dial_status_c[$i]','$dial_status_d[$i]','$dial_status_e[$i]') and list_id IN($camp_lists) and gmt_offset_now IN($GMT_allowed)");
		$campaign_leads_to_call=0;
		if ($dbhA->has_selected_record)
			{
			$iter=$dbhA->create_record_iterator;
			while ( $record = $iter->each)
				{
				$campaign_leads_to_call = "$record->[0]";
				if ($DB) {print "     leads to call count:  $campaign_leads_to_call\n";}
				} 
			}
		if ( ($lead_order[$i] eq "DOWN COUNT 2nd NEW") or ($lead_order[$i] eq "DOWN COUNT 3rd NEW") or ($lead_order[$i] eq "DOWN COUNT 4th NEW") )
			{
			$dbhA->query("SELECT count(*) FROM vicidial_list where called_since_last_reset='N' and status IN('NEW') and list_id IN($camp_lists) and gmt_offset_now IN($GMT_allowed)");
			$NEW_campaign_leads_to_call=0;
			if ($dbhA->has_selected_record)
				{
				$iter=$dbhA->create_record_iterator;
				while ( $record = $iter->each)
					{
					$NEW_campaign_leads_to_call = "$record->[0]";
					if ($DB) {print "     NEW leads to call count:  $NEW_campaign_leads_to_call\n";}
					} 
				}
			}

		##### IF no NEW leads to be called, error out of this campaign #####
		if ( ( ($lead_order[$i] eq "DOWN COUNT 2nd NEW") or ($lead_order[$i] eq "DOWN COUNT 3rd NEW") or ($lead_order[$i] eq "DOWN COUNT 4th NEW") ) && ($NEW_campaign_leads_to_call > 0) ) {$GOOD=1;}
		else
			{
			if ($DB) {print "     ERROR CANNOT ADD ANY NEW LEADS TO HOPPER\n";}
			}

		##### IF no leads to be called, error out of this campaign #####
		if ($campaign_leads_to_call < 1)
			{
			if ($DB) {print "     ERROR CANNOT ADD ANY LEADS TO HOPPER\n";}
			}
		else
			{
			if ($DB) {print "     Getting Leads to add to hopper\n";}
			$dbhA->query("SELECT lead_id FROM vicidial_hopper where campaign_id='$campaign_id[$i]';");
			 $rec_countLISTS=0;
			 $lead_id_lists = '';
			if ($dbhA->has_selected_record)
				{
				$iter=$dbhA->create_record_iterator;
				while ( $record = $iter->each)
					{
					   $lead_id_lists .= "'$record->[0]',";
					$rec_countLISTS++;
					} 
				$lead_id_lists .= "'0'";
				}
			
				$order_stmt='';
				$NEW_count = 0;
				$NEW_level = 0;
				$OTHER_level = $hopper_level[$i];   
				if ($lead_order[$i] eq "DOWN") {$order_stmt = 'order by lead_id asc';}
				if ($lead_order[$i] eq "UP") {$order_stmt = 'order by lead_id desc';}
				if ($lead_order[$i] eq "UP LAST NAME") {$order_stmt = 'order by last_name desc, lead_id asc';}
				if ($lead_order[$i] eq "DOWN LAST NAME") {$order_stmt = 'order by last_name, lead_id asc';}
				if ($lead_order[$i] eq "UP PHONE") {$order_stmt = 'order by phone_number desc, lead_id asc';}
				if ($lead_order[$i] eq "DOWN PHONE") {$order_stmt = 'order by phone_number, lead_id asc';}
				if ($lead_order[$i] eq "UP COUNT") {$order_stmt = 'order by called_count desc, lead_id asc';}
				if ($lead_order[$i] eq "DOWN COUNT") {$order_stmt = 'order by called_count, lead_id asc';}
				if ($lead_order[$i] eq "DOWN COUNT 2nd NEW") {$NEW_count = 2;}
				if ($lead_order[$i] eq "DOWN COUNT 3rd NEW") {$NEW_count = 3;}
				if ($lead_order[$i] eq "DOWN COUNT 4th NEW") {$NEW_count = 4;}

				if ($NEW_count > 0)
					{
					$NEW_level = int($hopper_level[$i] / $NEW_count);   
					$OTHER_level = ($hopper_level[$i] - $NEW_level);   
					$order_stmt = 'order by called_count, lead_id asc';
					if ($DB) {print "     looking for $NEW_level NEW leads mixed in with $OTHER_level other leads\n";}

					$stmtA = "SELECT lead_id,list_id,gmt_offset_now,phone_number,state FROM vicidial_list where called_since_last_reset='N' and status IN('NEW') and list_id IN($camp_lists) and lead_id NOT IN($lead_id_lists) and gmt_offset_now IN($GMT_allowed) $order_stmt limit $NEW_level;";
			#		if ($DB) {print "     STMT |$stmtA|\n";}
					$dbhA->query("$stmtA");
					if ($dbhA->has_selected_record)
						{
						$iter=$dbhA->create_record_iterator;
						 $NEW_rec_countLEADS=0;
						 @NEW_leads_to_hopper=@MT;
						 @NEW_lists_to_hopper=@MT;
						 @NEW_phone_to_hopper=@MT;
						while ( $record = $iter->each)
							{
							$NEW_leads_to_hopper[$NEW_rec_countLEADS] = "$record->[0]";
							$NEW_lists_to_hopper[$NEW_rec_countLEADS] = "$record->[1]";
							$NEW_phone_to_hopper[$NEW_rec_countLEADS] = "$record->[3]";
							if ($DB_show_offset) {print "LEAD_ADD: $record->[2] $record->[3] $record->[4]\n";}
							$NEW_rec_countLEADS++;
							} 
						}

					}



			if ($DB) {print "     lead call order:      $order_stmt\n";}
			$stmtA = "SELECT lead_id,list_id,gmt_offset_now,phone_number,state FROM vicidial_list where called_since_last_reset='N' and status IN('$dial_status_a[$i]','$dial_status_b[$i]','$dial_status_c[$i]','$dial_status_d[$i]','$dial_status_e[$i]') and list_id IN($camp_lists) and lead_id NOT IN($lead_id_lists) and gmt_offset_now IN($GMT_allowed) $order_stmt limit $OTHER_level;";
	#		if ($DB) {print "     STMT |$stmtA|\n";}
			$dbhA->query("$stmtA");
			if ($dbhA->has_selected_record)
				{
				$iter=$dbhA->create_record_iterator;
				 $rec_countLEADS=0;   $NEW_dec=99;   $NEW_in=0;
				 @leads_to_hopper=@MT;
				 @lists_to_hopper=@MT;
				while ( $record = $iter->each)
					{
					if ( ($NEW_count > 0) && ($NEW_rec_countLEADS > $NEW_in) )
						{
						if ($DB_show_offset) {print "NEW_COUNT: $NEW_count|$NEW_dec|$NEW_in|$NEW_rec_countLEADS\n";}
						if ($NEW_count > $NEW_dec) 
							{
							$NEW_dec++;
							}
						else
							{
							$leads_to_hopper[$rec_countLEADS] = "$NEW_leads_to_hopper[$NEW_in]";
							$lists_to_hopper[$rec_countLEADS] = "$NEW_lists_to_hopper[$NEW_in]";
							if ($DB_show_offset) {print "LEAD_ADD:    $NEW_leads_to_hopper[$NEW_in]   $NEW_phone_to_hopper[$NEW_in]\n";}
							$rec_countLEADS++;
							$NEW_in++;
							$NEW_dec=2;
							}
						}
					$leads_to_hopper[$rec_countLEADS] = "$record->[0]";
					$lists_to_hopper[$rec_countLEADS] = "$record->[1]";
					if ($DB_show_offset) {print "LEAD_ADD: $record->[2] $record->[3] $record->[4]\n";}
					$rec_countLEADS++;
					} 
				}

				if ($DB) {print "     Adding to hopper:     $rec_countLEADS\n";}
				$event_string = "|$campaign_id[$i]|Added to hopper $rec_countLEADS|";
				&event_logger;

			$h=0;
			foreach(@leads_to_hopper)
				{
				if ($leads_to_hopper[$h] != '0')
					{
					$stmtA = "INSERT INTO vicidial_hopper values('','$leads_to_hopper[$h]','$campaign_id[$i]','READY','','$lists_to_hopper[$h]');";
					$dbhA->query("$stmtA");
					}
				$h++;
				}
				if ($DB) {print "     DONE with this campaign\n";}

			}
		}
	
	
	$i++;
	}



$dbhA->close;

if($DB){print "DONE... Exiting... Goodbye... See you later... Really, I mean it :)\n";}

exit;



sub event_logger {
	### open the log file for writing ###
	open(Lout, ">>$VDHLOGfile")
			|| die "Can't open $VDHLOGfile: $!\n";

	print Lout "$now_date|$event_string|\n";

	close(Lout);

$event_string='';
}


