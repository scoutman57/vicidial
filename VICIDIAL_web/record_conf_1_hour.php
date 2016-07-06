<?

# grab: $server_ip $station $session_id

$server_ip = '10.0.0.12';

$STARTtime = date("U");
$TODAY = date("Y-m-d");
$MYSQL_datetime = date("Y-m-d H:i:s");
$FILE_datetime = date("Ymd-His_");
$secX = $STARTtime;

if (!$begin_date) {$begin_date = $TODAY;}
if (!$end_date) {$end_date = $TODAY;}

### modify to suite your MySQL server
$link=mysql_connect("10.0.0.10", "cron", "test");
mysql_select_db("asterisk");

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 7;";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("/home/www/ssldocs/vici/project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
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
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
		fwrite ($fp, "VICIDIAL|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);
		}
	else
		{
		fwrite ($fp, "VICIDIAL|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}

	$stmt="SELECT full_name from vicidial_users where user='$user';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$full_name = $row[0];

	}




?>
<html>
<head>
<title>VICIDIAL RECORD CONFERENCE: 1 hour</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER>

<? 
if ($NEW_RECORDING)
{
	if ( (strlen($server_ip) > 8) && (strlen($session_id) > 3) && (strlen($station) > 3) )
	{
	$local_DEF = 'Local/';
	$local_AMP = '@';
	$conf_silent_prefix = '7';
	$ext_context = 'demo';

	$stmt="INSERT INTO vicidial_manager values('','','$MYSQL_datetime','NEW','N','$server_ip','','Originate','RB$FILE_datetime$station','Channel: $local_DEF$conf_silent_prefix$session_id$local_AMP$ext_context','Context: $ext_context','Exten: 8309','Priority: 1','Callerid: $FILE_datetime$station','','','','','')";
	echo "|$stmt|\n<BR><BR>\n";
	$rslt=mysql_query($stmt, $link);

	$stmt="INSERT INTO recording_log (channel,server_ip,extension,start_time,start_epoch,filename) values('$session_id','$server_ip','$station','$MYSQL_datetime','$secX','$FILE_datetime$station')";
	echo "|$stmt|\n<BR><BR>\n";
	$rslt=mysql_query($stmt, $link);

	echo "Recording started\n<BR><BR>\n";
	echo "<a href=\"$PHP_SELF\">Back to main recording screen</a>\n<BR><BR>\n";
	}
	else
	{
	echo "ERROR!!!!    Not all info entered properly\n<BR><BR>\n";
	echo "|$server_ip| |$session_id| |$station|\n<BR><BR>\n";
	echo "<a href=\"$PHP_SELF\">Back to main recording screen</a>\n<BR><BR>\n";
	}
}
else
{
echo "<br>Start recording a conference for 1 hour: <form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=NEW_RECORDING value=1>\n";
echo "server_ip: <input type=text name=server_ip size=15 maxlength=15> | \n";
echo "session_id: <input type=text name=session_id size=7 maxlength=7> | \n";
echo "station: <input type=text name=station size=5 maxlength=5> | \n";
echo "<input type=submit name=submit value=submit>\n";
echo "<BR><BR><BR>\n";



}
?>

</BODY></HTML>