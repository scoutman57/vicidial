#!/usr/bin/perl
#
# AST_conf_update.pl version 0.1
#
# DESCRIPTION:
# uses the Asterisk Manager interface and Net::MySQL to update whether a conference
# is still in use or not. If not in use 3 times in a row the extension in the 
# conferences DB record is erased freeing that conference to be used again
#
# SUMMARY:
# This program was designed for people using the Asterisk PBX with conferences
#
# This program should be in the cron running every minute (like AST_vm_update.pl)
# 
# For this program to work you need to have the "asterisk" MySQL database 
# created with the conferences table in it, also make sure
# that the account running this program has read/write/update/delete access 
# to that database
# 
# It is recommended that you run this program on the local Asterisk machine
#
# If this script is run ever minute there is a theoretical limit of 
# 600 conferences that it can check due to the wait interval. If you have 
# more than this either change the cron when this script is run or change the 
# wait interval below
#
# Distributed with no warranty under the GNU Public License
#
# 50810-1532 - Added database server variable definitions lookup
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

### Grab Server values from the database
$stmtA = "SELECT telnet_host,telnet_port,ASTmgrUSERNAME,ASTmgrSECRET,ASTmgrUSERNAMEupdate,ASTmgrUSERNAMElisten,ASTmgrUSERNAMEsend,max_vicidial_trunks,answer_transfer_agent,local_gmt,ext_context FROM servers where server_ip = '$server_ip';";
$dbhA->query("$stmtA");
if ($dbhA->has_selected_record)
	{
	$iter=$dbhA->create_record_iterator;
	   while ( $record = $iter->each)
		{
		$DBtelnet_host	=			"$record->[0]";
		$DBtelnet_port	=			"$record->[1]";
		$DBASTmgrUSERNAME	=		"$record->[2]";
		$DBASTmgrSECRET	=			"$record->[3]";
		$DBASTmgrUSERNAMEupdate	=	"$record->[4]";
		$DBASTmgrUSERNAMElisten	=	"$record->[5]";
		$DBASTmgrUSERNAMEsend	=	"$record->[6]";
		$DBmax_vicidial_trunks	=	"$record->[7]";
		$DBanswer_transfer_agent=	"$record->[8]";
		$DBSERVER_GMT		=		"$record->[9]";
		$DBext_context	=			"$record->[10]";
		if ($DBtelnet_host)				{$telnet_host = $DBtelnet_host;}
		if ($DBtelnet_port)				{$telnet_port = $DBtelnet_port;}
		if ($DBASTmgrUSERNAME)			{$ASTmgrUSERNAME = $DBASTmgrUSERNAME;}
		if ($DBASTmgrSECRET)			{$ASTmgrSECRET = $DBASTmgrSECRET;}
		if ($DBASTmgrUSERNAMEupdate)	{$ASTmgrUSERNAMEupdate = $DBASTmgrUSERNAMEupdate;}
		if ($DBASTmgrUSERNAMElisten)	{$ASTmgrUSERNAMElisten = $DBASTmgrUSERNAMElisten;}
		if ($DBASTmgrUSERNAMEsend)		{$ASTmgrUSERNAMEsend = $DBASTmgrUSERNAMEsend;}
		if ($DBmax_vicidial_trunks)		{$max_vicidial_trunks = $DBmax_vicidial_trunks;}
		if ($DBanswer_transfer_agent)	{$answer_transfer_agent = $DBanswer_transfer_agent;}
		if ($DBSERVER_GMT)				{$SERVER_GMT = $DBSERVER_GMT;}
		if ($DBext_context)				{$ext_context = $DBext_context;}
		} 
	}



@PTextensions=@MT; @PT_conf_extens=@MT; @PTmessages=@MT; @PTold_messages=@MT; @NEW_messages=@MT; @OLD_messages=@MT;
$dbhA->query("SELECT extension,conf_exten from conferences where server_ip='$server_ip' and extension is NOT NULL and extension != '';");
if ($dbhA->has_selected_record)
   {
	$iter=$dbhA->create_record_iterator;
	$rec_count=0;
	while ( $record = $iter->each)
		{
		$PTextensions[$rec_count] =		 "$record->[0]";
		$PT_conf_extens[$rec_count] =	 "$record->[1]";
		$rec_count++;
		}
   }

if (!$telnet_port) {$telnet_port = '5038';}

### connect to asterisk manager through telnet
$t = new Net::Telnet (Port => $telnet_port,
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
	@list_channels = $t->cmd(String => "Action: Command\nCommand: Meetme list $PT_conf_extens[$i]\n\nAction: Ping\n\n", Prompt => '/Response: Pong.*/'); 

	$j=0;
	$conf_empty[$i]=0;
	$conf_users[$i]='';
	foreach(@list_channels)
		{
		if($DB){print "|$list_channels[$j]|\n";}
		if ($list_channels[$j] =~ /No active conferences|No such conference/i)
			{$conf_empty[$i]++;}
#		if ($list_channels[$j] =~ /^User /i)
#			{
#			$userx = '';
#			$userx = $list_channels[$j];
#			$userx =~ s/User \#: //gi;
#			$conf_users[$i] .= "$userx|";
#			}
		$j++;
		}

	if($DB){print "Meetme list $PT_conf_extens[$i]-  Exten:|$PTextensions[$i]| Empty:|$conf_empty[$i]|\n";}
	if (!$conf_empty[$i])
		{
		if($DB){print "CONFERENCE STILL HAS PARTICIPANTS, DOING NOTHING FOR THIS CONFERENCE\n";}
		if ($PTextensions[$i] =~ /Xtimeout\d$/i) 
			{
			$PTextensions[$i] =~ s/Xtimeout\d$//gi;
			$stmtA = "UPDATE conferences set extension='$PTextensions[$i]' where server_ip='$server_ip' and conf_exten='$PT_conf_extens[$i]';";
				if($DB){print STDERR "\n|$stmtA|\n";}
			$dbhA->query($stmtA)  or die  "Couldn't execute query:|$stmtA|\n";
			}
		}
	else
		{
		$NEWexten[$i] = $PTextensions[$i];
		if ($PTextensions[$i] =~ /Xtimeout3$/i) {$NEWexten[$i] =~ s/Xtimeout3$/Xtimeout2/gi;}
		if ($PTextensions[$i] =~ /Xtimeout2$/i) {$NEWexten[$i] =~ s/Xtimeout2$/Xtimeout1/gi;}
		if ($PTextensions[$i] =~ /Xtimeout1$/i) {$NEWexten[$i] = '';}
		if ( ($PTextensions[$i] !~ /Xtimeout\d$/i) and (length($PTextensions[$i])> 0) ) {$NEWexten[$i] .= 'Xtimeout3';}


		$stmtA = "UPDATE conferences set extension='$NEWexten[$i]' where server_ip='$server_ip' and conf_exten='$PT_conf_extens[$i]';";
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




