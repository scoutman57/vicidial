#!/usr/bin/perl
#
# AST_VDhopper.pl version 0.1
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
$DB=0;  # Debug flag, set to 0 for no debug messages, On an active system this will generate thousands of lines of output per minute
$US='__';
$MT[0]='';
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
	print "allowed run time options:\n  [-q] = quiet\n  [-t] = test\n\n";
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
		{
		$CLIcampaign = '';
		}
		if ($args =~ /--debug/i)
		{
		$DB=1;
		print "\n-----DEBUG -----\n\n";
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

sleep(1);	### sleep for 5 seconds to stagger cron script load

use lib './lib', '../lib';
use Net::MySQL;
	  

	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

if ($wipe_hopper_clean)
	{
	$stmtA = "DELETE from vicidial_hopper;";
	$dbhA->query("$stmtA");
	my $affected_rows = $dbhA->get_affected_rows_length;
	if ($DB) {print "Hopper Wiped Clean:  $affected_rows\n";}
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
		$hopper_level[$rec_count] =		 "$record->[13]";
		$rec_count++;
		}
   }

$i=0;
foreach(@campaign_id)
	{
	if ($DB) {print "Starting hopper run for $campaign_id[$i] campaign:\n";}

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

		$dbhA->query("SELECT count(*) FROM vicidial_list where called_since_last_reset='N' and status IN('$dial_status_a[$i]','$dial_status_b[$i]','$dial_status_c[$i]','$dial_status_d[$i]','$dial_status_e[$i]') and list_id IN($camp_lists)");
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
				if ($lead_order[$i] eq "DOWN") {$order_stmt = 'order by lead_id asc';}
				if ($lead_order[$i] eq "UP") {$order_stmt = 'order by lead_id desc';}
				if ($lead_order[$i] eq "UP LAST NAME") {$order_stmt = 'order by last_name desc, lead_id asc';}
				if ($lead_order[$i] eq "DOWN LAST NAME") {$order_stmt = 'order by last_name, lead_id asc';}
				if ($lead_order[$i] eq "UP PHONE") {$order_stmt = 'order by phone_number desc, lead_id asc';}
				if ($lead_order[$i] eq "DOWN PHONE") {$order_stmt = 'order by phone_number, lead_id asc';}
				if ($lead_order[$i] eq "UP COUNT") {$order_stmt = 'order by called_count desc, lead_id asc';}
				if ($lead_order[$i] eq "DOWN COUNT") {$order_stmt = 'order by called_count, lead_id asc';}

			if ($DB) {print "     lead call order:      $order_stmt\n";}
			$stmtA = "SELECT lead_id,list_id FROM vicidial_list where called_since_last_reset='N' and status IN('$dial_status_a[$i]','$dial_status_b[$i]','$dial_status_c[$i]','$dial_status_d[$i]','$dial_status_e[$i]') and list_id IN($camp_lists) and lead_id NOT IN($lead_id_lists) $order_stmt limit $hopper_level[$i];";
	#		if ($DB) {print "     STMT |$stmtA|\n";}
			$dbhA->query("$stmtA");
			if ($dbhA->has_selected_record)
				{
				$iter=$dbhA->create_record_iterator;
				 $rec_countLEADS=0;
				 @leads_to_hopper=@MT;
				 @lists_to_hopper=@MT;
				while ( $record = $iter->each)
					{
					$leads_to_hopper[$rec_countLEADS] = "$record->[0]";
					$lists_to_hopper[$rec_countLEADS] = "$record->[1]";
					$rec_countLEADS++;
					} 
				}

				if ($DB) {print "     Adding to hopper:     $rec_countLEADS\n";}
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




