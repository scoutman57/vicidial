<?

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
//$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
//$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
//$ADD=$_GET["ADD"];
### AST GUI database administration
### closer.php

# the purpose of this script and webpage is to allow for remote or local users of the system to log in and grab phone calls that are coming inbound into the Asterisk server and being put in the parked_channels table while they hear a soundfile for a limited amount of time before being forwarded on to either a set extension or a voicemail box. This gives remote or local agents a way to grab calls without tying up their phone lines all day. The agent sees the refreshing screen of calls on park and when they want to take one they just click on it, and a small window opens that will allow them to grab the call and/or look up more information on the caller through the callerID that is given(if available)


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$popup_page = './closer_popup.php';

if (!$begin_date) {$begin_date = $TODAY;}
if (!$end_date) {$end_date = $TODAY;}

#$link=mysql_connect("localhost", "cron", "1234");
#mysql_select_db("asterisk");

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 2;";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICIDIAL-CLOSER\"");
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
			$stmt="SELECT full_name from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
			$fullname = $row[0];
		fwrite ($fp, "VD_CLOSER|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);

		}
	else
		{
		fwrite ($fp, "VD_CLOSER|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}

	echo"<HTML><HEAD>\n";
	echo"<TITLE>VICIDIAL CLOSER: Main</TITLE></HEAD>\n";
	echo"</HEAD>\n";

?>

<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER><FONT FACE="Courier" COLOR=BLACK SIZE=3>

<? 

if (!$dialplan_number)
{

	if ($extension)
	{
	$stmt="SELECT count(*) from phones where extension='$extension';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$ext_found=$row[0];
		if ($ext_found > 0)
		{
		$stmt="SELECT dialplan_number,server_ip from phones where extension='$extension';";
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$dialplan_number=$row[0];
		$server_ip=$row[1];
	
		$stmt="INSERT INTO vicidial_user_log values('','$user','LOGIN','CLOSER','$NOW_TIME','$STARTtime');";
		$rslt=mysql_query($stmt, $link);

		echo"<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">\n";
		echo"<META HTTP-EQUIV=Refresh CONTENT=\"3; URL=$PHP_SELF?dialplan_number=$dialplan_number&server_ip=$server_ip&extension=$extension&DB=$DB\">\n";

		echo "<font=green><b>extension found, forwarding you to closer page, please wait 3 seconds...</b></font>\n";

		}
		else
		{
		echo "<font=red><b>The extension you entered does not exist, please try again</b></font>\n";
		echo "<br>Please enter your phone_ID: <form action=$PHP_SELF method=POST>\n";
		echo "<input type=hidden name=PHONE_LOGIN value=1>\n";
		echo "phone station ID: <input type=text name=extension size=10 maxlength=10 value=\"$extension\"> &nbsp; \n";
		echo "<input type=submit name=submit value=submit>\n";
		echo "<BR><BR><BR>\n";
		}

	}
	else
	{
	echo "<br>Please enter your phone_ID: <form action=$PHP_SELF method=POST>\n";
	echo "<input type=hidden name=PHONE_LOGIN value=1>\n";
	echo "phone station ID: <input type=text name=extension size=10 maxlength=10> &nbsp; \n";
	echo "<input type=submit name=submit value=submit>\n";
	echo "<BR><BR><BR>\n";
	}

exit;

}

echo"<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">\n";
echo"<META HTTP-EQUIV=Refresh CONTENT=\"5; URL=$PHP_SELF?dialplan_number=$dialplan_number&server_ip=$server_ip&extension=$extension&DB=$DB\">\n";

#CHANNEL    SERVER        CHANNEL_GROUP   EXTENSION    PARKED_BY            PARKED_TIME        
#----------------------------------------------------------------------------------------------
#Zap/73-1   10.10.11.11   IN_800_TPP_CS   TPPpark      7275338730           2004-04-22 12:41:00



echo "$NOW_TIME &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; $PHP_AUTH_USER - $fullname -  CALLS SENT TO: $dialplan_number<BR><BR>\n";

echo "Click on the channel below that you would like to have directed to your phone<BR><BR>\n";

echo "<PRE>\n";
echo "CHANNEL    SERVER        CHANNEL_GROUP   EXTENSION    PARKED_BY            PARKED_TIME        \n";
echo "----------------------------------------------------------------------------------------------\n";





$stmt="SELECT count(*) from parked_channels where server_ip='$server_ip' order by parked_time";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$parked_count = $row[0];
	if ($parked_count > 0)
	{
	$stmt="SELECT * from parked_channels where server_ip='$server_ip' and channel_group LIKE \"CL_%\" order by parked_time";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$parked_to_print = mysql_num_rows($rslt);
	$i=0;
	while ($i < $parked_to_print)
		{
		$row=mysql_fetch_row($rslt);
		$channel =			sprintf("%-11s", $row[0]);
		$server =			sprintf("%-14s", $row[1]);
		$channel_group =	sprintf("%-16s", $row[2]);
		$park_extension =	sprintf("%-13s", $row[3]);
		$parked_by =		sprintf("%-21s", $row[4]);
		$parked_time =		sprintf("%-19s", $row[5]);

		echo "<A HREF=\"$popup_page?channel=$row[0]&server_ip=$server_ip&parked_by=$row[4]&parked_time=$row[5]&dialplan_number=$dialplan_number&extension=$extension&DB=$DB\" target=\"_blank\">$channel</A>$server$channel_group$park_extension$parked_by$parked_time\n";

#	
		$i++;
		}

	}
	else
	{
	echo "**********************************************************************************************\n";
	echo "**********************************************************************************************\n";
	echo "*************************************** NO PARKED CALLS **************************************\n";
	echo "**********************************************************************************************\n";
	echo "**********************************************************************************************\n";
	}


$ENDtime = date("U");

$RUNtime = ($ENDtime - $STARTtime);

echo "</PRE>\n\n\n<br><br><br>\n\n";


echo "<font size=0>\n\n\n<br><br><br>\nscript runtime: $RUNtime seconds</font>";


?>


</body>
</html>

<?
	
exit; 



?>





