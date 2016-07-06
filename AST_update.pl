#!/usr/bin/perl
#
# AST_update.pl version 0.5
#
# DESCRIPTION:
# uses the Asterisk Manager interface and Net::MySQL to update the live_channels
# table and verify the parked_channels table in the asterisk MySQL database 
# This "near-live-status of Zap/SIP/Local channels" list is used by client apps
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with Digium
# Zaptel T1 cards and SIP VOIP hardphones or softphones as extensions, it
# could be adapted to other functions, but I designed it specifically for 
# Zap/SIP users. The program will run on UNIX or Win32 command line providing
# the following criteria are met:
# 
# Win32 - ActiveState Perl 5.8.0
# UNIX - Gnome or KDE with Tk/Tcl and perl Tk/Tcl modules loaded
# Both - Net::MySQL, Net::Telnet and Time::HiRes perl modules loaded
#
# For the client program to work, this program must always be running
# 
# For this program to work you need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# In your Asterisk server setup you also need to have several things activated
# and defined. See the CONF_Asterisk.txt file for details
#
# It is recommended that you run this program on the local Asterisk machine
#
# Distributed with no waranty under the GNU Public License
#

# constants
$DB=0;  # Debug flag, set to 0 for no debug messages, On an active system this will generate thousands of lines of output per minute
$US='__';
$MT[0]='';

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

	&get_time_now;

	$event_string='PROGRAM STARTED||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||';
	&event_logger;

use lib './lib', '../lib';
use Time::HiRes ('gettimeofday','usleep','sleep');  # necessary to have perl sleep command of less than one second
use Net::MySQL;
use Net::Telnet ();
	  
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

	$event_string='LOGGED INTO MYSQL SERVER ON 1 CONNECTION|';
	&event_logger;

$one_day_interval = 12;		# 1 month loops for one year
while($one_day_interval > 0)
{

		$event_string="STARTING NEW TELNET CONNECTION|ATTEMPT|ONE DAY INTERVAL:$one_day_interval|";
	&event_logger;

	### connect to asterisk manager through telnet
	$t = new Net::Telnet (Port => 5038,
						  Prompt => '/.*[\$%#>] $/',
						  Output_record_separator => '',);
	#$fh = $t->dump_log("$telnetlog");  # uncomment for telnet log
	$t->open("$telnet_host"); 
	$t->waitfor('/0\n$/');			# print login
	$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
	$t->waitfor('/Authentication accepted/');		# waitfor auth accepted

		$event_string="STARTING NEW TELNET CONNECTION|CONFIRMED CONNECTION|ONE DAY INTERVAL:$one_day_interval|";
	&event_logger;

	$endless_loop=5760000;		# 30 days minutes at .45 seconds per loop

	while($endless_loop > 0)
	{


		@DBchannels=@MT;

			&get_current_channels;

			&validate_parked_channels;

	$t->buffer_empty;
	@list_channels = $t->cmd(String => "Action: Command\nCommand: show channels\n\n", Prompt => '/--END COMMAND--.*/'); 

	if ( ($list_channels[1] =~ /State Appl\./) or  ($list_channels[2] =~ /State Appl\./) or  ($list_channels[3] =~ /State Appl\./) )
		{

		$c=0;
			if($DB){print "lines: $#list_channels\n";}
			if($DB){print "DBchn: $#DBchannels\n";}
			if($DB){print "DBsip: $#DBsips\n";}
		foreach(@list_channels)
			{
			#	$DBchannels =~ s/^\|//g;

				chomp($list_channels[$c]);
					if($DB){print "-|$list_channels[$c]|\n";}
				$list_channels[$c] =~ s/Congestion\s+\(Empty\)/ SIP\/CONGEST/gi;
				$list_channels[$c] =~ s/\(Outgoing Line\)|\(None\)/SIP\/ring/gi;
				$list_channels[$c] =~ s/\(Empty\)/SIP\/internal/gi;
				$list_channels[$c] =~ s/^\s*|\s*$//gi;
				$list_channels[$c] =~ s/\(.*\)//gi;
				$list_SIP[$c] = $list_channels[$c];
					if($DB){print "+|$list_channels[$c]|\n\n";}
				if ($list_channels[$c] =~ /^Zap/)
					{
						if($DB){print "current channels: $#DBchannels\n";}
					if ($list_channels[$c] =~ /^(\S+)\s+.+\s+(\S+)$/)
						{
						$channel = $1;
						$extension = $2;
						$extension =~ s/^SIP\/|-\S+$//gi;
						$extension =~ s/\|.*//gi;
						}
					$QRYchannel = "$channel$US$extension";
						if($DB){print "channel:   |$channel|\n";}
						if($DB){print "extension: |$extension|\n";}
						if($DB){print "QRYchannel:|$QRYchannel|\n";}

						$k=0;
						$channel_in_DB=0;
					foreach(@DBchannels)
						{
						if ( ($DBchannels[$k] eq "$QRYchannel") && (!$channel_in_DB) )
							{
							$DBchannels[$k] = '';
							$channel_in_DB++;
							}
						if($DB){print "DB $k|$DBchannels[$k]|     |";}
						$k++;
						}

					if ( (!$channel_in_DB) && (length($QRYchannel)>3) )
						{
						$stmtA = "INSERT INTO live_channels (channel,server_ip,extension) values('$channel','$server_ip','$extension')";
							if($DB){print STDERR "\n|$stmtA|\n";}
						$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
						}
					}
				if ($list_SIP[$c] =~ /^SIP|^Local/)
					{
						if($DB){print "current sips: $#DBsips\n";}
					if ($list_channels[$c] =~ /^(\S+)\s+.+\s+(\S+)$/)
						{
						$sipchan = $1;
						$sipexten = $2;
						$sipexten =~ s/^SIP\/|-\S+$//gi;
						$sipexten =~ s/\|.*//gi;
						}
					$QRYchannel = "$sipchan$US$sipexten";
						if($DB){print "channel:   |$sipchan|\n";}
						if($DB){print "extension: |$sipexten|\n";}
						if($DB){print "QRYchannel:|$QRYchannel|\n";}

						$k=0;
						$sipchan_in_DB=0;
					foreach(@DBsips)
						{
						if ( ($DBsips[$k] eq "$QRYchannel") && (!$sipchan_in_DB) )
							{
							$DBsips[$k] = '';
							$sipchan_in_DB++;
							}
						if($DB){print "DB $k|$DBsips[$k]|     |";}
						$k++;
						}

					if ( (!$sipchan_in_DB) && (length($QRYchannel)>3) )
						{
						$stmtA = "INSERT INTO live_sip_channels (channel,server_ip,extension) values('$sipchan','$server_ip','$sipexten')";
							if($DB){print STDERR "\n|$stmtA|\n";}
						$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
						}
					}

			$c++;
			}

			if ($#DBchannels >= 0)
				{
					$d=0;
				foreach(@DBchannels)
					{
					if (length($DBchannels[$d])>4)
						{
							($DELchannel, $DELextension) = split(/\_\_/, $DBchannels[$d]);
							$stmtB = "DELETE FROM live_channels where server_ip='$server_ip' and channel='$DELchannel' and extension='$DELextension' limit 1";
								if($DB){print STDERR "\n|$stmtB|\n";}
							$dbhA->query($stmtB);
				#			$dbhA->query($stmtB)  or die  "Couldn't execute query:\n";
						}
					$d++;
					}
				}

			if ($#DBsips >= 0)
				{
					$d=0;
				foreach(@DBsips)
					{
					if (length($DBsips[$d])>4)
						{
							($DELchannel, $DELextension) = split(/\_\_/, $DBsips[$d]);
							$stmtB = "DELETE FROM live_sip_channels where server_ip='$server_ip' and channel='$DELchannel' and extension='$DELextension' limit 1";
								if($DB){print STDERR "\n|$stmtB|\n";}
							$dbhA->query($stmtB);
				#			$dbhA->query($stmtB)  or die  "Couldn't execute query:\n";
						}
					$d++;
					}
				}

		### sleep for 45 hundredths of a second
		usleep(1*450*1000);

	$endless_loop--;
		if($DB){print STDERR "\nloop counter: |$endless_loop|\n";}

		### putting a blank file called "update.kill" in a directory will automatically safely kill this program
		if (-e '/home/cron/update.kill')
			{
			unlink('/home/cron/update.kill');
			$endless_loop=0;
			$one_day_interval=0;
			print "\nPROCESS KILLED MANUALLY... EXITING\n\n"
			}

		$bad_grabber_counter=0;

		}

	else
		{
		$bad_grabber_counter++;
		if($DB){print STDERR "\nbad grab, trying again\n";}
		### sleep for 20 hundredths of a second
		usleep(1*200*1000);

			$event_string="BAD GRAB TRYING AGAIN|BAD_GRABS: $bad_grabber_counter|$endless_loop|ONE DAY INTERVAL:$one_day_interval|";
		&event_logger;

		if ($bad_grabber_counter > 100)
			{
			$endless_loop=0;
				$event_string="TOO MANY BAD GRABS, STARTING NEW CONNECTION|BAD_GRABS: $bad_grabber_counter|$endless_loop|ONE DAY INTERVAL:$one_day_interval|";
			&event_logger;
			$bad_grabber_counter=0;
			}

		}


	}


		if($DB){print "DONE... Exiting... Goodbye... See you later... Not really, initiating next loop...\n";}

		$event_string='HANGING UP|';
		&event_logger;

		@hangup = $t->cmd(String => "Action: Logoff\n\n", Prompt => "/.*/"); 

		$ok = $t->close;

	$one_day_interval--;

}

		$event_string='CLOSING DB CONNECTION|';
		&event_logger;


	$dbhA->close;


	if($DB){print "DONE... Exiting... Goodbye... See you later... Really I mean it this time\n";}


exit;







#######################################################################
# This subroutine simply grabs all active channel/extension combinations from
# the asterisk MySQL database to be compared to the Asterisk Manager results
#######################################################################
sub get_current_channels
{
$channel_counter=0;
$sip_counter=0;

	if($DB){print STDERR "\n|SELECT channel,extension FROM live_channels where server_ip = '$server_ip'|\n";}

$dbhA->query("SELECT channel,extension FROM live_channels where server_ip = '$server_ip'");
if ($dbhA->has_selected_record)
   {
	$iter=$dbhA->create_record_iterator;
	$rec_count=0;
	while ( $record = $iter->each)
		{
		if($DB){print STDERR $record->[0],"|", $record->[1],"\n";}
			$DBchannels[$channel_counter] = "$record->[0]$US$record->[1]";

		$channel_counter++;
		$rec_count++;
		}
   }

$dbhA->query("SELECT channel,extension FROM live_sip_channels where server_ip = '$server_ip'");
if ($dbhA->has_selected_record)
   {
	$iter=$dbhA->create_record_iterator;
	$rec_count_sip=0;
	while ( $record = $iter->each)
		{
		if($DB){print STDERR $record->[0],"|", $record->[1],"\n";}
			$DBsips[$sip_counter] = "$record->[0]$US$record->[1]";

		$sip_counter++;
		$rec_count_sip++;
		}
   }

	&get_time_now;

$stmtU = "UPDATE server_updater set last_update='$now_date' where server_ip='$server_ip'";
	if($DB){print STDERR "\n|$stmtU|\n";}
$dbhA->query($stmtU);

}





#######################################################################
# The purpose of this subroutine is to make sure that the calls that are 
# listed as parked in the parked_channels table are in fact live (to make 
# sure the caller has not hung up) and if the channel is not live to delete 
# the parked_channels entry for that specific parked channel entry
# 
# Yes it does use two DB connections all by itself, I just did that for speed
# and ease of programming to be backward compatible with MySQL < 4.1 or else
# I would have used a delete with subselect and saved all of this bloated code
#######################################################################
sub validate_parked_channels
{

if (!$run_validate_parked_channels_now) 
	{

	$parked_counter=0;

	$dbhA->query("SELECT channel,extension FROM parked_channels where server_ip = '$server_ip' order by channel desc");
	if ($dbhA->has_selected_record)
	   {
		$iter=$dbhA->create_record_iterator;
		$rec_count=0;
		while ( $record = $iter->each)
		   {
			$PQchannel = $record->[0];
			$PQextension = $record->[1];
				if($DB){print STDERR "\n|$PQchannel|$PQextension|\n";}

			my $dbhB = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
			or 	die "Couldn't connect to database: \n";
			my $dbhC = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
			or 	die "Couldn't connect to database: \n";

			$event_string='LOGGED INTO MYSQL SERVER ON 2 CONNECTIONS TO VALIDATE PARKED CALLS|';
			&event_logger;


		   $dbhB->query("SELECT count(*) FROM live_channels where server_ip='$server_ip' and channel='$PQchannel' and extension='$PQextension'");
		   if ($dbhB->has_selected_record)
			   {
				$iterB=$dbhB->create_record_iterator;
				$rec_countB=0;
				while ( $recordB = $iterB->each)
				   {
					$PQcount = $recordB->[0];
						if($DB){print STDERR "\n|$PQcount|\n";}

					if ($PQcount < 1)
						{
						$DEL_chan_park_counter = "DEL$PQchannel$PQextension";
						$$DEL_chan_park_counter++;
							if($DB){print STDERR "\n|$$DEL_chan_park_counter|$DEL_chan_park_counter|\n";}

						if ($$DEL_chan_park_counter > 3)
							{
							$stmtPQ = "DELETE FROM parked_channels where server_ip='$server_ip' and channel='$PQchannel' and extension='$PQextension' limit 1";
								if($DB){print STDERR "\n|$stmtPQ|$$DEL_chan_park_counter|$DEL_chan_park_counter|\n\n";}
							$dbhC->query($stmtPQ);

							$$DEL_chan_park_counter=0;
							}
						}
				   }
			   }

			$event_string='CLOSING MYSQL CONNECTIONS OPENED TO VALIDATE PARKED CALLS|';
			&event_logger;


			$dbhB->close;
			$dbhC->close;

		   }
		$parked_counter++;
		$rec_count++;
	   }

	$run_validate_parked_channels_now=6;	# set to run every six times the program is called

	}

	$run_validate_parked_channels_now--;

}







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
}





sub event_logger {
	### open the log file for writing ###
	open(Lout, ">>$LOGfile")
			|| die "Can't open $LOGfile: $!\n";

	print Lout "$now_date|$event_string|\n";

	close(Lout);

$event_string='';
}
