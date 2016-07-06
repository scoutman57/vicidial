<?

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
//$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
//$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
//$ADD=$_GET["ADD"];
### AST GUI database administration
### remote_dispo.php

# this is the remote agent disposition screen for calls sent to remote agents. This allows the remote agent to modify customer information and disposition the call


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$FILE_datetime = $STARTtime;

$ext_context = 'demo';
if (!$begin_date) {$begin_date = $TODAY;}
if (!$end_date) {$end_date = $TODAY;}

#$link=mysql_connect("localhost", "cron", "1234");
#mysql_select_db("asterisk");

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 2;";
		if ($DB) {echo "$stmt\n";}
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

?>
<html>
<head>
<title>VICIDIAL REMOTE: Call Disposition</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER><FONT FACE="Courier" COLOR=BLACK SIZE=3>

<? 

echo "<!-- $call_began $lead_id -->";

if ($end_call > 0)
{

$call_length = ($STARTtime - $call_began);

	### insert a NEW record to the vicidial_closer_log table 
	$stmt="UPDATE vicidial_closer_log set end_epoch='$STARTtime', length_in_sec='$call_length', status='$status', user='$PHP_AUTH_USER' where lead_id='$lead_id' order by start_epoch desc limit 1;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	### update the lead record in the vicidial_list table 
	$stmt="UPDATE vicidial_list set status='$status',first_name='$first_name',last_name='$last_name',address1='$address1',address2='$address2',address3='$address3',city='$city',state='$state',province='$province',postal_code='$postal_code',country_code='$country_code',alt_phone='$alt_phone',email='$email',security_phrase='$security',comments='$comments',user='$PHP_AUTH_USER' where lead_id='$lead_id'";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	echo "Call has been dispositioned &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";

	echo "<form><input type=button value=\"Close This Window\" onClick=\"javascript:window.close();\"></form>\n";

}
else
{
	$stmt="SELECT count(*) from vicidial_list where lead_id='$lead_id'";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$row=mysql_fetch_row($rslt);
	$lead_count = $row[0];

	if ($lead_count > 0)
	{

		$stmt="SELECT * from vicidial_list where lead_id='$lead_id'";
		$rslt=mysql_query($stmt, $link);
		if ($DB) {echo "$stmt\n";}
		$row=mysql_fetch_row($rslt);
		   $lead_id			= "$row[0]";
		   $tsr				= "$row[4]";
		   $vendor_id		= "$row[5]";
		   $list_id			= "$row[7]";
		   $campaign_id		= "$row[8]";
		   $phone_code		= "$row[10]";
		   $phone_number	= "$row[11]";
		   $title			= "$row[12]";
		   $first_name		= "$row[13]";	#
		   $middle_initial	= "$row[14]";
		   $last_name		= "$row[15]";	#
		   $address1		= "$row[16]";	#
		   $address2		= "$row[17]";	#
		   $address3		= "$row[18]";	#
		   $city			= "$row[19]";	#
		   $state			= "$row[20]";	#
		   $province		= "$row[21]";	#
		   $postal_code		= "$row[22]";	#
		   $country_code	= "$row[23]";	#
		   $gender			= "$row[24]";
		   $date_of_birth	= "$row[25]";
		   $alt_phone		= "$row[26]";	#
		   $email			= "$row[27]";	#
		   $security		= "$row[28]";	#
		   $comments		= "$row[29]";	#

		echo "<br>Call information: $first_name $last_name - $phone_number<br><br><form action=$PHP_SELF method=POST>\n";
		echo "<input type=hidden name=end_call value=1>\n";
		echo "<input type=hidden name=DB value=\"$DB\">\n";
		echo "<input type=hidden name=lead_id value=\"$lead_id\">\n";
		echo "<input type=hidden name=list_id value=\"$list_id\">\n";
		echo "<input type=hidden name=campaign_id value=\"$campaign_id\">\n";
		echo "<input type=hidden name=phone_code value=\"$phone_code\">\n";
		echo "<input type=hidden name=phone_number value=\"$phone_number\">\n";
		echo "<input type=hidden name=server_ip value=\"$server_ip\">\n";
		echo "<input type=hidden name=extension value=\"$extension\">\n";
		echo "<input type=hidden name=channel value=\"$channel\">\n";
		echo "<input type=hidden name=call_began value=\"$call_began\">\n";
		echo "<input type=hidden name=parked_time value=\"$parked_time\">\n";
		echo "<table cellpadding=1 cellspacing=0>\n";
		echo "<tr><td colspan=2>Vendor ID: $vendor_id &nbsp; &nbsp; Campaign ID: $campaign_id</td></tr>\n";
		echo "<tr><td colspan=2>Fronter: $tsr &nbsp; &nbsp; List ID: $list_id</td></tr>\n";
		echo "<tr><td align=right>First Name: </td><td align=left><input type=text name=first_name size=15 maxlength=30 value=\"$first_name\"> &nbsp; \n";
		echo " Last Name: <input type=text name=last_name size=15 maxlength=30 value=\"$last_name\"> </td></tr>\n";
		echo "<tr><td align=right>Address 1 : </td><td align=left><input type=text name=address1 size=30 maxlength=30 value=\"$address1\"></td></tr>\n";
		echo "<tr><td align=right>Address 2 : </td><td align=left><input type=text name=address2 size=30 maxlength=30 value=\"$address2\"></td></tr>\n";
		echo "<tr><td align=right>Address 3 : </td><td align=left><input type=text name=address3 size=30 maxlength=30 value=\"$address3\"></td></tr>\n";
		echo "<tr><td align=right>City : </td><td align=left><input type=text name=city size=30 maxlength=30 value=\"$city\"></td></tr>\n";
		echo "<tr><td align=right>State: </td><td align=left><input type=text name=state size=2 maxlength=2 value=\"$state\"> &nbsp; \n";
		echo " Postal Code: <input type=text name=postal_code size=10 maxlength=10 value=\"$postal_code\"> </td></tr>\n";

		echo "<tr><td align=right>Province : </td><td align=left><input type=text name=province size=30 maxlength=30 value=\"$province\"></td></tr>\n";
		echo "<tr><td align=right>Country : </td><td align=left><input type=text name=country_code size=3 maxlength=3 value=\"$country_code\"></td></tr>\n";
		echo "<tr><td align=right>Alt Phone : </td><td align=left><input type=text name=alt_phone size=10 maxlength=10 value=\"$alt_phone\"></td></tr>\n";
		echo "<tr><td align=right>Email : </td><td align=left><input type=text name=email size=30 maxlength=50 value=\"$email\"></td></tr>\n";
		echo "<tr><td align=right>Security : </td><td align=left><input type=text name=security size=30 maxlength=100 value=\"$security\"></td></tr>\n";
		echo "<tr><td align=right>Comments : </td><td align=left><input type=text name=comments size=30 maxlength=255 value=\"$comments\"></td></tr>\n";
			echo "<tr bgcolor=#B6D3FC><td align=right>Disposition: </td><td align=left><select size=1 name=status>\n";

				$stmt="SELECT * from vicidial_statuses where selectable='Y' order by status";
				$rsltx=mysql_query($stmt, $link);
				$statuses_to_print = mysql_num_rows($rsltx);
				$statuses_list='';

				$o=0;
				while ($statuses_to_print > $o) {
					$rowx=mysql_fetch_row($rsltx);
					$statuses_list .= "<option value=\"$rowx[0]\">$rowx[0] - $rowx[1]</option>\n";
					$o++;
				}
			echo "$statuses_list";
			echo "</select></td></tr>\n";


		echo "<tr><td colspan=2><input type=submit name=submit value=\"DISPO CALL\"></td></tr>\n";
		echo "</table></form>\n";
		echo "<BR><BR><BR>\n";

	}
	else
	{
		echo "lead lookup FAILED for lead_id $lead_id &nbsp; &nbsp; &nbsp; $NOW_TIME\n<BR><BR>\n";
#		echo "<a href=\"$PHP_SELF\">Close this window</a>\n<BR><BR>\n";
	}






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





