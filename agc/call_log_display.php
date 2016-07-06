<?
### call_log_display.php

### This script is designed purely to send the inbound and outbound calls for a specific phone
### This script depends on the server_ip being sent and also needs to have a valid user/pass from the vicidial_users table
### 
### required variables:
###  - $server_ip
###  - $session_name
###  - $PHP_AUTH_USER
###  - $PHP_AUTH_PW
### optional variables:
###  - $format - ('text','debug')
###  - $exten - ('cc101','testphone','49-1','1234','913125551212',...)
###  - $protocol - ('SIP','Zap','IAX2',...)
###  - $in_limit - ('10','20','50','100',...)
###  - $out_limit - ('10','20','50','100',...)
### 

# changes
# 50406-1013 First build of script
# 50407-1452 Added definable limits
# 50503-1236 added session_name checking for extra security
# 50610-1158 Added NULL check on MySQL results to reduced errors
# 


require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$server_ip=$_GET["server_ip"];			if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$session_name=$_GET["session_name"];	if (!$session_name) {$session_name=$_POST["session_name"];}
$format=$_GET["format"];				if (!$format) {$format=$_POST["format"];}
$exten=$_GET["exten"];					if (!$exten) {$exten=$_POST["exten"];}
$protocol=$_GET["protocol"];			if (!$protocol) {$protocol=$_POST["protocol"];}

# default optional vars if not set
if (!$format)		{$format="text";}
if (!$in_limit)		{$in_limit="100";}
if (!$out_limit)	{$out_limit="100";}

$version = '0.0.4';
$build = '50610-1158';
$STARTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
if (!$query_date) {$query_date = $NOW_DATE;}

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 0;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
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
			Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
			Header("HTTP/1.0 401 Unauthorized");
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
echo "<!-- VERSION: $version     BUILD: $build    EXTEN: $exten   server_ip: $server_ip-->\n";
echo "<title>Call Log Display";
echo "</title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
}


	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($exten)<1) or (strlen($protocol)<3) )
	{
	$channel_live=0;
	echo "Exten $exten is not valid or protocol $protocol is not valid\n";
	exit;
	}
	else
	{
	##### print outbound calls from the call_log table
	$stmt="SELECT uniqueid,start_time,number_dialed,length_in_sec FROM call_log where server_ip = '$server_ip' and channel LIKE \"$protocol/$exten%\" order by start_time desc limit $out_limit;";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$out_calls_count = mysql_num_rows($rslt);}
	echo "$out_calls_count|";
	$loop_count=0;
		while ($out_calls_count>$loop_count)
		{
		$loop_count++;
		$row=mysql_fetch_row($rslt);

		$call_time_M = ($row[3] / 60);
		$call_time_M = round($call_time_M, 2);
		$call_time_M_int = intval("$call_time_M");
		$call_time_SEC = ($call_time_M - $call_time_M_int);
		$call_time_SEC = ($call_time_SEC * 60);
		$call_time_SEC = round($call_time_SEC, 0);
		if ($call_time_SEC < 10) {$call_time_SEC = "0$call_time_SEC";}
		$call_time_MS = "$call_time_M_int:$call_time_SEC";

		echo "$row[0] ~$row[1] ~$row[2] ~$call_time_MS|";
		}
	echo "\n";

	##### print inbound calls from the live_inbound_log table
	$stmt="SELECT call_log.uniqueid,live_inbound_log.start_time,live_inbound_log.extension,caller_id,length_in_sec from live_inbound_log,call_log where phone_ext='$exten' and live_inbound_log.server_ip = '$server_ip' and call_log.uniqueid=live_inbound_log.uniqueid order by start_time desc limit $in_limit;";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$in_calls_count = mysql_num_rows($rslt);}
	echo "$in_calls_count|";
	$loop_count=0;
		while ($in_calls_count>$loop_count)
		{
		$loop_count++;
		$row=mysql_fetch_row($rslt);

		$call_time_M = ($row[4] / 60);
		$call_time_M = round($call_time_M, 2);
		$call_time_M_int = intval("$call_time_M");
		$call_time_SEC = ($call_time_M - $call_time_M_int);
		$call_time_SEC = ($call_time_SEC * 60);
		$call_time_SEC = round($call_time_SEC, 0);
		if ($call_time_SEC < 10) {$call_time_SEC = "0$call_time_SEC";}
		$call_time_MS = "$call_time_M_int:$call_time_SEC";
		$callerIDnum = $row[3];   $callerIDname = $row[3];
		$callerIDnum = preg_replace("/.*<|>.*/","",$callerIDnum);
		$callerIDname = preg_replace("/\"| <\d*>/","",$callerIDname);

		echo "$row[0] ~$row[1] ~$row[2] ~$callerIDnum ~$callerIDname ~$call_time_MS|";
		}
	echo "\n";

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
