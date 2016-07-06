#!/usr/bin/perl
#
# AST_SQL_update_channels.pl version 0.4
#
# DESCRIPTION:
# uses the Asterisk Manager interface and Net::MySQL to update the live_channels
# table and verify the parked_channels table in the asterisk MySQL database 
# This "near-live-status of Zap channels" Database is then used by client apps
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
# Distributed with no waranty under the GNU Public License
#

# constants
$DB=0;  # Debug flag, set to 0 for no debug messages, On an active system this will generate thousands of lines of output per minute
$US='__';
$MT[0]='';

# Customized Variables
$server_ip = '10.0.0.2';		# Asterisk server IP
$ASTmgrUSERNAME = 'cron';		# Asterisk Manager interface username
$ASTmgrSECRET = 'test';			# Asterisk Manager interface secret
$DB_server = '10.0.0.3';		# MySQL server IP
$DB_database = 'asterisk';		# MySQL database name
$DB_user = 'cron';				# MySQL user
$DB_pass = 'test';				# MySQL pass




use lib './lib', '../lib';
use Time::HiRes ('gettimeofday','usleep','sleep');  # necessary to have perl sleep command of less than one second
use Net::MySQL;
use Net::Telnet ();
	  
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";
	my $dbhB = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";
	my $dbhC = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass") 
	or 	die "Couldn't connect to database: \n";

$one_day_interval = 35040;		# 24 hours for 15 minute loops = 96, 1 year = 35040
while($one_day_interval > 0)
{


	### connect to asterisk manager through telnet
	$t = new Net::Telnet (Port => 5038,
						  Prompt => '/.*[\$%#>] $/',
						  Output_record_separator => '',);
	#$fh = $t->dump_log("./telnet_log.txt");  # uncomment for telnet log
	$t->open("$server_ip"); 
	$t->waitfor('/0\n$/');			# print login
	$t->print("Action: Login\nUsername: $ASTmgrUSERNAME\nSecret: $ASTmgrSECRET\n\n");
	$t->waitfor('/Authentication accepted/');		# waitfor auth accepted


	$endless_loop=2700;		# 15 minutes at .75 seconds per loop

	while($endless_loop > 0)
	{


		@DBchannels=@MT;

			&get_current_channels;

			&validate_parked_channels;

	@list_channels = $t->cmd(String => "Action: Command\nCommand: show channels\n\n", Prompt => '/--END COMMAND--.*/'); 

	if ($list_channels[3] =~ /State Appl\./)
		{

		$c=0;
			if($DB){print "lines: $#list_channels\n";}
			if($DB){print "DBchn: $#DBchannels\n";}
		foreach(@list_channels)
			{
				$DBchannels =~ s/^\|//g;

				chomp($list_channels[$c]);
					if($DB){print "-|$list_channels[$c]|\n";}
				$list_channels[$c] =~ s/\(Outgoing Line\)/SIP\/ring/gi;
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
				if ($list_SIP[$c] =~ /^SIP/)
					{
					$list_SIP[$c] =~ s/-.*//gi;
						if($DB){print STDERR "\n|$list_SIP[$c]|\n";}
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
		}

	else
		{
		if($DB){print STDERR "\nbad grab, trying again\n";}
		}


	}


		if($DB){print "DONE... Exiting... Goodbye... See you later... Not really, initiating next loop...\n";}

		$ok = $t->close;

	$one_day_interval--;

}

	$dbhA->close;
	$dbhB->close;
	$dbhC->close;


	if($DB){print "DONE... Exiting... Goodbye... See you later... Really I mean it this time\n";}


exit;







#######################################################################
# This subroutine simply grabs all active channel/extension combinations from
# the asterisk MySQL database to be compared to the Asterisk Manager results
#######################################################################
sub get_current_channels
{
$channel_counter=0;

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

	&get_time_now;

### This step updates the server_updater record for the Asterisk server to let 
### the clients know that it has updated the live_channels table. if it does not
### update for 6 seconds the client machines show an alert popup

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
