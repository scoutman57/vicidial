#!/usr/bin/perl
#
# AST_vm_update.pl version 0.1
#
# DESCRIPTION:
# uses the Asterisk Manager interface and Net::MySQL to update the count of 
# voicemail messages for each mailbox (in the phone table) in the voicemail
# table list is used by client apps for voicemail notification
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with voicemail
#
# For the client program to notify of new messaged, this program must be in the 
# cron running every minute
# 
# For this program to work you need to have the "asterisk" MySQL database 
# created and create the tables listed in the CONF_MySQL.txt file, also make sure
# that the machine running this program has read/write/update/delete access 
# to that database
# 
# It is recommended that you run this program on the local Asterisk machine
#
# If this script is run ever minute there is a theoretical limit of 
# 600 mailboxes that it can check due to the wait interval. If you have 
# more than this either change the cron when this script is run or change the 
# wait interval below
#
# Distributed with no waranty under the GNU Public License
#

# constants
$DB=0;  # Debug flag, set to 0 for no debug messages, On an active system this will generate thousands of lines of output per minute
$US='__';
$MT[0]='';

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

use lib './lib', '../lib';
use Time::HiRes ('gettimeofday','usleep','sleep');  # necessary to have perl sleep command of less than one second
use Net::MySQL;
use Net::Telnet ();
	  

	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";



@PTextensions=@MT; @PTvoicemail_ids=@MT; @PTmessages=@MT; @PTold_messages=@MT; @NEW_messages=@MT; @OLD_messages=@MT;
$dbhA->query("SELECT extension,voicemail_id,messages,old_messages from phones where server_ip='$server_ip'");
if ($dbhA->has_selected_record)
   {
	$iter=$dbhA->create_record_iterator;
	$rec_count=0;
	while ( $record = $iter->each)
		{
		$PTextensions[$rec_count] =		 "$record->[0]";
		$PTvoicemail_ids[$rec_count] =	 "$record->[1]";
		$PTmessages[$rec_count] =		 "$record->[2]";
		$PTold_messages[$rec_count] =	 "$record->[3]";
		$rec_count++;
		}
   }


### connect to asterisk manager through telnet
$t = new Net::Telnet (Port => 5038,
					  Prompt => '/.*[\$%#>] $/',
					  Output_record_separator => '',);
#$fh = $t->dump_log("$telnetlog");  # uncomment for telnet log
	if (length($ASTmgrUSERNAMEsend) > 3) {$telnet_login = $ASTmgrUSERNAMEsend;}
	else {$telnet_login = $ASTmgrUSERNAME;}

$t->open("$telnet_host"); 
$t->waitfor('/0\n$/');			# print login
$t->print("Action: Login\nUsername: $telnet_login\nSecret: $ASTmgrSECRET\n\n");
$t->waitfor('/Authentication accepted/');		# waitfor auth accepted


$i=0;
foreach(@PTextensions)
	{
	@list_channels=@MT;
	$t->buffer_empty;
	@list_channels = $t->cmd(String => "Action: MailboxCount\nMailbox: $PTvoicemail_ids[$i]\n\nAction: Ping\n\n", Prompt => '/Response: Pong.*/'); 

	$j=0;
	foreach(@list_channels)
		{
		if ($list_channels[$j] =~ /Mailbox: $PTvoicemail_ids[$i]/)
			{
			$NEW_messages[$i] = "$list_channels[$j+1]";
			$NEW_messages[$i] =~ s/NewMessages: |\n//gi;
			$OLD_messages[$i] = "$list_channels[$j+2]";
			$OLD_messages[$i] =~ s/OldMessages: |\n//gi;
			}

		$j++;
		}

	if($DB){print "MailboxCount- NEW:|$NEW_messages[$i]|  OLD:|$OLD_messages[$i]|\n";}
	if ( ($NEW_messages[$i] eq $PTmessages[$i]) && ($OLD_messages[$i] eq $PTold_messages[$i]) )
		{
		if($DB){print "MESSAGE COUNT UNCHANGED, DOING NOTHING FOR THIS MAILBOX\n";}
		}
	else
		{
		$stmtA = "UPDATE phones set messages='$NEW_messages[$i]', old_messages='$OLD_messages[$i]' where server_ip='$server_ip' and extension='$PTextensions[$i]'";
			if($DB){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA)  or die  "Couldn't execute query:|$stmtA|\n";
		}

	$i++;
		### sleep for 10 hundredths of a second
		usleep(1*100*1000);
	}


$t->buffer_empty;
@hangup = $t->cmd(String => "Action: Logoff\n\n", Prompt => "/.*/"); 
$t->buffer_empty;
$ok = $t->close;

$dbhA->close;

if($DB){print "DONE... Exiting... Goodbye... See you later... Really I mean it this time\n";}

exit;




