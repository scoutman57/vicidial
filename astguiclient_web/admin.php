<?

### AST GUI database administration

### admin.php

$STARTtime = date("U");
$STARTdate = date("Y-m-d H:i:s");

if ($ADD==1) {$process = 'ADD NEW PHONE';}
if ($ADD==11) {$process = 'ADD NEW SERVER';}
if ($ADD==111) {$process = 'ADD NEW CONFERENCE';}
if ($ADD==2) {$process = 'ADDING NEW PHONE';}
if ($ADD==21) {$process = 'ADDING NEW SERVER';}
if ($ADD==211) {$process = 'ADDING NEW CONFERENCE';}
if ($ADD==3) {$process = 'MODIFY PHONE';}
if ($ADD==31) {$process = 'MODIFY SERVER';}
if ($ADD==311) {$process = 'MODIFY CONFERENCE';}
if ($ADD==4) {$process = 'MODIFYING PHONE';}
if ($ADD==41) {$process = 'MODIFYING SERVER';}
if ($ADD==411) {$process = 'MODIFYING CONFERENCE';}
if ($ADD==5) {$process = 'SEARCH PHONES';}
if ($ADD==6) {$process = 'SEARCH PHONES RESULTS';}
if ($ADD==0) {$process = 'PHONE LIST';}
if ($ADD==10) {$process = 'SERVER LIST';}
if ($ADD==100) {$process = 'CONFERENCE LIST';}

$link=mysql_connect("localhost", "cron", "1234");
mysql_select_db("asterisk");

	$stmt="SELECT count(*) from phones where login='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and active = 'Y' and status='ADMIN';";
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
	echo "|$stmt|\n";
    exit;
	}
  else
	{

	if($auth>0)
		{
		$office_no=strtoupper($PHP_AUTH_USER);
		$password=strtoupper($PHP_AUTH_PW);
			$stmt="SELECT fullname from phones where login='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGfullname=$row[0];
		fwrite ($fp, "ASTERISK|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);

		##### get server listing for dynamic pulldown
		$stmt="SELECT server_ip,server_description from servers order by server_ip";
		$rsltx=mysql_query($stmt, $link);
		$servers_to_print = mysql_num_rows($rsltx);
		$servers_list='';

		$o=0;
		while ($servers_to_print > $o)
			{
			$rowx=mysql_fetch_row($rsltx);
			$servers_list .= "<option value=\"$rowx[0]\">$rowx[0] - $rowx[1]</option>\n";
			$o++;
			}

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
<title>ASTERISK ADMIN: Administration - <? echo $process ?></title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER>
<TABLE WIDTH=620 BGCOLOR=#D9E6FE cellpadding=2 cellspacing=0><TR BGCOLOR=#015B91><TD ALIGN=LEFT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B> &nbsp; ASTERISK ADMIN: Administration</TD><TD ALIGN=RIGHT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B><? echo date("l F j, Y G:i:s A") ?> &nbsp; </TD></TR>
<TR BGCOLOR=#F0F5FE><TD ALIGN=LEFT COLSPAN=2><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1><B> &nbsp; <a href="./welcome.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>WELCOME</a> | <a href="<? echo $PHP_SELF ?>"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>LIST ALL PHONES</a> | <a href="<? echo $PHP_SELF ?>?ADD=1"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADD A NEW PHONE</a> | <a href="<? echo $PHP_SELF ?>?ADD=5"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>SEARCH FOR A PHONE</a> | <a href="<? echo $PHP_SELF ?>?ADD=11"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADD A SERVER</a> | <a href="<? echo $PHP_SELF ?>?ADD=10"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>LIST ALL SERVERS</a></TD></TR>
<TR BGCOLOR=#F0F5FE><TD ALIGN=LEFT COLSPAN=2><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1><B> &nbsp; <a href="<? echo $PHP_SELF ?>?ADD=100"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>SHOW ALL CONFERENCES</a> | <a href="<? echo $PHP_SELF ?>?ADD=111"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADD A NEW CONFERENCE</a></TD></TR>



<TR><TD ALIGN=LEFT COLSPAN=2>
<? 
######################
# ADD=1 display the ADD NEW PHONE FORM SCREEN
######################

if ($ADD==1)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>ADD A NEW PHONE<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=2>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone extension: </td><td align=left><input type=text name=extension size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dialplan Number: </td><td align=left><input type=text name=dialplan_number size=10 maxlength=10> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail Box: </td><td align=left><input type=text name=voicemail_id size=10 maxlength=10> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone IP address: </td><td align=left><input type=text name=phone_ip size=20 maxlength=15> (optional)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Computer IP address: </td><td align=left><input type=text name=computer_ip size=20 maxlength=15> (optional)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$campaign_id</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Login: </td><td align=left><input type=text name=login size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Status: </td><td align=left><select size=1 name=status><option>ACTIVE</option><option>SUSPENDED</option><option>CLOSED</option><option>PENDING</option><option>ADMIN</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active Account: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone Type: </td><td align=left><input type=text name=phone_type size=20 maxlength=50></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=fullname size=20 maxlength=50></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Company: </td><td align=left><input type=text name=company size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Picture: </td><td align=left><input type=text name=picture size=20 maxlength=19></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}


######################
# ADD=11 display the ADD NEW SERVERS FORM SCREEN
######################

if ($ADD==11)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>ADD A NEW SERVER<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=21>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server ID: </td><td align=left><input type=text name=server_id size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server Description: </td><td align=left><input type=text name=server_description size=30 maxlength=255></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP Address: </td><td align=left><input type=text name=server_ip size=20 maxlength=15></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}


######################
# ADD=111 display the ADD NEW CONFERENCES FORM SCREEN
######################

if ($ADD==111)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>ADD A NEW CONFERENCE<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=211>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Conference Number: </td><td align=left><input type=text name=list_id size=8 maxlength=7> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$campaign_id</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option SELECTED>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}


######################
# ADD=2 adds the new phone to the system
######################

if ($ADD==2)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";
	$stmt="SELECT count(*) from phones where extension='$extension' and server_ip='$server_ip';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ($row[0] > 0)
		{echo "<br>PHONE NOT ADDED - there is already a Phone in the system with this extension\n";}
	else
		{
		 if ( (strlen($extension) < 1) or (strlen($server_ip) < 7) or (strlen($dialplan_number) < 1) or (strlen($voicemail_id) < 1) or (strlen($login) < 1)  or (strlen($pass) < 1))
			{echo "<br>PHONE NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>PHONE ADDED\n";

			$stmt="INSERT INTO phones (extension,dialplan_number,voicemail_id,phone_ip,computer_ip,server_ip,login,pass,status,active,phone_type,fullname,company,picture) values('$extension','$dialplan_number','$voicemail_id','$phone_ip','$computer_ip','$server_ip','$login','$pass','$status','$active','$phone_type','$fullname','$company','$picture');";
			$rslt=mysql_query($stmt, $link);
			}
		}
$ADD=0;
}

######################
# ADD=21 adds the new server to the system
######################

if ($ADD==21)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";
	$stmt="SELECT count(*) from servers where server_id='$server_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ($row[0] > 0)
		{echo "<br>SERVER NOT ADDED - there is already a server in the system with this ID\n";}
	else
		{
		 if ( (strlen($server_id) < 1) or (strlen($server_ip) < 7) )
			{echo "<br>SERVER NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>SERVER ADDED\n";

			$stmt="INSERT INTO servers (server_id,server_description,server_ip,active) values('$server_id','$server_description','$server_ip','$active');";
			$rslt=mysql_query($stmt, $link);
			}
		}
$ADD=10;
}


######################
# ADD=211 adds the new conference to the system
######################

if ($ADD==211)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";
	$stmt="SELECT count(*) from conferences where conf_exten='$conf_exten' and server_ip='$server_ip';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ($row[0] > 0)
		{echo "<br>CONFERENCE NOT ADDED - there is already a conference in the system with this ID and server\n";}
	else
		{
		 if ( (strlen($conf_exten) < 1) or (strlen($server_ip) < 7) )
			{echo "<br>CONFERENCE NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>CONFERENCE ADDED\n";

			$stmt="INSERT INTO conferences (conf_exten,server_ip) values('$conf_exten','$server_ip');";
			$rslt=mysql_query($stmt, $link);
			}
		}
$ADD=100;
}



######################
# ADD=3 modify phone info in the system
######################

if ($ADD==3)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from phones where extension='$extension' and server_ip='$server_ip';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A PHONE RECORD: $row[1]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=4>\n";
echo "<input type=hidden name=old_extension value=\"$row[0]\">\n";
echo "<input type=hidden name=old_server_ip value=\"$row[5]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone extension: </td><td align=left><input type=text name=extension size=10 maxlength=10 value=\"$row[0]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dialplan Number: </td><td align=left><input type=text name=dialplan_number size=10 maxlength=10 value=\"$row[1]\"> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail Box: </td><td align=left><input type=text name=voicemail_id size=10 maxlength=10 value=\"$row[2]\"> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone IP address: </td><td align=left><input type=text name=phone_ip size=20 maxlength=15 value=\"$row[3]\"> (optional)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Computer IP address: </td><td align=left><input type=text name=computer_ip size=20 maxlength=15 value=\"$row[4]\"> (optional)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[5]</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Login: </td><td align=left><input type=text name=login size=10 maxlength=10 value=\"$row[6]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=10 maxlength=10 value=\"$row[7]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Status: </td><td align=left><select size=1 name=status><option>ACTIVE</option><option>SUSPENDED</option><option>CLOSED</option><option>PENDING</option><option>ADMIN</option><option selected>$row[8]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active Account: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[9]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone Type: </td><td align=left><input type=text name=phone_type size=20 maxlength=50 value=\"$row[10]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=fullname size=20 maxlength=50 value=\"$row[11]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Company: </td><td align=left><input type=text name=company size=10 maxlength=10 value=\"$row[12]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Picture: </td><td align=left><input type=text name=picture size=20 maxlength=19 value=\"$row[13]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>New Messages: </td><td align=left><b>$row[14]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Old Messages: </td><td align=left><b>$row[15]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<br><br><a href=\"./phone_stats.php?extension=$row[0]&server_ip=$row[5]\">Click here for phone stats</a>\n";

}


######################
# ADD=31 modify server info in the system
######################

if ($ADD==31)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from servers where server_id='$server_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A SERVER RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=41>\n";
echo "<input type=hidden name=old_server_id value=\"$server_id\">\n";
echo "<input type=hidden name=old_server_ip value=\"$row[2]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server ID: </td><td align=left><input type=text name=server_id size=10 maxlength=10 value=\"$row[0]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server Description: </td><td align=left><input type=text name=server_description size=30 maxlength=255 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP Address: </td><td align=left><input type=text name=server_ip size=20 maxlength=15 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[3]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<center>\n";
echo "<br><b>PHONES WITHIN THIS SERVER:</b><br>\n";
echo "<TABLE width=400 cellspacing=3>\n";
echo "<tr><td>EXTENSION</td><td>NAME</td><td>ACTIVE</td></tr>\n";

	$active_lists = 0;
	$inactive_lists = 0;
	$stmt="SELECT extension,active,fullname from phones where server_ip='$row[2]'";
	$rsltx=mysql_query($stmt, $link);
	$lists_to_print = mysql_num_rows($rsltx);
	$camp_lists='';

	$o=0;
	while ($lists_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
		$o++;
	if (ereg("Y", $rowx[1])) {$active_lists++;   $camp_lists .= "'$rowx[0]',";}
	if (ereg("N", $rowx[1])) {$inactive_lists++;}

	if (eregi("1$|3$|5$|7$|9$", $o))
		{$bgcolor='bgcolor="#B9CBFD"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';}

	echo "<tr $bgcolor><td><font size=1><a href=\"$PHP_SELF?ADD=3&extension=$rowx[0]&server_ip=$row[2]\">$rowx[0]</a></td><td><font size=1>$rowx[2]</td><td><font size=1>$rowx[1]</td></tr>\n";

	}

echo "</table></center><br>\n";
echo "<center><b>\n";

	$camp_lists = eregi_replace(".$","",$camp_lists);
echo "This server has $active_lists active phones and $inactive_lists inactive phones<br><br>\n";
echo "</b></center>\n";
}


######################
# ADD=311 modify conference info in the system
######################

if ($ADD==311)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from conferences where conf_exten='$conf_exten' and server_ip='$server_ip';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A CONFERENCE RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=411>\n";
echo "<input type=hidden name=old_conf_exten value=\"$row[0]\">\n";
echo "<input type=hidden name=old_server_ip value=\"$row[1]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Conference: </td><td align=left><input type=text name=conf_exten size=10 maxlength=7 value=\"$row[0]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[1]</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Current Extension: </td><td align=left><input type=text name=extension size=20 maxlength=20 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<center><b>\n";

}



######################
# ADD=4 submit phone modifications to the system
######################

if ($ADD==4)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT count(*) from phones where extension='$extension' and server_ip='$server_ip';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ( ($row[0] > 0) && ( ($extension != $old_extension) or ($server_ip != $old_server_ip) ) )
		{echo "<br>PHONE NOT MODIFIED - there is already a Phone in the system with this extension-server\n";}
	else
		{
			 if ( (strlen($extension) < 1) or (strlen($server_ip) < 7) or (strlen($dialplan_number) < 1) or (strlen($voicemail_id) < 1) or (strlen($login) < 1)  or (strlen($pass) < 1))
			{echo "<br>PHONE NOT MODIFIED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>PHONE MODIFIED: $extension\n";

			$stmt="UPDATE phones set extension='$extension', dialplan_number='$dialplan_number', voicemail_id='$voicemail_id', phone_ip='$phone_ip', computer_ip='$computer_ip', server_ip='$server_ip', login='$login', pass='$pass', status='$status', active='$active', phone_type='$phone_type', fullname='$fullname', company='$company', picture='$picture' where extension='$old_extension' and server_ip='$old_server_ip';";
			$rslt=mysql_query($stmt, $link);
			}
		}

	$stmt="SELECT * from phones where extension='$extension' and server_ip='$server_ip';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A PHONE RECORD: $row[1]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=4>\n";
echo "<input type=hidden name=old_extension value=\"$row[0]\">\n";
echo "<input type=hidden name=old_server_ip value=\"$row[5]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone extension: </td><td align=left><input type=text name=extension size=10 maxlength=10 value=\"$row[0]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dialplan Number: </td><td align=left><input type=text name=dialplan_number size=10 maxlength=10 value=\"$row[1]\"> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail Box: </td><td align=left><input type=text name=voicemail_id size=10 maxlength=10 value=\"$row[2]\"> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone IP address: </td><td align=left><input type=text name=phone_ip size=20 maxlength=15 value=\"$row[3]\"> (optional)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Computer IP address: </td><td align=left><input type=text name=computer_ip size=20 maxlength=15 value=\"$row[4]\"> (optional)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[5]</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Login: </td><td align=left><input type=text name=login size=10 maxlength=10 value=\"$row[6]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=10 maxlength=10 value=\"$row[7]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Status: </td><td align=left><select size=1 name=status><option>ACTIVE</option><option>SUSPENDED</option><option>CLOSED</option><option>PENDING</option><option>ADMIN</option><option selected>$row[8]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active Account: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[9]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone Type: </td><td align=left><input type=text name=phone_type size=20 maxlength=50 value=\"$row[10]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=fullname size=20 maxlength=50 value=\"$row[11]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Company: </td><td align=left><input type=text name=company size=10 maxlength=10 value=\"$row[12]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Picture: </td><td align=left><input type=text name=picture size=20 maxlength=19 value=\"$row[13]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>New Messages: </td><td align=left><b>$row[14]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Old Messages: </td><td align=left><b>$row[15]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<br><br><a href=\"./phone_stats.php?extension=$row[0]&server_ip=$row[5]\">Click here for phone stats</a>\n";

}

######################
# ADD=41 submit server modifications to the system
######################

if ($ADD==41)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT count(*) from servers where server_id='$server_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ( ($row[0] > 0) && ($server_id != $old_server_id) )
		{echo "<br>SERVER NOT MODIFIED - there is already a server in the system with this server_id\n";}
	else
		{
		$stmt="SELECT count(*) from servers where server_ip='$server_ip';";
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ( ($row[0] > 0) && ($server_ip != $old_server_ip) )
			{echo "<br>SERVER NOT MODIFIED - there is already a server in the system with this server_ip\n";}
		else
			{
			 if ( (strlen($server_id) < 1) or (strlen($server_ip) < 7) )
				{echo "<br>SERVER NOT MODIFIED - Please go back and look at the data you entered\n";}
			 else
				{
				echo "<br>SERVER MODIFIED: $campaign_id\n";

				$stmt="UPDATE servers set server_id='$server_id',server_description='$server_description',server_ip='$server_ip',active='$active' where server_id='$old_server_id';";
				$rslt=mysql_query($stmt, $link);
				}
			}
		}

	$stmt="SELECT * from servers where server_id='$server_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A SERVER RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=41>\n";
echo "<input type=hidden name=old_server_id value=\"$server_id\">\n";
echo "<input type=hidden name=old_server_ip value=\"$row[2]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server ID: </td><td align=left><input type=text name=server_id size=10 maxlength=10 value=\"$row[0]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server Description: </td><td align=left><input type=text name=server_description size=30 maxlength=255 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP Address: </td><td align=left><input type=text name=server_ip size=20 maxlength=15 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[3]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<center>\n";
echo "<br><b>PHONES WITHIN THIS SERVER:</b><br>\n";
echo "<TABLE width=400 cellspacing=3>\n";
echo "<tr><td>EXTENSION</td><td>NAME</td><td>ACTIVE</td></tr>\n";

	$active_lists = 0;
	$inactive_lists = 0;
	$stmt="SELECT extension,active,fullname from phones where server_ip='$row[2]'";
	$rsltx=mysql_query($stmt, $link);
	$lists_to_print = mysql_num_rows($rsltx);
	$camp_lists='';

	$o=0;
	while ($lists_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
		$o++;
	if (ereg("Y", $rowx[1])) {$active_lists++;   $camp_lists .= "'$rowx[0]',";}
	if (ereg("N", $rowx[1])) {$inactive_lists++;}

	if (eregi("1$|3$|5$|7$|9$", $o))
		{$bgcolor='bgcolor="#B9CBFD"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';}

	echo "<tr $bgcolor><td><font size=1><a href=\"$PHP_SELF?ADD=3&extension=$rowx[0]&server_ip=$row[2]\">$rowx[0]</a></td><td><font size=1>$rowx[2]</td><td><font size=1>$rowx[1]</td></tr>\n";

	}

echo "</table></center><br>\n";
echo "<center><b>\n";

	$camp_lists = eregi_replace(".$","",$camp_lists);
echo "This server has $active_lists active phones and $inactive_lists inactive phones<br><br>\n";
echo "</b></center>\n";

}

######################
# ADD=411 submit conference modifications to the system
######################

if ($ADD==411)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT count(*) from conferences where conf_exten='$conf_exten' and server_ip='$server_ip';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ( ($row[0] > 0) && ( ($conf_exten != $old_conf_exten) or ($server_ip != $old_server_ip) ) )
		{echo "<br>CONFERENCE NOT MODIFIED - there is already a Conference in the system with this extension-server\n";}
	else
		{
		 if ( (strlen($conf_exten) < 1) or (strlen($server_ip) < 7) )
			{echo "<br>CONFERENCE NOT MODIFIED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>CONFERENCE MODIFIED: $conf_exten\n";

			$stmt="UPDATE conferences set conf_exten='$conf_exten',server_ip='$server_ip',extension='$extension' where conf_exten='$old_conf_exten';";
			$rslt=mysql_query($stmt, $link);
			}
		}

	$stmt="SELECT * from conferences where conf_exten='$conf_exten';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A CONFERENCE RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=411>\n";
echo "<input type=hidden name=old_conf_exten value=\"$row[0]\">\n";
echo "<input type=hidden name=old_server_ip value=\"$row[1]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Conference: </td><td align=left><input type=text name=conf_exten size=10 maxlength=7 value=\"$row[0]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[1]</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Current Extension: </td><td align=left><input type=text name=extension size=20 maxlength=20 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<center><b>\n";

}


######################
# ADD=5 search form
######################

if ($ADD==5)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>SEARCH FOR A PHONE<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=6>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>extension: </td><td align=left><input type=text name=extension size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=fullname size=30 maxlength=30></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone type: </td><td align=left><input type=text name=phone_type size=30 maxlength=30></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=search value=search></td></tr>\n";
echo "</TABLE></center>\n";

}

######################
# ADD=6 user search results
######################

if ($ADD==6)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$SQL = '';
	if ($extension) {$SQL .= "user LIKE \"%$extension%\" and";}
	if ($fullname) {$SQL .= "fullname LIKE \"%$fullname%\" and";}
	if ($phone_type) {$SQL .= "phone_type LIKE \"%$phone_type%\" and";}
	$SQL = eregi_replace(" and$", "", $SQL);
	if (strlen($SQL)>5) {$SQL = "where $SQL";}

	$stmt="SELECT * from phones $SQL order by extension,server_ip;";
#	echo "\n|$stmt|\n";
	$rslt=mysql_query($stmt, $link);
	$phones_to_print = mysql_num_rows($rslt);

echo "<br>SEARCH RESULTS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($phones_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[0]</td><td><font size=1>$row[5]</td><td><font size=1>$row[1]</td><td><font size=1>$row[2]</td><td><font size=1>$row[8]</td><td><font size=1>$row[11]</td><td><font size=1>$row[14]</td><td><font size=1>$row[15]</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=3&extension=$row[0]&server_ip=$row[5]\">MODIFY</a> | <a href=\"./phone_stats.php?extension=$row[0]&server_ip=$row[5]\">STATS</a></td></tr>\n";
		$o++;
	}

echo "</TABLE></center>\n";

}



######################
# ADD=0 display all active users
######################
if ($ADD==0)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from phones order by extension,server_ip";
	$rslt=mysql_query($stmt, $link);
	$phones_to_print = mysql_num_rows($rslt);

echo "<br>PHONE LISTINGS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($phones_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[0]</td><td><font size=1>$row[5]</td><td><font size=1>$row[1]</td><td><font size=1>$row[2]</td><td><font size=1>$row[8]</td><td><font size=1>$row[11]</td><td><font size=1>$row[14]</td><td><font size=1>$row[15]</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=3&extension=$row[0]&server_ip=$row[5]\">MODIFY</a> | <a href=\"./phone_stats.php?extension=$row[0]&server_ip=$row[5]\">STATS</a></td></tr>\n";
		$o++;
	}

echo "</TABLE></center>\n";
}

######################
# ADD=10 display all servers
######################
if ($ADD==10)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from servers order by server_id";
	$rslt=mysql_query($stmt, $link);
	$phones_to_print = mysql_num_rows($rslt);

echo "<br>SERVER LISTINGS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($phones_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[0]</td><td><font size=1>$row[1]</td>";
		echo "<td><font size=1> $row[2]</td>";
		echo "<td><font size=1> $row[3]</td><td><font size=1> &nbsp;</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=31&server_id=$row[0]\">MODIFY</a></td></tr>\n";
		$o++;
	}

echo "</TABLE></center>\n";
}


######################
# ADD=100 display all conferences
######################
if ($ADD==100)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from conferences order by conf_exten";
	$rslt=mysql_query($stmt, $link);
	$phones_to_print = mysql_num_rows($rslt);

echo "<br>CONFERENCE LISTINGS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($phones_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[0]</td>";
		echo "<td><font size=1> $row[1]</td>";
		echo "<td><font size=1> $row[2]</td><td><font size=1>$row[4]</td><td><font size=1> &nbsp;</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=311&conf_exten=$row[0]&server_ip=$row[1]\">MODIFY</a></td></tr>\n";
		$o++;
	}

echo "</TABLE></center>\n";
}



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





