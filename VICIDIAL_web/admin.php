<?

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
//$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
//$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
//$ADD=$_GET["ADD"];
### AST GUI database administration
### admin.php

### make sure you have added a user to the vicidial_users MySQL table with at least user_level 8 to access this page the first time

$STARTtime = date("U");

#$link=mysql_connect("10.10.11.10", "cron", "1234");
#mysql_select_db("asterisk");

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 7;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

$fp = fopen ("./project_auth_entries.txt", "a");
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
	}

echo "<html>\n";
echo "<head>\n";
echo "<title>VICIDIAL ADMIN: ";

if ($ADD==1)	{echo "Add New User";}
if ($ADD==11)	{echo "Add New Campaign";}
if ($ADD==111)	{echo "Add New List";}
if ($ADD==1111)	{echo "Add New In-Group";}
if ($ADD==2)	{echo "New User Addition";}
if ($ADD==21)	{echo "New Campaign Addition";}
if ($ADD==211)	{echo "New List Addition";}
if ($ADD==2111)	{echo "New In-Group Addition";}
if ($ADD==3)	{echo "Modify User";}
if ($ADD==31)	{echo "Modify Campaign";}
if ($ADD==311)	{echo "Modify List";}
if ($ADD==3111)	{echo "Modify In-Group";}
if ($ADD==4)	{echo "Modify User";}
if ($ADD==41)	{echo "Modify Campaign";}
if ($ADD==411)	{echo "Modify List";}
if ($ADD==4111)	{echo "Modify In-Group";}
if ($ADD==0)	{echo "Welcome";}
if ($ADD==10)	{echo "Campaigns";}
if ($ADD==100)	{echo "Lists";}
if ($ADD==1000)	{echo "In-Groups";}
if ($ADD==5)	{echo "Search Form";}
if ($ADD==6)	{echo "Search Results";}
?>
</title>
</head>
<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>
<CENTER>
<TABLE WIDTH=620 BGCOLOR=#D9E6FE cellpadding=2 cellspacing=0><TR BGCOLOR=#015B91><TD ALIGN=LEFT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B> &nbsp; VICIDIAL ADMIN: Administration</TD><TD ALIGN=RIGHT><FONT FACE="ARIAL,HELVETICA" COLOR=WHITE SIZE=2><B><? echo date("l F j, Y G:i:s A") ?> &nbsp; </TD></TR>
<TR BGCOLOR=#F0F5FE><TD ALIGN=LEFT COLSPAN=2><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1><B> &nbsp; <a href="./welcome.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>WELCOME</a> | <a href="<? echo $PHP_SELF ?>"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>LIST ALL USERS</a> | <a href="<? echo $PHP_SELF ?>?ADD=1"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADD A NEW USER</a> | <a href="<? echo $PHP_SELF ?>?ADD=5"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>SEARCH FOR A USER</a> | <a href="<? echo $PHP_SELF ?>?ADD=11"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADD A CAMPAIGN</a> | <a href="<? echo $PHP_SELF ?>?ADD=10"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>LIST ALL CAMPAIGNS</a></TD></TR>
<TR BGCOLOR=#F0F5FE><TD ALIGN=LEFT COLSPAN=2><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1><B> &nbsp; <a href="<? echo $PHP_SELF ?>?ADD=100"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>SHOW ALL LISTS</a> | <a href="<? echo $PHP_SELF ?>?ADD=111"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADD A NEW LIST</a> | <a href="<? echo $PHP_SELF ?>?ADD=1000"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>SHOW ALL IN-GROUPS</a> | <a href="<? echo $PHP_SELF ?>?ADD=1111"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>ADD A NEW IN-GROUP</a></TD></TR>
<TR BGCOLOR=#F0F5FE><TD ALIGN=LEFT COLSPAN=2><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1><B> &nbsp; <a href="server_stats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>SERVER STATS</a> | <a href="AST_parkstats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>PARK REPORT</a> | <a href="AST_VDADstats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>VDAD REPORT</a> | <a href="AST_CLOSERstats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>CLOSER REPORT</a> | &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; | <a href="admin_search_lead.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>SEARCH FOR A LEAD</a> | <a href="group_hourly_stats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=1>GROUP HOURLY</a></TD></TR>


<TR><TD ALIGN=LEFT COLSPAN=2>
<? 
######################
# ADD=1 display the ADD NEW USER FORM SCREEN
######################

if ($ADD==1)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>ADD A NEW USER<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=2>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Number: </td><td align=left><input type=text name=user size=20 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=20 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=full_name size=20 maxlength=100></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Level: </td><td align=left><select size=1 name=user_level><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option><option>7</option><option>8</option><option>9</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}


######################
# ADD=11 display the ADD NEW CAMPAIGN FORM SCREEN
######################

if ($ADD==11)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>ADD A NEW CAMPAIGN<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=21>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Campaign ID: </td><td align=left><input type=text name=campaign_id size=8 maxlength=8></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Campaign Name: </td><td align=left><input type=text name=campaign_name size=30 maxlength=30></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Park Extension: </td><td align=left><input type=text name=park_ext size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Park Filename: </td><td align=left><input type=text name=park_file_name size=10 maxlength=10></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Web Form: </td><td align=left><input type=text name=web_form_address size=50 maxlength=255></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Allow Closers: </td><td align=left><select size=1 name=allow_closers><option>Y</option><option>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Hopper Level: </td><td align=left><select size=1 name=hopper_level><option>1</option><option>5</option><option>10</option><option>50</option><option>100</option><option>200</option><option>500</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Auto Dial Level: </td><td align=left><select size=1 name=auto_dial_level><option selected>0</option><option>1</option><option>1.1</option><option>1.2</option><option>1.3</option><option>1.4</option><option>1.5</option><option>1.6</option><option>1.7</option><option>1.8</option><option>1.9</option><option>2.0</option><option>2.2</option><option>2.5</option><option>2.7</option><option>3.0</option></select>(0 = off)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Next Agent Call: </td><td align=left><select size=1 name=next_agent_call><option >random</option><option>oldest_call_start</option><option>oldest_call_finish</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Local Call Time: </td><td align=left><select size=1 name=local_call_time><option >24hours</option><option >9am-9pm</option><option>9am-5pm</option><option>12pm-5pm</option><option>12pm-9pm</option><option>5pm-9pm</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail: </td><td align=left><input type=text name=voicemail_ext size=10 maxlength=10 value=\"$voicemail_ext\"></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}


######################
# ADD=111 display the ADD NEW LIST FORM SCREEN
######################

if ($ADD==111)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>ADD A NEW LIST<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=211>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>List ID: </td><td align=left><input type=text name=list_id size=8 maxlength=8> (digits only)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>List Name: </td><td align=left><input type=text name=list_name size=20 maxlength=20></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Campaign: </td><td align=left><select size=1 name=campaign_id>\n";

	$stmt="SELECT campaign_id,campaign_name from vicidial_campaigns order by campaign_id";
	$rsltx=mysql_query($stmt, $link);
	$campaigns_to_print = mysql_num_rows($rsltx);
	$campaigns_list='';

	$o=0;
	while ($campaigns_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
		$campaigns_list .= "<option value=\"$rowx[0]\">$rowx[0] - $rowx[1]</option>\n";
		$o++;
	}
echo "$campaigns_list";
echo "<option SELECTED>$campaign_id</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option SELECTED>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}


######################
# ADD=1111 display the ADD NEW INBOUND GROUP SCREEN
######################

if ($ADD==1111)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>ADD A NEW INBOUND GROUP<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=2111>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group ID: </td><td align=left><input type=text name=group_id size=20 maxlength=20> (no spaces)</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group Name: </td><td align=left><input type=text name=group_name size=30 maxlength=30></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group Color: </td><td align=left><input type=text name=group_color size=7 maxlength=7></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option SELECTED>Y</option><option>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Web Form: </td><td align=left><input type=text name=web_form_address size=50 maxlength=255 value=\"$web_form_address\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail: </td><td align=left><input type=text name=voicemail_ext size=10 maxlength=10 value=\"$voicemail_ext\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Next Agent Call: </td><td align=left><select size=1 name=next_agent_call><option >random</option><option>oldest_call_start</option><option>oldest_call_finish</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}


######################
# ADD=2 adds the new person to the system
######################

if ($ADD==2)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";
	$stmt="SELECT count(*) from vicidial_users where user='$user';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ($row[0] > 0)
		{echo "<br>USER NOT ADDED - there is already a user in the system with this user number\n";}
	else
		{
		 if ( (strlen($user) < 2) or (strlen($pass) < 2) or (strlen($full_name) < 2) )
			{echo "<br>USER NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>USER ADDED\n";

			$stmt="INSERT INTO vicidial_users values('','$user','$pass','$full_name','$user_level');";
			$rslt=mysql_query($stmt, $link);

			### LOG CHANGES TO LOG FILE ###
			$fp = fopen ("./admin_changes_log.txt", "a");
			fwrite ($fp, "$date|ADD A USER          |$PHP_AUTH_USER|$ip|'$user','$pass','$full_name','$user_level'|\n");
			fclose($fp);
			}
		}
$ADD=0;
}

######################
# ADD=21 adds the new campaign to the system
######################

if ($ADD==21)
{

	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";
	$stmt="SELECT count(*) from vicidial_campaigns where campaign_id='$campaign_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ($row[0] > 0)
		{echo "<br>CAMPAIGN NOT ADDED - there is already a campaign in the system with this ID\n";}
	else
		{
		 if ( (strlen($campaign_id) < 2) or (strlen($campaign_name) < 2) )
			{echo "<br>CAMPAIGN NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>CAMPAIGN ADDED\n";

			$stmt="INSERT INTO vicidial_campaigns values('$campaign_id','$campaign_name','$active','','','','','','DOWN','$park_ext','$park_file_name','$web_form_address','$allow_closers','$hopper_level','$auto_dial_level','$next_agent_call','$local_call_time','$voicemail_ext');";
			$rslt=mysql_query($stmt, $link);

			### LOG CHANGES TO LOG FILE ###
			$fp = fopen ("./admin_changes_log.txt", "a");
			fwrite ($fp, "$date|ADD A NEW CAMPAIGN  |$PHP_AUTH_USER|$ip|'$campaign_id','$campaign_name','$active','','','','','','DOWN','$park_ext','$park_file_name','$web_form_address','$allow_closers','$hopper_level','$auto_dial_level','$next_agent_call','$local_call_time','$voicemail_ext'|\n");
			fclose($fp);

			}
		}
$ADD=10;
}


######################
# ADD=211 adds the new list to the system
######################

if ($ADD==211)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";
	$stmt="SELECT count(*) from vicidial_lists where list_id='$list_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ($row[0] > 0)
		{echo "<br>LIST NOT ADDED - there is already a list in the system with this ID\n";}
	else
		{
		 if ( (strlen($campaign_id) < 2) or (strlen($list_name) < 2)  or (strlen($list_id) < 2) )
			{echo "<br>LIST NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>LIST ADDED\n";

			$stmt="INSERT INTO vicidial_lists values('$list_id','$list_name','$campaign_id','$active');";
			$rslt=mysql_query($stmt, $link);

			### LOG CHANGES TO LOG FILE ###
			$fp = fopen ("./admin_changes_log.txt", "a");
			fwrite ($fp, "$date|ADD A NEW LIST      |$PHP_AUTH_USER|$ip|'$list_id','$list_name','$campaign_id','$active'|\n");
			fclose($fp);

			}
		}
$ADD=100;
}



######################
# ADD=2111 adds the new inbound group to the system
######################

if ($ADD==2111)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";
	$stmt="SELECT count(*) from vicidial_inbound_groups where group_id='$group_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	if ($row[0] > 0)
		{echo "<br>GROUP NOT ADDED - there is already a group in the system with this ID\n";}
	else
		{
		 if ( (strlen($group_id) < 2) or (strlen($group_name) < 2)  or (strlen($group_color) < 2) )
			{echo "<br>GROUP NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			$stmt="INSERT INTO vicidial_inbound_groups values('$group_id','$group_name','$group_color','$active','$web_form_address','$voicemail_ext','$next_agent_call');";
			$rslt=mysql_query($stmt, $link);

			echo "<br>GROUP ADDED\n";

			### LOG CHANGES TO LOG FILE ###
			$fp = fopen ("./admin_changes_log.txt", "a");
			fwrite ($fp, "$date|ADD A NEW GROUP     |$PHP_AUTH_USER|$ip|'$group_id','$group_name','$group_color','$active','$web_form_address','$voicemail_ext','$next_agent_call'|\n");
			fclose($fp);

			}
		}
$ADD=1000;
}


######################
# ADD=3 modify user info in the system
######################

if ($ADD==3)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from vicidial_users where user='$user';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A USER'S RECORD: $row[1]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=4>\n";
echo "<input type=hidden name=user value=\"$row[1]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Number: </td><td align=left><b>$row[1]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=20 maxlength=10 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=full_name size=30 maxlength=30 value=\"$row[3]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Level: </td><td align=left><select size=1 name=user_level><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option><option>7</option><option>8</option><option>9</option><option SELECTED>$row[4]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<br><br><a href=\"./user_stats.php?user=$row[1]\">Click here for user stats</a>\n";

}


######################
# ADD=31 modify campaign info in the system
######################

if ($ADD==31)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from vicidial_campaigns where campaign_id='$campaign_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$dial_status_a = $row[3];
	$dial_status_b = $row[4];
	$dial_status_c = $row[5];
	$dial_status_d = $row[6];
	$dial_status_e = $row[7];
	$lead_order = $row[8];
	$hopper_level = $row[13];
	$auto_dial_level = $row[14];
	$next_agent_call = $row[15];
	$local_call_time = $row[16];
	$voicemail_ext = $row[17];

echo "<br>MODIFY A CAMPAIGN'S RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=41>\n";
echo "<input type=hidden name=campaign_id value=\"$campaign_id\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Campaign ID: </td><td align=left><b>$row[0]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Campaign Name: </td><td align=left><input type=text name=campaign_name size=40 maxlength=40 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option SELECTED>$row[2]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Park Extension: </td><td align=left>$row[9] - $row[10]</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Web Form: </td><td align=left>$row[11]</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Allow Closers: </td><td align=left><select size=1 name=allow_closers><option>Y</option><option>N</option><option SELECTED>$row[12]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 1: </td><td align=left><select size=1 name=dial_status_a>\n";

	$stmt="SELECT * from vicidial_statuses order by status";
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
echo "<option SELECTED>$dial_status_a</option>\n";
echo "</select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 2: </td><td align=left><select size=1 name=dial_status_b>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_b</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 3: </td><td align=left><select size=1 name=dial_status_c>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_c</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 4: </td><td align=left><select size=1 name=dial_status_d>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_d</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 5: </td><td align=left><select size=1 name=dial_status_e>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_e</option>\n";
echo "</select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>List Order: </td><td align=left><select size=1 name=lead_order><option>DOWN</option><option>UP</option><option>UP PHONE</option><option>DOWN PHONE</option><option>UP LAST NAME</option><option>DOWN LAST NAME</option><option>UP COUNT</option><option>DOWN COUNT</option><option>DOWN COUNT 2nd NEW</option><option>DOWN COUNT 3rd NEW</option><option>DOWN COUNT 4th NEW</option><option SELECTED>$lead_order</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Hopper Level: </td><td align=left><select size=1 name=hopper_level><option>1</option><option>5</option><option>10</option><option>50</option><option>100</option><option>200</option><option>500</option><option SELECTED>$hopper_level</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Force Reset of Hopper: </td><td align=left><select size=1 name=reset_hopper><option>Y</option><option SELECTED>N</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Auto Dial Level: </td><td align=left><select size=1 name=auto_dial_level><option >0</option><option>1</option><option>1.1</option><option>1.2</option><option>1.3</option><option>1.4</option><option>1.5</option><option>1.6</option><option>1.7</option><option>1.8</option><option>1.9</option><option>2.0</option><option>2.2</option><option>2.5</option><option>2.7</option><option>3.0</option><option SELECTED>$auto_dial_level</option></select>(0 = off)</td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Next Agent Call: </td><td align=left><select size=1 name=next_agent_call><option >random</option><option>oldest_call_start</option><option>oldest_call_finish</option><option SELECTED>$next_agent_call</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Local Call Time: </td><td align=left><select size=1 name=local_call_time><option >24hours</option><option >9am-9pm</option><option>9am-5pm</option><option>12pm-5pm</option><option>12pm-9pm</option><option>5pm-9pm</option><option SELECTED>$local_call_time</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail: </td><td align=left><input type=text name=voicemail_ext size=10 maxlength=10 value=\"$voicemail_ext\"></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

	##### calculate what gmt_offset_now values are within the allowed local_call_time setting
	if ($local_call_time == '24hours')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '9am-9pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 9) && ($phour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '9am-5pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 9) && ($phour <= 16) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '12pm-5pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 12) && ($phour <= 16) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '12pm-9pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 12) && ($phour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '5pm-9pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 17) && ($phour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}

	$GMT_allowed = "$GMT_allowed'99'";










echo "<center>\n";
echo "<br><b>LISTS WITHIN THIS CAMPAIGN:</b><br>\n";
echo "<TABLE width=400 cellspacing=3>\n";
echo "<tr><td>LIST ID</td><td>LIST NAME</td><td>ACTIVE</td></tr>\n";

	$active_lists = 0;
	$inactive_lists = 0;
	$stmt="SELECT list_id,active,list_name from vicidial_lists where campaign_id='$campaign_id'";
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

	echo "<tr $bgcolor><td><font size=1><a href=\"$PHP_SELF?ADD=311&list_id=$rowx[0]\">$rowx[0]</a></td><td><font size=1>$rowx[2]</td><td><font size=1>$rowx[1]</td></tr>\n";

	}

echo "</table></center><br>\n";
echo "<center><b>\n";

	$camp_lists = eregi_replace(".$","",$camp_lists);
echo "This campaign has $active_lists active lists and $inactive_lists inactive lists<br><br>\n";
	$stmt="SELECT count(*) FROM vicidial_list where called_since_last_reset='N' and status IN('$dial_status_a','$dial_status_b','$dial_status_c','$dial_status_d','$dial_status_e') and list_id IN($camp_lists) and gmt_offset_now IN($GMT_allowed)";
	if ($DB) {echo "$stmt\n";}
	$rsltx=mysql_query($stmt, $link);
	$rsltx_rows = mysql_num_rows($rsltx);
	if ($rsltx_rows)
		{
		$rowx=mysql_fetch_row($rsltx);
		$active_leads = "$rowx[0]";
		}
	else {$active_leads = '0';}

echo "This campaign has $active_leads leads to be dialed in those lists<br><br>\n";
	$stmt="SELECT count(*) FROM vicidial_hopper where campaign_id='$campaign_id' and status IN('READY')";
	if ($DB) {echo "$stmt\n";}
	$rsltx=mysql_query($stmt, $link);
	$rowx=mysql_fetch_row($rsltx);
	$hopper_leads = "$rowx[0]";

echo "This campaign has $hopper_leads leads in the dial hopper<br><br>\n";
echo "</b></center>\n";

}


######################
# ADD=311 modify list info in the system
######################

if ($ADD==311)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from vicidial_lists where list_id='$list_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$campaign_id = $row[2];
	$active = $row[3];

echo "<br>MODIFY A LIST'S RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=411>\n";
echo "<input type=hidden name=list_id value=\"$row[0]\">\n";
echo "<input type=hidden name=old_campaign_id value=\"$row[2]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>List ID: </td><td align=left><b>$row[0]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>List Name: </td><td align=left><input type=text name=list_name size=20 maxlength=20 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right><a href=\"$PHP_SELF?ADD=31&campaign_id=$campaign_id\">Campaign</a>: </td><td align=left><select size=1 name=campaign_id>\n";

	$stmt="SELECT campaign_id,campaign_name from vicidial_campaigns order by campaign_id";
	$rsltx=mysql_query($stmt, $link);
	$campaigns_to_print = mysql_num_rows($rsltx);
	$campaigns_list='';

	$o=0;
	while ($campaigns_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
		$campaigns_list .= "<option value=\"$rowx[0]\">$rowx[0] - $rowx[1]</option>\n";
		$o++;
	}
echo "$campaigns_list";
echo "<option SELECTED>$campaign_id</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option SELECTED>$active</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Reset Lead-Called-Status for this list: </td><td align=left><select size=1 name=reset_list><option>Y</option><option SELECTED>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<center>\n";
echo "<br><b>STATUSES WITHIN THIS LIST:</b><br>\n";
echo "<TABLE width=400 cellspacing=3>\n";
echo "<tr><td>STATUS</td><td>CALLED</td><td>NOT CALLED</td></tr>\n";

	$leads_in_list = 0;
	$leads_in_list_N = 0;
	$leads_in_list_Y = 0;
	$stmt="SELECT status,called_since_last_reset,count(*) from vicidial_list where list_id='$list_id' group by status,called_since_last_reset order by status,called_since_last_reset";
	$rsltx=mysql_query($stmt, $link);
	$statuses_to_print = mysql_num_rows($rsltx);

	$o=0;
	while ($statuses_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
	$leads_in_list = ($leads_in_list + $rowx[2]);

	if (eregi("1$|3$|5$|7$|9$", $o))
		{$bgcolor='bgcolor="#B9CBFD"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';}

	if ($rowx[1] == 'N')
		{
		$leads_in_list_N = ($leads_in_list_N + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0]</td><td><font size=1> </td><td><font size=1>$rowx[2]</td></tr>\n";
		}
	else 
		{
		$leads_in_list_Y = ($leads_in_list_Y + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0]</td><td><font size=1>$rowx[2]</td><td><font size=1> </td></tr>\n";

		}

		$o++;
	}

echo "<tr><td><font size=1>SUBTOTALS</td><td><font size=1>$leads_in_list_Y</td><td><font size=1>$leads_in_list_N</td></tr>\n";
echo "<tr bgcolor=\"#9BB9FB\"><td><font size=1>TOTAL</td><td colspan=2 align=center><font size=1>$leads_in_list</td></tr>\n";

echo "</table></center><br>\n";





echo "<center>\n";
echo "<br><b>TIME ZONES WITHIN THIS LIST:</b><br>\n";
echo "<TABLE width=500 cellspacing=3>\n";
echo "<tr><td>GMT OFFSET NOW (local time)</td><td>CALLED</td><td>NOT CALLED</td></tr>\n";

	$leads_in_list = 0;
	$leads_in_list_N = 0;
	$leads_in_list_Y = 0;
	$stmt="SELECT gmt_offset_now,called_since_last_reset,count(*) from vicidial_list where list_id='$list_id' group by gmt_offset_now,called_since_last_reset order by gmt_offset_now,called_since_last_reset";
	$rsltx=mysql_query($stmt, $link);
	$statuses_to_print = mysql_num_rows($rsltx);

	$o=0;
	$plus='+';
	while ($statuses_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
	$leads_in_list = ($leads_in_list + $rowx[2]);

	$LOCALzone=3600 * $rowx[0];
	$LOCALdate=gmdate("D M Y H:i", time() + $LOCALzone);

	if ($rowx[0] >= 0) {$rowx[0] = "$plus$rowx[0]";}
	if (eregi("1$|3$|5$|7$|9$", $o))
		{$bgcolor='bgcolor="#B9CBFD"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';}

	if ($rowx[1] == 'N')
		{
		$leads_in_list_N = ($leads_in_list_N + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0] &nbsp; &nbsp; ($LOCALdate)</td><td><font size=1> </td><td><font size=1>$rowx[2]</td></tr>\n";
		}
	else 
		{
		$leads_in_list_Y = ($leads_in_list_Y + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0] &nbsp; &nbsp; ($LOCALdate)</td><td><font size=1>$rowx[2]</td><td><font size=1> </td></tr>\n";

		}

		$o++;
	}

echo "<tr><td><font size=1>SUBTOTALS</td><td><font size=1>$leads_in_list_Y</td><td><font size=1>$leads_in_list_N</td></tr>\n";
echo "<tr bgcolor=\"#9BB9FB\"><td><font size=1>TOTAL</td><td colspan=2 align=center><font size=1>$leads_in_list</td></tr>\n";

echo "</table></center><br>\n";







	$leads_in_list = 0;
	$leads_in_list_N = 0;
	$leads_in_list_Y = 0;
	$stmt="SELECT status,called_count,count(*) from vicidial_list where list_id='$list_id' group by status,called_count order by status,called_count";
	$rsltx=mysql_query($stmt, $link);
	$status_called_to_print = mysql_num_rows($rsltx);

	$o=0;
	$sts=0;
	$first_row=1;
	$all_called_first=1000;
	$all_called_last=0;
	while ($status_called_to_print > $o) 
	{
	$rowx=mysql_fetch_row($rsltx);
	$leads_in_list = ($leads_in_list + $rowx[2]);
	$count_statuses[$o]			= "$rowx[0]";
	$count_called[$o]			= "$rowx[1]";
	$count_count[$o]			= "$rowx[2]";
	$all_called_count[$rowx[1]] = ($all_called_count[$rowx[1]] + $rowx[2]);

	if ( (strlen($status[$sts]) < 1) or ($status[$sts] != "$rowx[0]") )
		{
		if ($first_row) {$first_row=0;}
		else {$sts++;}
		$status[$sts] = "$rowx[0]";
		$status_called_first[$sts] = "$rowx[1]";
		if ($status_called_first[$sts] < $all_called_first) {$all_called_first = $status_called_first[$sts];}
		}
	$leads_in_sts[$sts] = ($leads_in_sts[$sts] + $rowx[2]);
	$status_called_last[$sts] = "$rowx[1]";
	if ($status_called_last[$sts] > $all_called_last) {$all_called_last = $status_called_last[$sts];}

	$o++;
	}




echo "<center>\n";
echo "<br><b>CALLED COUNTS WITHIN THIS LIST:</b><br>\n";
echo "<TABLE width=500 cellspacing=1>\n";
echo "<tr><td align=center><font size=1>STATUS</td>";
$first = $all_called_first;
while ($first <= $all_called_last)
	{
	echo "<td align=center><font size=1>$first</td>";
	$first++;
	}
echo "<td align=center><font size=1>SUBTOTAL</td></tr>\n";

	$sts=0;
	$statuses_called_to_print = count($status);
	while ($statuses_called_to_print > $sts) 
	{
	if (eregi("1$|3$|5$|7$|9$", $sts))
		{$bgcolor='bgcolor="#B9CBFD"';   $AB='bgcolor="#9BB9FB"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';   $AB='bgcolor="#B9CBFD"';}
#	echo "$status[$sts]|$status_called_first[$sts]|$status_called_last[$sts]|$leads_in_sts[$sts]|\n";
#	echo "$status[$sts]|";
	echo "<tr $bgcolor><td><font size=1>$status[$sts]</td>";

	$first = $all_called_first;
	while ($first <= $all_called_last)
		{
		if (eregi("1$|3$|5$|7$|9$", $sts))
			{
			if (eregi("1$|3$|5$|7$|9$", $first)) {$AB='bgcolor="#9BB9FB"';} 
			else{$AB='bgcolor="#B9CBFD"';}
			}
		else
			{
			if (eregi("0$|2$|4$|6$|8$", $first)) {$AB='bgcolor="#9BB9FB"';} 
			else{$AB='bgcolor="#B9CBFD"';}
			}

		$called_printed=0;
		$o=0;
		while ($status_called_to_print > $o) 
			{
			if ( ($count_statuses[$o] == "$status[$sts]") and ($count_called[$o] == "$first") )
				{
				$called_printed++;
				echo "<td $AB><font size=1> $count_count[$o]</td>";
				}


			$o++;
			}
		if (!$called_printed) 
			{echo "<td $AB><font size=1> &nbsp;</td>";}
		$first++;
		}
	echo "<td><font size=1>$leads_in_sts[$sts]</td></tr>\n\n";

	$sts++;
	}

echo "<tr><td align=center><b><font size=1>TOTAL</td>";
$first = $all_called_first;
while ($first <= $all_called_last)
	{
	echo "<td align=center><b><font size=1>$all_called_count[$first]</td>";
	$first++;
	}
echo "<td align=center><b><font size=1>$leads_in_list</td></tr>\n";

echo "</table></center><br>\n";





echo "<center><b>\n";

}



######################
# ADD=3111 modify group info in the system
######################

if ($ADD==3111)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from vicidial_inbound_groups where group_id='$group_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$group_name = $row[1];
	$group_color = $row[2];
	$active = $row[3];
	$web_form_address = $row[4];
	$voicemail_ext = $row[5];
	$next_agent_call = $row[6];

echo "<br>MODIFY A GROUP'S RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=4111>\n";
echo "<input type=hidden name=group_id value=\"$row[0]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group ID: </td><td align=left><b>$row[0]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group Name: </td><td align=left><input type=text name=group_name size=30 maxlength=30 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group Color: </td><td align=left bgcolor=\"$row[2]\"><input type=text name=group_color size=7 maxlength=7 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option SELECTED>$active</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Web Form: </td><td align=left><input type=text name=web_form_address size=50 maxlength=255 value=\"$web_form_address\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail: </td><td align=left><input type=text name=voicemail_ext size=10 maxlength=10 value=\"$voicemail_ext\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Next Agent Call: </td><td align=left><select size=1 name=next_agent_call><option >random</option><option>oldest_call_start</option><option>oldest_call_finish</option><option SELECTED>$next_agent_call</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "</table></center><br>\n";

echo "<center><b>\n";

}



######################
# ADD=4 submit user modifications to the system
######################

if ($ADD==4)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	 if ( (strlen($pass) < 2) or (strlen($full_name) < 2) or (strlen($user_level) < 1) )
		{echo "<br>USER NOT MODIFIED - Please go back and look at the data you entered\n";}
	 else
		{
		echo "<br>USER MODIFIED: $user\n";

		$stmt="UPDATE vicidial_users set pass='$pass',full_name='$full_name',user_level='$user_level' where user='$user';";
		$rslt=mysql_query($stmt, $link);

		### LOG CHANGES TO LOG FILE ###
		$fp = fopen ("./admin_changes_log.txt", "a");
		fwrite ($fp, "$date|MODIFY USER INFO    |$PHP_AUTH_USER|$ip|pass='$pass',full_name='$full_name',user_level='$user_level' where user='$user'|\n");
		fclose($fp);

		}

	$stmt="SELECT * from vicidial_users where user='$user';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);

echo "<br>MODIFY A USER'S RECORD: $row[1]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=4>\n";
echo "<input type=hidden name=user value=\"$row[1]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Number: </td><td align=left><b>$row[1]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=20 maxlength=10 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=full_name size=30 maxlength=30 value=\"$row[3]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Level: </td><td align=left><select size=1 name=user_level><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option><option>7</option><option>8</option><option>9</option><option SELECTED>$row[4]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

}

######################
# ADD=41 submit campaign modifications to the system
######################

if ($ADD==41)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	 if ( (strlen($campaign_name) < 6) or (strlen($active) < 1) )
		{echo "<br>CAMPAIGN NOT MODIFIED - Please go back and look at the data you entered\n";}
	 else
		{
		echo "<br>CAMPAIGN MODIFIED: $campaign_id\n";

		$stmt="UPDATE vicidial_campaigns set campaign_name='$campaign_name',active='$active',dial_status_a='$dial_status_a',dial_status_b='$dial_status_b',dial_status_c='$dial_status_c',dial_status_d='$dial_status_d',dial_status_e='$dial_status_e',lead_order='$lead_order',allow_closers='$allow_closers',hopper_level='$hopper_level', auto_dial_level='$auto_dial_level', next_agent_call='$next_agent_call', local_call_time='$local_call_time', voicemail_ext='$voicemail_ext' where campaign_id='$campaign_id';";
		$rslt=mysql_query($stmt, $link);

		if ($reset_hopper == 'Y')
			{
			echo "<br>RESETTING CAMPAIGN LEAD HOPPER\n";
			echo "<br> - Wait 1 minute before dialing next number\n";
			$stmt="DELETE from vicidial_hopper where campaign_id='$campaign_id' and status='READY';";
			$rslt=mysql_query($stmt, $link);

			### LOG RESET TO LOG FILE ###
			$fp = fopen ("./admin_changes_log.txt", "a");
			fwrite ($fp, "$date|CAMPAIGN HOPPERRESET|$PHP_AUTH_USER|$ip|campaign_name='$campaign_name'|\n");
			fclose($fp);
			}

		### LOG CHANGES TO LOG FILE ###
		$fp = fopen ("./admin_changes_log.txt", "a");
		fwrite ($fp, "$date|MODIFY CAMPAIGN INFO|$PHP_AUTH_USER|$ip|campaign_name='$campaign_name',active='$active',dial_status_a='$dial_status_a',dial_status_b='$dial_status_b',dial_status_c='$dial_status_c',dial_status_d='$dial_status_d',dial_status_e='$dial_status_e',lead_order='$lead_order',allow_closers='$allow_closers',hopper_level='$hopper_level', auto_dial_level='$auto_dial_level', next_agent_call='$next_agent_call', local_call_time='$local_call_time', voicemail_ext='$voicemail_ext' where campaign_id='$campaign_id'|$reset_hopper|\n");
		fclose($fp);

		}

	$stmt="SELECT * from vicidial_campaigns where campaign_id='$campaign_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$dial_status_a = $row[3];
	$dial_status_b = $row[4];
	$dial_status_c = $row[5];
	$dial_status_d = $row[6];
	$dial_status_e = $row[7];
	$lead_order = $row[8];
	$hopper_level = $row[13];
	$auto_dial_level = $row[14];
	$next_agent_call = $row[15];
	$local_call_time = $row[16];
	$voicemail_ext = $row[17];

echo "<br>MODIFY A CAMPAIGN'S RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=41>\n";
echo "<input type=hidden name=campaign_id value=\"$campaign_id\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Campaign ID: </td><td align=left><b>$row[0]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Campaign Name: </td><td align=left><input type=text name=campaign_name size=40 maxlength=40 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option SELECTED>$row[2]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Park Extension: </td><td align=left>$row[9] - $row[10]</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Web Form: </td><td align=left>$row[11]</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Allow Closers: </td><td align=left><select size=1 name=allow_closers><option>Y</option><option>N</option><option SELECTED>$row[12]</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 1: </td><td align=left><select size=1 name=dial_status_a>\n";

	$stmt="SELECT * from vicidial_statuses order by status";
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
echo "<option SELECTED>$dial_status_a</option>\n";
echo "</select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 2: </td><td align=left><select size=1 name=dial_status_b>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_b</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 3: </td><td align=left><select size=1 name=dial_status_c>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_c</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 4: </td><td align=left><select size=1 name=dial_status_d>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_d</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dial status 5: </td><td align=left><select size=1 name=dial_status_e>\n";
echo "$statuses_list";
echo "<option SELECTED>$dial_status_e</option>\n";
echo "</select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>List Order: </td><td align=left><select size=1 name=lead_order><option>DOWN</option><option>UP</option><option>UP PHONE</option><option>DOWN PHONE</option><option>UP LAST NAME</option><option>DOWN LAST NAME</option><option>UP COUNT</option><option>DOWN COUNT</option><option>DOWN COUNT 2nd NEW</option><option>DOWN COUNT 3rd NEW</option><option>DOWN COUNT 4th NEW</option><option SELECTED>$lead_order</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Hopper Level: </td><td align=left><select size=1 name=hopper_level><option>1</option><option>5</option><option>10</option><option>50</option><option>100</option><option>200</option><option>500</option><option SELECTED>$hopper_level</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Force Reset of Hopper: </td><td align=left><select size=1 name=reset_hopper><option>Y</option><option SELECTED>N</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Auto Dial Level: </td><td align=left><select size=1 name=auto_dial_level><option >0</option><option>1</option><option>1.1</option><option>1.2</option><option>1.3</option><option>1.4</option><option>1.5</option><option>1.6</option><option>1.7</option><option>1.8</option><option>1.9</option><option>2.0</option><option>2.2</option><option>2.5</option><option>2.7</option><option>3.0</option><option SELECTED>$auto_dial_level</option></select>(0 = off)</td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Next Agent Call: </td><td align=left><select size=1 name=next_agent_call><option >random</option><option>oldest_call_start</option><option>oldest_call_finish</option><option SELECTED>$next_agent_call</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Local Call Time: </td><td align=left><select size=1 name=local_call_time><option >24hours</option><option>9am-9pm</option><option>9am-5pm</option><option>12pm-5pm</option><option>12pm-9pm</option><option>5pm-9pm</option><option SELECTED>$local_call_time</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail: </td><td align=left><input type=text name=voicemail_ext size=10 maxlength=10 value=\"$voicemail_ext\"></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";


	##### calculate what gmt_offset_now values are within the allowed local_call_time setting
	if ($local_call_time == '24hours')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '9am-9pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 9) && ($phour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '9am-5pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 9) && ($phour <= 16) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '12pm-5pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 12) && ($phour <= 16) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '12pm-9pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 12) && ($phour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}
	if ($local_call_time == '5pm-9pm')
		{
		$p='13';
		$GMT_allowed = '';
		while ($p > -13)
			{
			$pzone=3600 * $p;
			$phour=gmdate("G", time() + $pzone);
			if ( ($phour >= 17) && ($phour <= 20) ){$tz = sprintf("%.2f", $p);	$GMT_allowed = "$GMT_allowed'$tz',";}
			$p = ($p - 0.25);
			}
		}

	$GMT_allowed = "$GMT_allowed'99'";









echo "<center>\n";
echo "<br><b>LISTS WITHIN THIS CAMPAIGN:</b><br>\n";
echo "<TABLE width=400 cellspacing=3>\n";
echo "<tr><td>LIST ID</td><td>LIST NAME</td><td>ACTIVE</td></tr>\n";

	$active_lists = 0;
	$inactive_lists = 0;
	$stmt="SELECT list_id,active,list_name from vicidial_lists where campaign_id='$campaign_id'";
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

	echo "<tr $bgcolor><td><font size=1><a href=\"$PHP_SELF?ADD=311&list_id=$rowx[0]\">$rowx[0]</a></td><td><font size=1>$rowx[2]</td><td><font size=1>$rowx[1]</td></tr>\n";

	}

echo "</table></center><br>\n";
echo "<center><b>\n";

	$camp_lists = eregi_replace(".$","",$camp_lists);
echo "This campaign has $active_lists active lists and $inactive_lists inactive lists<br><br>\n";
	$stmt="SELECT count(*) FROM vicidial_list where called_since_last_reset='N' and status IN('$dial_status_a','$dial_status_b','$dial_status_c','$dial_status_d','$dial_status_e') and list_id IN($camp_lists) and gmt_offset_now IN($GMT_allowed)";
	$rsltx=mysql_query($stmt, $link);
	$rsltx_rows = mysql_num_rows($rsltx);
	if ($rsltx_rows)
		{
		$rowx=mysql_fetch_row($rsltx);
		$active_leads = "$rowx[0]";
		}
	else {$active_leads = '0';}

echo "This campaign has $active_leads leads to be dialed in those lists<br><br>\n";
	$stmt="SELECT count(*) FROM vicidial_hopper where campaign_id='$campaign_id' and status IN('READY')";
	$rsltx=mysql_query($stmt, $link);
	$rowx=mysql_fetch_row($rsltx);
	$hopper_leads = "$rowx[0]";

echo "This campaign has $hopper_leads leads in the dial hopper<br><br>\n";
echo "</b></center>\n";

}

######################
# ADD=411 submit list modifications to the system
######################

if ($ADD==411)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	 if ( (strlen($list_name) < 2) or (strlen($campaign_id) < 2) )
		{echo "<br>LIST NOT MODIFIED - Please go back and look at the data you entered\n";}
	 else
		{
		echo "<br>LIST MODIFIED: $user\n";

		$stmt="UPDATE vicidial_lists set list_name='$list_name',campaign_id='$campaign_id',active='$active' where list_id='$list_id';";
		$rslt=mysql_query($stmt, $link);

		if ($reset_list == 'Y')
			{
			echo "<br>RESETTING LIST-CALLED-STATUS\n";
			$stmt="UPDATE vicidial_list set called_since_last_reset='N' where list_id='$list_id';";
			$rslt=mysql_query($stmt, $link);
			### LOG RESET TO LOG FILE ###
			$fp = fopen ("./admin_changes_log.txt", "a");
			fwrite ($fp, "$date|RESET LIST CALLED   |$PHP_AUTH_USER|$ip|list_name='$list_name'|\n");
			fclose($fp);
			}
		if ($campaign_id != "$old_campaign_id")
			{
			echo "<br>REMOVING LIST HOPPER LEADS FROM OLD CAMPAIGN HOPPER ($old_campaign_id)\n";
			$stmt="DELETE from vicidial_hopper where list_id='$list_id' and campaign_id='$old_campaign_id';";
			$rslt=mysql_query($stmt, $link);
			}

		### LOG CHANGES TO LOG FILE ###
		$fp = fopen ("./admin_changes_log.txt", "a");
		fwrite ($fp, "$date|MODIFY LIST INFO    |$PHP_AUTH_USER|$ip|list_name='$list_name',campaign_id='$campaign_id',active='$active' where list_id='$list_id'|\n");
		fclose($fp);

		}

	$stmt="SELECT * from vicidial_lists where list_id='$list_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$campaign_id = $row[2];
	$active = $row[3];

echo "<br>MODIFY A LIST'S RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=411>\n";
echo "<input type=hidden name=list_id value=\"$row[0]\">\n";
echo "<input type=hidden name=old_campaign_id value=\"$row[2]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>List ID: </td><td align=left><b>$row[0]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>List Name: </td><td align=left><input type=text name=list_name size=20 maxlength=20 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right><a href=\"$PHP_SELF?ADD=31&campaign_id=$campaign_id\">Campaign</a>: </td><td align=left><select size=1 name=campaign_id>\n";

	$stmt="SELECT campaign_id,campaign_name from vicidial_campaigns order by campaign_id";
	$rsltx=mysql_query($stmt, $link);
	$campaigns_to_print = mysql_num_rows($rsltx);
	$campaigns_list='';

	$o=0;
	while ($campaigns_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
		$campaigns_list .= "<option value=\"$rowx[0]\">$rowx[0] - $rowx[1]</option>\n";
		$o++;
	}
echo "$campaigns_list";
echo "<option SELECTED>$campaign_id</option>\n";
echo "</select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option SELECTED>$active</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Reset Lead-Called-Status for this list: </td><td align=left><select size=1 name=reset_list><option>Y</option><option SELECTED>N</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "<center>\n";
echo "<br><b>STATUSES WITHIN THIS LIST:</b><br>\n";
echo "<TABLE width=400 cellspacing=3>\n";
echo "<tr><td>STATUS</td><td>CALLED</td><td>NOT CALLED</td></tr>\n";

	$leads_in_list = 0;
	$leads_in_list_N = 0;
	$leads_in_list_Y = 0;
	$stmt="SELECT status,called_since_last_reset,count(*) from vicidial_list where list_id='$list_id' group by status,called_since_last_reset order by status,called_since_last_reset";
	$rsltx=mysql_query($stmt, $link);
	$statuses_to_print = mysql_num_rows($rsltx);

	$o=0;
	while ($statuses_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
	$leads_in_list = ($leads_in_list + $rowx[2]);

	if (eregi("1$|3$|5$|7$|9$", $o))
		{$bgcolor='bgcolor="#B9CBFD"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';}

	if ($rowx[1] == 'N')
		{
		$leads_in_list_N = ($leads_in_list_N + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0]</td><td><font size=1> </td><td><font size=1>$rowx[2]</td></tr>\n";
		}
	else 
		{
		$leads_in_list_Y = ($leads_in_list_Y + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0]</td><td><font size=1>$rowx[2]</td><td><font size=1> </td></tr>\n";

		}

		$o++;
	}

echo "<tr><td><font size=1>SUBTOTALS</td><td><font size=1>$leads_in_list_Y</td><td><font size=1>$leads_in_list_N</td></tr>\n";
echo "<tr bgcolor=\"#9BB9FB\"><td><font size=1>TOTAL</td><td colspan=2 align=center><font size=1>$leads_in_list</td></tr>\n";

echo "</table></center><br>\n";





echo "<center>\n";
echo "<br><b>TIME ZONES WITHIN THIS LIST:</b><br>\n";
echo "<TABLE width=500 cellspacing=3>\n";
echo "<tr><td>GMT OFFSET NOW (local time)</td><td>CALLED</td><td>NOT CALLED</td></tr>\n";

	$leads_in_list = 0;
	$leads_in_list_N = 0;
	$leads_in_list_Y = 0;
	$stmt="SELECT gmt_offset_now,called_since_last_reset,count(*) from vicidial_list where list_id='$list_id' group by gmt_offset_now,called_since_last_reset order by gmt_offset_now,called_since_last_reset";
	$rsltx=mysql_query($stmt, $link);
	$statuses_to_print = mysql_num_rows($rsltx);

	$o=0;
	$plus='+';
	while ($statuses_to_print > $o) {
		$rowx=mysql_fetch_row($rsltx);
	$leads_in_list = ($leads_in_list + $rowx[2]);

	$LOCALzone=3600 * $rowx[0];
	$LOCALdate=gmdate("D M Y H:i", time() + $LOCALzone);

	if ($rowx[0] >= 0) {$rowx[0] = "$plus$rowx[0]";}
	if (eregi("1$|3$|5$|7$|9$", $o))
		{$bgcolor='bgcolor="#B9CBFD"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';}

	if ($rowx[1] == 'N')
		{
		$leads_in_list_N = ($leads_in_list_N + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0] &nbsp; &nbsp; ($LOCALdate)</td><td><font size=1> </td><td><font size=1>$rowx[2]</td></tr>\n";
		}
	else 
		{
		$leads_in_list_Y = ($leads_in_list_Y + $rowx[2]);
		echo "<tr $bgcolor><td><font size=1>$rowx[0] &nbsp; &nbsp; ($LOCALdate)</td><td><font size=1>$rowx[2]</td><td><font size=1> </td></tr>\n";

		}

		$o++;
	}

echo "<tr><td><font size=1>SUBTOTALS</td><td><font size=1>$leads_in_list_Y</td><td><font size=1>$leads_in_list_N</td></tr>\n";
echo "<tr bgcolor=\"#9BB9FB\"><td><font size=1>TOTAL</td><td colspan=2 align=center><font size=1>$leads_in_list</td></tr>\n";

echo "</table></center><br>\n";










	$leads_in_list = 0;
	$leads_in_list_N = 0;
	$leads_in_list_Y = 0;
	$stmt="SELECT status,called_count,count(*) from vicidial_list where list_id='$list_id' group by status,called_count order by status,called_count";
	$rsltx=mysql_query($stmt, $link);
	$status_called_to_print = mysql_num_rows($rsltx);

	$o=0;
	$sts=0;
	$first_row=1;
	$all_called_first=1000;
	$all_called_last=0;
	while ($status_called_to_print > $o) 
	{
	$rowx=mysql_fetch_row($rsltx);
	$leads_in_list = ($leads_in_list + $rowx[2]);
	$count_statuses[$o]			= "$rowx[0]";
	$count_called[$o]			= "$rowx[1]";
	$count_count[$o]			= "$rowx[2]";
	$all_called_count[$rowx[1]] = ($all_called_count[$rowx[1]] + $rowx[2]);

	if ( (strlen($status[$sts]) < 1) or ($status[$sts] != "$rowx[0]") )
		{
		if ($first_row) {$first_row=0;}
		else {$sts++;}
		$status[$sts] = "$rowx[0]";
		$status_called_first[$sts] = "$rowx[1]";
		if ($status_called_first[$sts] < $all_called_first) {$all_called_first = $status_called_first[$sts];}
		}
	$leads_in_sts[$sts] = ($leads_in_sts[$sts] + $rowx[2]);
	$status_called_last[$sts] = "$rowx[1]";
	if ($status_called_last[$sts] > $all_called_last) {$all_called_last = $status_called_last[$sts];}

	$o++;
	}




echo "<center>\n";
echo "<br><b>CALLED COUNTS WITHIN THIS LIST:</b><br>\n";
echo "<TABLE width=500 cellspacing=1>\n";
echo "<tr><td align=center><font size=1>STATUS</td>";
$first = $all_called_first;
while ($first <= $all_called_last)
	{
	echo "<td align=center><font size=1>$first</td>";
	$first++;
	}
echo "<td align=center><font size=1>SUBTOTAL</td></tr>\n";

	$sts=0;
	$statuses_called_to_print = count($status);
	while ($statuses_called_to_print > $sts) 
	{
	if (eregi("1$|3$|5$|7$|9$", $sts))
		{$bgcolor='bgcolor="#B9CBFD"';   $AB='bgcolor="#9BB9FB"';} 
	else
		{$bgcolor='bgcolor="#9BB9FB"';   $AB='bgcolor="#B9CBFD"';}
#	echo "$status[$sts]|$status_called_first[$sts]|$status_called_last[$sts]|$leads_in_sts[$sts]|\n";
#	echo "$status[$sts]|";
	echo "<tr $bgcolor><td><font size=1>$status[$sts]</td>";

	$first = $all_called_first;
	while ($first <= $all_called_last)
		{
		if (eregi("1$|3$|5$|7$|9$", $sts))
			{
			if (eregi("1$|3$|5$|7$|9$", $first)) {$AB='bgcolor="#9BB9FB"';} 
			else{$AB='bgcolor="#B9CBFD"';}
			}
		else
			{
			if (eregi("0$|2$|4$|6$|8$", $first)) {$AB='bgcolor="#9BB9FB"';} 
			else{$AB='bgcolor="#B9CBFD"';}
			}

		$called_printed=0;
		$o=0;
		while ($status_called_to_print > $o) 
			{
			if ( ($count_statuses[$o] == "$status[$sts]") and ($count_called[$o] == "$first") )
				{
				$called_printed++;
				echo "<td $AB><font size=1> $count_count[$o]</td>";
				}


			$o++;
			}
		if (!$called_printed) 
			{echo "<td $AB><font size=1> &nbsp;</td>";}
		$first++;
		}
	echo "<td><font size=1>$leads_in_sts[$sts]</td></tr>\n\n";

	$sts++;
	}

echo "<tr><td align=center><b><font size=1>TOTAL</td>";
$first = $all_called_first;
while ($first <= $all_called_last)
	{
	echo "<td align=center><b><font size=1>$all_called_count[$first]</td>";
	$first++;
	}
echo "<td align=center><b><font size=1>$leads_in_list</td></tr>\n";

echo "</table></center><br>\n";




echo "<center><b>\n";

}


######################
# ADD=4111 modify group info in the system
######################

if ($ADD==4111)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	 if ( (strlen($group_name) < 2) or (strlen($group_color) < 2) )
		{echo "<br>GROUP NOT MODIFIED - Please go back and look at the data you entered\n";}
	 else
		{
		echo "<br>GROUP MODIFIED: $user\n";

		$stmt="UPDATE vicidial_inbound_groups set group_name='$group_name', group_color='$group_color', active='$active', web_form_address='$web_form_address', voicemail_ext='$voicemail_ext', next_agent_call='$next_agent_call' where group_id='$group_id';";
		$rslt=mysql_query($stmt, $link);

		### LOG CHANGES TO LOG FILE ###
		$fp = fopen ("./admin_changes_log.txt", "a");
		fwrite ($fp, "$date|MODIFY GROUP INFO   |$PHP_AUTH_USER|$ip|group_name='$group_name',group_color='$group_color',active='$active', web_form_address='$web_form_address', voicemail_ext='$voicemail_ext', next_agent_call='$next_agent_call' where group_id='$group_id'|\n");
		fclose($fp);

		}

	$stmt="SELECT * from vicidial_inbound_groups where group_id='$group_id';";
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$group_name = $row[1];
	$group_color = $row[2];
	$active = $row[3];
	$web_form_address = $row[4];
	$voicemail_ext = $row[5];
	$next_agent_call = $row[6];

echo "<br>MODIFY A GROUP'S RECORD: $row[0]<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=4111>\n";
echo "<input type=hidden name=group_id value=\"$row[0]\">\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group ID: </td><td align=left><b>$row[0]</b></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group Name: </td><td align=left><input type=text name=group_name size=30 maxlength=30 value=\"$row[1]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Group Color: </td><td align=left bgcolor=\"$row[2]\"><input type=text name=group_color size=7 maxlength=7 value=\"$row[2]\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option SELECTED>$active</option></select></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Web Form: </td><td align=left><input type=text name=web_form_address size=50 maxlength=255 value=\"$web_form_address\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail: </td><td align=left><input type=text name=voicemail_ext size=10 maxlength=10 value=\"$voicemail_ext\"></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Next Agent Call: </td><td align=left><select size=1 name=next_agent_call><option >random</option><option>oldest_call_start</option><option>oldest_call_finish</option><option SELECTED>$next_agent_call</option></select></td></tr>\n";

echo "<tr bgcolor=#B6D3FC><td align=center colspan=2><input type=submit name=submit value=submit></td></tr>\n";
echo "</TABLE></center>\n";

echo "</table></center><br>\n";

echo "<center><b>\n";

}



######################
# ADD=5 search form
######################

if ($ADD==5)
{
echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

echo "<br>SEARCH FOR A USER<form action=$PHP_SELF method=POST>\n";
echo "<input type=hidden name=ADD value=6>\n";
echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Number: </td><td align=left><input type=text name=user size=20 maxlength=20></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=full_name size=30 maxlength=30></td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Level: </td><td align=left><select size=1 name=user_level><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option><option>7</option><option>8</option><option>9</option></select></td></tr>\n";
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
	if ($user) {$SQL .= "user LIKE \"%$user%\" and";}
	if ($full_name) {$SQL .= "full_name LIKE \"%$full_name%\" and";}
	if ($user_level) {$SQL .= "user_level LIKE \"%$user_level%\" and";}
	$SQL = eregi_replace(" and$", "", $SQL);
	if (strlen($SQL)>5) {$SQL = "where $SQL";}

	$stmt="SELECT * from vicidial_users $SQL order by full_name desc;";
#	echo "\n|$stmt|\n";
	$rslt=mysql_query($stmt, $link);
	$people_to_print = mysql_num_rows($rslt);

echo "<br>SEARCH RESULTS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($people_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[1]</td><td><font size=1>$row[3]</td><td><font size=1>$row[4]</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=3&user=$row[1]\">MODIFY</a> | <a href=\"./user_stats.php?user=$row[1]\">STATS</a></td></tr>\n";
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

	$stmt="SELECT * from vicidial_users order by full_name";
	$rslt=mysql_query($stmt, $link);
	$people_to_print = mysql_num_rows($rslt);

echo "<br>USER LISTINGS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($people_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[1]</td><td><font size=1>$row[3]</td><td><font size=1>$row[4]</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=3&user=$row[1]\">MODIFY</a> | <a href=\"./user_stats.php?user=$row[1]\">STATS</a></td></tr>\n";
		$o++;
	}

echo "</TABLE></center>\n";
}

######################
# ADD=10 display all campaigns
######################
if ($ADD==10)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from vicidial_campaigns order by campaign_id";
	$rslt=mysql_query($stmt, $link);
	$people_to_print = mysql_num_rows($rslt);

echo "<br>CAMPAIGN LISTINGS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($people_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[0]</td><td><font size=1>$row[1]</td>";
		echo "<td><font size=1> $row[2]</td>";
		echo "<td><font size=1> $row[3]</td><td><font size=1>$row[4]</td><td><font size=1>$row[5]</td>";
		echo "<td><font size=1> $row[6]</td><td><font size=1>$row[7]</td><td><font size=1> &nbsp;</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=31&campaign_id=$row[0]\">MODIFY</a></td></tr>\n";
		$o++;
	}

echo "</TABLE></center>\n";
}


######################
# ADD=100 display all lists
######################
if ($ADD==100)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from vicidial_lists order by list_id";
	$rslt=mysql_query($stmt, $link);
	$people_to_print = mysql_num_rows($rslt);

echo "<br>LIST LISTINGS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($people_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[0]</td>";
		echo "<td><font size=1> $row[1]</td>";
		echo "<td><font size=1> $row[2]</td><td><font size=1>$row[4]</td><td><font size=1>$row[5]</td>";
		echo "<td><font size=1> $row[3]</td><td><font size=1>$row[7]</td><td><font size=1> &nbsp;</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=311&list_id=$row[0]\">MODIFY</a></td></tr>\n";
		$o++;
	}

echo "</TABLE></center>\n";
}



######################
# ADD=1000 display all inbound groups
######################
if ($ADD==1000)
{
	echo "<FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2>";

	$stmt="SELECT * from vicidial_inbound_groups order by group_id";
	$rslt=mysql_query($stmt, $link);
	$people_to_print = mysql_num_rows($rslt);

echo "<br>INBOUND GROUP LISTINGS:\n";
echo "<center><TABLE width=600 cellspacing=0 cellpadding=1>\n";

	$o=0;
	while ($people_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if (eregi("1$|3$|5$|7$|9$", $o))
			{$bgcolor='bgcolor="#B9CBFD"';} 
		else
			{$bgcolor='bgcolor="#9BB9FB"';}
		echo "<tr $bgcolor><td><font size=1>$row[0]</td>";
		echo "<td><font size=1> $row[1]</td>";
		echo "<td><font size=1> $row[3]</td>";
		echo "<td><font size=1> $row[5]</td>";
		echo "<td bgcolor=\"$row[2]\"><font size=1> &nbsp;</td>";
		echo "<td><font size=1><a href=\"$PHP_SELF?ADD=3111&group_id=$row[0]\">MODIFY</a></td></tr>\n";
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





