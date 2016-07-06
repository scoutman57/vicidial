<?

### AST GUI database administration

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
//$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
//$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
//$ADD=$_GET["ADD"];
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
if ($ADD==99999) {$process = 'HELP';}

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

$NWB = " &nbsp; <a href=\"javascript:openNewWindow('$PHP_SELF?ADD=99999";
$NWE = "')\"><IMG SRC=\"help.gif\" WIDTH=20 HEIGHT=20 BORDER=0 ALT=\"HELP\" ALIGN=TOP></A>";
######################
# ADD=99999 display the HELP SCREENS
######################

if ($ADD==99999)
{
echo "<html>\n";
echo "<head>\n";
echo "<title>ASTERISK ADMIN: Administration - $process </title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
echo "<CENTER>\n";
echo "<TABLE WIDTH=98% BGCOLOR=#E6E6E6 cellpadding=2 cellspacing=0><TR><TD ALIGN=LEFT><FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=4><B>ASTERISK ADMIN: HELP<BR></B></FONT><FONT FACE=\"ARIAL,HELVETICA\" COLOR=BLACK SIZE=2><BR><BR>\n";

?>
<B><FONT SIZE=3>PHONES TABLE</FONT></B><BR><BR>
<A NAME="phones-extension">
<BR>
<B>Phone extension - </B> This field is where you put the phone's name(as it appears to Asterisk) not including the protocol or slash at the beginning. For Example: for the SIP phone SIP/test101 the Phone extension would be test101. Also, for IAX2 phones make sure you use the full phone's name: IAX2/IAXphone1@IAXphone1 would be IAXphone1@IAXphone1. For Zap phones make sure you put the full channel: Zap/25-1 would be 25-1.  (Another note, make sure you set the Protocol below correctly for your type of phone.)

<BR>
<A NAME="phones-dialplan_number">
<BR>
<B>Dialplan number - </B> This field is for the number you dial to have the phone ring. This number is defined in the extensions.conf file of your Asterisk server

<BR>
<A NAME="phones-voicemail_id">
<BR>
<B>Voicemail Box - </B> This field is for the voicemail box that the messages go to for the user of this phone. We use this to check for voicemail messages and for the user to be able to use the VOICEMAIL button on astGUIclient app.

<BR>
<A NAME="phones-phone_ip">
<BR>
<B>Phone IP address - </B> This field is for the phone's IP address if it is a VOIP phone. This is an optional field

<BR>
<A NAME="phones-computer_ip">
<BR>
<B>Computer IP address - </B> This field is for the user's computer IP address. This is an optional field

<BR>
<A NAME="phones-server_ip">
<BR>
<B>Server IP - </B> This menu is where you select which server the phone is active on.

<BR>
<A NAME="phones-login">
<BR>
<B>Login - </B> The login used for the phone user to get to admin functions.

<BR>
<A NAME="phones-pass">
<BR>
<B>Password - </B> The password used for the phone user to get to admin functions.

<BR>
<A NAME="phones-status">
<BR>
<B>Status - </B> The status of the phone in the system, ACTIVE and ADMIN allow for GUI clients to work. ADMIN allows access to this administrative web site. All other statuses do not allow GUI or Admin web access.

<BR>
<A NAME="phones-active">
<BR>
<B>Active Account - </B> Whether the phone is active to put it in the list in the GUI client.

<BR>
<A NAME="phones-phone_type">
<BR>
<B>Phone Type - </B> Purely for administrative notes.

<BR>
<A NAME="phones-fullname">
<BR>
<B>Full Name - </B> Used by the GUIclient in the list of active phones.

<BR>
<A NAME="phones-company">
<BR>
<B>Company - </B> Purely for administrative notes.

<BR>
<A NAME="phones-picture">
<BR>
<B>Picture - </B> Not yet Implemented.

<BR>
<A NAME="phones-messages">
<BR>
<B>New Messages - </B> Number of new voicemail messages for this phone on the Asterisk server.

<BR>
<A NAME="phones-old_messages">
<BR>
<B>Old Messages - </B> Number of old voicemail messages for this phone on the Asterisk server.

<BR>
<A NAME="phones-protocol">
<BR>
<B>Client Protocol - </B> The protocol that the phone uses to connect to the Asterisk server: SIP, IAX2, Zap . Also, there is EXTERNAL for remote dial numbers or speed dial numbers that you want to list as phones.

<BR>
<A NAME="phones-local_gmt">
<BR>
<B>Local GMT - </B> The difference from Greenwich Mean time(or ZULU time) where the phone is located. DO NOT ADJUST FOR DAYLIGHT SAVINGS TIME. This is used by the VICIDIAL campaign to accurately display the time and customer time.

<BR>
<A NAME="phones-ASTmgrUSERNAME">
<BR>
<B>Manager Login - </B> This is the login that the GUI clients for this phone will use to access the Database where the server data resides.

<BR>
<A NAME="phones-ASTmgrSECRET">
<BR>
<B>Manager Secret - </B> This is the password that the GUI clients for this phone will use to access the Database where the server data resides.

<BR>
<A NAME="phones-login_user">
<BR>
<B>VICIDIAL Default User - </B> This is to place a default value in the VICIDIAL user field whenever this phone user opens the astVICIDIAL client app. Leave blank for no user.

<BR>
<A NAME="phones-login_pass">
<BR>
<B>VICIDIAL Default Pass - </B> This is to place a default value in the VICIDIAL password field whenever this phone user opens the astVICIDIAL client app. Leave blank for no pass.

<BR>
<A NAME="phones-login_campaign">
<BR>
<B>VICIDIAL Default Campaign - </B> This is to place a default value in the VICIDIAL campaign field whenever this phone user opens the astVICIDIAL client app. Leave blank for no campaign.

<BR>
<A NAME="phones-park_on_extension">
<BR>
<B>Park Exten - </B> This is the default Parking extension for the client apps. Verify that a different one works before you change this.

<BR>
<A NAME="phones-conf_on_extension">
<BR>
<B>Conf Exten - </B> This is the default Conference park extension for the client apps. Verify that a different one works before you change this.

<BR>
<A NAME="phones-VICIDIAL_park_on_extension">
<BR>
<B>VICIDIAL Park Exten - </B> This is the default Parking extension for VICIDIAL client app. Verify that a different one works before you change this.

<BR>
<A NAME="phones-VICIDIAL_park_on_filename">
<BR>
<B>VICIDIAL Park File - </B> This is the default VICIDIAL park extension file name for the client apps. Verify that a different one works before you change this. limited to 10 characters.

<BR>
<A NAME="phones-monitor_prefix">
<BR>
<B>Monitor Prefix - </B> This is the dialplan prefix for monitoring of Zap channels automatically within the astGUIclient app. Only change according to the extensions.conf ZapBarge extensions records.

<BR>
<A NAME="phones-recording_exten">
<BR>
<B>Recording Exten - </B> This is the dialplan extension for the recording extension that is used to drop into meetme conferences to record them. It usually lasts upto one hour if not stopped. verify with extensions.conf file before changing.

<BR>
<A NAME="phones-voicemail_exten">
<BR>
<B>VMAIL Main Exten - </B> This is the dialplan extension going to check your voicemail. verify with extensions.conf file before changing.

<BR>
<A NAME="phones-voicemail_dump_exten">
<BR>
<B>VMAIL Dump Exten - </B> This is the dialplan prefix used to send calls directly to a user's voicemail from a live call in the astGUIclient app. verify with extensions.conf file before changing.

<BR>
<A NAME="phones-ext_context">
<BR>
<B>Exten Context - </B> This is the dialplan context that this phone primarily uses. It is assumed that all numbers dialed by the client apps are using this context so it is a good idea to make sure this is the most wide context possible. verify with extensions.conf file before changing.

<BR>
<A NAME="phones-dtmf_send_extension">
<BR>
<B>DTMF send Channel - </B> This is the channel string used to send DTMF sounds into meetme conferences from the client apps. Verify the exten and context with the extensions.conf file.

<BR>
<A NAME="phones-call_out_number_group">
<BR>
<B>Outbound Call Group - </B> This is the channel group that outbound calls from this phone are placed out of. There are a couple routines in the client apps that use this. For Zap channels you want to use something like Zap/g2 , for IAX2 trunks you would want to use the full IAX prefix like IAX2/VICItest1:secret@10.10.10.15:4569. Verify the trunks with the extensions.conf file(it is usually what you have defined as the TRUNK global variable at the top of the file).

<BR>
<A NAME="phones-client_browser">
<BR>
<B>Browser Location - </B> This is applicable to only UNIX/LINUX clients, the absolute path to Mozilla or Firefox browser on the machine. verify this by launching it manually.

<BR>
<A NAME="phones-install_directory">
<BR>
<B>Install Directory - </B> This is the place where the astGUIclient and astVICIDIAL scripts are located on your machine. For Win32 it should be something like C:\AST_VICI and for UNIX it should be something like /usr/local/perl_TK. verify this manually.

<BR>
<A NAME="phones-local_web_callerID_URL">
<BR>
<B>CallerID URL - </B> This is the web address of the page used to do custom callerID lookups. default testing address is: http://astguiclient.sf.net/test_callerid_output.php

<BR>
<A NAME="phones-VICIDIAL_web_URL">
<BR>
<B>VICIDIAL Default URL - </B> This is the web address of the page used to do custom VICIDIAL Web Form queries. default testing address is: http://astguiclient.sf.net/test_VICIDIAL_output.php

<BR>
<A NAME="phones-AGI_call_logging_enabled">
<BR>
<B>Call Logging - </B> This is set to true if the call_log.agi file is in place in the extensions.conf file for all outbound and hangup 'h' extensions to log all calls. This should always be 1 because it is manditory for many astGUIclient and VICIDIAL features to work properly.

<BR>
<A NAME="phones-user_switching_enabled">
<BR>
<B>User Switching - </B> Set to true to allow user to switch to another user account. NOTE: If user switches they can initiate recording on the new user's phone conversation

<BR>
<A NAME="phones-conferencing_enabled">
<BR>
<B>Conferencing - </B> Set to true to allow user to start conference calls with upto six external lines.

<BR>
<A NAME="phones-admin_hangup_enabled">
<BR>
<B>Admin Hangup - </B> Set to true to allow user to be able to hangup any line at will through astGUIclient. Good idea only to enable this for Admin users.

<BR>
<A NAME="phones-admin_hijack_enabled">
<BR>
<B>Admin Hijack - </B> Set to true to allow user to be able to grab and redirect to their extension any line at will through astGUIclient. Good idea only to enable this for Admin users. But is very useful for Managers.

<BR>
<A NAME="phones-admin_monitor_enabled">
<BR>
<B>Admin Monitor - </B> Set to true to allow user to be able to grab and redirect to their extension any line at will through astGUIclient. Good idea only to enable this for Admin users. But is very useful for Managers and as a training tool.

<BR>
<A NAME="phones-call_parking_enabled">
<BR>
<B>Call Park - </B> Set to true to allow user to be able to park calls on astGUIclient hold to be picked up by any other astGUIclient user on the system. Calls stay on hold for upto a half hour then hangup. Usually enabled for all.

<BR>
<A NAME="phones-updater_check_enabled">
<BR>
<B>Updater Check - </B> Set to true to display a popup warning that the updater time has not changed in 20 seconds. Useful for Admin users.

<BR>
<A NAME="phones-AFLogging_enabled">
<BR>
<B>AF Logging - </B> Set to true to log many actions of astGUIclient usage to a text file on the user's computer.

<BR>
<A NAME="phones-QUEUE_ACTION_enabled">
<BR>
<B>Queue Enabled - </B> Set to true to have client apps use the Asterisk Central Queue system. Required for VICIDIAL and recommended for all users.

<BR>
<A NAME="phones-CallerID_popup_enabled">
<BR>
<B>CallerID Popup - </B> Set to true to allow for numbers defined in the extensions.conf file to send CallerID popup screens to astGUIclient users.

<BR>
<A NAME="phones-voicemail_button_enabled">
<BR>
<B>VMail Button - </B> Set to true to display the VOICEMAIL button and the messages count display on astGUIclient.

<BR>
<A NAME="phones-enable_fast_refresh">
<BR>
<B>Fast Refresh - </B> Set to true to enable a new rate of refresh of call information for the astGUIclient. Default disabled rate is 1000 ms (1 second). Can increase system load if you lower this number.

<BR>
<A NAME="phones-fast_refresh_rate">
<BR>
<B>Fast Refresh Rate - </B> in milliseconds. Only used if Fast Refresh is enabled. Default disabled rate is 1000 ms (1 second). Can increase system load if you lower this number.

<BR>
<A NAME="phones-enable_persistant_mysql">
<BR>
<B>Persistant MySQL - </B> If enabled the astGUIclient connection will remain connected instead of connecting every second. Useful if you have a fast refresh rate set. It will increase the number of connections on your MySQL machine.

<BR>
<A NAME="phones-auto_dial_next_number">
<BR>
<B>Auto Dial Next Number - </B> If enabled the VICIDIAL client will dial the next number on the list automatically upon disposition of a call unless they selected to "Stop Dialing" on the disposition screen.

<BR>
<A NAME="phones-VDstop_rec_after_each_call">
<BR>
<B>Stop Rec after each call - </B> If enabled the VICIDIAL client will stop whatever recording is going on after each call has been dispositioned. Useful if you are doing a lot of recording or you are using a web form to trigger recording.

<BR>
<A NAME="phones-DBX_server">
<BR>
<B>DBX Server - </B> The MySQL database server that this user should be connecting to.

<BR>
<A NAME="phones-DBX_database">
<BR>
<B>DBX Database - </B> The MySQL database that this user should be connecting to. Default is asterisk.

<BR>
<A NAME="phones-DBX_user">
<BR>
<B>DBX User - </B> The MySQL user login that this user should be using when connecting. Default is cron.

<BR>
<A NAME="phones-DBX_pass">
<BR>
<B>DBX Pass - </B> The MySQL user password that this user should be using when connecting. Default is 1234.

<BR>
<A NAME="phones-DBX_port">
<BR>
<B>DBX Port - </B> The MySQL TCP port that this user should be using when connecting. Default is 3306.

<BR>
<A NAME="phones-DBY_server">
<BR>
<B>DBY Server - </B> The MySQL database server that this user should be connecting to. Secondary server, not used currently.

<BR>
<A NAME="phones-DBY_database">
<BR>
<B>DBY Database - </B> The MySQL database that this user should be connecting to. Default is asterisk. Secondary server, not used currently.

<BR>
<A NAME="phones-DBY_user">
<BR>
<B>DBY User - </B> The MySQL user login that this user should be using when connecting. Default is cron. Secondary server, not used currently.

<BR>
<A NAME="phones-DBY_pass">
<BR>
<B>DBY Pass - </B> The MySQL user password that this user should be using when connecting. Default is 1234. Secondary server, not used currently.

<BR>
<A NAME="phones-DBY_port">
<BR>
<B>DBY Port - </B> The MySQL TCP port that this user should be using when connecting. Default is 3306. Secondary server, not used currently.


<BR><BR><BR><BR>

<B><FONT SIZE=3>SERVERS TABLE</FONT></B><BR><BR>
<A NAME="servers-server_id">
<BR>
<B>Server ID - </B> This field is where you put the Asterisk server's name, doesn't have to be an official domain sub, just a nickname to identify the server to Admin users.

<BR>
<A NAME="servers-server_description">
<BR>
<B>Server Description - </B> The field where you use a small phrase to describe the Asterisk server.

<BR>
<A NAME="servers-server_ip">
<BR>
<B>Server IP Address - </B> The field where you put the Network IP address of the Asterisk server.

<BR>
<A NAME="servers-active">
<BR>
<B>Active - </B> Set whether the Asterisk server is active or inactive.


<BR><BR><BR><BR>

<B><FONT SIZE=3>CONFERENCES TABLE</FONT></B><BR><BR>
<A NAME="conferences-conf_exten">
<BR>
<B>Conference Number - </B> This field is where you put the meetme conference dialpna number. It is also recommended that the meetme number in meetme.conf matches this number for each entry. This is for the conferences in astGUIclient and is used for leave-3way-call functionality in VICIDIAL.

<BR>
<A NAME="conferences-server_ip">
<BR>
<B>Server IP - </B> The menu where you select the Asterisk server that this conference will be on.






<BR><BR><BR><BR><BR><BR><BR><BR>
<BR><BR><BR><BR><BR><BR><BR><BR>
THE END
</TD></TR></TABLE></BODY></HTML>
<?
exit;

#### END HELP SCREENS
}








?>
<html>
<head>
<title>ASTERISK ADMIN: Administration - <? echo $process ?></title>
<script language="Javascript">
function openNewWindow(url) {
  window.open (url,"",'width=500,height=300,scrollbars=yes,menubar=yes,address=yes');
}
</script>
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

echo "<center><TABLE width=600 cellspacing=3>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone extension: </td><td align=left><input type=text name=extension size=20 maxlength=100 value=\"\">$NWB#phones-extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dialplan Number: </td><td align=left><input type=text name=dialplan_number size=15 maxlength=20 value=\"$row[1]\"> (digits only)$NWB#phones-dialplan_number$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail Box: </td><td align=left><input type=text name=voicemail_id size=10 maxlength=10 value=\"$row[2]\"> (digits only)$NWB#phones-voicemail_id$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone IP address: </td><td align=left><input type=text name=phone_ip size=20 maxlength=15 value=\"$row[3]\"> (optional)$NWB#phones-phone_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Computer IP address: </td><td align=left><input type=text name=computer_ip size=20 maxlength=15 value=\"$row[4]\"> (optional)$NWB#phones-computer_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[5]</option>\n";
echo "</select>$NWB#phones-server_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Login: </td><td align=left><input type=text name=login size=10 maxlength=10 value=\"$row[6]\">$NWB#phones-login$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=10 maxlength=10 value=\"$row[7]\">$NWB#phones-pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Status: </td><td align=left><select size=1 name=status><option>ACTIVE</option><option>SUSPENDED</option><option>CLOSED</option><option>PENDING</option><option>ADMIN</option><option selected>$row[8]</option></select>$NWB#phones-status$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active Account: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[9]</option></select>$NWB#phones-active$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone Type: </td><td align=left><input type=text name=phone_type size=20 maxlength=50 value=\"$row[10]\">$NWB#phones-phone_type$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=fullname size=20 maxlength=50 value=\"$row[11]\">$NWB#phones-fullname$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Company: </td><td align=left><input type=text name=company size=10 maxlength=10 value=\"$row[12]\">$NWB#phones-company$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Picture: </td><td align=left><input type=text name=picture size=20 maxlength=19 value=\"$row[13]\">$NWB#phones-picture$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Client Protocol: </td><td align=left><select size=1 name=protocol><option>SIP</option><option>Zap</option><option>IAX2</option><option>EXTERNAL</option><option selected>$row[16]</option></select>$NWB#phones-protocol$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Local GMT: </td><td align=left><select size=1 name=local_gmt><option>12</option><option>11</option><option>10</option><option>9</option><option>8</option><option>7</option><option>6</option><option>5</option><option>4</option><option>3</option><option>2</option><option>1</option><option>0</option><option>-1</option><option>-2</option><option>-3</option><option>-4</option><option>-5</option><option>-6</option><option>-7</option><option>-8</option><option>-9</option><option>-10</option><option>-11</option><option>-12</option><option selected>$row[17]</option></select> (Do NOT Adjust for DST)$NWB#phones-local_gmt$NWE</td></tr>\n";
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
echo "<tr bgcolor=#B6D3FC><td align=right>Server ID: </td><td align=left><input type=text name=server_id size=10 maxlength=10>$NWB#servers-server_id$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server Description: </td><td align=left><input type=text name=server_description size=30 maxlength=255>$NWB#servers-server_description$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP Address: </td><td align=left><input type=text name=server_ip size=20 maxlength=15>$NWB#servers-server_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option></select>$NWB#servers-active$NWE</td></tr>\n";
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
echo "<tr bgcolor=#B6D3FC><td align=right>Conference Number: </td><td align=left><input type=text name=conf_exten size=8 maxlength=7> (digits only)$NWB#conferences-conf_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$server_ip</option>\n";
echo "</select>$NWB#conferences-server_ip$NWE</td></tr>\n";
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
		{echo "<br>PHONE NOT ADDED - there is already a Phone in the system with this extension/server\n";}
	else
		{
		 if ( (strlen($extension) < 1) or (strlen($server_ip) < 7) or (strlen($dialplan_number) < 1) or (strlen($voicemail_id) < 1) or (strlen($login) < 1)  or (strlen($pass) < 1))
			{echo "<br>PHONE NOT ADDED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>PHONE ADDED\n";

			$stmt="INSERT INTO phones (extension,dialplan_number,voicemail_id,phone_ip,computer_ip,server_ip,login,pass,status,active,phone_type,fullname,company,picture,protocol,local_gmt) values('$extension','$dialplan_number','$voicemail_id','$phone_ip','$computer_ip','$server_ip','$login','$pass','$status','$active','$phone_type','$fullname','$company','$picture','$protocol','$local_gmt');";
			$rslt=mysql_query($stmt, $link);
			}
		}
$ADD=3;
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
echo "<tr bgcolor=#B6D3FC><td align=right>Phone extension: </td><td align=left><input type=text name=extension size=20 maxlength=100 value=\"$row[0]\">$NWB#phones-extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dialplan Number: </td><td align=left><input type=text name=dialplan_number size=15 maxlength=20 value=\"$row[1]\"> (digits only)$NWB#phones-dialplan_number$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail Box: </td><td align=left><input type=text name=voicemail_id size=10 maxlength=10 value=\"$row[2]\"> (digits only)$NWB#phones-voicemail_id$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone IP address: </td><td align=left><input type=text name=phone_ip size=20 maxlength=15 value=\"$row[3]\"> (optional)$NWB#phones-phone_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Computer IP address: </td><td align=left><input type=text name=computer_ip size=20 maxlength=15 value=\"$row[4]\"> (optional)$NWB#phones-computer_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[5]</option>\n";
echo "</select>$NWB#phones-server_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Login: </td><td align=left><input type=text name=login size=10 maxlength=10 value=\"$row[6]\">$NWB#phones-login$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=10 maxlength=10 value=\"$row[7]\">$NWB#phones-pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Status: </td><td align=left><select size=1 name=status><option>ACTIVE</option><option>SUSPENDED</option><option>CLOSED</option><option>PENDING</option><option>ADMIN</option><option selected>$row[8]</option></select>$NWB#phones-status$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active Account: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[9]</option></select>$NWB#phones-active$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone Type: </td><td align=left><input type=text name=phone_type size=20 maxlength=50 value=\"$row[10]\">$NWB#phones-phone_type$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=fullname size=20 maxlength=50 value=\"$row[11]\">$NWB#phones-fullname$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Company: </td><td align=left><input type=text name=company size=10 maxlength=10 value=\"$row[12]\">$NWB#phones-company$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Picture: </td><td align=left><input type=text name=picture size=20 maxlength=19 value=\"$row[13]\">$NWB#phones-picture$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>New Messages: </td><td align=left><b>$row[14]</b>$NWB#phones-messages$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Old Messages: </td><td align=left><b>$row[15]</b>$NWB#phones-old_messages$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Client Protocol: </td><td align=left><select size=1 name=protocol><option>SIP</option><option>Zap</option><option>IAX2</option><option>EXTERNAL</option><option selected>$row[16]</option></select>$NWB#phones-protocol$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Local GMT: </td><td align=left><select size=1 name=local_gmt><option>12</option><option>11</option><option>10</option><option>9</option><option>8</option><option>7</option><option>6</option><option>5</option><option>4</option><option>3</option><option>2</option><option>1</option><option>0</option><option>-1</option><option>-2</option><option>-3</option><option>-4</option><option>-5</option><option>-6</option><option>-7</option><option>-8</option><option>-9</option><option>-10</option><option>-11</option><option>-12</option><option selected>$row[17]</option></select> (Do NOT Adjust for DST)$NWB#phones-local_gmt$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Manager Login: </td><td align=left><input type=text name=ASTmgrUSERNAME size=20 maxlength=20 value=\"$row[18]\">$NWB#phones-ASTmgrUSERNAME$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Manager Secret: </td><td align=left><input type=text name=ASTmgrSECRET size=20 maxlength=20 value=\"$row[19]\">$NWB#phones-ASTmgrSECRET$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default User: </td><td align=left><input type=text name=login_user size=20 maxlength=20 value=\"$row[20]\">$NWB#phones-login_user$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default Pass: </td><td align=left><input type=text name=login_pass size=20 maxlength=20 value=\"$row[21]\">$NWB#phones-login_pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default Campaign: </td><td align=left><input type=text name=login_campaign size=10 maxlength=10 value=\"$row[22]\">$NWB#phones-login_campaign$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Park Exten: </td><td align=left><input type=text name=park_on_extension size=10 maxlength=10 value=\"$row[23]\">$NWB#phones-park_on_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Conf Exten: </td><td align=left><input type=text name=conf_on_extension size=10 maxlength=10 value=\"$row[24]\">$NWB#phones-conf_on_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Park Exten: </td><td align=left><input type=text name=VICIDIAL_park_on_extension size=10 maxlength=10 value=\"$row[25]\">$NWB#phones-VICIDIAL_park_on_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Park File: </td><td align=left><input type=text name=VICIDIAL_park_on_filename size=10 maxlength=10 value=\"$row[26]\">$NWB#phones-VICIDIAL_park_on_filename$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Monitor Prefix: </td><td align=left><input type=text name=monitor_prefix size=10 maxlength=10 value=\"$row[27]\">$NWB#phones-monitor_prefix$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Recording Exten: </td><td align=left><input type=text name=recording_exten size=10 maxlength=10 value=\"$row[28]\">$NWB#phones-recording_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VMailMain Exten: </td><td align=left><input type=text name=voicemail_exten size=10 maxlength=10 value=\"$row[29]\">$NWB#phones-voicemail_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VMailDump Exten: </td><td align=left><input type=text name=voicemail_dump_exten size=20 maxlength=20 value=\"$row[30]\">$NWB#phones-voicemail_dump_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Exten Context: </td><td align=left><input type=text name=ext_context size=20 maxlength=20 value=\"$row[31]\">$NWB#phones-ext_context$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DTMFSend Channel: </td><td align=left><input type=text name=dtmf_send_extension size=40 maxlength=100 value=\"$row[32]\">$NWB#phones-dtmf_send_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Outbound Call Group: </td><td align=left><input type=text name=call_out_number_group size=40 maxlength=100 value=\"$row[33]\">$NWB#phones-call_out_number_group$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Browser Location: </td><td align=left><input type=text name=client_browser size=40 maxlength=100 value=\"$row[34]\">$NWB#phones-client_browser$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Install Directory: </td><td align=left><input type=text name=install_directory size=40 maxlength=100 value=\"$row[35]\">$NWB#phones-install_directory$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>CallerID URL: </td><td align=left><input type=text name=local_web_callerID_URL size=40 maxlength=255 value=\"$row[36]\">$NWB#phones-local_web_callerID_URL$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default URL: </td><td align=left><input type=text name=VICIDIAL_web_URL size=40 maxlength=255 value=\"$row[37]\">$NWB#phones-VICIDIAL_web_URL$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Call Logging: </td><td align=left><select size=1 name=AGI_call_logging_enabled><option>1</option><option>0</option><option selected>$row[38]</option></select>$NWB#phones-AGI_call_logging_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Switching: </td><td align=left><select size=1 name=user_switching_enabled><option>1</option><option>0</option><option selected>$row[39]</option></select>$NWB#phones-user_switching_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Conferencing: </td><td align=left><select size=1 name=conferencing_enabled><option>1</option><option>0</option><option selected>$row[40]</option></select>$NWB#phones-conferencing_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Admin Hangup: </td><td align=left><select size=1 name=admin_hangup_enabled><option>1</option><option>0</option><option selected>$row[41]</option></select>$NWB#phones-admin_hangup_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Admin Hijack: </td><td align=left><select size=1 name=admin_hijack_enabled><option>1</option><option>0</option><option selected>$row[42]</option></select>$NWB#phones-admin_hijack_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Admin Monitor: </td><td align=left><select size=1 name=admin_monitor_enabled><option>1</option><option>0</option><option selected>$row[43]</option></select>$NWB#phones-admin_monitor_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Call Park: </td><td align=left><select size=1 name=call_parking_enabled><option>1</option><option>0</option><option selected>$row[44]</option></select>$NWB#phones-call_parking_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Updater Check: </td><td align=left><select size=1 name=updater_check_enabled><option>1</option><option>0</option><option selected>$row[45]</option></select>$NWB#phones-updater_check_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>AF Logging: </td><td align=left><select size=1 name=AFLogging_enabled><option>1</option><option>0</option><option selected>$row[46]</option></select>$NWB#phones-AFLogging_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Queue Enabled: </td><td align=left><select size=1 name=QUEUE_ACTION_enabled><option>1</option><option>0</option><option selected>$row[47]</option></select>$NWB#phones-QUEUE_ACTION_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>CallerID Popup: </td><td align=left><select size=1 name=CallerID_popup_enabled><option>1</option><option>0</option><option selected>$row[48]</option></select>$NWB#phones-CallerID_popup_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VMail Button: </td><td align=left><select size=1 name=voicemail_button_enabled><option>1</option><option>0</option><option selected>$row[49]</option></select>$NWB#phones-voicemail_button_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Fast Refresh: </td><td align=left><select size=1 name=enable_fast_refresh><option>1</option><option>0</option><option selected>$row[50]</option></select>$NWB#phones-enable_fast_refresh$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Fast Refresh Rate: </td><td align=left><input type=text size=5 name=fast_refresh_rate value=\"$row[51]\">(in ms)$NWB#phones-fast_refresh_rate$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Persistant MySQL: </td><td align=left><select size=1 name=enable_persistant_mysql><option>1</option><option>0</option><option selected>$row[52]</option></select>$NWB#phones-enable_persistant_mysql$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Auto Dial Next Number: </td><td align=left><select size=1 name=auto_dial_next_number><option>1</option><option>0</option><option selected>$row[53]</option></select>$NWB#phones-auto_dial_next_number$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Stop Rec after each call: </td><td align=left><select size=1 name=VDstop_rec_after_each_call><option>1</option><option>0</option><option selected>$row[54]</option></select>$NWB#phones-VDstop_rec_after_each_call$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Server: </td><td align=left><input type=text name=DBX_server size=15 maxlength=15 value=\"$row[55]\"> (Primary DB Server)$NWB#phones-DBX_server$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Database: </td><td align=left><input type=text name=DBX_database size=15 maxlength=15 value=\"$row[56]\"> (Primary Server Database)$NWB#phones-DBX_database$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX User: </td><td align=left><input type=text name=DBX_user size=15 maxlength=15 value=\"$row[57]\"> (Primary DB Login)$NWB#phones-DBX_user$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Pass: </td><td align=left><input type=text name=DBX_pass size=15 maxlength=15 value=\"$row[58]\"> (Primary DB Secret)$NWB#phones-DBX_pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Port: </td><td align=left><input type=text name=DBX_port size=6 maxlength=6 value=\"$row[59]\"> (Primary DB Port)$NWB#phones-DBX_port$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Server: </td><td align=left><input type=text name=DBY_server size=15 maxlength=15 value=\"$row[60]\"> (Secondary DB Server)$NWB#phones-DBY_server$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Database: </td><td align=left><input type=text name=DBY_database size=15 maxlength=15 value=\"$row[61]\"> (Secondary Server Database)$NWB#phones-DBY_database$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY User: </td><td align=left><input type=text name=DBY_user size=15 maxlength=15 value=\"$row[62]\"> (Secondary DB Login)$NWB#phones-DBY_user$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Pass: </td><td align=left><input type=text name=DBY_pass size=15 maxlength=15 value=\"$row[63]\"> (Secondary DB Secret)$NWB#phones-DBY_pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Port: </td><td align=left><input type=text name=DBY_port size=6 maxlength=6 value=\"$row[64]\"> (Secondary DB Port)$NWB#phones-DBY_port$NWE</td></tr>\n";
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
echo "<tr bgcolor=#B6D3FC><td align=right>Server ID: </td><td align=left><input type=text name=server_id size=10 maxlength=10 value=\"$row[0]\">$NWB#servers-server_id$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server Description: </td><td align=left><input type=text name=server_description size=30 maxlength=255 value=\"$row[1]\">$NWB#servers-server_description$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP Address: </td><td align=left><input type=text name=server_ip size=20 maxlength=15 value=\"$row[2]\">$NWB#servers-server_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[3]</option></select>$NWB#servers-active$NWE</td></tr>\n";
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
echo "<tr bgcolor=#B6D3FC><td align=right>Conference: </td><td align=left><input type=text name=conf_exten size=10 maxlength=7 value=\"$row[0]\">$NWB#conferences-conf_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[1]</option>\n";
echo "</select>$NWB#conferences-server_ip$NWE</td></tr>\n";
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
		{echo "<br>PHONE NOT MODIFIED - there is already a Phone in the system with this extension/server\n";}
	else
		{
			 if ( (strlen($extension) < 1) or (strlen($server_ip) < 7) or (strlen($dialplan_number) < 1) or (strlen($voicemail_id) < 1) or (strlen($login) < 1)  or (strlen($pass) < 1))
			{echo "<br>PHONE NOT MODIFIED - Please go back and look at the data you entered\n";}
		 else
			{
			echo "<br>PHONE MODIFIED: $extension\n";

			$stmt="UPDATE phones set extension='$extension', dialplan_number='$dialplan_number', voicemail_id='$voicemail_id', phone_ip='$phone_ip', computer_ip='$computer_ip', server_ip='$server_ip', login='$login', pass='$pass', status='$status', active='$active', phone_type='$phone_type', fullname='$fullname', company='$company', picture='$picture', protocol='$protocol', local_gmt='$local_gmt', ASTmgrUSERNAME='$ASTmgrUSERNAME', ASTmgrSECRET='$ASTmgrSECRET', login_user='$login_user', login_pass='$login_pass', login_campaign='$login_campaign', park_on_extension='$park_on_extension', conf_on_extension='$conf_on_extension', VICIDIAL_park_on_extension='$VICIDIAL_park_on_extension', VICIDIAL_park_on_filename='$VICIDIAL_park_on_filename', monitor_prefix='$monitor_prefix', recording_exten='$recording_exten', voicemail_exten='$voicemail_exten', voicemail_dump_exten='$voicemail_dump_exten', ext_context='$ext_context', dtmf_send_extension='$dtmf_send_extension', call_out_number_group='$call_out_number_group', client_browser='$client_browser', install_directory='$install_directory', local_web_callerID_URL='$local_web_callerID_URL', VICIDIAL_web_URL='$VICIDIAL_web_URL', AGI_call_logging_enabled='$AGI_call_logging_enabled', user_switching_enabled='$user_switching_enabled', conferencing_enabled='$conferencing_enabled', admin_hangup_enabled='$admin_hangup_enabled', admin_hijack_enabled='$admin_hijack_enabled', admin_monitor_enabled='$admin_monitor_enabled', call_parking_enabled='$call_parking_enabled', updater_check_enabled='$updater_check_enabled', AFLogging_enabled='$AFLogging_enabled', QUEUE_ACTION_enabled='$QUEUE_ACTION_enabled', CallerID_popup_enabled='$CallerID_popup_enabled', voicemail_button_enabled='$voicemail_button_enabled', enable_fast_refresh='$enable_fast_refresh', fast_refresh_rate='$fast_refresh_rate', enable_persistant_mysql='$enable_persistant_mysql', auto_dial_next_number='$auto_dial_next_number', VDstop_rec_after_each_call='$VDstop_rec_after_each_call', DBX_server='$DBX_server', DBX_database='$DBX_database', DBX_user='$DBX_user', DBX_pass='$DBX_pass', DBX_port='$DBX_port', DBY_server='$DBY_server', DBY_database='$DBY_database', DBY_user='$DBY_user', DBY_pass='$DBY_pass', DBY_port='$DBY_port' where extension='$old_extension' and server_ip='$old_server_ip';";
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
echo "<tr bgcolor=#B6D3FC><td align=right>Phone extension: </td><td align=left><input type=text name=extension size=20 maxlength=100 value=\"$row[0]\">$NWB#phones-extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Dialplan Number: </td><td align=left><input type=text name=dialplan_number size=15 maxlength=20 value=\"$row[1]\"> (digits only)$NWB#phones-dialplan_number$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Voicemail Box: </td><td align=left><input type=text name=voicemail_id size=10 maxlength=10 value=\"$row[2]\"> (digits only)$NWB#phones-voicemail_id$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone IP address: </td><td align=left><input type=text name=phone_ip size=20 maxlength=15 value=\"$row[3]\"> (optional)$NWB#phones-phone_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Computer IP address: </td><td align=left><input type=text name=computer_ip size=20 maxlength=15 value=\"$row[4]\"> (optional)$NWB#phones-computer_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[5]</option>\n";
echo "</select>$NWB#phones-server_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Login: </td><td align=left><input type=text name=login size=10 maxlength=10 value=\"$row[6]\">$NWB#phones-login$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Password: </td><td align=left><input type=text name=pass size=10 maxlength=10 value=\"$row[7]\">$NWB#phones-pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Status: </td><td align=left><select size=1 name=status><option>ACTIVE</option><option>SUSPENDED</option><option>CLOSED</option><option>PENDING</option><option>ADMIN</option><option selected>$row[8]</option></select>$NWB#phones-status$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active Account: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[9]</option></select>$NWB#phones-active$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Phone Type: </td><td align=left><input type=text name=phone_type size=20 maxlength=50 value=\"$row[10]\">$NWB#phones-phone_type$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Full Name: </td><td align=left><input type=text name=fullname size=20 maxlength=50 value=\"$row[11]\">$NWB#phones-fullname$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Company: </td><td align=left><input type=text name=company size=10 maxlength=10 value=\"$row[12]\">$NWB#phones-company$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Picture: </td><td align=left><input type=text name=picture size=20 maxlength=19 value=\"$row[13]\">$NWB#phones-picture$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>New Messages: </td><td align=left><b>$row[14]</b>$NWB#phones-messages$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Old Messages: </td><td align=left><b>$row[15]</b>$NWB#phones-old_messages$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Client Protocol: </td><td align=left><select size=1 name=protocol><option>SIP</option><option>Zap</option><option>IAX2</option><option>EXTERNAL</option><option selected>$row[16]</option></select>$NWB#phones-protocol$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Local GMT: </td><td align=left><select size=1 name=local_gmt><option>12</option><option>11</option><option>10</option><option>9</option><option>8</option><option>7</option><option>6</option><option>5</option><option>4</option><option>3</option><option>2</option><option>1</option><option>0</option><option>-1</option><option>-2</option><option>-3</option><option>-4</option><option>-5</option><option>-6</option><option>-7</option><option>-8</option><option>-9</option><option>-10</option><option>-11</option><option>-12</option><option selected>$row[17]</option></select> (Do NOT Adjust for DST)$NWB#phones-local_gmt$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Manager Login: </td><td align=left><input type=text name=ASTmgrUSERNAME size=20 maxlength=20 value=\"$row[18]\">$NWB#phones-ASTmgrUSERNAME$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Manager Secret: </td><td align=left><input type=text name=ASTmgrSECRET size=20 maxlength=20 value=\"$row[19]\">$NWB#phones-ASTmgrSECRET$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default User: </td><td align=left><input type=text name=login_user size=20 maxlength=20 value=\"$row[20]\">$NWB#phones-login_user$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default Pass: </td><td align=left><input type=text name=login_pass size=20 maxlength=20 value=\"$row[21]\">$NWB#phones-login_pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default Campaign: </td><td align=left><input type=text name=login_campaign size=10 maxlength=10 value=\"$row[22]\">$NWB#phones-login_campaign$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Park Exten: </td><td align=left><input type=text name=park_on_extension size=10 maxlength=10 value=\"$row[23]\">$NWB#phones-park_on_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Conf Exten: </td><td align=left><input type=text name=conf_on_extension size=10 maxlength=10 value=\"$row[24]\">$NWB#phones-conf_on_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Park Exten: </td><td align=left><input type=text name=VICIDIAL_park_on_extension size=10 maxlength=10 value=\"$row[25]\">$NWB#phones-VICIDIAL_park_on_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Park File: </td><td align=left><input type=text name=VICIDIAL_park_on_filename size=10 maxlength=10 value=\"$row[26]\">$NWB#phones-VICIDIAL_park_on_filename$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Monitor Prefix: </td><td align=left><input type=text name=monitor_prefix size=10 maxlength=10 value=\"$row[27]\">$NWB#phones-monitor_prefix$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Recording Exten: </td><td align=left><input type=text name=recording_exten size=10 maxlength=10 value=\"$row[28]\">$NWB#phones-recording_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VMailMain Exten: </td><td align=left><input type=text name=voicemail_exten size=10 maxlength=10 value=\"$row[29]\">$NWB#phones-voicemail_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VMailDump Exten: </td><td align=left><input type=text name=voicemail_dump_exten size=20 maxlength=20 value=\"$row[30]\">$NWB#phones-voicemail_dump_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Exten Context: </td><td align=left><input type=text name=ext_context size=20 maxlength=20 value=\"$row[31]\">$NWB#phones-ext_context$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DTMFSend Channel: </td><td align=left><input type=text name=dtmf_send_extension size=40 maxlength=100 value=\"$row[32]\">$NWB#phones-dtmf_send_extension$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Outbound Call Group: </td><td align=left><input type=text name=call_out_number_group size=40 maxlength=100 value=\"$row[33]\">$NWB#phones-call_out_number_group$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Browser Location: </td><td align=left><input type=text name=client_browser size=40 maxlength=100 value=\"$row[34]\">$NWB#phones-client_browser$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Install Directory: </td><td align=left><input type=text name=install_directory size=40 maxlength=100 value=\"$row[35]\">$NWB#phones-install_directory$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>CallerID URL: </td><td align=left><input type=text name=local_web_callerID_URL size=40 maxlength=255 value=\"$row[36]\">$NWB#phones-local_web_callerID_URL$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VICIDIAL Default URL: </td><td align=left><input type=text name=VICIDIAL_web_URL size=40 maxlength=255 value=\"$row[37]\">$NWB#phones-VICIDIAL_web_URL$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Call Logging: </td><td align=left><select size=1 name=AGI_call_logging_enabled><option>1</option><option>0</option><option selected>$row[38]</option></select>$NWB#phones-AGI_call_logging_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>User Switching: </td><td align=left><select size=1 name=user_switching_enabled><option>1</option><option>0</option><option selected>$row[39]</option></select>$NWB#phones-user_switching_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Conferencing: </td><td align=left><select size=1 name=conferencing_enabled><option>1</option><option>0</option><option selected>$row[40]</option></select>$NWB#phones-conferencing_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Admin Hangup: </td><td align=left><select size=1 name=admin_hangup_enabled><option>1</option><option>0</option><option selected>$row[41]</option></select>$NWB#phones-admin_hangup_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Admin Hijack: </td><td align=left><select size=1 name=admin_hijack_enabled><option>1</option><option>0</option><option selected>$row[42]</option></select>$NWB#phones-admin_hijack_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Admin Monitor: </td><td align=left><select size=1 name=admin_monitor_enabled><option>1</option><option>0</option><option selected>$row[43]</option></select>$NWB#phones-admin_monitor_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Call Park: </td><td align=left><select size=1 name=call_parking_enabled><option>1</option><option>0</option><option selected>$row[44]</option></select>$NWB#phones-call_parking_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Updater Check: </td><td align=left><select size=1 name=updater_check_enabled><option>1</option><option>0</option><option selected>$row[45]</option></select>$NWB#phones-updater_check_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>AF Logging: </td><td align=left><select size=1 name=AFLogging_enabled><option>1</option><option>0</option><option selected>$row[46]</option></select>$NWB#phones-AFLogging_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Queue Enabled: </td><td align=left><select size=1 name=QUEUE_ACTION_enabled><option>1</option><option>0</option><option selected>$row[47]</option></select>$NWB#phones-QUEUE_ACTION_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>CallerID Popup: </td><td align=left><select size=1 name=CallerID_popup_enabled><option>1</option><option>0</option><option selected>$row[48]</option></select>$NWB#phones-CallerID_popup_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>VMail Button: </td><td align=left><select size=1 name=voicemail_button_enabled><option>1</option><option>0</option><option selected>$row[49]</option></select>$NWB#phones-voicemail_button_enabled$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Fast Refresh: </td><td align=left><select size=1 name=enable_fast_refresh><option>1</option><option>0</option><option selected>$row[50]</option></select>$NWB#phones-enable_fast_refresh$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Fast Refresh Rate: </td><td align=left><input type=text size=5 name=fast_refresh_rate value=\"$row[51]\">(in ms)$NWB#phones-fast_refresh_rate$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Persistant MySQL: </td><td align=left><select size=1 name=enable_persistant_mysql><option>1</option><option>0</option><option selected>$row[52]</option></select>$NWB#phones-enable_persistant_mysql$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Auto Dial Next Number: </td><td align=left><select size=1 name=auto_dial_next_number><option>1</option><option>0</option><option selected>$row[53]</option></select>$NWB#phones-auto_dial_next_number$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Stop Rec after each call: </td><td align=left><select size=1 name=VDstop_rec_after_each_call><option>1</option><option>0</option><option selected>$row[54]</option></select>$NWB#phones-VDstop_rec_after_each_call$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Server: </td><td align=left><input type=text name=DBX_server size=15 maxlength=15 value=\"$row[55]\"> (Primary DB Server)$NWB#phones-DBX_server$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Database: </td><td align=left><input type=text name=DBX_database size=15 maxlength=15 value=\"$row[56]\"> (Primary Server Database)$NWB#phones-DBX_database$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX User: </td><td align=left><input type=text name=DBX_user size=15 maxlength=15 value=\"$row[57]\"> (Primary DB Login)$NWB#phones-DBX_user$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Pass: </td><td align=left><input type=text name=DBX_pass size=15 maxlength=15 value=\"$row[58]\"> (Primary DB Secret)$NWB#phones-DBX_pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBX Port: </td><td align=left><input type=text name=DBX_port size=6 maxlength=6 value=\"$row[59]\"> (Primary DB Port)$NWB#phones-DBX_port$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Server: </td><td align=left><input type=text name=DBY_server size=15 maxlength=15 value=\"$row[60]\"> (Secondary DB Server)$NWB#phones-DBY_server$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Database: </td><td align=left><input type=text name=DBY_database size=15 maxlength=15 value=\"$row[61]\"> (Secondary Server Database)$NWB#phones-DBY_database$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY User: </td><td align=left><input type=text name=DBY_user size=15 maxlength=15 value=\"$row[62]\"> (Secondary DB Login)$NWB#phones-DBY_user$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Pass: </td><td align=left><input type=text name=DBY_pass size=15 maxlength=15 value=\"$row[63]\"> (Secondary DB Secret)$NWB#phones-DBY_pass$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>DBY Port: </td><td align=left><input type=text name=DBY_port size=6 maxlength=6 value=\"$row[64]\"> (Secondary DB Port)$NWB#phones-DBY_port$NWE</td></tr>\n";
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
				echo "<br>SERVER MODIFIED: $server_ip\n";

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
echo "<tr bgcolor=#B6D3FC><td align=right>Server ID: </td><td align=left><input type=text name=server_id size=10 maxlength=10 value=\"$row[0]\">$NWB#servers-server_id$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server Description: </td><td align=left><input type=text name=server_description size=30 maxlength=255 value=\"$row[1]\">$NWB#servers-server_description$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP Address: </td><td align=left><input type=text name=server_ip size=20 maxlength=15 value=\"$row[2]\">$NWB#servers-server_ip$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Active: </td><td align=left><select size=1 name=active><option>Y</option><option>N</option><option selected>$row[3]</option></select>$NWB#servers-active$NWE</td></tr>\n";
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
echo "<tr bgcolor=#B6D3FC><td align=right>Conference: </td><td align=left><input type=text name=conf_exten size=10 maxlength=7 value=\"$row[0]\">$NWB#conferences-conf_exten$NWE</td></tr>\n";
echo "<tr bgcolor=#B6D3FC><td align=right>Server IP: </td><td align=left><select size=1 name=server_ip>\n";

echo "$servers_list";
echo "<option SELECTED>$row[1]</option>\n";
echo "</select>$NWB#conferences-server_ip$NWE</td></tr>\n";
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
# ADD=6 phone search results
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
# ADD=0 display all active phones
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
		echo "<tr $bgcolor><td><font size=1>$row[0]</td><td><font size=1>$row[16]</td><td><font size=1>$row[5]</td><td><font size=1>$row[1]</td><td><font size=1>$row[2]</td><td><font size=1>$row[8]</td><td><font size=1>$row[11]</td><td><font size=1>$row[14]</td><td><font size=1>$row[15]</td>";
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





