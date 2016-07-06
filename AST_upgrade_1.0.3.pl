#!/usr/bin/perl
#
# AST_upgrade_from_1.0.2.pl version 0.1
#
# DESCRIPTION:
# ONLY RUN THIS SCRIPT ONCE!!!!!!!!!
# ONLY RUN THIS SCRIPT AFTER RUNNING THE SQL UPDATER!!!!!!!!!!!!!!!
#
# This script will populate the called_count variable in the vicidial_list table
# by doing a lookup of the number of calls placed to each lead based upon the vicidial_log records.
#
# Distributed with no waranty under the GNU Public License
#

$secX = time();
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = ($year + 1900);
	$yy = $year; $yy =~ s/^..//gi;
	$mon++;
	if ($mon < 10) {$mon = "0$mon";}
	if ($mday < 10) {$mday = "0$mday";}
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}
	if ($sec < 10) {$sec = "0$sec";}
$SQLdate_NOW="$year-$mon-$mday $hour:$min:$sec";

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
	print "allowed run time options:\n  [-q] = quiet\n  [-t] = test\n  [--debug] = debugging messages\n\n";
	}
	else
	{
		if ($args =~ /-q/i)
		{
		$q=1;   $Q=1;
		}
		if ($args =~ /--debug/i)
		{
		$DB=1;
		print "\n-----DEBUGGING -----\n\n";
		}
		if ($args =~ /-t|--test/i)
		{
		$T=1; $TEST=1;
		print "\n-----TESTING -----\n\n";
		}
	}
}
else
{
print "no command line options set\n";
}
### end parsing run-time options ###


if ( (!$Q) && ($T) )	{print "---------- TEST  ----------\n\n";}
if ( (!$Q) && ($DB) )	{print "---------- DEBUG ----------\n\n";}
if ( (!$Q) && ($DB) )	{print "START DATETIME:            $SQLdate_NOW\n\n";}

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

#override the config file values DEV testing use only
#$DB_database = 'asterisk_test';

use Net::MySQL;
	  
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

	my $dbhB = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";


	$stmtA = "update vicidial_list set called_count=0;";
		if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA);
		if (!$Q) {print " - vicidial_list called_count set to zero for all records\n";}

	$stmtA = "optimize table vicidial_list;";
		if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA);
		if (!$Q) {print " - vicidial_list table optimized\n";}

	$stmtA = "optimize table vicidial_log;";
		if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA);
		if (!$Q) {print " - vicidial_log table optimized\n";}


	$stmtA = "select lead_id from vicidial_list order by lead_id;";
		if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA);
		if ($dbhA->has_selected_record)
		{
		$iterA=$dbhA->create_record_iterator;
		 $rec_countY=0;
		   while ($recordA = $iterA->each)
			{
			$lead_id = "$recordA->[0]";
			$lead_id_count = '0';

			$stmtB = "select count(*) from vicidial_log where lead_id='$lead_id';";
				if($DB){print STDERR "\n|$stmtB|\n";}
				$dbhB->query($stmtB);
				if ($dbhB->has_selected_record)
				{
				$iterB=$dbhB->create_record_iterator;
				   while ($recordB = $iterB->each)
					{
					$lead_id_count = "$recordB->[0]";
					if($DB){print STDERR "\n|$lead_id|\n";}
					} 
				}

			if ($lead_id_count > 0)
				{
				$stmtB = "update vicidial_list set called_count='$lead_id_count' where lead_id='$lead_id';";
					if($DB){print STDERR "\n|$stmtB|\n";}
					if (!$T) {$dbhB->query($stmtB);}
				}

			if($DB){print STDERR "|$lead_id|$lead_id_count|\n";}

			$rec_countY++;
			if ($rec_countY =~ /0$/i) {print ".";}
			if ($rec_countY =~ /00$/i) {print "$rec_countY\n";}

			} 
		}

	if (!$Q) {print " - called_count upgrade finished          \n";}


	$dbhA->close;
	$dbhB->close;

$secX = time();
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = ($year + 1900);
	$yy = $year; $yy =~ s/^..//gi;
	$mon++;
	if ($mon < 10) {$mon = "0$mon";}
	if ($mday < 10) {$mday = "0$mday";}
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}
	if ($sec < 10) {$sec = "0$sec";}
$SQLdate_NOW="$year-$mon-$mday $hour:$min:$sec";

if ( (!$Q) && ($DB) )	{print "DONE DATETIME:             $SQLdate_NOW\n\n";}

exit;






