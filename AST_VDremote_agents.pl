#!/usr/bin/perl
#
# AST_VDremote_agents.pl version 0.1
#
# DESCRIPTION:
# uses Net::MySQL to keep remote agents logged in to the VICIDIAL system 
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with VICIDIAL
#
# For the client to use VICIDIAL with remote agents, this must always be running 
# 
# It is recommended that you run this program on the local Asterisk machine
#
# This script is to run perpetually querying every second to update the remote 
# agents that should appear to be logged in so that the calls can be transferred 
# out to them properly.
#
# It is good practice to keep this program running by placing the associated 
# KEEPALIVE script running every minute to ensure this program is always running
#
# Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#
# changes:
# 50215-0954 - First version of script
# 50810-1615 - Added database server variable definitions lookup
#

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
	print "allowed run time options:\n  [-t] = test\n  [-v] = verbose debug messages\n  [--delay=XXX] = delay of XXX seconds per loop, default 2 seconds\n\n";
	}
	else
	{
		if ($args =~ /--delay=/i)
		{
		@data_in = split(/--delay=/,$args);
			$loop_delay = $data_in[1];
			print "     LOOP DELAY OVERRIDE!!!!! = $loop_delay seconds\n\n";
			$loop_delay = ($loop_delay * 1000);
		}
		else
		{
		$loop_delay = '2000';
		}
		if ($args =~ /-v/i)
		{
		$V=1; # Debug flag, set to 0 for no debug messages, On an active system this will generate hundreds of lines of output per minute
		}
		if ($args =~ /-t/i)
		{
		$TEST=1;
		$T=1;
		}
	}
}
else
{
print "no command line options set\n";
	$loop_delay = '2000';
	$V=1;
}
### end parsing run-time options ###


# constants
$US='__';
$MT[0]='';

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

use lib './lib', '../lib';
use Time::HiRes ('gettimeofday','usleep','sleep');  # necessary to have perl sleep command of less than one second
use Net::MySQL;
	
	### connect to MySQL database defined in the AST_SERVER_conf.pl file
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";

### Grab Server values from the database
$stmtA = "SELECT local_gmt FROM servers where server_ip = '$server_ip';";
$dbhA->query("$stmtA");
if ($dbhA->has_selected_record)
	{
	$iter=$dbhA->create_record_iterator;
	   while ( $record = $iter->each)
		{
		$DBSERVER_GMT		=		"$record->[0]";
		if ($DBSERVER_GMT)				{$SERVER_GMT = $DBSERVER_GMT;}
		} 
	}


	&get_time_now;	# update time/date variables

	$event_string='PROGRAM STARTED||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||';
	&event_logger;	# writes to the log and if debug flag is set prints to STDOUT


	$event_string='LOGGED INTO MYSQL SERVER ON 1 CONNECTION|';
	&event_logger;

$one_day_interval = 12;		# 1 month loops for one year 
while($one_day_interval > 0)
{

	$endless_loop=5760000;		# 30 days minutes at XXX seconds per loop

	while($endless_loop > 0)
	{
		&get_time_now;

		if ($endless_loop =~ /0$|5$/)
		{
		### delete call records that are LIVE for over 10 minutes and last_update_time < '$PDtsSQLdate'
		$stmtA = "DELETE FROM vicidial_live_agents where server_ip='$server_ip' and status IN('PAUSED') and extension LIKE \"R/%\"";
		$dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;

		$event_string = "|     lagged call vla agent DELETED $affected_rows";
		 &event_logger;


		$stmtA = "UPDATE vicidial_live_agents set status='INCALL', last_call_time='$SQLdate' where server_ip='$server_ip' and status IN('QUEUE') and extension LIKE \"R/%\"";
		$dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;

		$event_string = "|     QUEUEd call listing vla UPDATEd $affected_rows";
		 &event_logger;

		#@psoutput = `/bin/ps -f --no-headers -A`;
		@psoutput = `/bin/ps -o "%p %a" --no-headers -A`;

		$running_listen = 0;

		$i=0;
		foreach (@psoutput)
		{
			chomp($psoutput[$i]);

		@psline = split(/\/usr\/bin\/perl /,$psoutput[$i]);

		if ($psline[1] =~ /AST_manager_li/) {$running_listen++;}

		$i++;
		}

		if (!$running_listen) 
			{
			$endless_loop=0;
			$one_day_interval=0;
			print "\nPROCESS KILLED NO LISTENER RUNNING... EXITING\n\n";
			}

		if($DB){print "checking to see if listener is dead |$running_listen|\n";}
		}



		$user_counter=0;
		@DBremote_user=@MT;
		@DBremote_server_ip=@MT;
		@DBremote_campaign=@MT;
		@DBremote_conf_exten=@MT;
		@DBremote_closer=@MT;
		@DBremote_random=@MT;
		@loginexistsRANDOM=@MT;
		@loginexistsALL=@MT;
		@VD_user=@MT;
		@VD_extension=@MT;
		@VD_status=@MT;
		@VD_uniqueid=@MT;
		@VD_callerid=@MT;
		@VD_random=@MT;
	###############################################################################
	###### first grab all of the ACTIVE remote agents information from the database
	###############################################################################
		$dbhA->query("SELECT * FROM vicidial_remote_agents where status IN('ACTIVE') and server_ip='$server_ip' order by user_start");
		if ($dbhA->has_selected_record)
		   {
			$iter=$dbhA->create_record_iterator;
			while ( $record = $iter->each)
				{
				$user_start =				"$record->[1]";
				$number_of_lines =			"$record->[2]";
				$conf_exten =				"$record->[4]";
				$campaign_id =				"$record->[6]";
				$closer_campaigns =			"$record->[7]";

				$y=0;
				while ($y < $number_of_lines)
					{
					$random = int( rand(9999999)) + 10000000;
					$user_id = ($user_start + $y);
					$DBremote_user[$user_counter] =			"$user_id";
					$DBremote_server_ip[$user_counter] =	"$server_ip";
					$DBremote_campaign[$user_counter] =		"$campaign_id";
					$DBremote_conf_exten[$user_counter] =	"$conf_exten";
					$DBremote_closer[$user_counter] =		"$closer_campaigns";
					$DBremote_random[$user_counter] =		"$random";
					
					$y++;
					$user_counter++;
					}
				
				}
			if ($V) {print STDERR "$user_counter live remote agents ACTIVE\n";}
		   }


	###############################################################################
	###### second traverse array of remote agents to be active and insert or update 
	###### in vicidial_live_agents table 
	###############################################################################
		$h=0;
		foreach(@DBremote_user) 
			{
			if (length($DBremote_user[$h])>1) 
				{
				
				### check to see if the record exists and only needs random number update
				$dbhA->query("SELECT count(*) FROM vicidial_live_agents where user='$DBremote_user[$h]' and server_ip='$server_ip' and campaign_id='$DBremote_campaign[$h]' and conf_exten='$DBremote_conf_exten[$h]' and closer_campaigns='$DBremote_closer[$h]'");
				if ($dbhA->has_selected_record)
					{
					$iter=$dbhA->create_record_iterator;
					   while ( $record = $iter->each)
					   {
					   $loginexistsRANDOM[$h] = "$record->[0]";
					   } 
					}
				if ($loginexistsRANDOM[$h] > 0)
					{
					$stmtA = "UPDATE vicidial_live_agents set random_id='$DBremote_random[$h]' where user='$DBremote_user[$h]' and server_ip='$server_ip' and campaign_id='$DBremote_campaign[$h]' and conf_exten='$DBremote_conf_exten[$h]' and closer_campaigns='$DBremote_closer[$h]'";
					$dbhA->query("$stmtA");
					my $affected_rows = $dbhA->get_affected_rows_length;
					if ($V) {print STDERR "$DBremote_user[$h] $DBremote_campaign[$h] ONLY RANDOM ID UPDATE: $affected_rows\n";}
					}
				### check if record for user on server exists at all in vicidial_live_agents
				else
					{
					$dbhA->query("SELECT count(*) FROM vicidial_live_agents where user='$DBremote_user[$h]' and server_ip='$server_ip'");
					if ($dbhA->has_selected_record)
						{
						$iter=$dbhA->create_record_iterator;
						   while ( $record = $iter->each)
						   {
						   $loginexistsALL[$h] = "$record->[0]";
						   } 
						}
					if ($loginexistsALL[$h] > 0)
						{
						$stmtA = "UPDATE vicidial_live_agents set random_id='$DBremote_random[$h]',campaign_id='$DBremote_campaign[$h]',conf_exten='$DBremote_conf_exten[$h]',closer_campaigns='$DBremote_closer[$h]', status='READY' where user='$DBremote_user[$h]' and server_ip='$server_ip'";
						$dbhA->query("$stmtA");
						my $affected_rows = $dbhA->get_affected_rows_length;
						if ($V) {print STDERR "$DBremote_user[$h] ALL UPDATE: $affected_rows\n";}
						}
					### no records exist so insert a new one
					else
						{
						$stmtA = "INSERT INTO vicidial_live_agents (user,server_ip,conf_exten,extension,status,campaign_id,random_id,last_call_time,last_update_time,last_call_finish,closer_campaigns,channel,uniqueid,callerid) values('$DBremote_user[$h]','$server_ip','$DBremote_conf_exten[$h]','R/$DBremote_user[$h]','READY','$DBremote_campaign[$h]','$DBremote_random[$h]','$SQLdate','$tsSQLdate','$SQLdate','$DBremote_closer[$h]','','','')";
						$dbhA->query("$stmtA");
						if ($V) {print STDERR "$DBremote_user[$h] NEW INSERT\n";}
						}
					}
				}
			$h++;
			}


	###############################################################################
	###### third validate that the calls that the vicidial_live_agents are on are not dead
	###### and if they are wipe out the values and set the agent record back to READY
	###############################################################################
		$dbhA->query("SELECT user,extension,status,uniqueid,callerid FROM vicidial_live_agents where extension LIKE \"R/%\" and server_ip='$server_ip' and uniqueid > 10");
		if ($dbhA->has_selected_record)
		   {
			$iter=$dbhA->create_record_iterator;
			$z=0;
			while ( $record = $iter->each)
				{
				$VDuser =				"$record->[0]";
				$VDextension =			"$record->[1]";
				$VDstatus =				"$record->[2]";
				$VDuniqueid =			"$record->[3]";
				$VDcallerid =			"$record->[4]";
				$VDrandom = int( rand(9999999)) + 10000000;

				$VD_user[$z] =			"$VDuser";
				$VD_extension[$z] =		"$VDextension";
				$VD_status[$z] =		"$VDstatus";
				$VD_uniqueid[$z] =		"$VDuniqueid";
				$VD_callerid[$z] =		"$VDcallerid";
				$VD_random[$z] =		"$VDrandom";
					
				$z++;				
				}
			if ($V) {print STDERR "$z remote agents on calls\n";}
		   }
		$z=0;
		foreach(@VD_user) 
			{
			$dbhA->query("SELECT count(*) FROM vicidial_auto_calls where uniqueid='$VD_uniqueid[$z]' and server_ip='$server_ip'");
			if ($dbhA->has_selected_record)
				{
				$iter=$dbhA->create_record_iterator;
				   while ( $record = $iter->each)
				   {
				   $autocallexists[$z] = "$record->[0]";
				   } 
				}
			if ($autocallexists[$z] < 1)
				{
				$stmtA = "UPDATE vicidial_live_agents set random_id='$VD_random[$z]',status='READY', last_call_finish='$SQLdate',lead_id='',uniqueid='',callerid='',channel=''  where user='$VD_user[$z]' and server_ip='$server_ip'";
				$dbhA->query("$stmtA");
				my $affected_rows = $dbhA->get_affected_rows_length;
				if ($V) {print STDERR "$VD_user[$z] CALL WIPE UPDATE: $affected_rows|$VD_uniqueid[$z]\n";}
				}

			$z++;
			}






	###############################################################################
	###### last, wait for a little bit and repeat the loop
	###############################################################################

		### sleep for X seconds before beginning the loop again
		usleep(1*$loop_delay*1000);

	$endless_loop--;
		if($DB){print STDERR "\nloop counter: |$endless_loop|\n";}

		### putting a blank file called "VDAD.kill" in the directory will automatically safely kill this program
		if (-e '/home/cron/VDAD.kill')
			{
			unlink('/home/cron/VDAD.kill');
			$endless_loop=0;
			$one_day_interval=0;
			print "\nPROCESS KILLED MANUALLY... EXITING\n\n"
			}

		$bad_grabber_counter=0;


	}


		if($DB){print "DONE... Exiting... Goodbye... See you later... Not really, initiating next loop...\n";}

		$event_string='HANGING UP|';
		&event_logger;

	$one_day_interval--;

}

		$event_string='CLOSING DB CONNECTION|';
		&event_logger;


	$dbhA->close;


	if($DB){print "DONE... Exiting... Goodbye... See you later... Really I mean it this time\n";}


exit;













sub get_time_now	#get the current date and time and epoch for logging call lengths and datetimes
{
	$secX = time();
$secX = time();
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($secX);
	$LOCAL_GMT_OFF = $SERVER_GMT;
	$LOCAL_GMT_OFF_STD = $SERVER_GMT;
	if ($isdst) {$LOCAL_GMT_OFF++;} 

$GMT_now = ($secX - ($LOCAL_GMT_OFF * 3600));
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($GMT_now);
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}

	if ($DB) {print "TIME DEBUG: $LOCAL_GMT_OFF_STD|$LOCAL_GMT_OFF|$isdst|   GMT: $hour:$min\n";}

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = ($year + 1900);
$mon++;
if ($mon < 10) {$mon = "0$mon";}
if ($mday < 10) {$mday = "0$mday";}
if ($hour < 10) {$Fhour = "0$hour";}
if ($min < 10) {$min = "0$min";}
if ($sec < 10) {$sec = "0$sec";}

$now_date_epoch = time();
$now_date = "$year-$mon-$mday $hour:$min:$sec";
	$CIDdate = "$mon$mday$hour$min$sec";
	$tsSQLdate = "$year$mon$mday$hour$min$sec";
	$SQLdate = "$year-$mon-$mday $hour:$min:$sec";
	$filedate = "$year-$mon-$mday";

$BDtarget = ($secX - 10);
($Bsec,$Bmin,$Bhour,$Bmday,$Bmon,$Byear,$Bwday,$Byday,$Bisdst) = localtime($BDtarget);
$Byear = ($Byear + 1900);
$Bmon++;
if ($Bmon < 10) {$Bmon = "0$Bmon";}
if ($Bmday < 10) {$Bmday = "0$Bmday";}
if ($Bhour < 10) {$Bhour = "0$Bhour";}
if ($Bmin < 10) {$Bmin = "0$Bmin";}
if ($Bsec < 10) {$Bsec = "0$Bsec";}
	$BDtsSQLdate = "$Byear$Bmon$Bmday$Bhour$Bmin$Bsec";

$PDtarget = ($secX - 30);
($Psec,$Pmin,$Phour,$Pmday,$Pmon,$Pyear,$Pwday,$Pyday,$Pisdst) = localtime($PDtarget);
$Pyear = ($Pyear + 1900);
$Pmon++;
if ($Pmon < 10) {$Pmon = "0$Pmon";}
if ($Pmday < 10) {$Pmday = "0$Pmday";}
if ($Phour < 10) {$Phour = "0$Phour";}
if ($Pmin < 10) {$Pmin = "0$Pmin";}
if ($Psec < 10) {$Psec = "0$Psec";}
	$PDtsSQLdate = "$Pyear$Pmon$Pmday$Phour$Pmin$Psec";

$XDtarget = ($secX - 120);
($Xsec,$Xmin,$Xhour,$Xmday,$Xmon,$Xyear,$Xwday,$Xyday,$Xisdst) = localtime($XDtarget);
$Xyear = ($Xyear + 1900);
$Xmon++;
if ($Xmon < 10) {$Xmon = "0$Xmon";}
if ($Xmday < 10) {$Xmday = "0$Xmday";}
if ($Xhour < 10) {$Xhour = "0$Xhour";}
if ($Xmin < 10) {$Xmin = "0$Xmin";}
if ($Xsec < 10) {$Xsec = "0$Xsec";}
	$XDSQLdate = "$Xyear-$Xmon-$Xmday $Xhour:$Xmin:$Xsec";

$TDtarget = ($secX - 600);
($Tsec,$Tmin,$Thour,$Tmday,$Tmon,$Tyear,$Twday,$Tyday,$Tisdst) = localtime($TDtarget);
$Tyear = ($Tyear + 1900);
$Tmon++;
if ($Tmon < 10) {$Tmon = "0$Tmon";}
if ($Tmday < 10) {$Tmday = "0$Tmday";}
if ($Thour < 10) {$Thour = "0$Thour";}
if ($Tmin < 10) {$Tmin = "0$Tmin";}
if ($Tsec < 10) {$Tsec = "0$Tsec";}
	$TDSQLdate = "$Tyear-$Tmon-$Tmday $Thour:$Tmin:$Tsec";

}





sub event_logger
{

if ($DB) {print "$now_date|$event_string|\n";}
	### open the log file for writing ###
	open(Lout, ">>/home/cron/remote.$filedate")
			|| die "Can't open /home/cron/remote.$filedate: $!\n";

	print Lout "$now_date|$event_string|\n";

	close(Lout);

$event_string='';
}
