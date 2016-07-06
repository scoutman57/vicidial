<?
### conf_exten_check.php

### This script is designed purely to send whether the meetme conference has live channels connected and which they are
### This script depends on the server_ip being sent and also needs to have a valid user/pass from the vicidial_users table
### 
### required variables:
###  - $server_ip
###  - $session_name
###  - $user
###  - $pass
### optional variables:
###  - $format - ('text','debug')
###  - $ACTION - ('refresh','register')
###  - $client - ('agc','vdc')
###  - $conf_exten - ('8600011',...)
###  - $exten - ('123test',...)
### 

# changes
# 50509-1054 First build of script
# 50511-1112 Added ability to register a conference room
# 50610-1159 Added NULL check on MySQL results to reduced errors
# 50706-1429 script changed to not use HTTP login vars, user/pass instead
# 50706-1525 Added date-time display for vicidial client display
#

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
$user=$_GET["user"];					if (!$user) {$user=$_POST["user"];}
$pass=$_GET["pass"];					if (!$pass) {$pass=$_POST["pass"];}
$server_ip=$_GET["server_ip"];			if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$session_name=$_GET["session_name"];	if (!$session_name) {$session_name=$_POST["session_name"];}
$format=$_GET["format"];				if (!$format) {$format=$_POST["format"];}
$ACTION=$_GET["ACTION"];				if (!$ACTION) {$ACTION=$_POST["ACTION"];}
$client=$_GET["client"];				if (!$client) {$client=$_POST["client"];}
$conf_exten=$_GET["conf_exten"];		if (!$conf_exten) {$conf_exten=$_POST["conf_exten"];}
$exten=$_GET["exten"];					if (!$exten) {$exten=$_POST["exten"];}

# default optional vars if not set
if (!$format)	{$format="text";}
if (!$ACTION)	{$ACTION="refresh";}
if (!$client)	{$client="agc";}

$version = '0.0.5';
$build = '50706-1525';
$STARTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$FILE_TIME = date("Ymd_His");
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
echo "<!-- VERSION: $version     BUILD: $build    MEETME: $conf_exten   server_ip: $server_ip-->\n";
echo "<title>Conf Extension Check";
echo "</title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
}

	if ($ACTION == 'refresh')
	{
		$MT[0]='';
		$row='';   $rowx='';
		$channel_live=1;
		if (strlen($conf_exten)<1)
		{
		$channel_live=0;
		echo "Conf Exten $conf_exten is not valid\n";
		exit;
		}
		else
		{

		if ($client == 'vdc')
			{
			echo "DateTime: $NOW_TIME|";
			echo "UnixTime: $STARTtime|";
			echo "\n";
			}
		$total_conf=0;
		$stmt="SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and extension = '$conf_exten';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		if ($rslt) {$sip_list = mysql_num_rows($rslt);}
	#	echo "$sip_list|";
		$loop_count=0;
			while ($sip_list>$loop_count)
			{
			$loop_count++; $total_conf++;
			$row=mysql_fetch_row($rslt);
			$ChannelA[$total_conf] = "$row[0]";
			if ($format=='debug') {echo "\n<!-- $row[0] -->";}
			}
		$stmt="SELECT channel FROM live_channels where server_ip = '$server_ip' and extension = '$conf_exten';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		if ($rslt) {$channels_list = mysql_num_rows($rslt);}
	#	echo "$channels_list|";
		$loop_count=0;
		while ($channels_list>$loop_count)
			{
			$loop_count++; $total_conf++;
			$row=mysql_fetch_row($rslt);
			$ChannelA[$total_conf] = "$row[0]";
			if ($format=='debug') {echo "\n<!-- $row[0] -->";}
			}
		}
		$channels_list = ($channels_list + $sip_list);
		echo "$channels_list|";

		$counter=0;
		while($total_conf > $counter)
		{
			$counter++;
			echo "$ChannelA[$counter] ~";
		}

	echo "\n";
	}

	if ($ACTION == 'register')
	{
		$MT[0]='';
		$row='';   $rowx='';
		$channel_live=1;
		if ( (strlen($conf_exten)<1) || (strlen($exten)<1) )
		{
		$channel_live=0;
		echo "Conf Exten $conf_exten is not valid or Exten $exten is not valid\n";
		exit;
		}
		else
		{
		$stmt="UPDATE conferences set extension='$exten' where server_ip = '$server_ip' and conf_exten = '$conf_exten';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		}
		echo "conference $conf_exten has been registered to $exten\n";
	}



if ($format=='debug') 
	{
	$ENDtime = date("U");
	$RUNtime = ($ENDtime - $STARTtime);
	echo "\n<!-- script runtime: $RUNtime seconds -->";
	echo "\n</body>\n</html>\n";
	}
	
exit; 

?>
