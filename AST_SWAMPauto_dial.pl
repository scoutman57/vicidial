#!/usr/bin/perl
#
# AST_SWAMPauto_dial.pl version 0.1
#
# DESCRIPTION:
# uses Net::MySQL to place auto_dial calls on the VICIDIAL dialer system
#
# SUMMARY:
# This program was designed for calling back 800 numbers found in spam email
# blasts to give them a taste of what they are doing to us. It places a set 
# number of calls using a specific spoofed callerid for a set time period
#
# Distributed with no waranty under the GNU Public License
#
# changes:
# 50708-1533 - First version
# 

$SWAMPLOGfile = '/home/cron/SWAMP_LOG.txt';

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
	print "allowed run time options:\n  [-t] = test\n  [-debug] = verbose debug messages\n  [--delay=XXX] = delay of XXX seconds per loop, default 2.5 seconds\n\n";
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
		$loop_delay = '2500';
		}
		if ($args =~ /-debug/i)
		{
		$DB=1; # Debug flag, set to 0 for no debug messages, On an active system this will generate hundreds of lines of output per minute
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
	$DB=1;
}
### end parsing run-time options ###

$dialstring_800_number = '8886764491';	# SPAM seminar spam to call 888 number
$dialstring_800_number = '8007596446';	# SPAM seminar spam to call 800 number
$dialstring_800_number = '8006743148';	# SPAM seminar spam to call 800 number
$dialstring_800_number = '8887013877';	# SPAM seminar spam to call 800 number


# constants
$US='_';
$loop_delay = '65500';
$meetme='8600021';
$it='0';
$total_loops='5000';
$dialstring_800_prefix = '81';
$dialstring_800_number = '8887013877';
$dialstring = "$dialstring_800_prefix$dialstring_800_number";
$MT[0]='';
$RECcount=''; ### leave blank for no REC count
$RECprefix='7'; ### leave blank for no REC prefix

#	$CIDlist[0] = '8504143300';	# Florida
#	$CIDlist[1] = '6512963353';	# Minnesota
#	$CIDlist[2] = '9163223360';	# California
#	$CIDlist[3] = '2253266705';	# Louisiana
#	$CIDlist[4] = '4046563300';	# Georgia
#	$CIDlist[5] = '3342427300';	# Alabama
#	$CIDlist[6] = '6013593680';	# Mississippi
#	$CIDlist[7] = '6157411671';	# Tennessee
#	$CIDlist[8] = '5026965300';	# Kentucky
	$CIDlist[0] = '3125556666';	# chicago XXX
	$CIDlist[1] = '2125556666';	# newyork xxx



	
### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

	&get_time_now;	# update time/date variables

	$event_string='PROGRAM STARTED||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||';
	&event_logger;	# writes to the log and if debug flag is set prints to STDOUT

use lib './lib', '../lib';
use Time::HiRes ('gettimeofday','usleep','sleep');  # necessary to have perl sleep command of less than one second
use Net::MySQL;
	
### connect to MySQL database defined in the AST_SERVER_conf.pl file
my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
or 	die "Couldn't connect to database: $DB_server - $DB_database\n";


$event_string='LOGGED INTO MYSQL SERVER ON 1 CONNECTION|';
&event_logger;

$total=0;
$list_it=0;
$list_inc=0;
while($it < $total_loops)
	{
	&get_time_now;	# update time/date variables

	$CIDtemp = ($CIDlist[$list_it] + $list_inc);
	
	$k=0;
	while ($k < 3)
		{
		$stmtA = "INSERT INTO vicidial_manager values('','','$SQLdate','NEW','N','$server_ip','','Originate','TESTCIDX$CIDdate$US$it','Channel: Local/$meetme@demo','Context; demo','Exten: $dialstring','Priority: 1','Callerid: \"Georgia Aty Gen\" <$CIDtemp>','','','','','');";
	   $dbhA->query("$stmtA");
		my $affected_rows = $dbhA->get_affected_rows_length;
		$k++;
		$total++;

		$event_string="CALL: $total TO: $dialstring   CID: $CIDtemp   it: $it   list_it: $list_it   list_inc: $list_inc";
		print "$event_string\n";
		&event_logger;

		}
	### sleep before beginning the loop again
	usleep(1*$loop_delay*1000);

	$it++;
	$list_it++;
	if ($list_it > $#CIDlist) {$list_it=0;  $list_inc++;}
	}

exit;













sub get_time_now	#get the current date and time and epoch for logging call lengths and datetimes
{
	$secX = time();
$secX = time();

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
$file_date = "$year-$mon-$mday";
	$CIDdate = "$mon$mday$hour$min$sec";
	$tsSQLdate = "$year$mon$mday$hour$min$sec";
	$SQLdate = "$year-$mon-$mday $hour:$min:$sec";

}





sub event_logger
{

#if ($DB) {print "$now_date|$event_string|\n";}
	### open the log file for writing ###
	open(Lout, ">>$SWAMPLOGfile")
			|| die "Can't open $SWAMPLOGfile: $!\n";

	print Lout "$now_date|$event_string|\n";

	close(Lout);

$event_string='';
}
