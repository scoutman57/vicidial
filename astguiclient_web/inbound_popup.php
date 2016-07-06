<?
### inbound_popup.php
### 
### Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
###
# this is the inbound popup of a specific call that grabs the call and allows you to go and fetch info on that caller in the local CRM system.

require("dbconnect.php");

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
$vendor_id=$_GET["vendor_id"];				if (!$vendor_id) {$vendor_id=$_POST["vendor_id"];}
$phone=$_GET["phone"];						if (!$phone) {$phone=$_POST["phone"];}
$lead_id=$_GET["lead_id"];					if (!$lead_id) {$lead_id=$_POST["lead_id"];}
$first_name=$_GET["first_name"];			if (!$first_name) {$first_name=$_POST["first_name"];}
$last_name=$_GET["last_name"];				if (!$last_name) {$last_name=$_POST["last_name"];}
$phone_number=$_GET["phone_number"];		if (!$phone_number) {$phone_number=$_POST["phone_number"];}
$end_call=$_GET["end_call"];				if (!$end_call) {$end_call=$_POST["end_call"];}
$DB=$_GET["DB"];							if (!$DB) {$DB=$_POST["DB"];}
$dispo=$_GET["dispo"];						if (!$dispo) {$dispo=$_POST["dispo"];}
$list_id=$_GET["list_id"];					if (!$list_id) {$list_id=$_POST["list_id"];}
$campaign_id=$_GET["campaign_id"];			if (!$campaign_id) {$campaign_id=$_POST["campaign_id"];}
$phone_code=$_GET["phone_code"];			if (!$phone_code) {$phone_code=$_POST["phone_code"];}
$server_ip=$_GET["server_ip"];				if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$extension=$_GET["extension"];				if (!$extension) {$extension=$_POST["extension"];}
$channel=$_GET["channel"];					if (!$channel) {$channel=$_POST["channel"];}
$call_began=$_GET["call_began"];			if (!$call_began) {$call_began=$_POST["call_began"];}
$parked_time=$_GET["parked_time"];			if (!$parked_time) {$parked_time=$_POST["parked_time"];}
$tsr=$_GET["tsr"];							if (!$tsr) {$tsr=$_POST["tsr"];}
$address1=$_GET["address1"];				if (!$address1) {$address1=$_POST["address1"];}
$address2=$_GET["address2"];				if (!$address2) {$address2=$_POST["address2"];}
$address3=$_GET["address3"];				if (!$address3) {$address3=$_POST["address3"];}
$city=$_GET["city"];						if (!$city) {$city=$_POST["city"];}
$state=$_GET["state"];						if (!$state) {$state=$_POST["state"];}
$postal_code=$_GET["postal_code"];			if (!$postal_code) {$postal_code=$_POST["postal_code"];}
$province=$_GET["province"];				if (!$province) {$province=$_POST["province"];}
$country_code=$_GET["country_code"];		if (!$country_code) {$country_code=$_POST["country_code"];}
$alt_phone=$_GET["alt_phone"];				if (!$alt_phone) {$alt_phone=$_POST["alt_phone"];}
$email=$_GET["email"];						if (!$email) {$email=$_POST["email"];}
$security=$_GET["security"];				if (!$security) {$security=$_POST["security"];}
$comments=$_GET["comments"];				if (!$comments) {$comments=$_POST["comments"];}
$status=$_GET["status"];					if (!$status) {$status=$_POST["status"];}
$submit=$_GET["submit"];					if (!$submit) {$submit=$_POST["submit"];}
$SUBMIT=$_GET["SUBMIT"];					if (!$SUBMIT) {$SUBMIT=$_POST["SUBMIT"];}


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





