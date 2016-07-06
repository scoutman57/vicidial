#!/usr/bin/perl
#
# AST_VDadapt.pl version 2.0.3   *DBI-version*
#
# DESCRIPTION:
# adjusts the auto_dial_level for vicidial adaptive-predictive campaigns. 
#
# Copyright (C) 2007  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#
# CHANGELOG
# 60823-1302 - First build from AST_VDhopper.pl
# 60825-1734 - Functional alpha version, no loop
# 60826-0857 - Added loop and CLI flag options
# 60827-0035 - Separate Drop calculation and target dial level calculation into different subroutines
#            - Alter code so that DROP percentages would calculate only about once a minute no matter he loop delay
# 60828-1149 - Add field for target dial_level difference, -1 would target one agent waiting, +1 would target 1 customer waiting
# 60919-1243 - Changed variables to use arrays for all campaign-specific values
# 61215-1110 - Added answered calls stats and use drops as percentage of answered for today
# 70111-1600 - Added ability to use BLEND/INBND/*_C/*_B/*_I as closer campaigns
# 70205-1429 - Added code for campaign_changedate and campaign_stats_refresh updates
# 70213-1221 - Added code for QueueMetrics queue_log QUEUESTART record
# 70219-1249 - Removed unused references to dial_status_x fields
# 70409-1219 - Removed CLOSER-type campaign restriction
#

# constants
$DB=0;  # Debug flag, set to 0 for no debug messages, On an active system this will generate lots of lines of output per minute
$US='__';
$MT[0]='';

$i=0;
$drop_count_updater=0;
$stat_it=15;
$diff_ratio_updater=0;
$stat_count=1;
$VCScalls_today[$i]=0;
$VCSdrops_today[$i]=0;
$VCSdrops_today_pct[$i]=0;
$VCScalls_hour[$i]=0;
$VCSdrops_hour[$i]=0;
$VCSdrops_hour_pct[$i]=0;
$VCScalls_halfhour[$i]=0;
$VCSdrops_halfhour[$i]=0;
$VCSdrops_halfhour_pct[$i]=0;
$VCScalls_five[$i]=0;
$VCSdrops_five[$i]=0;
$VCSdrops_five_pct[$i]=0;
$VCScalls_one[$i]=0;
$VCSdrops_one[$i]=0;
$VCSdrops_one_pct[$i]=0;
$total_agents[$i]=0;
$ready_agents[$i]=0;
$waiting_calls[$i]=0;
$ready_diff_total[$i]=0;
$waiting_diff_total[$i]=0;
$total_agents_total[$i]=0;
$ready_diff_avg[$i]=0;
$waiting_diff_avg[$i]=0;
$total_agents_avg[$i]=0;
$stat_differential[$i]=0;
$VCSINCALL[$i]=0;
$VCSREADY[$i]=0;
$VCSCLOSER[$i]=0;
$VCSPAUSED[$i]=0;
$VCSagents[$i]=0;
$VCSagents_calc[$i]=0;
$VCSagents_active[$i]=0;

# set to 61 initially so that a baseline drop count is pulled
$drop_count_updater=61;

$secT = time();
	&get_time_now;

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
	print "allowed run time options(must stay in this order):\n  [--debug] = debug\n  [--debugX] = super debug\n  [-t] = test\n  [--loops=XXX] = force a number of loops of XXX\n  [--delay=XXX] = force a loop delay of XXX seconds\n  [--campaign=XXX] = run for campaign XXX only\n  [-force] = force calculation of suggested predictive dial_level\n  [-test] = test only, do not alter dial_level\n\n";
	}
	else
	{
		if ($args =~ /--campaign=/i) # CLI defined campaign
			{
			@CLIvarARY = split(/--campaign=/,$args);
			@CLIvarARX = split(/ /,$CLIvarARY[1]);
			if (length($CLIvarARX[0])>2)
				{
				$CLIcampaign = $CLIvarARX[0];
				$CLIcampaign =~ s/\/$| |\r|\n|\t//gi;
				}
			else
				{$CLIcampaign = '';}
			@CLIvarARY=@MT;   @CLIvarARY=@MT;
			}
		else
			{$CLIcampaign = '';}
		if ($args =~ /--level=/i) # CLI defined level
			{
			@CLIvarARY = split(/--level=/,$args);
			@CLIvarARX = split(/ /,$CLIvarARY[1]);
			if (length($CLIvarARX[0])>2)
				{
				$CLIlevel = $CLIvarARX[0];
				$CLIlevel =~ s/\/$| |\r|\n|\t//gi;
				$CLIlevel =~ s/\D//gi;
				}
			else
				{$CLIlevel = '';}
			@CLIvarARY=@MT;   @CLIvarARY=@MT;
			}
		else
			{$CLIlevel = '';}
		if ($args =~ /--loops=/i) # CLI defined loops
			{
			@CLIvarARY = split(/--loops=/,$args);
			@CLIvarARX = split(/ /,$CLIvarARY[1]);
			if (length($CLIvarARX[0])>2)
				{
				$CLIloops = $CLIvarARX[0];
				$CLIloops =~ s/\/$| |\r|\n|\t//gi;
				$CLIloops =~ s/\D//gi;
				}
			else
				{$CLIloops = '1000000';}
			@CLIvarARY=@MT;   @CLIvarARY=@MT;
			}
		else
			{$CLIloops = '1000000';}
		if ($args =~ /--delay=/i) # CLI defined delay
			{
			@CLIvarARY = split(/--delay=/,$args);
			@CLIvarARX = split(/ /,$CLIvarARY[1]);
			if (length($CLIvarARX[0])>2)
				{
				$CLIdelay = $CLIvarARX[0];
				$CLIdelay =~ s/\/$| |\r|\n|\t//gi;
				$CLIdelay =~ s/\D//gi;
				}
			else
				{$CLIdelay = '1';}
			@CLIvarARY=@MT;   @CLIvarARY=@MT;
			}
		else
			{$CLIdelay = '1';}
		if ($args =~ /--debug/i)
			{
			$DB=1;
			print "\n----- DEBUG -----\n\n";
			}
		if ($args =~ /--debugX/i)
			{
			$DBX=1;
			print "\n";
			print "----- SUPER DEBUG -----\n";
			print "VARS-\n";
			print "CLIcampaign- $CLIcampaign\n";
			print "CLIlevel-    $CLIlevel\n";
			print "CLIloops-    $CLIloops\n";
			print "CLIdelay-    $CLIdelay\n";
			print "\n";
			}
		if ($args =~ /-force/i)
			{
			$force_test=1;
			print "\n----- FORCE TESTING -----\n\n";
			}
		if ($args =~ /-t/i)
			{
			$T=1;   $TEST=1;
			print "\n-----TESTING -----\n\n";
			}
	}
}
else
{
$CLIcampaign = '';
$CLIlevel = '';
$CLIloops = '1000000';
$CLIdelay = '1';
}

# default path to astguiclient configuration file:
$PATHconf =		'/etc/astguiclient.conf';

open(conf, "$PATHconf") || die "can't open $PATHconf: $!\n";
@conf = <conf>;
close(conf);
$i=0;
foreach(@conf)
	{
	$line = $conf[$i];
	$line =~ s/ |>|\n|\r|\t|\#.*|;.*//gi;
	if ( ($line =~ /^PATHhome/) && ($CLIhome < 1) )
		{$PATHhome = $line;   $PATHhome =~ s/.*=//gi;}
	if ( ($line =~ /^PATHlogs/) && ($CLIlogs < 1) )
		{$PATHlogs = $line;   $PATHlogs =~ s/.*=//gi;}
	if ( ($line =~ /^PATHagi/) && ($CLIagi < 1) )
		{$PATHagi = $line;   $PATHagi =~ s/.*=//gi;}
	if ( ($line =~ /^PATHweb/) && ($CLIweb < 1) )
		{$PATHweb = $line;   $PATHweb =~ s/.*=//gi;}
	if ( ($line =~ /^PATHsounds/) && ($CLIsounds < 1) )
		{$PATHsounds = $line;   $PATHsounds =~ s/.*=//gi;}
	if ( ($line =~ /^PATHmonitor/) && ($CLImonitor < 1) )
		{$PATHmonitor = $line;   $PATHmonitor =~ s/.*=//gi;}
	if ( ($line =~ /^VARserver_ip/) && ($CLIserver_ip < 1) )
		{$VARserver_ip = $line;   $VARserver_ip =~ s/.*=//gi;}
	if ( ($line =~ /^VARDB_server/) && ($CLIDB_server < 1) )
		{$VARDB_server = $line;   $VARDB_server =~ s/.*=//gi;}
	if ( ($line =~ /^VARDB_database/) && ($CLIDB_database < 1) )
		{$VARDB_database = $line;   $VARDB_database =~ s/.*=//gi;}
	if ( ($line =~ /^VARDB_user/) && ($CLIDB_user < 1) )
		{$VARDB_user = $line;   $VARDB_user =~ s/.*=//gi;}
	if ( ($line =~ /^VARDB_pass/) && ($CLIDB_pass < 1) )
		{$VARDB_pass = $line;   $VARDB_pass =~ s/.*=//gi;}
	if ( ($line =~ /^VARDB_port/) && ($CLIDB_port < 1) )
		{$VARDB_port = $line;   $VARDB_port =~ s/.*=//gi;}
	$i++;
	}

if (!$VARDB_port) {$VARDB_port='3306';}

use DBI;	  

$dbhA = DBI->connect("DBI:mysql:$VARDB_database:$VARDB_server:$VARDB_port", "$VARDB_user", "$VARDB_pass")
 or die "Couldn't connect to database: " . DBI->errstr;

if ($DBX) {print "CONNECTED TO DATABASE:  $VARDB_server|$VARDB_database\n";}


#############################################
##### START QUEUEMETRICS LOGGING LOOKUP #####
$stmtA = "SELECT enable_queuemetrics_logging,queuemetrics_server_ip,queuemetrics_dbname,queuemetrics_login,queuemetrics_pass,queuemetrics_log_id FROM system_settings;";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	 @aryA = $sthA->fetchrow_array;
		$enable_queuemetrics_logging =	"$aryA[0]";
		$queuemetrics_server_ip	=		"$aryA[1]";
		$queuemetrics_dbname	=		"$aryA[2]";
		$queuemetrics_login	=			"$aryA[3]";
		$queuemetrics_pass	=			"$aryA[4]";
		$queuemetrics_log_id =			"$aryA[5]";
	 $rec_count++;
	}
$sthA->finish();

if ($enable_queuemetrics_logging > 0)
	{
	$dbhB = DBI->connect("DBI:mysql:$queuemetrics_dbname:$queuemetrics_server_ip:3306", "$queuemetrics_login", "$queuemetrics_pass")
	 or die "Couldn't connect to database: " . DBI->errstr;

	if ($DBX) {print "CONNECTED TO DATABASE:  $queuemetrics_server_ip|$queuemetrics_dbname\n";}

	$stmtB = "INSERT INTO queue_log SET partition='P01',time_id='$secT',call_id='NONE',queue='NONE',agent='NONE',verb='QUEUESTART',serverid='$queuemetrics_log_id';";
	$Baffected_rows = $dbhB->do($stmtB);

	$dbhB->disconnect();
	}
##### END QUEUEMETRICS LOGGING LOOKUP #####
###########################################


$master_loop=0;

### Start master loop ###
while ($master_loop<$CLIloops) 
{
	&get_time_now;

	### Grab Server values from the database
	$stmtA = "SELECT vd_server_logs,local_gmt FROM servers where server_ip = '$VARserver_ip';";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		 @aryA = $sthA->fetchrow_array;
			$DBvd_server_logs =			"$aryA[0]";
			$DBSERVER_GMT		=		"$aryA[1]";
			if ($DBvd_server_logs =~ /Y/)	{$SYSLOG = '1';}
				else {$SYSLOG = '0';}
			if (length($DBSERVER_GMT)>0)	{$SERVER_GMT = $DBSERVER_GMT;}
		 $rec_count++;
		}
	$sthA->finish();



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

#	if ($DB) {print "TIME DEBUG: $master_loop   $LOCAL_GMT_OFF_STD|$LOCAL_GMT_OFF|$isdst|   GMT: $hour:$min\n";}

@campaign_id=@MT; 
@lead_order=@MT;
@hopper_level=@MT;
@auto_dial_level=@MT;
@local_call_time=@MT;
@lead_filter_id=@MT;
@use_internal_dnc=@MT;
@dial_method=@MT;
@available_only_ratio_tally[$i]=@MT;
@adaptive_dropped_percentage=@MT;
@adaptive_maximum_level=@MT;
@adaptive_latest_server_time=@MT;
@adaptive_intensity=@MT;
@adaptive_dl_diff_target=@MT;
@campaign_changedate=@MT;
@campaign_stats_refresh=@MT;

if ($CLIcampaign)
	{
	$stmtA = "SELECT * from vicidial_campaigns where campaign_id='$CLIcampaign'";
	}
else
	{
	$stmtA = "SELECT campaign_id,lead_order,hopper_level,auto_dial_level,local_call_time,lead_filter_id,use_internal_dnc,dial_method,available_only_ratio_tally,adaptive_dropped_percentage,adaptive_maximum_level,adaptive_latest_server_time,adaptive_intensity,adaptive_dl_diff_target,UNIX_TIMESTAMP(campaign_changedate),campaign_stats_refresh from vicidial_campaigns where ( (active='Y') or (campaign_stats_refresh='Y') )";
	}
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$campaign_id[$rec_count] =					$aryA[0];
	$lead_order[$rec_count] =					$aryA[1];
	if (!$CLIlevel) 
		{$hopper_level[$rec_count] =			$aryA[2];}
	else
		{$hopper_level[$rec_count] =			$CLIlevel;}
	$auto_dial_level[$rec_count] =				$aryA[3];
	$local_call_time[$rec_count] =				$aryA[4];
	$lead_filter_id[$rec_count] =				$aryA[5];
	$use_internal_dnc[$rec_count] =				$aryA[6];
	$dial_method[$rec_count] =					$aryA[7];
	$available_only_ratio_tally[$i][$rec_count] =	$aryA[8];
	$adaptive_dropped_percentage[$rec_count] =	$aryA[9];
	$adaptive_maximum_level[$rec_count] =		$aryA[10];
	$adaptive_latest_server_time[$rec_count] =	$aryA[11];
	$adaptive_intensity[$rec_count] =			$aryA[12];
	$adaptive_dl_diff_target[$rec_count] =		$aryA[13];
	$campaign_changedate[$rec_count] =			$aryA[14];
	$campaign_stats_refresh[$rec_count] =		$aryA[15];

	$rec_count++;
	}
$sthA->finish();
if ($DB) {print "$now_date CAMPAIGNS TO PROCESSES ADAPT FOR:  $rec_count|$#campaign_id       IT: $master_loop\n";}


##### LOOP THROUGH EACH CAMPAIGN AND PROCESS THE HOPPER #####
$i=0;
foreach(@campaign_id)
	{
 	### Find out how many leads are in the hopper from a specific campaign
	$hopper_ready_count=0;
	$stmtA = "SELECT count(*) from vicidial_hopper where campaign_id='$campaign_id[$i]' and status='READY';";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$hopper_ready_count = $aryA[0];
		if ($DB) {print "     $campaign_id[$i] hopper READY count:   $hopper_ready_count";}
#		if ($DBX) {print "     |$stmtA|\n";}
		$rec_count++;
		}
	$sthA->finish();
	$event_string = "|$campaign_id[$i]|$hopper_level[$i]|$hopper_ready_count|$local_call_time[$i]|$diff_ratio_updater|$drop_count_updater|";
		if ($DBX) {print "$i     $event_string\n";}
	&event_logger;	

	##### IF THERE ARE NO LEADS IN THE HOPPER FOR THE CAMPAIGN WE DO NOT WANT TO ADJUST THE DIAL_LEVEL
	if ($hopper_ready_count>0)
		{
		### BEGIN - GATHER STATS FOR THE vicidial_campaign_stats TABLE ###
		$vicidial_log = 'vicidial_log FORCE INDEX (call_date) ';
	#	$vicidial_log = 'vicidial_log';
		$differential_onemin[$i]=0;
		$agents_average_onemin[$i]=0;

	#	### Grab the count of agents and lines
	#	if ($campaign_id[$i] !~ /(CLOSER|BLEND|INBND|_C$|_B$|_I$)/)
	#		{
			&count_agents_lines;
	#		}
	#	else
	#		{
	#		if ($DB) {print "     CLOSER CAMPAIGN\n";}
	#		}

		if ($total_agents_avg[$i] > 0)
			{
			### Update Drop counter every 60 seconds
			if ($drop_count_updater>=60)
				{
				&calculate_drops;
				}

			### Calculate and update Dial level every 15 seconds
			if ($diff_ratio_updater>=15)
				{
				&calculate_dial_level;
				}
			}
		else
			{
			if ($campaign_stats_refresh[$i] =~ /Y/)
				{
				if ($drop_count_updater>=60)
					{
					if ($DB) {print "     REFRESH OVERRIDE: $campaign_id[$i]\n";}

					&calculate_drops;

					$RESETdrop_count_updater++;

					$stmtA = "UPDATE vicidial_campaigns SET campaign_stats_refresh='N' where campaign_id='$campaign_id[$i]';";
					$affected_rows = $dbhA->do($stmtA);
					}
				}
			else
				{
				if ($campaign_changedate[$i] >= $VDL_ninty)
					{
					if ($drop_count_updater>=60)
						{
						if ($DB) {print "     CHANGEDATE OVERRIDE: $campaign_id[$i]\n";}

						&calculate_drops;

						$RESETdrop_count_updater++;
						}
					}
				}
			}
		}
	else
		{
		if ($campaign_stats_refresh[$i] =~ /Y/)
			{
			if ($drop_count_updater>=60)
				{
				if ($DB) {print "     REFRESH OVERRIDE: $campaign_id[$i]\n";}

				&calculate_drops;

				$RESETdrop_count_updater++;

				$stmtA = "UPDATE vicidial_campaigns SET campaign_stats_refresh='N' where campaign_id='$campaign_id[$i]';";
				$affected_rows = $dbhA->do($stmtA);
				}
			}
		else
			{
			if ($campaign_changedate[$i] >= $VDL_ninty)
				{
				if ($drop_count_updater>=60)
					{
					if ($DB) {print "     CHANGEDATE OVERRIDE: $campaign_id[$i]\n";}

					&calculate_drops;

					$RESETdrop_count_updater++;
					}
				}
			}
		}
	$i++;
	}

if ($RESETdiff_ratio_updater>0) {$RESETdiff_ratio_updater=0;   $diff_ratio_updater=0;}
if ($RESETdrop_count_updater>0) {$RESETdrop_count_updater=0;   $drop_count_updater=0;}
$diff_ratio_updater = ($diff_ratio_updater + $CLIdelay);
$drop_count_updater = ($drop_count_updater + $CLIdelay);

sleep($CLIdelay);

$stat_count++;
$master_loop++;
}

$dbhA->disconnect();

if($DB)
{
### calculate time to run script ###
$secY = time();
$secZ = ($secY - $secT);

if (!$q) {print "DONE. Script execution time in seconds: $secZ\n";}
}

exit;





### SUBROUTINES ###############################################################

sub event_logger
{
if ($SYSLOG)
	{
	if (!$VDHLOGfile) {$VDHLOGfile = "$PATHlogs/adapt.$year-$mon-$mday";}

	### open the log file for writing ###
	open(Lout, ">>$VDHLOGfile")
			|| die "Can't open $VDHLOGfile: $!\n";
	print Lout "$now_date|$event_string|\n";
	close(Lout);
	}
$event_string='';
}


sub adaptive_logger
{
if ($SYSLOG)
	{
	$VDHCLOGfile = "$PATHlogs/VDadaptive-$campaign_id[$i].$file_date";

	### open the log file for writing ###
	open(Aout, ">>$VDHCLOGfile")
			|| die "Can't open $VDHCLOGfile: $!\n";
	print Aout "$now_date$adaptive_string\n";
	close(Aout);
	}
$adaptive_string='';
}

sub get_time_now
{
$secX = time();
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = ($year + 1900);
$mon++;
if ($mon < 10) {$mon = "0$mon";}
if ($mday < 10) {$mday = "0$mday";}
if ($hour < 10) {$Fhour = "0$hour";}
if ($min < 10) {$min = "0$min";}
if ($sec < 10) {$sec = "0$sec";}
$file_date = "$year-$mon-$mday";
$now_date = "$year-$mon-$mday $hour:$min:$sec";
$VDL_date = "$year-$mon-$mday 00:00:01";
$current_hourmin = "$hour$min";

### get date-time of one hour ago ###
	$VDL_hour = ($secX - (60 * 60));
($Vsec,$Vmin,$Vhour,$Vmday,$Vmon,$Vyear,$Vwday,$Vyday,$Visdst) = localtime($VDL_hour);
$Vyear = ($Vyear + 1900);
$Vmon++;
if ($Vmon < 10) {$Vmon = "0$Vmon";}
if ($Vmday < 10) {$Vmday = "0$Vmday";}
$VDL_hour = "$Vyear-$Vmon-$Vmday $Vhour:$Vmin:$Vsec";

### get date-time of half hour ago ###
	$VDL_halfhour = ($secX - (30 * 60));
($Vsec,$Vmin,$Vhour,$Vmday,$Vmon,$Vyear,$Vwday,$Vyday,$Visdst) = localtime($VDL_halfhour);
$Vyear = ($Vyear + 1900);
$Vmon++;
if ($Vmon < 10) {$Vmon = "0$Vmon";}
if ($Vmday < 10) {$Vmday = "0$Vmday";}
$VDL_halfhour = "$Vyear-$Vmon-$Vmday $Vhour:$Vmin:$Vsec";

### get date-time of five minutes ago ###
	$VDL_five = ($secX - (5 * 60));
($Vsec,$Vmin,$Vhour,$Vmday,$Vmon,$Vyear,$Vwday,$Vyday,$Visdst) = localtime($VDL_five);
$Vyear = ($Vyear + 1900);
$Vmon++;
if ($Vmon < 10) {$Vmon = "0$Vmon";}
if ($Vmday < 10) {$Vmday = "0$Vmday";}
$VDL_five = "$Vyear-$Vmon-$Vmday $Vhour:$Vmin:$Vsec";

### get epoch of ninty seconds ago ###
	$VDL_ninty = ($secX - (1 * 90));

### get date-time of one minute ago ###
	$VDL_one = ($secX - (1 * 60));
($Vsec,$Vmin,$Vhour,$Vmday,$Vmon,$Vyear,$Vwday,$Vyday,$Visdst) = localtime($VDL_one);
$Vyear = ($Vyear + 1900);
$Vmon++;
if ($Vmon < 10) {$Vmon = "0$Vmon";}
if ($Vmday < 10) {$Vmday = "0$Vmday";}
$VDL_one = "$Vyear-$Vmon-$Vmday $Vhour:$Vmin:$Vsec";
}


sub count_agents_lines
{
### Calculate campaign-wide agent waiting and calls waiting differential
$stat_it=15;
$total_agents[$i]=0;
$ready_agents[$i]=0;
$waiting_calls[$i]=0;
$ready_diff_total[$i]=0;
$waiting_diff_total[$i]=0;
$total_agents_total[$i]=0;
$ready_diff_avg[$i]=0;
$waiting_diff_avg[$i]=0;
$total_agents_avg[$i]=0;
$stat_differential[$i]=0;

$stmtA = "SELECT count(*),status from vicidial_live_agents where campaign_id='$campaign_id[$i]' and last_update_time > '$VDL_one' group by status;";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$VCSagent_count[$i] =		 "$aryA[0]";
	$VCSagent_status[$i] =		 "$aryA[1]";
	$rec_count++;
	if ($VCSagent_status[$i] =~ /READY|DONE/) {$ready_agents[$i] = ($ready_agents[$i] + $VCSagent_count[$i]);}
	$total_agents[$i] = ($total_agents[$i] + $VCSagent_count[$i]);
	}
$sthA->finish();

$stmtA = "SELECT count(*) FROM vicidial_auto_calls where campaign_id='$campaign_id[$i]' and status IN('LIVE');";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
		$waiting_calls[$i] = "$aryA[0]";
	$rec_count++;
	}
$sthA->finish();

$stat_ready_agents[$i][$stat_count] = $ready_agents[$i];
$stat_waiting_calls[$i][$stat_count] = $waiting_calls[$i];
$stat_total_agents[$i][$stat_count] = $total_agents[$i];

if ($stat_count < 15) 
	{
	$stat_it = $stat_count;
	$stat_B = 1;
	}
else
	{
	$stat_B = ($stat_count - 14);
	}

$it=0;
while($it < $stat_it)
	{
	$it_ary = ($it + $stat_B);
	$ready_diff_total[$i] = ($ready_diff_total[$i] + $stat_ready_agents[$i][$it_ary]);
	$waiting_diff_total[$i] = ($waiting_diff_total[$i] + $stat_waiting_calls[$i][$it_ary]);
	$total_agents_total[$i] = ($total_agents_total[$i] + $stat_total_agents[$i][$it_ary]);
#		$event_string="$stat_count $it_ary   $stat_total_agents[$i][$it_ary]|$stat_ready_agents[$i][$it_ary]|$stat_waiting_calls[$i][$it_ary]";
#		if ($DB) {print "     $event_string\n";}
#		&event_logger;
	$it++;
	}

if ($ready_diff_total[$i] > 0) 
	{$ready_diff_avg[$i] = ($ready_diff_total[$i] / $stat_it);}
if ($waiting_diff_total[$i] > 0) 
	{$waiting_diff_avg[$i] = ($waiting_diff_total[$i] / $stat_it);}
if ($total_agents_total[$i] > 0) 
	{$total_agents_avg[$i] = ($total_agents_total[$i] / $stat_it);}
$stat_differential[$i] = ($ready_diff_avg[$i] - $waiting_diff_avg[$i]);

$event_string="CAMPAIGN DIFFERENTIAL: $total_agents_avg[$i]   $stat_differential[$i]   ($ready_diff_avg[$i] - $waiting_diff_avg[$i])";
if ($DBX) {print "$campaign_id[$i]|$event_string\n";}
if ($DB) {print "     $event_string\n";}

&event_logger;

#	$stmtA = "UPDATE vicidial_campaign_stats SET differential_onemin[$i]='$stat_differential[$i]', agents_average_onemin[$i]='$total_agents_avg[$i]' where campaign_id='$DBIPcampaign[$i]';";
#	$affected_rows = $dbhA->do($stmtA);
}


sub calculate_drops
{
$RESETdrop_count_updater++;
$VCScalls_today[$i]=0;
$VCSanswers_today[$i]=0;
$VCSdrops_today[$i]=0;
$VCSdrops_today_pct[$i]=0;
$VCSdrops_answers_today_pct[$i]=0;
$VCScalls_hour[$i]=0;
$VCSanswers_hour[$i]=0;
$VCSdrops_hour[$i]=0;
$VCSdrops_hour_pct[$i]=0;
$VCScalls_halfhour[$i]=0;
$VCSanswers_halfhour[$i]=0;
$VCSdrops_halfhour[$i]=0;
$VCSdrops_halfhour_pct[$i]=0;
$VCScalls_five[$i]=0;
$VCSanswers_five[$i]=0;
$VCSdrops_five[$i]=0;
$VCSdrops_five_pct[$i]=0;
$VCScalls_one[$i]=0;
$VCSanswers_one[$i]=0;
$VCSdrops_one[$i]=0;
$VCSdrops_one_pct[$i]=0;

# LAST ONE MINUTE CALL AND DROP STATS
$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_one';";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$VCScalls_one[$i] =		 "$aryA[0]";
	$rec_count++;
	}
$sthA->finish();
if ($VCScalls_one[$i] > 0)
	{
	# LAST MINUTE ANSWERS
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_one' and status NOT IN('NA','B');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSanswers_one[$i] =		 "$aryA[0]";
		$rec_count++;
		}
	$sthA->finish();
	# LAST MINUTE DROPS
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_one' and status IN('DROP','XDROP');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSdrops_one[$i] =		 "$aryA[0]";
		if ($VCSdrops_one[$i] > 0)
			{
			$VCSdrops_one_pct[$i] = ( ($VCSdrops_one[$i] / $VCScalls_one[$i]) * 100 );
			$VCSdrops_one_pct[$i] = sprintf("%.2f", $VCSdrops_one_pct[$i]);	
			}
		$rec_count++;
		}
	$sthA->finish();
	}

# TODAY CALL AND DROP STATS
$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_date';";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$VCScalls_today[$i] =		 "$aryA[0]";
	$rec_count++;
	}
$sthA->finish();
if ($VCScalls_today[$i] > 0)
	{
	# TODAY ANSWERS
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_date' and status NOT IN('NA','B');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSanswers_today[$i] =		 "$aryA[0]";
		$rec_count++;
		}
	$sthA->finish();
	# TODAY DROPS
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_date' and status IN('DROP','XDROP');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSdrops_today[$i] =		 "$aryA[0]";
		if ($VCSdrops_today[$i] > 0)
			{
			$VCSdrops_today_pct[$i] = ( ($VCSdrops_today[$i] / $VCScalls_today[$i]) * 100 );
			$VCSdrops_today_pct[$i] = sprintf("%.2f", $VCSdrops_today_pct[$i]);
			if ($VCSanswers_today[$i] < 1) {$VCSanswers_today[$i] = 1;}
			$VCSdrops_answers_today_pct[$i] = ( ($VCSdrops_today[$i] / $VCSanswers_today[$i]) * 100 );
			$VCSdrops_answers_today_pct[$i] = sprintf("%.2f", $VCSdrops_answers_today_pct[$i]);
			}
		$rec_count++;
		}
	$sthA->finish();
	}

# LAST HOUR CALL AND DROP STATS
$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_hour';";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$VCScalls_hour[$i] =		 "$aryA[0]";
	$rec_count++;
	}
$sthA->finish();
if ($VCScalls_hour[$i] > 0)
	{
	# ANSWERS LAST HOUR
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_hour' and status NOT IN('NA','B');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSanswers_hour[$i] =		 "$aryA[0]";
		$rec_count++;
		}
	$sthA->finish();
	# DROP LAST HOUR
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_hour' and status IN('DROP','XDROP');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSdrops_hour[$i] =		 "$aryA[0]";
		if ($VCSdrops_hour[$i] > 0)
			{
			$VCSdrops_hour_pct[$i] = ( ($VCSdrops_hour[$i] / $VCScalls_hour[$i]) * 100 );
			$VCSdrops_hour_pct[$i] = sprintf("%.2f", $VCSdrops_hour_pct[$i]);	
			}
		$rec_count++;
		}
	$sthA->finish();
	}

# LAST HALFHOUR CALL AND DROP STATS
$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_halfhour';";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$VCScalls_halfhour[$i] =		 "$aryA[0]";
	$rec_count++;
	}
$sthA->finish();
if ($VCScalls_halfhour[$i] > 0)
	{
	# ANSWERS HALFHOUR
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_halfhour' and status NOT IN('NA','B');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSanswers_halfhour[$i] =		 "$aryA[0]";
		$rec_count++;
		}
	$sthA->finish();
	# DROPS HALFHOUR
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_halfhour' and status IN('DROP','XDROP');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSdrops_halfhour[$i] =		 "$aryA[0]";
		if ($VCSdrops_halfhour[$i] > 0)
			{
			$VCSdrops_halfhour_pct[$i] = ( ($VCSdrops_halfhour[$i] / $VCScalls_halfhour[$i]) * 100 );
			$VCSdrops_halfhour_pct[$i] = sprintf("%.2f", $VCSdrops_halfhour_pct[$i]);	
			}
		$rec_count++;
		}
	$sthA->finish();
	}

# LAST FIVE MINUTE CALL AND DROP STATS
$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_five';";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$VCScalls_five[$i] =		 "$aryA[0]";
	$rec_count++;
	}
$sthA->finish();
if ($VCScalls_five[$i] > 0)
	{
	# ANSWERS FIVEMINUTE
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_five' and status NOT IN('NA','B');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSanswers_five[$i] =		 "$aryA[0]";
		$rec_count++;
		}
	$sthA->finish();
	# DROPS FIVEMINUTE
	$stmtA = "SELECT count(*) from $vicidial_log where campaign_id='$campaign_id[$i]' and call_date > '$VDL_five' and status IN('DROP','XDROP');";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$VCSdrops_five[$i] =		 "$aryA[0]";
		if ($VCSdrops_five[$i] > 0)
			{
			$VCSdrops_five_pct[$i] = ( ($VCSdrops_five[$i] / $VCScalls_five[$i]) * 100 );
			$VCSdrops_five_pct[$i] = sprintf("%.2f", $VCSdrops_five_pct[$i]);	
			}
		$rec_count++;
		}
	$sthA->finish();
	}
if ($DBX) {print "$campaign_id[$i]|$VCSdrops_five_pct[$i]|$VCSdrops_today_pct[$i]\n";}

$stmtA = "UPDATE vicidial_campaign_stats SET calls_today='$VCScalls_today[$i]',answers_today='$VCSanswers_today[$i]',drops_today='$VCSdrops_today[$i]',drops_today_pct='$VCSdrops_today_pct[$i]',drops_answers_today_pct='$VCSdrops_answers_today_pct[$i]',calls_hour='$VCScalls_hour[$i]',answers_hour='$VCSanswers_hour[$i]',drops_hour='$VCSdrops_hour[$i]',drops_hour_pct='$VCSdrops_hour_pct[$i]',calls_halfhour='$VCScalls_halfhour[$i]',answers_halfhour='$VCSanswers_halfhour[$i]',drops_halfhour='$VCSdrops_halfhour[$i]',drops_halfhour_pct='$VCSdrops_halfhour_pct[$i]',calls_fivemin='$VCScalls_five[$i]',answers_fivemin='$VCSanswers_five[$i]',drops_fivemin='$VCSdrops_five[$i]',drops_fivemin_pct='$VCSdrops_five_pct[$i]',calls_onemin='$VCScalls_one[$i]',answers_onemin='$VCSanswers_one[$i]',drops_onemin='$VCSdrops_one[$i]',drops_onemin_pct='$VCSdrops_one_pct[$i]' where campaign_id='$campaign_id[$i]';";
$affected_rows = $dbhA->do($stmtA);
if ($DBX) {print "$campaign_id[$i]|$stmtA|\n";}
}



sub calculate_dial_level
{
$RESETdiff_ratio_updater++;
$VCSINCALL[$i]=0;
$VCSREADY[$i]=0;
$VCSCLOSER[$i]=0;
$VCSPAUSED[$i]=0;
$VCSagents[$i]=0;
$VCSagents_calc[$i]=0;
$VCSagents_active[$i]=0;

# COUNTS OF STATUSES OF AGENTS IN THIS CAMPAIGN
$stmtA = "SELECT count(*),status from vicidial_live_agents where campaign_id='$campaign_id[$i]' and last_update_time > '$VDL_one' group by status;";
$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
$sthArows=$sthA->rows;
$rec_count=0;
while ($sthArows > $rec_count)
	{
	@aryA = $sthA->fetchrow_array;
	$VCSagent_count[$i] =		 "$aryA[0]";
	$VCSagent_status[$i] =		 "$aryA[1]";
	$rec_count++;
	if ($VCSagent_status[$i] =~ /INCALL|QUEUE/) {$VCSINCALL[$i] = ($VCSINCALL[$i] + $VCSagent_count[$i]);}
	if ($VCSagent_status[$i] =~ /READY/) {$VCSREADY[$i] = ($VCSREADY[$i] + $VCSagent_count[$i]);}
	if ($VCSagent_status[$i] =~ /CLOSER/) {$VCSCLOSER[$i] = ($VCSCLOSER[$i] + $VCSagent_count[$i]);}
	if ($VCSagent_status[$i] =~ /PAUSED/) {$VCSPAUSED[$i] = ($VCSPAUSED[$i] + $VCSagent_count[$i]);}
	$VCSagents[$i] = ($VCSagents[$i] + $VCSagent_count[$i]);
	}
$sthA->finish();

if ($available_only_ratio_tally[$i] =~ /Y/) 
	{$VCSagents_calc[$i] = $VCSREADY[$i];}
else
	{$VCSagents_calc[$i] = ($VCSINCALL[$i] + $VCSREADY[$i]);}
$VCSagents_active[$i] = ($VCSINCALL[$i] + $VCSREADY[$i] + $VCSCLOSER[$i]);

### END - GATHER STATS FOR THE vicidial_campaign_stats TABLE ###

if ($campaign_id[$i] =~ /(CLOSER|BLEND|INBND|_C$|_B$|_I$)/)
	{
	# GET AVERAGES FROM THIS CAMPAIGN
	$stmtA = "SELECT differential_onemin,agents_average_onemin from vicidial_campaign_stats where campaign_id='$campaign_id[$i]';";
	$sthA = $dbhA->prepare($stmtA) or die "preparing: ",$dbhA->errstr;
	$sthA->execute or die "executing: $stmtA ", $dbhA->errstr;
	$sthArows=$sthA->rows;
	$rec_count=0;
	while ($sthArows > $rec_count)
		{
		@aryA = $sthA->fetchrow_array;
		$differential_onemin[$i] =		 "$aryA[0]";
		$agents_average_onemin[$i] =	 "$aryA[1]";
		$rec_count++;
		}
	$sthA->finish();
	}
else
	{
	$agents_average_onemin[$i] =	$total_agents_avg[$i];  
	$differential_onemin[$i] =		$stat_differential[$i];
	}

if ( ($dial_method[$i] =~ /ADAPT_HARD_LIMIT|ADAPT_AVERAGE|ADAPT_TAPERED/) || ($force_test>0) )
	{
	# Calculate the optimal dial_level differential for the past minute
	$differential_target[$i] = ($differential_onemin[$i] + $adaptive_dl_diff_target[$i]);
	$differential_mul[$i] = ($differential_target[$i] / $agents_average_onemin[$i]);
	$differential_pct_raw[$i] = ($differential_mul[$i] * 100);
	$differential_pct[$i] = sprintf("%.2f", $differential_pct_raw[$i]);

	# Factor in the intensity setting
	$intensity_mul[$i] = ($adaptive_intensity[$i] / 100);
	if ($differential_pct_raw[$i] < 0)
		{
		$abs_intensity_mul[$i] = abs($intensity_mul[$i] - 1);
		$intensity_diff[$i] = ($differential_pct_raw[$i] * $abs_intensity_mul[$i]);
		}
	else
		{$intensity_diff[$i] = ($differential_pct_raw[$i] * ($intensity_mul[$i] + 1) );}
	$intensity_pct[$i] = sprintf("%.2f", $intensity_diff[$i]);	
	$intensity_diff_mul[$i] = ($intensity_diff[$i] / 100);

	# Suggested dial_level based on differential
	$suggested_dial_level[$i] = ($auto_dial_level[$i] * ($differential_mul[$i] + 1) );
	$suggested_dial_level[$i] = sprintf("%.3f", $suggested_dial_level[$i]);

	# Suggested dial_level based on differential with intensity setting
	$intensity_dial_level[$i] = ($auto_dial_level[$i] * ($intensity_diff_mul[$i] + 1) );
	$intensity_dial_level[$i] = sprintf("%.3f", $intensity_dial_level[$i]);

	# Calculate last timezone target for ADAPT_TAPERED
	$last_target_hour_final[$i] = $adaptive_latest_server_time[$i];
#	if ($last_target_hour_final[$i]>2400) {$last_target_hour_final[$i]=2400;}
	$tapered_hours_left[$i] = ($last_target_hour_final[$i] - $current_hourmin);
	if ($tapered_hours_left[$i] > 1000)
		{$tapered_rate[$i] = 1;}
	else
		{$tapered_rate[$i] = ($tapered_hours_left[$i] / 1000);}

	$adaptive_string  = "\n";
	$adaptive_string .= "CAMPAIGN:   $campaign_id[$i]\n";
	$adaptive_string .= "SETTINGS-\n";
	$adaptive_string .= "   DIAL LEVEL:    $auto_dial_level[$i]\n";
	$adaptive_string .= "   DIAL METHOD:   $dial_method[$i]\n";
	$adaptive_string .= "   AVAIL ONLY:    $available_only_ratio_tally[$i]\n";
	$adaptive_string .= "   DROP PERCENT:  $adaptive_dropped_percentage[$i]\n";
	$adaptive_string .= "   MAX LEVEL:     $adaptive_maximum_level[$i]\n";
	$adaptive_string .= "   SERVER TIME:   $current_hourmin\n";
	$adaptive_string .= "   LATE TARGET:   $last_target_hour_final[$i]     ($tapered_hours_left[$i] left|$tapered_rate[$i])\n";
	$adaptive_string .= "   INTENSITY:     $adaptive_intensity[$i]\n";
	$adaptive_string .= "   DLDIFF TARGET: $adaptive_dl_diff_target[$i]\n";
	$adaptive_string .= "CURRENT STATS-\n";
	$adaptive_string .= "   AVG AGENTS:      $agents_average_onemin[$i]\n";
	$adaptive_string .= "   AGENTS:          $VCSagents[$i]  ACTIVE: $VCSagents_active[$i]   CALC: $VCSagents_calc[$i]  INCALL: $VCSINCALL[$i]    READY: $VCSREADY[$i]\n";
	$adaptive_string .= "   DL DIFFERENTIAL: $differential_target[$i] = ($differential_onemin[$i] + $adaptive_dl_diff_target[$i])\n";
	$adaptive_string .= "DIAL LEVEL SUGGESTION-\n";
	$adaptive_string .= "      PERCENT DIFF: $differential_pct[$i]\n";
	$adaptive_string .= "      SUGGEST DL:   $suggested_dial_level[$i] = ($auto_dial_level[$i] * ($differential_mul[$i] + 1) )\n";
	$adaptive_string .= "      INTENSE DIFF: $intensity_pct[$i]\n";
	$adaptive_string .= "      INTENSE DL:   $intensity_dial_level[$i] = ($auto_dial_level[$i] * ($intensity_diff_mul[$i] + 1) )\n";
	if ($intensity_dial_level[$i] > $adaptive_maximum_level[$i])
		{
		$adaptive_string .= "      DIAL LEVEL OVER CAP! SETTING TO CAP: $adaptive_maximum_level[$i]\n";
		$intensity_dial_level[$i] = $adaptive_maximum_level[$i];
		}
	if ($intensity_dial_level[$i] < 1)
		{
		$adaptive_string .= "      DIAL LEVEL TOO LOW! SETTING TO 1\n";
		$intensity_dial_level[$i] = "1.0";
		}
	$adaptive_string .= "DROP STATS-\n";
	$adaptive_string .= "   TODAY DROPS:     $VCScalls_today[$i]   $VCSdrops_today[$i]   $VCSdrops_today_pct[$i]%\n";
	$adaptive_string .= "     ANSWER DROPS:     $VCSanswers_today[$i]   $VCSdrops_answers_today_pct[$i]%\n";
	$adaptive_string .= "   ONE HOUR DROPS:  $VCScalls_hour[$i]/$VCSanswers_hour[$i]   $VCSdrops_hour[$i]   $VCSdrops_hour_pct[$i]%\n";
	$adaptive_string .= "   HALF HOUR DROPS: $VCScalls_halfhour[$i]/$VCSanswers_halfhour[$i]   $VCSdrops_halfhour[$i]   $VCSdrops_halfhour_pct[$i]%\n";
	$adaptive_string .= "   FIVE MIN DROPS:  $VCScalls_five[$i]/$VCSanswers_five[$i]   $VCSdrops_five[$i]   $VCSdrops_five_pct[$i]%\n";
	$adaptive_string .= "   ONE MIN DROPS:   $VCScalls_one[$i]/$VCSanswers_one[$i]   $VCSdrops_one[$i]   $VCSdrops_one_pct[$i]%\n";

	### DROP PERCENTAGE RULES TO LOWER DIAL_LEVEL ###
	if ( ($VCScalls_one[$i] > 20) && ($VCSdrops_one_pct[$i] > 50) )
		{
		$intensity_dial_level[$i] = ($intensity_dial_level[$i] / 2);
		$adaptive_string .= "      DROP RATE OVER 50% FOR LAST MINUTE! CUTTING DIAL LEVEL TO: $intensity_dial_level[$i]\n";
		}
	if ( ($VCScalls_today[$i] > 50) && ($VCSdrops_answers_today_pct[$i] > $adaptive_dropped_percentage[$i]) )
		{
		if ($dial_method[$i] =~ /ADAPT_HARD_LIMIT/) 
			{
			$intensity_dial_level[$i] = "1.0";
			$adaptive_string .= "      DROP RATE OVER HARD LIMIT FOR TODAY! HARD DIAL LEVEL TO: 1.0\n";
			}
		if ($dial_method[$i] =~ /ADAPT_AVERAGE/) 
			{
			$intensity_dial_level[$i] = ($intensity_dial_level[$i] / 2);
			$adaptive_string .= "      DROP RATE OVER LIMIT FOR TODAY! AVERAGING DIAL LEVEL TO: $intensity_dial_level[$i]\n";
			}
		if ($dial_method[$i] =~ /ADAPT_TAPERED/) 
			{
			if ($tapered_hours_left[$i] < 0) 
				{
				$intensity_dial_level[$i] = "1.0";
				$adaptive_string .= "      DROP RATE OVER LAST HOUR LIMIT FOR TODAY! TAPERING DIAL LEVEL TO: 1.0\n";
				}
			else
				{
				$intensity_dial_level[$i] = ($intensity_dial_level[$i] * $tapered_rate[$i]);
				$adaptive_string .= "      DROP RATE OVER LIMIT FOR TODAY! TAPERING DIAL LEVEL TO: $intensity_dial_level[$i]\n";
				}
			}
		}

	### ALWAYS RAISE DIAL_LEVEL TO 1.0 IF IT IS LOWER ###
	if ($intensity_dial_level[$i] < 1)
		{
		$adaptive_string .= "      DIAL LEVEL TOO LOW! SETTING TO 1\n";
		$intensity_dial_level[$i] = "1.0";
		}

	if (!$TEST)
		{
		$stmtA = "UPDATE vicidial_campaigns SET auto_dial_level='$intensity_dial_level[$i]' where campaign_id='$campaign_id[$i]';";
		$Uaffected_rows = $dbhA->do($stmtA);
		}

	$adaptive_string .= "DIAL LEVEL UPDATED TO: $intensity_dial_level[$i]          CONFIRM: $Uaffected_rows\n";
	}

if ($DB) {print "campaign stats updated:  $campaign_id[$i]   $adaptive_string\n";}

	&adaptive_logger;
}
