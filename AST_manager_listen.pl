#!/usr/bin/perl
#
# AST_manager_listen.pl version 0.1
#
# Part of the Asterisk Central Queue System (ACQS)
#
# DESCRIPTION:
# connects to the Asterisk Manager interface and updates records in the 
# vicidial_manager table of the asterisk database in MySQL based upon the 
# events that it receives
# 
# SUMMARY:
# This program was designed as the listen-only part of the ACQS. It's job is to
# look for certain events and based upon either the uniqueid or the callerid of 
# the call update the status and information of an action record in the 
# vicidial_manager table of the asterisk MySQL database.
# 
# Win32 - ActiveState Perl 5.8.0
# UNIX - Gnome or KDE with Tk/Tcl and perl Tk/Tcl modules loaded
# Both - Net::MySQL, Net::Telnet and Time::HiRes perl modules loaded
#
# For the client program to work in ACQS mode, this program must be running
# 
# For this program to work you need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# In your Asterisk server setup you also need to have several things activated
# and defined. See the CONF_Asterisk.txt file for details
#
# Distributed with no waranty under the GNU Public License
#

# constants
$DB=1;  # Debug flag, set to 0 for no debug messages, On an active system this will generate thousands of lines of output per minute
$US='__';
$MT[0]='';



### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file


	&get_time_now;

	$event_string='PROGRAM STARTED||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||';
	&event_logger;

#use lib './lib', '../lib';
use Time::HiRes ('gettimeofday','usleep','sleep');  # necessary to have perl sleep command of less than one second
use Net::MySQL;
use Net::Telnet ();
	  
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

	$event_string='LOGGED INTO MYSQL SERVER ON 1 CONNECTION|';
	&event_logger;

$one_day_interval = 90;		# 1 day loops for 3 months
while($one_day_interval > 0)
{

		$event_string="STARTING NEW TELNET CONNECTION|ATTEMPT|ONE DAY INTERVAL:$one_day_interval|";
	&event_logger;
#   Errmode    => Return,

	### connect to asterisk manager through telnet
	$tn = new Net::Telnet (Port => 5038,
						  Prompt => '/.*[\$%#>] $/',
						  Output_record_separator => '',);
	#$fh = $tn->dump_log("$LItelnetlog");  # uncomment for telnet log
	$tn->open("$telnet_host"); 
	$tn->waitfor('/0\n$/');			# print login
	$tn->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
	$tn->waitfor('/Authentication accepted/');		# waitfor auth accepted

			$tn->buffer_empty;

		$event_string="STARTING NEW TELNET CONNECTION|CONFIRMED CONNECTION|ONE DAY INTERVAL:$one_day_interval|";
	&event_logger;

	$endless_loop=864000;		# 1 day at .10 seconds per loop

	while($endless_loop > 0)
	{
		### sleep for 10 hundredths of a second
		usleep(1*100*1000);


		$read_input_buf = $tn->get(Errmode    => Return, Timeout    => 1,);
		$input_buf_length = length($input_buf);

		if ($read_input_buf !~ /\n\n/)
			{
			$input_buf = "$input_buf$read_input_buf";
			}
		else
			{
			$input_buf = "$input_buf$read_input_buf";
			@input_lines = split(/\n\n/, $input_buf);

			if($DB){print "input buffer: $input_buf_length     lines: $#input_lines\n";}
			if($DB){print "|$input_buf|\n";}
			
			$manager_string = "$input_buf";
				&manager_output_logger;

			$input_buf = '';
			

			@command_line=@MT;
			$ILcount=0;
			foreach(@input_lines)
				{
				if ($input_lines[$ILcount] =~ /State: Ringing|State: Up|State: Dialing|Event: Hangup/)
					{
					$input_lines[$ILcount] =~ s/^\n|^\n\n//gi;
					@command_line=split(/\n/, $input_lines[$ILcount]);
					if ($input_lines[$ILcount] =~ /Event: Hangup/)
						{
						$channel = $command_line[1];
						$channel =~ s/Channel: |\s*$//gi;
						$uniqueid = $command_line[2];
						$uniqueid =~ s/Uniqueid: |\s*$//gi;
						$stmtA = "UPDATE vicidial_manager set status='DEAD', channel='$channel' where server_ip = '$server_ip' and uniqueid = '$uniqueid'";

						print STDERR "|$stmtA|\n";
					   $dbhA->query("$stmtA");
						my $affected_rows = $dbhA->get_affected_rows_length;
						if($DB){print "|$affected_rows HANGUPS updated|\n";}
						}
		
					if ($input_lines[$ILcount] =~ /State: Dialing/)
						{
						$channel = $command_line[1];
						$channel =~ s/Channel: |\s*$//gi;
						$callid = $command_line[3];
						$callid =~ s/Callerid: |\s*$//gi;
						$uniqueid = $command_line[4];
						$uniqueid =~ s/Uniqueid: |\s*$//gi;
						$stmtA = "UPDATE vicidial_manager set status='SENT', channel='$channel', uniqueid = '$uniqueid' where server_ip = '$server_ip' and callerid = '$callid'";

						print STDERR "|$stmtA|\n";
					   $dbhA->query("$stmtA");
						my $affected_rows = $dbhA->get_affected_rows_length;
						if($DB){print "|$affected_rows DIALINGs updated|\n";}
						}
					if ($input_lines[$ILcount] =~ /State: Ringing|State: Up/)
						{
						$channel = $command_line[1];
						$channel =~ s/Channel: |\s*$//gi;
						$callid = $command_line[3];
						$callid =~ s/Callerid: |\s*$//gi;
						$uniqueid = $command_line[4];
						$uniqueid =~ s/Uniqueid: |\s*$//gi;
						$stmtA = "UPDATE vicidial_manager set status='UPDATED', channel='$channel', uniqueid = '$uniqueid' where server_ip = '$server_ip' and callerid = '$callid'";

						print STDERR "|$stmtA|\n";
					   $dbhA->query("$stmtA");
						my $affected_rows = $dbhA->get_affected_rows_length;
						if($DB){print "|$affected_rows RINGINGs updated|\n";}
						}
		
					}
				$ILcount++;
				}

			}


	$endless_loop--;
	$keepalive_count_loop++;
		if($DB){print STDERR "loop counter: |$endless_loop|$keepalive_count_loop|\r";}

		### putting a blank file called "sendmgr.kill" in a directory will automatically safely kill this program
		if ( (-e '/home/cron/listenmgr.kill') or ($sendonlyone) )
			{
			unlink('/home/cron/listenmgr.kill');
			$endless_loop=0;
			$one_day_interval=0;
			print "\nPROCESS KILLED MANUALLY... EXITING\n\n"
			}

		if ($endless_loop =~ /00$/)
			{
				&get_time_now;

			@list_lines = $tn->cmd(String => "Action: Command\nCommand: show uptime\n\n", Prompt => '/--END COMMAND--.*/'); 
			if($DB){print "input lines: $#list_lines\n";}

			if($DB){print "+++++++++++++++++++++++++++++++sending keepalive transmit line $endless_loop|$now_date|\n";}
			$keepalive_count_loop=0;
			}


	}


		if($DB){print "DONE... Exiting... Goodbye... See you later... Not really, initiating next loop...$one_day_interval left\n";}

		$event_string='HANGING UP|';
		&event_logger;

		@hangup = $tn->cmd(String => "Action: Logoff\n\n", Prompt => "/.*/"); 

		$ok = $tn->close;

	$one_day_interval--;

}

		$event_string='CLOSING DB CONNECTION|';
		&event_logger;


	$dbhA->close;


	if($DB){print "DONE... Exiting... Goodbye... See you later... Really I mean it this time\n";}


exit;







sub get_time_now	#get the current date and time and epoch for logging call lengths and datetimes
{
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
$action_log_date = "$year-$mon-$mday";
}





sub event_logger {
	### open the log file for writing ###
	open(Lout, ">>$LILOGfile")
			|| die "Can't open $LILOGfile: $!\n";

	print Lout "$now_date|$event_string|\n";

	close(Lout);

$event_string='';
}




sub manager_output_logger
{
open(MOout, ">>/home/cron/listen.$action_log_date")
			|| die "Can't open /home/cron/listen.$action_log_date: $!\n";

	print MOout "$now_date|$manager_string|\n";

	close(MOout);
}
