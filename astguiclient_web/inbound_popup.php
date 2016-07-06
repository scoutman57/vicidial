<?

require(".dbconnect.php");

require_once(".htglobalize.php");

### If you have globals turned off uncomment these lines
//$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
//$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
//$ADD=$_GET["ADD"];
### AST GUI database administration
### inbound_popup.php

# this is the inbound popup of a specific call that grabs the call and allows you to go and fetch info on that caller in the local CRM system.


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$popup_page = './inbound_popup.php';
$FILE_datetime = $STARTtime;

$ext_context = 'demo';
if (!$begin_date) {$begin_date = $TODAY;}
if (!$end_date) {$end_date = $TODAY;}

#$link=mysql_connect("localhost", "cron", "1234");
#mysql_select_db("asterisk");

	$stmt="SELECT count(*) from phones where login='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and active = 'Y' and status IN('ACTIVE','ADMIN');";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-ASTERISK\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
    exit;
	}
  else
	{

	if($auth>0)
		{
		$office_no=strtoupper($PHP_AUTH_USER);
		$password=strtoupper($PHP_AUTH_PW);
			$stmt="SELECT fullname,dialplan_number from phones where login='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
		fwrite ($fp, "ASTERISK|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);

		##### get server listing for dynamic pulldown
		$stmt="SELECT fullname,dialplan_number,server_ip from phones where login='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
		if ($DB) {echo "$stmt\n";}
		$rsltx=mysql_query($stmt, $link);
		$rowx=mysql_fetch_row($rsltx);
		$fullname = $rowx[0];
		$dialplan_number = $rowx[1];
		$user_server_ip = $rowx[2];
		if ($DB) {echo "|$rowx[0]|$rowx[1]|$rowx[2]|\n";}
		}
	else
		{
		fwrite ($fp, "ASTERISK|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}

?>
<html>
<head>
<title>ASTERISK REMOTE INBOUND: Popup</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER><FONT FACE="Courier" COLOR=BLACK SIZE=3>

<? 

$stmt="SELECT count(*) from parked_channels where server_ip='$user_server_ip' and parked_time='$parked_time' and channel='$channel'";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$parked_count = $row[0];

if ($parked_count > 0)
{

	$stmt="DELETE from parked_channels where server_ip='$user_server_ip' and parked_time='$parked_time' and channel='$channel' LIMIT 1";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	$DTqueryCID = "RR$FILE_datetime$PHP_AUTH_USER";

	### insert a NEW record to the vicidial_manager table to be processed
	$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$user_server_ip','','Redirect','$DTqueryCID','Exten: $dialplan_number','Channel: $channel','Context: $ext_context','Priority: 1','Callerid: $DTqueryCID','','','','','')";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	echo "Redirect command sent for channel $channel &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";


   $url = 'https://10.10.10.15/internal/back_end_systems/cust_serv/index.php?Search=SEARCH&';
	$Suser = 'username=';
	$Spass = '&passwd=';
	$Sphone = '&phone=';

   $newurl = "$url$Suser$PHP_AUTH_USER$Spass$PHP_AUTH_PW$Sphone$phone";
	if ( ($phone == 'unknown') or (strlen($phone)<9) )
	{$newurl = "$url$Suser$PHP_AUTH_USER$Spass$PHP_AUTH_PW";}

	echo "<a href=\"$newurl\">Look up this customer in Customer Service System</a>\n<BR><BR>\n";

	echo "<a href=\"$PHP_SELF\">Close this window</a>\n<BR><BR>\n";
}
else
{
	echo "Redirect command FAILED for channel $channel &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";
	echo "<a href=\"$PHP_SELF\">Close this window</a>\n<BR><BR>\n";
}



$ENDtime = date("U");

$RUNtime = ($ENDtime - $STARTtime);

echo "\n\n\n<br><br><br>\n\n";


echo "<font size=0>\n\n\n<br><br><br>\nscript runtime: $RUNtime seconds</font>";


?>


</body>
</html>

<?
	
exit; 



?>





