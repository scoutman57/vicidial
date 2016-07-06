<?
### manager_send.php

### This script is designed purely to insert records into the vicidial_manager table to signal Actions to an asterisk server
### This script depends on the server_ip being sent and also needs to have a valid user/pass from the vicidial_users table
### 
### required variables:
###  - $server_ip
###  - $session_name
###  - $user
###  - $pass
### optional variables:
###  - $ACTION - ('Originate','Redirect','Hangup','Command','Monitor','StopMonitor','SysCIDOriginate','RedirectName','RedirectNameVmail','MonitorConf','StopMonitorConf','RedirectXtra','RedirectVD')
###  - $queryCID - ('CN012345678901234567',...)
###  - $format - ('text','debug')
###  - $channel - ('Zap/41-1','SIP/test101-1jut','IAX2/iaxy@iaxy',...)
###  - $exten - ('1234','913125551212',...)
###  - $ext_context - ('default','demo',...)
###  - $ext_priority - ('1','2',...)
###  - $filename - ('20050406-125623_44444',...)
###  - $extenName - ('phone100',...)
###  - $parkedby - ('phone100',...)
###  - $extrachannel - ('Zap/41-1','SIP/test101-1jut','IAX2/iaxy@iaxy',...)
###  - $auto_dial_level - ('0','1','1.1',...)
###  - $campaign - ('CLOSER','TESTCAMP',...)
###  - $uniqueid - ('1120232758.2406800',...)
###  - $lead_id - ('1234',...)
###  - $seconds - ('32',...)
### 

# changes
# 50401-1002 First build of script, Hangup function only
# 50404-1045 Redirect basic function enabled
# 50406-1522 Monitor basic function enabled
# 50407-1647 Monitor and StopMonitor full functions enabled
# 50422-1120 basic Originate function enabled
# 50428-1451 basic SysCIDOriginate function enabled for checking voicemail
# 50502-1539 basic RedirectName and RedirectNameVmail added
# 50503-1227 added session_name checking for extra security
# 50523-1341 added Conference call start/stop recording
# 50523-1421 added OriginateName and OriginateNameVmail for local calls
# 50524-1602 added RedirectToPark and RedirectFromPark
# 50531-1203 added RedirecXtra for dual channel redirection
# 50630-1100 script changed to not use HTTP login vars, user/pass instead
# 50804-1148 Added RedirectVD for VICIDIAL blind redirection with logging
# 50815-1204 Added NEXTAVAILABLE to RedirectXtra function
#


require("dbconnect.php");

require_once("htglobalize.php");

### These are variable assignments for PHP globals off
$user=$_GET["user"];					if (!$user) {$user=$_POST["user"];}
$pass=$_GET["pass"];					if (!$pass) {$pass=$_POST["pass"];}
$server_ip=$_GET["server_ip"];			if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$session_name=$_GET["session_name"];	if (!$session_name) {$session_name=$_POST["session_name"];}
$ACTION=$_GET["ACTION"];				if (!$ACTION) {$ACTION=$_POST["ACTION"];}
$queryCID=$_GET["queryCID"];			if (!$queryCID) {$queryCID=$_POST["queryCID"];}
$format=$_GET["format"];				if (!$format) {$format=$_POST["format"];}
$channel=$_GET["channel"];				if (!$channel) {$channel=$_POST["channel"];}
$exten=$_GET["exten"];					if (!$exten) {$exten=$_POST["exten"];}
$ext_context=$_GET["ext_context"];		if (!$ext_context) {$ext_context=$_POST["ext_context"];}
$ext_priority=$_GET["ext_priority"];	if (!$ext_priority) {$ext_priority=$_POST["ext_priority"];}
$filename=$_GET["filename"];			if (!$filename) {$filename=$_POST["filename"];}
$extenName=$_GET["extenName"];			if (!$extenName) {$extenName=$_POST["extenName"];}
$parkedby=$_GET["parkedby"];			if (!$parkedby) {$parkedby=$_POST["parkedby"];}
$extrachannel=$_GET["extrachannel"];	if (!$extrachannel) {$extrachannel=$_POST["extrachannel"];}
$auto_dial_level=$_GET["auto_dial_level"];	if (!$auto_dial_level) {$auto_dial_level=$_POST["auto_dial_level"];}
$campaign=$_GET["campaign"];			if (!$campaign) {$campaign=$_POST["campaign"];}
$uniqueid=$_GET["uniqueid"];			if (!$uniqueid) {$uniqueid=$_POST["uniqueid"];}
$lead_id=$_GET["lead_id"];				if (!$lead_id) {$lead_id=$_POST["lead_id"];}
$seconds=$_GET["seconds"];				if (!$seconds) {$seconds=$_POST["seconds"];}

# default optional vars if not set
if (!$ACTION)	{$ACTION="Originate";}
if (!$format)	{$format="alert";}
if (!$ext_priority)	{$ext_priority="1";}


$version = '0.0.15';
$build = '50815-1204';
$STARTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
if (!$query_date) {$query_date = $NOW_DATE;}

	$stmt="SELECT count(*) from vicidial_users where user='$user' and pass='$pass' and user_level > 0;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

  if( (strlen($user)<2) or (strlen($pass)<2) or (!$auth))
	{
    echo "Invalid Username/Password: |$user|$pass|\n";
    exit;
	}
  else
	{

	if( ( (strlen($server_ip)<6) or (!$server_ip) ) or ( (strlen($session_name)<12) or (!$session_name) ) )
		{
		echo "Invalid server_ip: |$server_ip|  or  Invalid session_name: |$session_name|\n";
		exit;
		}
	else
		{
		$stmt="SELECT count(*) from web_client_sessions where session_name='$session_name' and server_ip='$server_ip';";
		if ($DB) {echo "|$stmt|\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$SNauth=$row[0];
		  if(!$SNauth)
			{
			echo "Invalid session_name: |$session_name|$server_ip|\n";
			exit;
			}
		  else
			{
			# do nothing for now
			}
		}
	}

if ($format=='debug')
{
echo "<html>\n";
echo "<head>\n";
echo "<!-- VERSION: $version     BUILD: $build    ACTION: $ACTION   server_ip: $server_ip-->\n";
echo "<title>Manager Send: ";
if ($ACTION=="Originate")		{echo "Originate";}
if ($ACTION=="Redirect")		{echo "Redirect";}
if ($ACTION=="RedirectName")	{echo "RedirectName";}
if ($ACTION=="Hangup")			{echo "Hangup";}
if ($ACTION=="Command")			{echo "Command";}
if ($ACTION==99999)	{echo "HELP";}
echo "</title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
}





######################
# ACTION=SysCIDOriginate  - insert Originate Manager statement allowing small CIDs for system calls
######################
if ($ACTION=="SysCIDOriginate")
{
	if ( (strlen($exten)<1) or (strlen($channel)<1) or (strlen($ext_context)<1) or (strlen($queryCID)<1) )
	{
		echo "Exten $exten is not valid or queryCID $queryCID is not valid, Originate command not inserted\n";
	}
	else
	{
	$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$queryCID','Channel: $channel','Context; $ext_context','Exten: $exten','Priority: $ext_priority','Callerid: $queryCID','','','','','');";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	echo "Originate command sent for Exten $exten Channel $channel on $server_ip\n";
	}
}



######################
# ACTION=Originate, OriginateName, OriginateNameVmail  - insert Originate Manager statement
######################
if ($ACTION=="OriginateName")
{
	if ( (strlen($channel)<3) or (strlen($queryCID)<15)  or (strlen($extenName)<1)  or (strlen($ext_context)<1)  or (strlen($ext_priority)<1) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "extenName $extenName must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "\nOriginateName Action not sent\n";
	}
	else
	{
		$stmt="SELECT dialplan_number FROM phones where server_ip = '$server_ip' and extension='$extenName';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$name_count = mysql_num_rows($rslt);
		if ($name_count>0)
		{
		$row=mysql_fetch_row($rslt);
		$exten = $row[0];
		$ACTION="Originate";
		}
	}
}

if ($ACTION=="OriginateNameVmail")
{
	if ( (strlen($channel)<3) or (strlen($queryCID)<15)  or (strlen($extenName)<1)  or (strlen($exten)<1)  or (strlen($ext_context)<1)  or (strlen($ext_priority)<1) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "extenName $extenName must be set\n";
		echo "exten $exten must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "\nOriginateNameVmail Action not sent\n";
	}
	else
	{
		$stmt="SELECT voicemail_id FROM phones where server_ip = '$server_ip' and extension='$extenName';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$name_count = mysql_num_rows($rslt);
		if ($name_count>0)
		{
		$row=mysql_fetch_row($rslt);
		$exten = "$exten$row[0]";
		$ACTION="Originate";
		}
	}
}

if ($ACTION=="Originate")
{
	if ( (strlen($exten)<1) or (strlen($channel)<1) or (strlen($ext_context)<1) or (strlen($queryCID)<10) )
	{
		echo "Exten $exten is not valid or queryCID $queryCID is not valid, Originate command not inserted\n";
	}
	else
	{
	$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$queryCID','Channel: $channel','Context; $ext_context','Exten: $exten','Priority: $ext_priority','Callerid: $queryCID','','','','','');";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	echo "Originate command sent for Exten $exten Channel $channel on $server_ip\n";
	}
}



######################
# ACTION=Hangup  - insert Hangup Manager statement
######################
if ($ACTION=="Hangup")
{
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($channel)<3) or (strlen($queryCID)<15) )
	{
		$channel_live=0;
		echo "Channel $channel is not valid or queryCID $queryCID is not valid, Hangup command not inserted\n";
	}
	else
	{
		$stmt="SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$channel';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row==0)
		{
			$stmt="SELECT count(*) FROM live_sip_channels where server_ip = '$server_ip' and channel='$channel';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$rowx=mysql_fetch_row($rslt);
			if ($rowx==0)
			{
				$channel_live=0;
				echo "Channel $channel is not live on $server_ip, Hangup command not inserted\n";
			}	
		}
		if ($channel_live==1)
		{
		$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Hangup','$queryCID','Channel: $channel','','','','','','','','','');";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		echo "Hangup command sent for Channel $channel on $server_ip\n";
		}
	}
}



######################
# ACTION=Redirect, RedirectName, RedirectNameVmail, RedirectToPark, RedirectFromPark, RedirectVD
# - insert Redirect Manager statement using extensions name
######################
if ($ACTION=="RedirectVD")
{
	if ( (strlen($channel)<3) or (strlen($queryCID)<15) or (strlen($exten)<1) or (strlen($campaign)<1) or (strlen($ext_context)<1) or (strlen($ext_priority)<1) or (strlen($auto_dial_level)<1) or (strlen($uniqueid)<2) or (strlen($lead_id)<2) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "exten $exten must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "auto_dial_level $auto_dial_level must be set\n";
		echo "campaign $campaign must be set\n";
		echo "uniqueid $uniqueid must be set\n";
		echo "lead_id $lead_id must be set\n";
		echo "\nRedirectVD Action not sent\n";
	}
	else
	{
			if (eregi("CLOSER",$campaign))
				{
				$stmt = "UPDATE vicidial_closer_log set end_epoch='$STARTtime', length_in_sec='$seconds',status='XFER' where lead_id='$lead_id' order by start_epoch desc limit 1;";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);
				}
			if ($auto_dial_level < 1)
				{
				$stmt = "UPDATE vicidial_log set end_epoch='$STARTtime', length_in_sec='$seconds',status='XFER' where uniqueid='$uniqueid';";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);
				}
			else
				{
				$stmt = "DELETE from vicidial_auto_calls where uniqueid='$uniqueid';";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);
				}

		$ACTION="Redirect";
	}
}

if ($ACTION=="RedirectToPark")
{
	if ( (strlen($channel)<3) or (strlen($queryCID)<15) or (strlen($exten)<1) or (strlen($extenName)<1) or (strlen($ext_context)<1) or (strlen($ext_priority)<1) or (strlen($parkedby)<1) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "exten $exten must be set\n";
		echo "extenName $extenName must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "parkedby $parkedby must be set\n";
		echo "\nRedirectToPark Action not sent\n";
	}
	else
	{
		$stmt = "INSERT INTO parked_channels values('$channel','$server_ip','','$extenName','$parkedby','$NOW_TIME');";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$ACTION="Redirect";
	}
}

if ($ACTION=="RedirectFromPark")
{
	if ( (strlen($channel)<3) or (strlen($queryCID)<15) or (strlen($exten)<1) or (strlen($ext_context)<1) or (strlen($ext_priority)<1) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "exten $exten must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "\nRedirectFromPark Action not sent\n";
	}
	else
	{
		$stmt = "DELETE FROM parked_channels where server_ip='$server_ip' and channel='$channel';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$ACTION="Redirect";
	}
}

if ($ACTION=="RedirectName")
{
	if ( (strlen($channel)<3) or (strlen($queryCID)<15)  or (strlen($extenName)<1)  or (strlen($ext_context)<1)  or (strlen($ext_priority)<1) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "extenName $extenName must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "\nRedirectName Action not sent\n";
	}
	else
	{
		$stmt="SELECT dialplan_number FROM phones where server_ip = '$server_ip' and extension='$extenName';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$name_count = mysql_num_rows($rslt);
		if ($name_count>0)
		{
		$row=mysql_fetch_row($rslt);
		$exten = $row[0];
		$ACTION="Redirect";
		}
	}
}

if ($ACTION=="RedirectNameVmail")
{
	if ( (strlen($channel)<3) or (strlen($queryCID)<15)  or (strlen($extenName)<1)  or (strlen($exten)<1)  or (strlen($ext_context)<1)  or (strlen($ext_priority)<1) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "extenName $extenName must be set\n";
		echo "exten $exten must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "\nRedirectNameVmail Action not sent\n";
	}
	else
	{
		$stmt="SELECT voicemail_id FROM phones where server_ip = '$server_ip' and extension='$extenName';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$name_count = mysql_num_rows($rslt);
		if ($name_count>0)
		{
		$row=mysql_fetch_row($rslt);
		$exten = "$exten$row[0]";
		$ACTION="Redirect";
		}
	}
}

if ($ACTION=="RedirectXtra")
{
	if ($channel=="$extrachannel")
	{$ACTION="Redirect";}
	else
	{
		$row='';   $rowx='';
		$channel_liveX=1;
		$channel_liveY=1;
		if ( (strlen($channel)<3) or (strlen($queryCID)<15) or (strlen($exten)<1) or (strlen($ext_context)<1) or (strlen($ext_priority)<1) or (strlen($extrachannel)<3) )
		{
			$channel_liveX=0;
			$channel_liveY=0;
			echo "One of these variables is not valid:\n";
			echo "Channel $channel must be greater than 2 characters\n";
			echo "ExtraChannel $extrachannel must be greater than 2 characters\n";
			echo "queryCID $queryCID must be greater than 14 characters\n";
			echo "exten $exten must be set\n";
			echo "ext_context $ext_context must be set\n";
			echo "ext_priority $ext_priority must be set\n";
			echo "\nRedirect Action not sent\n";
		}
		else
		{
			if ($exten == "NEXTAVAILABLE")
			{
			$stmt="SELECT conf_exten FROM conferences where server_ip='$server_ip' and extension='' limit 1;";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
				if (strlen($row[0]) > 3)
				{
				$stmt="UPDATE conferences set extension='$SIP_user' where server_ip='$server_ip' and conf_exten='$row[0]';";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);
				$exten = $row[0];
				}
				else
				{
				$channel_liveX=0;
				echo "Cannot find empty conference on $server_ip, Redirect command not inserted\n";
				}
			}

			$stmt="SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$channel';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row==0)
			{
				$stmt="SELECT count(*) FROM live_sip_channels where server_ip = '$server_ip' and channel='$channel';";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);
				$rowx=mysql_fetch_row($rslt);
				if ($rowx==0)
				{
					$channel_liveX=0;
					echo "Channel $channel is not live on $server_ip, Redirect command not inserted\n";
				}	
			}
			$stmt="SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$extrachannel';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row==0)
			{
				$stmt="SELECT count(*) FROM live_sip_channels where server_ip = '$server_ip' and channel='$extrachannel';";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);
				$rowx=mysql_fetch_row($rslt);
				if ($rowx==0)
				{
					$channel_liveY=0;
					echo "Channel $channel is not live on $server_ip, Redirect command not inserted\n";
				}	
			}
			if ( ($channel_liveX==1) && ($channel_liveY==1) )
			{
			$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Redirect','$queryCID','Channel: $channel','ExtraChannel: $extrachannel','Context: $ext_context','Exten: $exten','Priority: $ext_priority','CallerID: $queryCID','','','','');";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);

			echo "RedirectXtra command sent for Channel $channel and \nExtraChannel $extrachannel\n to $exten on $server_ip\n";
			}
			else
			{
				if ($channel_liveX==1)
				{$ACTION="Redirect";}
				if ($channel_liveY==1)
				{$ACTION="Redirect";   $channel=$extrachannel;}

			}
		}
	}
}


if ($ACTION=="Redirect")
{
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($channel)<3) or (strlen($queryCID)<15)  or (strlen($exten)<1)  or (strlen($ext_context)<1)  or (strlen($ext_priority)<1) )
	{
		$channel_live=0;
		echo "One of these variables is not valid:\n";
		echo "Channel $channel must be greater than 2 characters\n";
		echo "queryCID $queryCID must be greater than 14 characters\n";
		echo "exten $exten must be set\n";
		echo "ext_context $ext_context must be set\n";
		echo "ext_priority $ext_priority must be set\n";
		echo "\nRedirect Action not sent\n";
	}
	else
	{
		$stmt="SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$channel';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row==0)
		{
			$stmt="SELECT count(*) FROM live_sip_channels where server_ip = '$server_ip' and channel='$channel';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$rowx=mysql_fetch_row($rslt);
			if ($rowx==0)
			{
				$channel_live=0;
				echo "Channel $channel is not live on $server_ip, Redirect command not inserted\n";
			}	
		}
		if ($channel_live==1)
		{
		$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Redirect','$queryCID','Channel: $channel','Context: $ext_context','Exten: $exten','Priority: $ext_priority','CallerID: $queryCID','','','','','');";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);

		echo "Redirect command sent for Channel $channel on $server_ip\n";
		}
	}
}



######################
# ACTION=Monitor or Stop Monitor  - insert Monitor/StopMonitor Manager statement to start recording on a channel
######################
if ( ($ACTION=="Monitor") || ($ACTION=="StopMonitor") )
{
	if ($ACTION=="StopMonitor")
		{$SQLfile = "";}
	else
		{$SQLfile = "File: $filename";}

	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($channel)<3) or (strlen($queryCID)<15) or (strlen($filename)<15) )
	{
		$channel_live=0;
		echo "Channel $channel is not valid or queryCID $queryCID is not valid or filename: $filename is not valid, $ACTION command not inserted\n";
	}
	else
	{
		$stmt="SELECT count(*) FROM live_channels where server_ip = '$server_ip' and channel='$channel';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row==0)
		{
			$stmt="SELECT count(*) FROM live_sip_channels where server_ip = '$server_ip' and channel='$channel';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$rowx=mysql_fetch_row($rslt);
			if ($rowx==0)
			{
				$channel_live=0;
				echo "Channel $channel is not live on $server_ip, $ACTION command not inserted\n";
			}	
		}
		if ($channel_live==1)
		{
		$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','$ACTION','$queryCID','Channel: $channel','$SQLfile','','','','','','','','');";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);

		if ($ACTION=="Monitor")
			{
			$stmt = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('$channel','$server_ip','$exten','$NOW_TIME','$STARTtime','$filename')";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);

			$stmt="SELECT recording_id FROM recording_log where filename='$filename'";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$row=mysql_fetch_row($rslt);
			$recording_id = $row[0];
			}
		else
			{
			$stmt="SELECT recording_id,start_epoch FROM recording_log where filename='$filename'";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$rec_count = mysql_num_rows($rslt);
				if ($rec_count>0)
				{
				$row=mysql_fetch_row($rslt);
				$recording_id = $row[0];
				$start_time = $row[1];
				$length_in_sec = ($STARTtime - $start_time);
				$length_in_min = ($length_in_sec / 60);
				$length_in_min = sprintf("%8.2f", $length_in_min);

				$stmt = "UPDATE recording_log set end_time='$NOW_TIME',end_epoch='$STARTtime',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename'";
					if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				}

			}
		echo "$ACTION command sent for Channel $channel on $server_ip\nFilename: $filename\nRecording_ID: $recording_id\n";
		}
	}
}






######################
# ACTION=MonitorConf or StopMonitorConf  - insert Monitor/StopMonitor Manager statement to start recording on a conference
######################
if ( ($ACTION=="MonitorConf") || ($ACTION=="StopMonitorConf") )
{
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($exten)<3) or (strlen($channel)<4) or (strlen($filename)<15) )
	{
		$channel_live=0;
		echo "Channel $channel is not valid or exten $exten is not valid or filename: $filename is not valid, $ACTION command not inserted\n";
	}
	else
	{

	if ($ACTION=="MonitorConf")
		{
		$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$filename','Channel: $channel','Context; $ext_context','Exten: $exten','Priority: $ext_priority','Callerid: $filename','','','','','');";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);

		$stmt = "INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('$channel','$server_ip','$exten','$NOW_TIME','$STARTtime','$filename')";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);

		$stmt="SELECT recording_id FROM recording_log where filename='$filename'";
		$rslt=mysql_query($stmt, $link);
		if ($DB) {echo "$stmt\n";}
		$row=mysql_fetch_row($rslt);
		$recording_id = $row[0];
		}
	else
		{
		$stmt="SELECT recording_id,start_epoch FROM recording_log where filename='$filename'";
		$rslt=mysql_query($stmt, $link);
		if ($DB) {echo "$stmt\n";}
		$rec_count = mysql_num_rows($rslt);
			if ($rec_count>0)
			{
			$row=mysql_fetch_row($rslt);
			$recording_id = $row[0];
			$start_time = $row[1];
			$length_in_sec = ($STARTtime - $start_time);
			$length_in_min = ($length_in_sec / 60);
			$length_in_min = sprintf("%8.2f", $length_in_min);

			$stmt = "UPDATE recording_log set end_time='$NOW_TIME',end_epoch='$STARTtime',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename'";
				if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			}

		# find and hang up all recordings going on in this conference # and extension = '$exten' 
		$stmt="SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and channel LIKE \"$channel%\" and channel LIKE \"%,1\";";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
	#	$rec_count = intval(mysql_num_rows($rslt) / 2);
		$rec_count = mysql_num_rows($rslt);
		$h=0;
			while ($rec_count>$h)
			{
			$rowx=mysql_fetch_row($rslt);
			$HUchannel[$h] = $rowx[0];
			$h++;
			}
		$i=0;
			while ($h>$i)
			{
			$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Hangup','RH12345$STARTtime$i','Channel: $HUchannel[$i]','','','','','','','','','');";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$i++;
			}

		}
		echo "$ACTION command sent for Channel $channel on $server_ip\nFilename: $filename\nRecording_ID: $recording_id\n RECORDING WILL LAST UP TO 60 MINUTES\n";
	}
}












$ENDtime = date("U");
$RUNtime = ($ENDtime - $STARTtime);
if ($format=='debug') {echo "\n<!-- script runtime: $RUNtime seconds -->";}
if ($format=='debug') {echo "\n</body>\n</html>\n";}
	
exit; 

?>





