#!/usr/bin/perl
#
# AST_update.pl version 1.2  (build 50303-0958)
#
# DESCRIPTION:
# uses the Asterisk Manager interface and Net::MySQL to update the live_channels
# tables and verify the parked_channels table in the asterisk MySQL database 
# This "near-live-status of Zap/SIP/Local/IAX channels" list is used by clients
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with Digium
# Zaptel telco cards and SIP VOIP hardphones or softphones as extensions, it
# could be adapted to other functions, but I designed it specifically for 
# Zap/IAX2/SIP users. The program will run on UNIX or Win32 command line 
# providing the following criteria are met:
# 
# Win32 - ActiveState Perl 5.8.0
# UNIX - Gnome or KDE with Tk/Tcl and perl Tk/Tcl modules loaded
# Both - Net::MySQL, Net::Telnet and Time::HiRes perl modules loaded
#
# For the client program to work, this program must always be running
# 
# For this program to work you need to have the "asterisk" MySQL database 
# created and create the tables listed in the MySQL_AST_CREATE_tables.sql file,
# also make sure that the machine running this program has select/insert/update/delete
# access to that database
# 
# In your Asterisk server setup you also need to have several things activated
# and defined. See the CONF_Asterisk.txt file for details
#
# It is recommended that you run this program on the local Asterisk machine
#
# Distributed with no warranty under the GNU Public License
#
# version changes:
# 41228-1659 - modified to compensate for manager output response hiccups
# 50107-1611 - modified to add Zap and IAX2 clients (differentiate from trunks)
# 50117-1537 - modified to add MySQL port ($DB_port) var from conf file
# 50303-0958 - modified to compensate for Zap manager output hiccups

# constants
$DB=0;	# Debug flag, set to 1 for debug messages  WARNING LOTS OF OUTPUT!!!
$DBP=0;	# Debug flag, set to 1 for debug messages  WARNING LOTS OF OUTPUT!!!
$US='__';
$AMP='@';
$MT[0]='';

# DB table variables for testing
	$parked_channels =		'parked_channels';
	$live_channels =		'live_channels';
	$live_sip_channels =	'live_sip_channels';
	$server_updater =		'server_updater';
#	$parked_channels =		'TEST_parked_channels';
#	$live_channels =		'TEST_live_channels';
#	$live_sip_channels =	'TEST_live_sip_channels';
#	$server_updater =		'TEST_server_updater';


### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

	&get_time_now;

	$event_string='PROGRAM STARTED||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||';
	&event_logger;

use lib './lib', '../lib';
use Time::HiRes ('gettimeofday','usleep','sleep');  # necessary to have perl sleep command of less than one second
use Net::MySQL;
use Net::Telnet ();
	  
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";

	$event_string='LOGGED INTO MYSQL SERVER ON 1 CONNECTION|';
	&event_logger;

##### LOOK FOR ZAP CLIENTS AS DEFINED IN THE phones TABLE SO THEY ARE NOT MISLABELED AS TRUNKS
	print STDERR "LOOKING FOR Zap clients assigned to this server:\n";
	$Zap_client_count=0;
	$Zap_client_list='|';
	$stmtA = "SELECT extension FROM phones where protocol = 'Zap' and server_ip='$server_ip'";
	if($DB){print STDERR "|$stmtA|\n";}
	$dbhA->query("$stmtA");
	if ($dbhA->has_selected_record)
	   {
		$iter=$dbhA->create_record_iterator;
		while ( $record = $iter->each)
			{
			print STDERR $record->[0],"\n";
			$Zap_client_list .= "$record->[0]|";
			$Zap_client_count++;
			}
	   }

##### LOOK FOR IAX2 CLIENTS AS DEFINED IN THE phones TABLE SO THEY ARE NOT MISLABELED AS TRUNKS
	print STDERR "LOOKING FOR IAX2 clients assigned to this server:\n";
	$IAX2_client_count=0;
	$IAX2_client_list='|';
	$stmtA = "SELECT extension FROM phones where protocol = 'IAX2' and server_ip='$server_ip'";
	if($DB){print STDERR "|$stmtA|\n";}
	$dbhA->query("$stmtA");
	if ($dbhA->has_selected_record)
	   {
		$iter=$dbhA->create_record_iterator;
		while ( $record = $iter->each)
			{
			print STDERR $record->[0],"\n";
			$IAX2_client_list .= "$record->[0]|";
			if ($record->[0] !~ /\@/)
				{$IAX2_client_list .= "$record->[0]$AMP$record->[0]|";}
			else
				{
				$IAX_user = $record->[0];
				$IAX_user =~ s/\@.*$//gi;
				$IAX2_client_list .= "$IAX_user|";
				}
			$IAX2_client_count++;
			}
	   }

	print STDERR "Zap Clients:  $Zap_client_list\n";
	print STDERR "IAX2 Clients: $IAX2_client_list\n";

$one_day_interval = 12;		# 2 hour loops for one day
while($one_day_interval > 0)
{

		$event_string="STARTING NEW MANAGER TELNET CONNECTION||ATTEMPT|ONE DAY INTERVAL:$one_day_interval|";
	&event_logger;

	### connect to asterisk manager through telnet
	$t = new Net::Telnet (Port => 5038,
						  Prompt => '/.*[\$%#>] $/',
						  Output_record_separator => '',);
	#$fh = $t->dump_log("$telnetlog");  # uncomment for telnet log
	if (length($ASTmgrUSERNAMEupdate) > 3) {$telnet_login = $ASTmgrUSERNAMEupdate;}
	else {$telnet_login = $ASTmgrUSERNAME;}
	$t->open("$telnet_host"); 
	$t->waitfor('/0\n$/');			# print login
	$t->print("Action: Login\nUsername: $telnet_login\nSecret: $ASTmgrSECRET\n\n");
	$t->waitfor('/Authentication accepted/');		# waitfor auth accepted

		$event_string="STARTING NEW MANAGER TELNET CONNECTION|$telnet_login|CONFIRMED CONNECTION|ONE DAY INTERVAL:$one_day_interval|";
	&event_logger;

	$endless_loop=5760000;		# 30 days minutes at .45 seconds per loop

	while($endless_loop > 0)
	{


		@DBchannels=@MT;
		@DBsips=@MT;

			&get_current_channels;

			&validate_parked_channels;

	$t->buffer_empty;
	@list_channels = $t->cmd(String => "Action: Command\nCommand: show channels\n\n", Prompt => '/--END COMMAND-.*/'); 

	##### TEST CLIENT CHANNELS ZAP/IAX2 TO SEE IF THERE WAS A LARGE HICCUP IN OUTPUT FROM PREVIOUS OUTPUT
	@test_channels=@list_channels;
	$test_zap_count=0;
	$test_iax_count=0;
	$test_local_count=0;
	$test_sip_count=0;
	$s=0;
	foreach(@test_channels)
		{
		chomp($test_channels[$s]);
		$test_channels[$s] =~ s/Congestion\s+\(Empty\)/ SIP\/CONGEST/gi;
		$test_channels[$s] =~ s/\(Outgoing Line\)|\(None\)/SIP\/ring/gi;
		$test_channels[$s] =~ s/\(Empty\)/SIP\/internal/gi;
		$test_channels[$s] =~ s/^\s*|\s*$//gi;
		$test_channels[$s] =~ s/\(.*\)//gi;
		if ($test_channels[$s] =~ /^Zap|^IAX2|^SIP|^Local/)
			{
			if ($test_channels[$s] =~ /^(\S+)\s+.+\s+(\S+)$/)
				{
				$channel = $1;
				$extension = $2;
				$extension =~ s/^SIP\/|-\S+$//gi;
				$extension =~ s/\|.*//gi;
				if ($channel =~ /^SIP/) {$test_sip_count++;}
				if ($channel =~ /^Local/) {$test_local_count++;}
				if ($IAX2_client_count) 
					{
					$channel_match=$channel;
					$channel_match =~ s/\/\d+$//gi;
					$channel_match =~ s/^IAX2\///gi;
					if ($IAX2_client_list =~ /\|$channel_match\|/i) {$test_iax_count++;}
					}
				if ($Zap_client_count) 
					{
					$channel_match=$channel;
					$channel_match =~ s/^Zap\///gi;
					if ($Zap_client_list =~ /\|$channel_match\|/i) {$test_zap_count++;}
					}
				}
			}
		$s++;
		}



		#	$DB_live_lines = ($#DBchannels + $#DBsips);
		$DB_live_lines = ($channel_counter + $sip_counter);
		if ( (!$DB_live_lines) or ($#list_channels < 2) )
			{$PERCENT_static = 0;}
		else
			{
			$PERCENT_static = ( ($#list_channels / $DB_live_lines) * 100);
			$PERCENT_static = sprintf("%6.2f", $PERCENT_static);
			}

		if ( (!$test_zap_count) or ($zap_client_counter < 2) )
			{$PERCENT_ZC_static = 0;}
		else
			{
			$PERCENT_ZC_static = ( ($test_zap_count / $zap_client_counter) * 100);
			$PERCENT_ZC_static = sprintf("%6.2f", $PERCENT_ZC_static);
			}

		if ( (!$test_iax_count) or ($iax_client_counter < 2) )
			{$PERCENT_IC_static = 0;}
		else
			{
			$PERCENT_IC_static = ( ($test_iax_count / $iax_client_counter) * 100);
			$PERCENT_IC_static = sprintf("%6.2f", $PERCENT_IC_static);
			}

		if ( (!$test_local_count) or ($local_client_counter < 2) )
			{$PERCENT_LC_static = 0;}
		else
			{
			$PERCENT_LC_static = ( ($test_local_count / $local_client_counter) * 100);
			$PERCENT_LC_static = sprintf("%6.2f", $PERCENT_LC_static);
			}

		if ( (!$test_sip_count) or ($sip_client_counter < 2) )
			{$PERCENT_SC_static = 0;}
		else
			{
			$PERCENT_SC_static = ( ($test_sip_count / $sip_client_counter) * 100);
			$PERCENT_SC_static = sprintf("%6.2f", $PERCENT_SC_static);
			}

		if ($endless_loop =~ /0$/)
			{print "-$now_date   $PERCENT_static    $#list_channels    $#DBchannels:$channel_counter      $#DBsips:$sip_counter    $PERCENT_ZC_static|$test_zap_count:$zap_client_counter    $PERCENT_IC_static|$test_iax_count:$iax_client_counter    $PERCENT_LC_static|$test_local_count:$local_client_counter    $PERCENT_SC_static|$test_sip_count:$sip_client_counter\n";}

		if ( ( ($PERCENT_static < 10) && ( ($channel_counter > 3) or ($sip_counter > 4) ) ) or
			( ($PERCENT_static < 20) && ( ($channel_counter > 10) or ($sip_counter > 10) ) ) or
			( ($PERCENT_static < 30) && ( ($channel_counter > 20) or ($sip_counter > 20) ) ) or
			( ($PERCENT_static < 40) && ( ($channel_counter > 30) or ($sip_counter > 30) ) ) or
			( ($PERCENT_static < 50) && ( ($channel_counter > 40) or ($sip_counter > 40) ) ) or
			( ($PERCENT_ZC_static < 20) && ( $zap_client_counter > 3 ) )  or
			( ($PERCENT_ZC_static < 40) && ( $zap_client_counter > 9 ) )  or
			( ($PERCENT_IC_static < 20) && ( $iax_client_counter > 3 ) )  or
			( ($PERCENT_IC_static < 40) && ( $iax_client_counter > 9 ) )  or
			( ($PERCENT_SC_static < 20) && ( $sip_client_counter > 3 ) )  or
			( ($PERCENT_SC_static < 40) && ( $sip_client_counter > 9 ) )    )
			{
			$UD_bad_grab++;
			$event_string="------ UPDATER BAD GRAB!!!    UBGcount: $UD_bad_grab\n          $PERCENT_static    $#list_channels    $#DBchannels:$channel_counter      $#DBsips:$sip_counter    $PERCENT_ZC_static|$test_zap_count:$zap_client_counter    $PERCENT_IC_static|$test_iax_count:$iax_client_counter    $PERCENT_LC_static|$test_local_count:$local_client_counter    $PERCENT_SC_static|$test_sip_count:$sip_client_counter\n";
			print "$event_string\n";
				&event_logger;
			if ($UD_bad_grab > 20) {$UD_bad_grab=0;}
			}
		else{$UD_bad_grab=0;}

	if ( ( ($list_channels[1] =~ /State Appl\./) or  ($list_channels[2] =~ /State Appl\./) or  ($list_channels[3] =~ /State Appl\./) ) && (!$UD_bad_grab) )
		{

		$c=0;
			if($DB){print "lines: $#list_channels\n";}
			if($DB){print "DBchn: $#DBchannels\n";}
			if($DB){print "DBsip: $#DBsips\n";}
		foreach(@list_channels)
			{
			#	$DBchannels =~ s/^\|//g;

				chomp($list_channels[$c]);
					if( ($DB) or ($UD_bad_grab) ){print "-|$list_channels[$c]|\n";}
				$list_channels[$c] =~ s/Congestion\s+\(Empty\)/ SIP\/CONGEST/gi;
				$list_channels[$c] =~ s/\(Outgoing Line\)|\(None\)/SIP\/ring/gi;
				$list_channels[$c] =~ s/\(Empty\)/SIP\/internal/gi;
				$list_channels[$c] =~ s/^\s*|\s*$//gi;
				$list_channels[$c] =~ s/\(.*\)//gi;
				$list_SIP[$c] = $list_channels[$c];
					if( ($DB) or ($UD_bad_grab) ){print "+|$list_channels[$c]|\n\n";}

		########## PARSE EACH LINE TO DETERMINE WHETHER IT IS TRUNK OR CLIENT AND PUT IN APPROPRIATE TABLE
			if ($list_channels[$c] =~ /^Zap|^IAX2|^SIP|^Local/)
				{
				if ($list_channels[$c] =~ /^(\S+)\s+.+\s+(\S+)$/)
					{
					$line_type = '';
					$channel = $1;
					$extension = $2;
					$extension =~ s/^SIP\/|-\S+$//gi;
					$extension =~ s/\|.*//gi;
					$QRYchannel = "$channel$US$extension";

					if( ($DB) or ($UD_bad_grab) ){print "channel:   |$channel|\n";}
					if( ($DB) or ($UD_bad_grab) ){print "extension: |$extension|\n";}
					if( ($DB) or ($UD_bad_grab) ){print "QRYchannel:|$QRYchannel|\n";}

					if ($channel =~ /^Zap|^IAX2/) {$line_type = 'TRUNK';}
					if ($channel =~ /^SIP|^Local/) {$line_type = 'CLIENT';}
					if ($IAX2_client_count) 
						{
						$channel_match=$channel;
						$channel_match =~ s/\/\d+$//gi;
						$channel_match =~ s/^IAX2\///gi;
	#					print "checking for IAX2 client:   |$channel_match|\n";
						if ($IAX2_client_list =~ /\|$channel_match\|/i) {$line_type = 'CLIENT';}
						}
					if ($Zap_client_count) 
						{
						$channel_match=$channel;
						$channel_match =~ s/^Zap\///gi;
	#					print "checking for Zap client:   |$channel_match|\n";
						if ($Zap_client_list =~ /\|$channel_match\|/i) {$line_type = 'CLIENT';}
						}

					if ($line_type eq 'TRUNK')
						{
						if( ($DB) or ($UD_bad_grab) ){print "current channels: $#DBchannels\n";}

							$k=0;
							$channel_in_DB=0;
						foreach(@DBchannels)
							{
							if ( ($DBchannels[$k] eq "$QRYchannel") && (!$channel_in_DB) )
								{
								$DBchannels[$k] = '';
								$channel_in_DB++;
								}
							if( ($DB) or ($UD_bad_grab) ){print "DB $k|$DBchannels[$k]|     |";}
							$k++;
							}

						if ( (!$channel_in_DB) && (length($QRYchannel)>3) )
							{
							$stmtA = "INSERT INTO $live_channels (channel,server_ip,extension) values('$channel','$server_ip','$extension')";
								if( ($DB) or ($UD_bad_grab) ){print STDERR "\n|$stmtA|\n";}
							$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
							}
						}

					if ($line_type eq 'CLIENT')
						{
						if( ($DB) or ($UD_bad_grab) ){print "current sips: $#DBsips\n";}

							$k=0;
							$sipchan_in_DB=0;
						foreach(@DBsips)
							{
							if ( ($DBsips[$k] eq "$QRYchannel") && (!$sipchan_in_DB) )
								{
								$DBsips[$k] = '';
								$sipchan_in_DB++;
								}
							if( ($DB) or ($UD_bad_grab) ){print "DB $k|$DBsips[$k]|     |";}
							$k++;
							}

						if ( (!$sipchan_in_DB) && (length($QRYchannel)>3) )
							{
							$stmtA = "INSERT INTO $live_sip_channels (channel,server_ip,extension) values('$channel','$server_ip','$extension')";
								if( ($DB) or ($UD_bad_grab) ){print STDERR "\n|$stmtA|\n";}
							$dbhA->query($stmtA)  or die  "Couldn't execute query:\n";
							}
						}
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
							$stmtB = "DELETE FROM $live_channels where server_ip='$server_ip' and channel='$DELchannel' and extension='$DELextension' limit 1";
								if( ($DB) or ($UD_bad_grab) ){print STDERR "\n|$stmtB|\n";}
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
							$stmtB = "DELETE FROM $live_sip_channels where server_ip='$server_ip' and channel='$DELchannel' and extension='$DELextension' limit 1";
								if( ($DB) or ($UD_bad_grab) ){print STDERR "\n|$stmtB|\n";}
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
$zap_client_counter=0;
$iax_client_counter=0;
$local_client_counter=0;
$sip_client_counter=0;

	if($DB){print STDERR "\n|SELECT channel,extension FROM $live_channels where server_ip = '$server_ip'|\n";}

$dbhA->query("SELECT channel,extension FROM $live_channels where server_ip = '$server_ip'");
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

$dbhA->query("SELECT channel,extension FROM $live_sip_channels where server_ip = '$server_ip'");
if ($dbhA->has_selected_record)
   {
	$iter=$dbhA->create_record_iterator;
	$rec_count_sip=0;
	while ( $record = $iter->each)
		{
		if($DB){print STDERR $record->[0],"|", $record->[1],"\n";}
			$DBsips[$sip_counter] = "$record->[0]$US$record->[1]";

		if ($record->[0] =~ /^Zap/) {$zap_client_counter++;}
		if ($record->[0] =~ /^IAX/) {$iax_client_counter++;}
		if ($record->[0] =~ /^Local/) {$local_client_counter++;}
		if ($record->[0] =~ /^SIP/) {$sip_client_counter++;}
		$sip_counter++;
		$rec_count_sip++;
		}
   }

	&get_time_now;

$stmtU = "UPDATE $server_updater set last_update='$now_date' where server_ip='$server_ip'";
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
	@ARchannel=@MT;   @ARextension=@MT;   @ARparked_time=@MT;   @ARparked_time_UNIX=@MT;   
	$dbhA->query("SELECT channel,extension,parked_time,UNIX_TIMESTAMP(parked_time) FROM $parked_channels where server_ip = '$server_ip' order by channel desc, parked_time desc");
	if ($dbhA->has_selected_record)
	   {
		$iter=$dbhA->create_record_iterator;
		$rec_count=0;
		while ( $record = $iter->each)
		   {
			$PQchannel = $record->[0];
			$PQextension = $record->[1];
			$PQparked_time = $record->[2];
			$PQparked_time_UNIX = $record->[3];
				if($DB){print STDERR "\n|$PQchannel|$PQextension|$PQparked_time|$PQparked_time_UNIX|\n";}

			my $dbhC = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";


			$AR=0;
			$record_deleted=0;
			foreach(@ARchannel)
			   {
				if (@ARchannel[$AR] eq "$PQchannel")
					{
					if (@ARparked_time_UNIX[$AR] > $PQparked_time_UNIX)
						{
							if($DBP){print "Duplicate parked channel delete: |$PQchannel|$PQparked_time|\n";}
						$stmtPQ = "DELETE FROM $parked_channels where server_ip='$server_ip' and channel='$PQchannel' and extension='$PQextension' and parked_time='$PQparked_time' limit 1";
								if($DB){print STDERR "\n|$stmtPQ|$$DEL_chan_park_counter|$DEL_chan_park_counter|\n\n";}
							$dbhC->query($stmtPQ);
							
							$DEL_chan_park_counter = "DEL$PQchannel$PQextension";
							$$DEL_chan_park_counter=0;
						$record_deleted++;
						}

					}

				$AR++;
			   }
			
			
			
			if (!$record_deleted)
				{
				$ARchannel[$rec_count] = $record->[0];
				$ARextension[$rec_count] = $record->[1];
				$ARparked_time[$rec_count] = $record->[2];
				$ARparked_time_UNIX[$rec_count] = $record->[3];
			

				my $dbhB = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
					or 	die "Couldn't connect to database: $DB_server - $DB_database\n";


				$event_string='LOGGED INTO MYSQL SERVER ON 2 CONNECTIONS TO VALIDATE PARKED CALLS|';
				&event_logger;


			   $dbhB->query("SELECT count(*) FROM $live_channels where server_ip='$server_ip' and channel='$PQchannel' and extension='$PQextension'");
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
								if($DBP){print STDERR "Parked counter down|$$DEL_chan_park_counter|$DEL_chan_park_counter|\n";}

							### if the parked channel doesn't exist 6 times then delete it from table
							if ($$DEL_chan_park_counter > 5)
								{
							if($DBP){print "          parked channel delete: |$PQchannel|$PQparked_time|\n";}
								$stmtPQ = "DELETE FROM $parked_channels where server_ip='$server_ip' and channel='$PQchannel' and extension='$PQextension' limit 1";
									if($DB){print STDERR "\n|$stmtPQ|$$DEL_chan_park_counter|$DEL_chan_park_counter|\n\n";}
								$dbhC->query($stmtPQ);

									$ARchannel[$rec_count] = '';
									$ARextension[$rec_count] = '';
									$ARparked_time[$rec_count] = '';
									$ARparked_time_UNIX[$rec_count] = '';
								$$DEL_chan_park_counter=0;
								}
							}
						else
						   {
							$DEL_chan_park_counter = "DEL$PQchannel$PQextension";
							$$DEL_chan_park_counter=0;
						   }
					   }
				   }

				$event_string='CLOSING MYSQL CONNECTIONS OPENED TO VALIDATE PARKED CALLS|';
				&event_logger;


				$dbhB->close;

				}

			$dbhC->close;

		   }
		$parked_counter++;
		$rec_count++;
	   }

	$run_validate_parked_channels_now=5;	# set to run every five times the subroutine runs

	}

	$run_validate_parked_channels_now--;

}





################################################################################
##### get the current date and time and epoch for logging call lengths and datetimes
sub get_time_now
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





################################################################################
##### open the log file for writing ###
sub event_logger 
{
open(Lout, ">>$LOGfile")
		|| die "Can't open $LOGfile: $!\n";
print Lout "$now_date|$event_string|\n";
close(Lout);
$event_string='';
}
