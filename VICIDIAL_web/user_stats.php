<?

### user_stats.php

$STARTtime = date("U");
$TODAY = date("Y-m-d");

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
<title>VICIDIAL ADMIN: User Stats</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER>
<TABLE WIDTH=620 BGCOLOR=#D9E6FE cellpadding=2 cellspacing=0><TR BGCOLOR=#015B91><TD ALIGN=LEFT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B> &nbsp; VICIDIAL ADMIN: User Stats for <? echo $user ?></TD><TD ALIGN=RIGHT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B><? echo date("l F j, Y G:i:s A") ?> &nbsp; </TD></TR>




<? 

echo "<TR BGCOLOR=\"#F0F5FE\"><TD ALIGN=LEFT COLSPAN=2><FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2><B> &nbsp; \n";

echo "<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=user value=\"$user\">\n";
echo "<input type=text name=begin_date value=\"$begin_date\" size=10 maxsize=10> to \n";
echo "<input type=text name=end_date value=\"$end_date\" size=10 maxsize=10> &nbsp;\n";
echo "<input type=submit name=submit value=submit>\n";


echo " &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; $user - $full_name\n";

echo "</B></TD></TR>\n";
echo "<TR><TD ALIGN=LEFT COLSPAN=2>\n";


	$stmt="SELECT count(*),status, sum(length_in_sec) from vicidial_log where user='$user' and call_date >= '$begin_date 0:00:01'  and call_date <= '$end_date 23:59:59' group by status order by status";
	$rslt=mysql_query($stmt, $link);
	$statuses_to_print = mysql_num_rows($rslt);

echo "<br><center>\n";

echo "<B>TALK TIME AND STATUS:</B>\n";

echo "<center><TABLE width=300 cellspacing=0 cellpadding=1>\n";
echo "<tr><td><font size=2>STATUS </td><td align=right><font size=2> COUNT</td><td align=right><font size=2> HOURS:MINUTES</td></tr>\n";

	$total_calls=0;
	$o=0;
	while ($statuses_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}

		$call_seconds = $row[2];
		$call_hours = ($call_seconds / 3600);
		$call_hours = round($call_hours, 2);
		$call_hours_int = intval("$call_hours");
		$call_minutes = ($call_hours - $call_hours_int);
		$call_minutes = ($call_minutes * 60);
		$call_minutes_int = round($call_minutes, 0);
		if ($call_minutes_int < 10) {$call_minutes_int = "0$call_minutes_int";}

		echo "<tr $bgcolor><td><font size=2>$row[1]</td>";
		echo "<td align=right><font size=2> $row[0]</td>\n";
		echo "<td align=right><font size=2> $call_hours_int:$call_minutes_int</td></tr>\n";
		$total_calls = ($total_calls + $row[0]);

		$call_seconds=0;
		$o++;
	}

	$stmt="SELECT sum(length_in_sec) from vicidial_log where user='$user' and call_date >= '$begin_date 0:00:01'  and call_date <= '$end_date 23:59:59'";
	$rslt=mysql_query($stmt, $link);
	$counts_to_print = mysql_num_rows($rslt);
		$row=mysql_fetch_row($rslt);
	$call_seconds = $row[0];
	$call_hours = ($call_seconds / 3600);
	$call_hours = round($call_hours, 2);
	$call_hours_int = intval("$call_hours");
	$call_minutes = ($call_hours - $call_hours_int);
	$call_minutes = ($call_minutes * 60);
	$call_minutes_int = round($call_minutes, 0);
	if ($call_minutes_int < 10) {$call_minutes_int = "0$call_minutes_int";}

echo "<tr><td><font size=2>TOTAL CALLS </td><td align=right><font size=2> $total_calls</td><td align=right><font size=2> $call_hours_int:$call_minutes_int</td></tr>\n";
echo "</TABLE></center>\n";
echo "<br><br>\n";

echo "<center>\n";

echo "<B>LOGIN/LOGOUT TIME:</B>\n";
echo "<TABLE width=400 cellspacing=0 cellpadding=1>\n";
echo "<tr><td><font size=2>EVENT </td><td align=right><font size=2> DATE</td><td align=right><font size=2> CAMPAIGN</td><td align=right><font size=2> HOURS:MINUTES</td></tr>\n";

	$stmt="SELECT event,event_epoch,event_date,campaign_id from vicidial_user_log where user='$user' and event_date >= '$begin_date 0:00:01'  and event_date <= '$end_date 23:59:59'";
	$rslt=mysql_query($stmt, $link);
	$events_to_print = mysql_num_rows($rslt);

	$total_calls=0;
	$o=0;
	$event_start_seconds='';
	$event_stop_seconds='';
	while ($events_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("LOGIN", $row[0]))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}

		if (ereg("LOGIN", $row[0]))
			{
			$event_start_seconds = $row[1];
			echo "<tr $bgcolor><td><font size=2>$row[0]</td>";
			echo "<td align=right><font size=2> $row[2]</td>\n";
			echo "<td align=right><font size=2> $row[3]</td>\n";
			echo "<td align=right><font size=2> </td></tr>\n";
			}
		if (ereg("LOGOUT", $row[0]))
			{
			if ($event_start_seconds)
				{
				$event_stop_seconds = $row[1];
				$event_seconds = ($event_stop_seconds - $event_start_seconds);
				$total_login_time = ($total_login_time + $event_seconds);
				$event_hours = ($event_seconds / 3600);
				$event_hours = round($event_hours, 2);
				$event_hours_int = intval("$event_hours");
				$event_minutes = ($event_hours - $event_hours_int);
				$event_minutes = ($event_minutes * 60);
				$event_minutes_int = round($event_minutes, 0);
				if ($event_minutes_int < 10) {$event_minutes_int = "0$event_minutes_int";}
				echo "<tr $bgcolor><td><font size=2>$row[0]</td>";
				echo "<td align=right><font size=2> $row[2]</td>\n";
				echo "<td align=right><font size=2> $row[3]</td>\n";
				echo "<td align=right><font size=2> $event_hours_int:$event_minutes_int</td></tr>\n";
				$event_start_seconds='';
				$event_stop_seconds='';
				}
			else
				{
				echo "<tr $bgcolor><td><font size=2>$row[0]</td>";
				echo "<td align=right><font size=2> $row[2]</td>\n";
				echo "<td align=right><font size=2> $row[3]</td>\n";
				echo "<td align=right><font size=2> </td></tr>\n";
				}
			}

		$total_calls = ($total_calls + $row[0]);

		$call_seconds=0;
		$o++;
	}

$total_login_hours = ($total_login_time / 3600);
$total_login_hours = round($total_login_hours, 2);
$total_login_hours_int = intval("$total_login_hours");
$total_login_minutes = ($total_login_hours - $total_login_hours_int);
$total_login_minutes = ($total_login_minutes * 60);
$total_login_minutes_int = round($total_login_minutes, 0);
if ($total_login_minutes_int < 10) {$total_login_minutes_int = "0$total_login_minutes_int";}

echo "<tr><td><font size=2>TOTAL</td>";
echo "<td align=right><font size=2> </td>\n";
echo "<td align=right><font size=2> </td>\n";
echo "<td align=right><font size=2> $total_login_hours_int:$total_login_minutes_int</td></tr>\n";

echo "</TABLE></center>\n";


$ENDtime = date("U");

$RUNtime = ($ENDtime - $STARTtime);

echo "\n\n\n<br><br><br>\n\n";


echo "<font size=0>\n\n\n<br><br><br>\nscript runtime: $RUNtime seconds</font>";


?>


</TD></TR><TABLE>
</body>
</html>

<?
	
exit; 



?>





