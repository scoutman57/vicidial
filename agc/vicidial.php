<?
### vicidial.php - the web-based version of the astVICIDIAL client application
### 
### make sure you have added a user to the vicidial_users MySQL table with at least
### user_level 1 or greater to access this page. Also, you need to have the login
### and pass of a phone listed in the asterisk.phones table. The page grabs the 
### server info and other details from this login and pass.
###
### This script works best with Firefox or Mozilla, but will run for a couple
### hours on Internet Explorer before the memory leaks cause a crash.
###
### Other scripts that this application depends on:
### - vdc_db_query.php: Updates information in the database
### - manager_send.php: Sends manager actions to the DB for execution
###
### CHANGES
### 50607-1426 - First Build of VICIDIAL web client basic login process finished
### 50628-1620 - Added some basic formatting and worked on process flow
### 50628-1715 - Startup variables mapped to javascript variables
### 50629-1303 - Added Login Closer in-groups selection box and vla update
### 50629-1530 - Rough layout for customer info form section and button links
### 50630-1453 - Rough Manual Dial/Hangup with customer info displayed
### 50701-1450 - Added vicidial_log entries on dial and hangup
### 50701-1634 - Added Logout function
### 50705-1259 - Added call disposition functionality
### 50705-1432 - Added lead info DB update function
### 50705-1658 - Added web form functionality
### 50706-1043 - Added call park and pickup functions
### 50706-1234 - Added Start/Stop Recording functionality
### 50706-1614 - Added conference channels display option
### 50711-1333 - Removed call check redundancy and fixed a span bug
### 50727-1424 - Added customer channel and participant present sensing/alerts
### 50804-1057 - Added SendDTMF function and reconfigured the transfer span
### 50804-1224 - Added Local and Internal Closer transfer functions
### 50804-1628 - Added Blind transfer, activated LIVE CALL image and fixed bugs
### 50804-1808 - Added button images for left buttons
### 50815-1151 - Added 3Way calling functions to Transfer-conf frame
### 50815-1602 - Added images and buttons for xfer functions
### 50816-1813 - Added basic autodial outbound call pickup functions
### 50817-1113 - Fixes to auto_dialing call receipt
### 50817-1234 - Added inbound call receipt capability
### 50817-1541 - Added customer time display
### 50817-1541 - Added customer time display
### 50818-1327 - Added stop-all-recordings-after-each-vicidial-call option
### 50818-1703 - Added pretty login section
### 50825-1200 - Modified form field lengths, added double-click dispositions
### 

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
$DB=$_GET['DB'];						if (!$DB) {$DB=$_POST["DB"];}
$phone_login=$_GET['phone_login'];		if (!$phone_login) {$phone_login=$_POST["phone_login"];}
	if (!$phone_login) {$phone_login=$_GET["pl"];}
$phone_pass=$_GET['phone_pass'];		if (!$phone_pass) {$phone_pass=$_POST["phone_pass"];}
	if (!$phone_pass) {$phone_pass=$_GET["pp"];}
$VD_login=$_GET['VD_login'];			if (!$VD_login) {$VD_login=$_POST["VD_login"];}
$VD_pass=$_GET['VD_pass'];				if (!$VD_pass) {$VD_pass=$_POST["VD_pass"];}
$VD_campaign=$_GET['VD_campaign'];		if (!$VD_campaign) {$VD_campaign=$_POST["VD_campaign"];}
	$VD_campaign = strtoupper($VD_campaign);
$relogin=$_GET['relogin'];				if (!$relogin) {$relogin=$_POST["relogin"];}

$forever_stop=0;

$version = '0.0.29';
$build = '50825-1200';

if ($force_logout)
{
    echo "You have now logged out. Thank you\n";
    exit;
}

$STARTtime = date("U");
$NOW_TIME = date("Y-m-d H:i:s");
$tsNOW_TIME = date("YmdHis");
$FILE_TIME = date("Ymd-His");
$CIDdate = date("ymdHis");
	$month_old = mktime(0, 0, 0, date("m"), date("d")-2,  date("Y"));
	$past_month_date = date("Y-m-d H:i:s",$month_old);

$random = (rand(1000000, 9999999) + 10000000);

$conf_silent_prefix = '7';

$US='_';
$AT='@';
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");
$script_name = getenv("SCRIPT_NAME");
$server_name = getenv("SERVER_NAME");
$server_port = getenv("SERVER_PORT");
if (eregi("443",$server_port)) {$HTTPprotocol = 'https://';}
  else {$HTTPprotocol = 'http://';}
$agcDIR = "$HTTPprotocol$server_name$script_name";
$agcDIR = eregi_replace('astguiclient.php','',$agcDIR);

header ("Cache-Control: no-cache, must-revalidate");  // HTTP/1.1
header ("Pragma: no-cache");                          // HTTP/1.0
echo "<html>\n";
echo "<head>\n";
echo "<!-- VERSION: $version     BUILD: $build -->\n";

if ($relogin == 'YES')
{
echo "<title>VICIDIAL web client: Re-Login</title>\n";
echo "<FORM ACTION=\"$agcDIR\" METHOD=POST>\n";
echo "<INPUT TYPE=HIDDEN NAME=DB VALUE=\"$DB\">\n";
echo "<BR><BR><BR><CENTER><TABLE WIDTH=300 CELLPADDING=0 CELLSPACING=0 BGCOLOR=\"#E0C2D6\"><TR BGCOLOR=WHITE>";
echo "<TD ALIGN=LEFT VALIGN=BOTTOM><IMG SRC=\"./images/vdc_tab_vicidial.gif\" BORDER=0></TD>";
echo "<TD ALIGN=CENTER VALIGN=MIDDLE> Re-Login </TD>";
echo "</TR>\n";
echo "<TR><TD ALIGN=LEFT COLSPAN=2><font size=1> &nbsp; </TD></TR>\n";
echo "<TR><TD ALIGN=RIGHT>Phone Login: </TD>";
echo "<TD ALIGN=LEFT><INPUT TYPE=TEXT NAME=phone_login SIZE=10 MAXLENGTH=20 VALUE=\"$phone_login\"></TD></TR>\n";
echo "<TR><TD ALIGN=RIGHT>Phone Password:  </TD>";
echo "<TD ALIGN=LEFT><INPUT TYPE=PASSWORD NAME=phone_pass SIZE=10 MAXLENGTH=20 VALUE=\"$phone_pass\"></TD></TR>\n";
echo "<TR><TD ALIGN=RIGHT>User Login:  </TD>";
echo "<TD ALIGN=LEFT><INPUT TYPE=TEXT NAME=VD_login SIZE=10 MAXLENGTH=20 VALUE=\"$VD_login\"></TD></TR>\n";
echo "<TR><TD ALIGN=RIGHT>User Password:  </TD>";
echo "<TD ALIGN=LEFT><INPUT TYPE=PASSWORD NAME=VD_pass SIZE=10 MAXLENGTH=20 VALUE=\"$VD_pass\"></TD></TR>\n";
echo "<TR><TD ALIGN=RIGHT>Campaign:  </TD>";
echo "<TD ALIGN=LEFT><INPUT TYPE=TEXT NAME=VD_campaign SIZE=10 MAXLENGTH=20 VALUE=\"$VD_campaign\"></TD></TR>\n";
echo "<TR><TD ALIGN=CENTER COLSPAN=2><INPUT TYPE=SUBMIT NAME=SUBMIT VALUE=SUBMIT></TD></TR>\n";
echo "<TR><TD ALIGN=LEFT COLSPAN=2><font size=1><BR>VERSION: $version &nbsp; &nbsp; &nbsp; BUILD: $build</TD></TR>\n";
echo "</TABLE>\n";
echo "</FORM>\n\n";
echo "</body>\n\n";
echo "</html>\n\n";
exit;
}
if ( (strlen($phone_login)<2) or (strlen($phone_pass)<2) )
{
echo "<title>VICIDIAL web client:  Phone Login</title>\n";
echo "<FORM ACTION=\"$agcDIR\" METHOD=POST>\n";
echo "<INPUT TYPE=HIDDEN NAME=DB VALUE=\"$DB\">\n";
echo "<BR><BR><BR><CENTER><TABLE WIDTH=300 CELLPADDING=0 CELLSPACING=0 BGCOLOR=\"#E0C2D6\"><TR BGCOLOR=WHITE>";
echo "<TD ALIGN=LEFT VALIGN=BOTTOM><IMG SRC=\"./images/vdc_tab_vicidial.gif\" BORDER=0></TD>";
echo "<TD ALIGN=CENTER VALIGN=MIDDLE> Phone Login </TD>";
echo "</TR>\n";
echo "<TR><TD ALIGN=LEFT COLSPAN=2><font size=1> &nbsp; </TD></TR>\n";
echo "<TR><TD ALIGN=RIGHT>Phone Login: </TD>";
echo "<TD ALIGN=LEFT><INPUT TYPE=TEXT NAME=phone_login SIZE=10 MAXLENGTH=20 VALUE=\"\"></TD></TR>\n";
echo "<TR><TD ALIGN=RIGHT>Phone Password:  </TD>";
echo "<TD ALIGN=LEFT><INPUT TYPE=PASSWORD NAME=phone_pass SIZE=10 MAXLENGTH=20 VALUE=\"\"></TD></TR>\n";
echo "<TR><TD ALIGN=CENTER COLSPAN=2><INPUT TYPE=SUBMIT NAME=SUBMIT VALUE=SUBMIT></TD></TR>\n";
echo "<TR><TD ALIGN=LEFT COLSPAN=2><font size=1><BR>VERSION: $version &nbsp; &nbsp; &nbsp; BUILD: $build</TD></TR>\n";
echo "</TABLE>\n";
echo "</FORM>\n\n";
echo "</body>\n\n";
echo "</html>\n\n";
exit;
}
else
{
$fp = fopen ("./vicidial_auth_entries.txt", "a");
$VDloginDISPLAY=0;

	if ( (strlen($VD_login)<2) or (strlen($VD_pass)<2) or (strlen($VD_campaign)<2) )
	{
	$VDloginDISPLAY=1;
	}
	else
	{
	$stmt="SELECT count(*) from vicidial_users where user='$VD_login' and pass='$VD_pass' and user_level > 0;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

	if($auth>0)
		{
		$login=strtoupper($VD_login);
		$password=strtoupper($VD_pass);
		##### grab the full name of the agent
		$stmt="SELECT full_name,user_level from vicidial_users where user='$VD_login' and pass='$VD_pass'";
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$LOGfullname=$row[0];
		fwrite ($fp, "vdweb|GOOD|$date|$VD_login|$VD_pass|$ip|$browser|$LOGfullname|\n");
		fclose($fp);

		$user_abb = "$VD_login$VD_login$VD_login$VD_login";
		while ( (strlen($user_abb) > 4) and ($forever_stop < 200) )
			{$user_abb = eregi_replace("^.","",$user_abb);   $forever_stop++;}

		##### check to see that the campaign is active
		$stmt="SELECT count(*) FROM vicidial_campaigns where campaign_id='$VD_campaign' and active='Y';";
		if ($DB) {echo "|$stmt|\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$CAMPactive=$row[0];
		if($CAMPactive>0)
			{
			$VARstatuses='';
			$VARstatusnames='';
			##### grab the statuses that can be used for dispositioning by an agent
			$stmt="SELECT status,status_name FROM vicidial_statuses WHERE selectable='Y' and status != 'NEW' order by status limit 50;";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$VD_statuses_ct = mysql_num_rows($rslt);
			$i=0;
			while ($i < $VD_statuses_ct)
				{
				$row=mysql_fetch_row($rslt);
				$statuses[$i] =$row[0];
				$status_names[$i] =$row[1];
				$VARstatuses = "$VARstatuses'$statuses[$i]',";
				$VARstatusnames = "$VARstatusnames'$status_names[$i]',";
				$i++;
				}

			##### grab the campaign-specific statuses that can be used for dispositioning by an agent
			$stmt="SELECT status,status_name FROM vicidial_campaign_statuses WHERE selectable='Y' and status != 'NEW' and campaign_id='$VD_campaign' order by status limit 50;";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$VD_statuses_camp = mysql_num_rows($rslt);
			$j=0;
			while ($j < $VD_statuses_camp)
				{
				$row=mysql_fetch_row($rslt);
				$statuses[$i] =$row[0];
				$status_names[$i] =$row[1];
				$VARstatuses = "$VARstatuses'$statuses[$i]',";
				$VARstatusnames = "$VARstatusnames'$status_names[$i]',";
				$i++;
				$j++;
				}
			$VD_statuses_ct = ($VD_statuses_ct+$VD_statuses_camp);
			$VARstatuses = substr("$VARstatuses", 0, -1); 
			$VARstatusnames = substr("$VARstatusnames", 0, -1); 

			##### grab the inbound groups to choose from if campaign contains CLOSER
			$VARingroups="''";
			if (eregi("CLOSER", $VD_campaign))
				{
				$VARingroups='';
				$stmt="select group_id from vicidial_inbound_groups where active = 'Y' order by group_id limit 20;";
				$rslt=mysql_query($stmt, $link);
				if ($DB) {echo "$stmt\n";}
				$closer_ct = mysql_num_rows($rslt);
				$INgrpCT=0;
				while ($INgrpCT < $closer_ct)
					{
					$row=mysql_fetch_row($rslt);
					$closer_groups[$INgrpCT] =$row[0];
					$VARingroups = "$VARingroups'$closer_groups[$INgrpCT]',";
					$INgrpCT++;
					}
				$VARingroups = substr("$VARingroups", 0, -1); 
				}

			##### grab the statuses to be dialed for your campaign as well as other campaign settings
			$stmt="SELECT dial_status_a,dial_status_b,dial_status_c,dial_status_d,dial_status_e,park_ext,park_file_name,web_form_address,allow_closers,auto_dial_level,dial_timeout,dial_prefix,campaign_cid,campaign_vdad_exten FROM vicidial_campaigns where campaign_id = '$VD_campaign';";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$row=mysql_fetch_row($rslt);
			   $status_A = $row[0];
			   $status_B = $row[1];
			   $status_C = $row[2];
			   $status_D = $row[3];
			   $status_E = $row[4];
			   $park_ext = $row[5];
			   $park_file_name = $row[6];
			   $web_form_address = $row[7];
			   $allow_closers = $row[8];
			   $auto_dial_level = $row[9];
			   $dial_timeout = $row[10];
			   $dial_prefix = $row[11];
			   $campaign_cid = $row[12];
			   $campaign_vdad_exten = $row[13];

			##### grab the number of leads in the hopper for this campaign
			$stmt="SELECT count(*) FROM vicidial_hopper where campaign_id = '$VD_campaign' and status='READY';";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$row=mysql_fetch_row($rslt);
			   $campaign_leads_to_call = $row[0];
			   print "<!-- $campaign_leads_to_call - leads left to call in hopper -->\n";

			}
		else
			{
			$VDloginDISPLAY=1;
			$VDdisplayMESSAGE = "Campaign not active, please try again<BR>";
			}
		}
	else
		{
		fwrite ($fp, "vdweb|FAIL|$date|$VD_login|$VD_pass|$ip|$browser|\n");
		fclose($fp);
		$VDloginDISPLAY=1;
		$VDdisplayMESSAGE = "Login incorrect, please try again<BR>";
		}
	}
	if ($VDloginDISPLAY)
	{
	echo "<title>VICIDIAL web client: Campaign Login</title>\n";
	echo "<FORM ACTION=\"$agcDIR\" METHOD=POST>\n";
	echo "<INPUT TYPE=HIDDEN NAME=DB VALUE=\"$DB\">\n";
	echo "<INPUT TYPE=HIDDEN NAME=phone_login VALUE=\"$phone_login\">\n";
	echo "<INPUT TYPE=HIDDEN NAME=phone_pass VALUE=\"$phone_pass\">\n";
	echo "<BR><BR><BR><CENTER><TABLE WIDTH=300 CELLPADDING=0 CELLSPACING=0 BGCOLOR=\"#E0C2D6\"><TR BGCOLOR=WHITE>";
	echo "<TD ALIGN=LEFT VALIGN=BOTTOM><IMG SRC=\"./images/vdc_tab_vicidial.gif\" BORDER=0></TD>";
	echo "<TD ALIGN=CENTER VALIGN=MIDDLE> Campaign Login </TD>";
	echo "</TR>\n";
	echo "<TR><TD ALIGN=LEFT COLSPAN=2><font size=1> &nbsp; </TD></TR>\n";
	echo "<TR><TD ALIGN=RIGHT>User Login:  </TD>";
	echo "<TD ALIGN=LEFT><INPUT TYPE=TEXT NAME=VD_login SIZE=10 MAXLENGTH=20 VALUE=\"$VD_login\"></TD></TR>\n";
	echo "<TR><TD ALIGN=RIGHT>User Password:  </TD>";
	echo "<TD ALIGN=LEFT><INPUT TYPE=PASSWORD NAME=VD_pass SIZE=10 MAXLENGTH=20 VALUE=\"$VD_pass\"></TD></TR>\n";
	echo "<TR><TD ALIGN=RIGHT>Campaign:  </TD>";
	echo "<TD ALIGN=LEFT><INPUT TYPE=TEXT NAME=VD_campaign SIZE=10 MAXLENGTH=20 VALUE=\"$VD_campaign\"></TD></TR>\n";
	echo "<TR><TD ALIGN=CENTER COLSPAN=2><INPUT TYPE=SUBMIT NAME=SUBMIT VALUE=SUBMIT></TD></TR>\n";
	echo "<TR><TD ALIGN=LEFT COLSPAN=2><font size=1><BR>VERSION: $version &nbsp; &nbsp; &nbsp; BUILD: $build</TD></TR>\n";
	echo "</TABLE>\n";
	echo "</FORM>\n\n";
	echo "</body>\n\n";
	echo "</html>\n\n";
	exit;
	}

$authphone=0;
$stmt="SELECT count(*) from phones where login='$phone_login' and pass='$phone_pass' and active = 'Y';";
if ($DB) {echo "|$stmt|\n";}
$rslt=mysql_query($stmt, $link);
$row=mysql_fetch_row($rslt);
$authphone=$row[0];
if (!$authphone)
	{
	echo "<title>VICIDIAL web client: Phone Login Error</title>\n";
	echo "<FORM ACTION=\"$agcDIR\" METHOD=POST>\n";
	echo "<INPUT TYPE=HIDDEN NAME=DB VALUE=\"$DB\">\n";
	echo "<INPUT TYPE=HIDDEN NAME=VD_login VALUE=\"$VD_login\">\n";
	echo "<INPUT TYPE=HIDDEN NAME=VD_pass VALUE=\"$VD_pass\">\n";
	echo "<INPUT TYPE=HIDDEN NAME=VD_campaign VALUE=\"$VD_campaign\">\n";
	echo "<BR><BR><BR><CENTER><TABLE WIDTH=300 CELLPADDING=0 CELLSPACING=0 BGCOLOR=\"#E0C2D6\"><TR BGCOLOR=WHITE>";
	echo "<TD ALIGN=LEFT VALIGN=BOTTOM><IMG SRC=\"./images/vdc_tab_vicidial.gif\" BORDER=0></TD>";
	echo "<TD ALIGN=CENTER VALIGN=MIDDLE> Login Error</TD>";
	echo "</TR>\n";
	echo "<TR><TD ALIGN=CENTER COLSPAN=2><font size=1> &nbsp; <BR><FONT SIZE=3>Sorry, your phone login and password are not active in this system, please try again: <BR> &nbsp;</TD></TR>\n";
	echo "<TR><TD ALIGN=RIGHT>Phone Login: </TD>";
	echo "<TD ALIGN=LEFT><INPUT TYPE=TEXT NAME=phone_login SIZE=10 MAXLENGTH=20 VALUE=\"$phone_login\"></TD></TR>\n";
	echo "<TR><TD ALIGN=RIGHT>Phone Password:  </TD>";
	echo "<TD ALIGN=LEFT><INPUT TYPE=PASSWORD NAME=phone_pass SIZE=10 MAXLENGTH=20 VALUE=\"$phone_pass\"></TD></TR>\n";
	echo "<TR><TD ALIGN=CENTER COLSPAN=2><INPUT TYPE=SUBMIT NAME=SUBMIT VALUE=SUBMIT></TD></TR>\n";
	echo "<TR><TD ALIGN=LEFT COLSPAN=2><font size=1><BR>VERSION: $version &nbsp; &nbsp; &nbsp; BUILD: $build</TD></TR>\n";
	echo "</TABLE>\n";
	echo "</FORM>\n\n";
	echo "</body>\n\n";
	echo "</html>\n\n";
	exit;
	}
else
	{
	echo "<title>VICIDIAL web client</title>\n";
	$stmt="SELECT * from phones where login='$phone_login' and pass='$phone_pass' and active = 'Y';";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$extension=$row[0];
	$dialplan_number=$row[1];
	$voicemail_id=$row[2];
	$phone_ip=$row[3];
	$computer_ip=$row[4];
	$server_ip=$row[5];
	$login=$row[6];
	$pass=$row[7];
	$status=$row[8];
	$active=$row[9];
	$phone_type=$row[10];
	$fullname=$row[11];
	$company=$row[12];
	$picture=$row[13];
	$messages=$row[14];
	$old_messages=$row[15];
	$protocol=$row[16];
	$local_gmt=$row[17];
	$ASTmgrUSERNAME=$row[18];
	$ASTmgrSECRET=$row[19];
	$login_user=$row[20];
	$login_pass=$row[21];
	$login_campaign=$row[22];
	$park_on_extension=$row[23];
	$conf_on_extension=$row[24];
	$VICIDIAL_park_on_extension=$row[25];
	$VICIDIAL_park_on_filename=$row[26];
	$monitor_prefix=$row[27];
	$recording_exten=$row[28];
	$voicemail_exten=$row[29];
	$voicemail_dump_exten=$row[30];
	$ext_context=$row[31];
	$dtmf_send_extension=$row[32];
	$call_out_number_group=$row[33];
	$client_browser=$row[34];
	$install_directory=$row[35];
	$local_web_callerID_URL=$row[36];
	$VICIDIAL_web_URL=$row[37];
	$AGI_call_logging_enabled=$row[38];
	$user_switching_enabled=$row[39];
	$conferencing_enabled=$row[40];
	$admin_hangup_enabled=$row[41];
	$admin_hijack_enabled=$row[42];
	$admin_monitor_enabled=$row[43];
	$call_parking_enabled=$row[44];
	$updater_check_enabled=$row[45];
	$AFLogging_enabled=$row[46];
	$QUEUE_ACTION_enabled=$row[47];
	$CallerID_popup_enabled=$row[48];
	$voicemail_button_enabled=$row[49];
	$enable_fast_refresh=$row[50];
	$fast_refresh_rate=$row[51];
	$enable_persistant_mysql=$row[52];
	$auto_dial_next_number=$row[53];
	$VDstop_rec_after_each_call=$row[54];
	$DBX_server=$row[55];
	$DBX_database=$row[56];
	$DBX_user=$row[57];
	$DBX_pass=$row[58];
	$DBX_port=$row[59];

	if ($protocol == 'EXTERNAL')
		{
		$protocol = 'Local';
		$extension = "$dialplan_number$AT$ext_context";
		}
	$SIP_user = "$protocol/$extension";

	$stmt="SELECT asterisk_version from servers where server_ip='$server_ip';";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$asterisk_version=$row[0];

	# If a park extension is not set, use the default one
	if ( (strlen($park_ext)>0) && (strlen($park_file_name)>0) )
		{
		$VICIDIAL_park_on_extension = "$park_ext";
		$VICIDIAL_park_on_filename = "$park_file_name";
		print "<!-- CAMPAIGN CUSTOM PARKING:  |$VICIDIAL_park_on_extension|$VICIDIAL_park_on_filename| -->\n";
		}
		print "<!-- CAMPAIGN DEFAULT PARKING: |$VICIDIAL_park_on_extension|$VICIDIAL_park_on_filename| -->\n";

	# If a web form address is not set, use the default one
	if (strlen($web_form_address)>0)
		{
		$VICIDIAL_web_form_address = "$web_form_address";
		print "<!-- CAMPAIGN CUSTOM WEB FORM:   |$VICIDIAL_web_form_address| -->\n";
		}
	else
		{
		$VICIDIAL_web_form_address = "$VICIDIAL_web_URL";
		print "<!-- CAMPAIGN DEFAULT WEB FORM:  |$VICIDIAL_web_form_address| -->\n";
		$VICIDIAL_web_form_address_enc = rawurlencode($VICIDIAL_web_form_address);

		}
	$VICIDIAL_web_form_address_enc = rawurlencode($VICIDIAL_web_form_address);

	# If closers are allowed on this campaign
	if ($allow_closers=="Y")
		{
		$VICIDIAL_allow_closers = 1;
		print "<!-- CAMPAIGN ALLOWS CLOSERS:    |$VICIDIAL_allow_closers| -->\n";
		}
	else
		{
		$VICIDIAL_allow_closers = 0;
		print "<!-- CAMPAIGN ALLOWS NO CLOSERS: |$VICIDIAL_allow_closers| -->\n";
		}


	$session_ext = eregi_replace("[^a-z0-9]", "", $extension);
	if (strlen($session_ext) > 10) {$session_ext = substr($session_ext, 0, 10);}
	$session_rand = (rand(1,9999999) + 10000000);
	$session_name = "$STARTtime$US$session_ext$session_rand";

	$stmt="DELETE from web_client_sessions where start_time < '$past_month_date' and extension='$extension' and server_ip = '$server_ip' and program = 'agc';";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	$stmt="INSERT INTO web_client_sessions values('$extension','$server_ip','vicidial','$NOW_TIME','$session_name');";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);

	if ( (eregi("CLOSER", $VD_campaign)) || ($campaign_leads_to_call > 0) )
		{
		### insert an entry into the user log for the login event
		$stmt = "INSERT INTO vicidial_user_log values('','$VD_login','LOGIN','$VD_campaign','$NOW_TIME','$STARTtime')";
		if ($DB) {echo "|$stmt|\n";}
		$rslt=mysql_query($stmt, $link);

		##### check to see if the user has a conf extension already, this happens if they previously exited uncleanly
		$stmt="SELECT conf_exten FROM vicidial_conferences where extension='$SIP_user' and server_ip = '$server_ip' LIMIT 1;";
		$rslt=mysql_query($stmt, $link);
		if ($DB) {echo "$stmt\n";}
		$prev_login_ct = mysql_num_rows($rslt);
		$i=0;
		while ($i < $prev_login_ct)
			{
			$row=mysql_fetch_row($rslt);
			$session_id =$row[0];
			$i++;
			}
		if ($prev_login_ct > 0)
			{print "<!-- USING PREVIOUS MEETME ROOM - $session_id - $NOW_TIME - $SIP_user -->\n";}
		else
			{
			##### grab the next available vicidial_conference room and reserve it
			$stmt="SELECT conf_exten FROM vicidial_conferences where server_ip = '$server_ip' and extension='' LIMIT 1;";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$free_conf_ct = mysql_num_rows($rslt);
			$i=0;
			while ($i < $free_conf_ct)
				{
				$row=mysql_fetch_row($rslt);
				$session_id =$row[0];
				$i++;
				}
			$stmt="UPDATE vicidial_conferences set extension='$SIP_user' where server_ip='$server_ip' and conf_exten='$session_id';";
			$rslt=mysql_query($stmt, $link);
			print "<!-- USING NEW MEETME ROOM - $session_id - $NOW_TIME - $SIP_user -->\n";

			}

		$stmt="UPDATE vicidial_list set status='N', user='' where status IN('QUEUE','INCALL') and user ='$VD_login';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);
		print "<!-- old QUEUE and INCALL reverted list:   |$affected_rows| -->\n";

		$stmt="DELETE from vicidial_hopper where status IN('QUEUE','INCALL','DONE') and user ='$VD_login';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);
		print "<!-- old QUEUE and INCALL reverted hopper: |$affected_rows| -->\n";

		$stmt="DELETE from vicidial_live_agents where user ='$VD_login';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);
		print "<!-- old vicidial_live_agents records cleared: |$affected_rows| -->\n";

	#	print "<B>You have logged in as user: $VD_login on phone: $SIP_user to campaign: $VD_campaign</B><BR>\n";
		$VICIDIAL_is_logged_in=1;

		### use manager middleware-app to connect the phone to the user
		$SIqueryCID = "S$CIDdate$session_id";
		### insert a NEW record to the vicidial_manager table to be processed
		$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$SIqueryCID','Channel: $SIP_user','Context: $ext_context','Exten: $session_id','Priority: 1','Callerid: $SIqueryCID','','','','','');";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);
		print "<!-- call placed to session_id: $session_id from phone: $SIP_user -->\n";

		if ($auto_dial_level > 0)
			{
			print "<!-- campaign is set to auto_dial_level: $auto_dial_level -->\n";

			$closer_chooser_string='';
			$stmt="INSERT INTO vicidial_live_agents (user,server_ip,conf_exten,extension,status,lead_id,campaign_id,uniqueid,callerid,channel,random_id,last_call_time,last_update_time,last_call_finish,closer_campaigns) values('$VD_login','$server_ip','$session_id','$SIP_user','PAUSED','','$VD_campaign','','','','$random','$NOW_TIME','$tsNOW_TIME','$NOW_TIME','$closer_chooser_string');";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$affected_rows = mysql_affected_rows($link);
			print "<!-- new vicidial_live_agents record inserted: |$affected_rows| -->\n";

			if (eregi("CLOSER", $VD_campaign))
				{
				print "<!-- code to trigger window to pick closer groups goes here -->\n";
				}
			}
		else
			{
			print "<!-- campaign is set to manual dial: $auto_dial_level -->\n";



			}
		}
	else
		{
		echo "<title>VICIDIAL web client: VICIDIAL Campaign Login</title>\n";
		echo "<B>Sorry, there are no leads in the hopper for this campaign</B>\n";
		echo "<FORM ACTION=\"$PHP_SELF\" METHOD=POST>\n";
		echo "<INPUT TYPE=HIDDEN NAME=DB VALUE=\"$DB\">\n";
		echo "<INPUT TYPE=HIDDEN NAME=phone_login VALUE=\"$phone_login\">\n";
		echo "<INPUT TYPE=HIDDEN NAME=phone_pass VALUE=\"$phone_pass\">\n";
		echo "Login: <INPUT TYPE=TEXT NAME=VD_login SIZE=10 MAXLENGTH=20 VALUE=\"$VD_login\">\n<br>";
		echo "Password: <INPUT TYPE=PASSWORD NAME=VD_pass SIZE=10 MAXLENGTH=20 VALUE=\"$VD_pass\"><br>\n";
		echo "Campaign: <INPUT TYPE=TEXT NAME=VD_campaign SIZE=10 MAXLENGTH=20 VALUE=\"$VD_campaign\"><br>\n";
		echo "<INPUT TYPE=SUBMIT NAME=SUBMIT VALUE=SUBMIT>\n";
		echo "</FORM>\n\n";
		echo "</body>\n\n";
		echo "</html>\n\n";
		exit;
		}
	}
}

?>
	<script language="Javascript">	
	var MTvar;
	var NOW_TIME = '<? echo $NOW_TIME ?>';
	var SQLdate = '<? echo $NOW_TIME ?>';
	var STARTtime = '<? echo $STARTtime ?>';
	var UnixTime = '<? echo $STARTtime ?>';
	var UnixTimeMS = 0;
	var t = new Date();
	var c = new Date();
	LCAe = new Array('','','','','','');
	LCAc = new Array('','','','','','');
	LCAt = new Array('','','','','','');
	LMAe = new Array('','','','','','');
	VARstatuses = new Array(<? echo $VARstatuses ?>);
	VARstatusnames = new Array(<? echo $VARstatusnames ?>);
	var VD_statuses_ct = '<? echo $VD_statuses_ct ?>';
	VARingroups = new Array(<? echo $VARingroups ?>);
	var INgroupCOUNT = '<? echo $INgrpCT ?>';
	
	var recLIST = '';
	var filename = '';
	var last_filename = '';
	var LCAcount = 0;
	var LMAcount = 0;
	var filedate = '<? echo $FILE_TIME ?>';
	var agcDIR = '<? echo $agcDIR ?>';
	var extension = '<? echo $extension ?>';
	var extension_xfer = '<? echo $extension ?>';
	var dialplan_number = '<? echo $dialplan_number ?>';
	var ext_context = '<? echo $ext_context ?>';
	var protocol = '<? echo $protocol ?>';
	var local_gmt ='<? echo $local_gmt ?>';
	var server_ip = '<? echo $server_ip ?>';
	var asterisk_version = '<? echo $asterisk_version ?>';
<?
if ($enable_fast_refresh < 1) {echo "\tvar refresh_interval = 1000;\n";}
	else {echo "\tvar refresh_interval = $fast_refresh_rate;\n";}
?>
	var session_id = '<? echo $session_id ?>';
	var VICIDIAL_closer_login_checked = 0;
	var VICIDIAL_closer_login_selected = 0;
	var VICIDIAL_pause_calling = 1;
	var MDnextCID = '';
	var XDnextCID = '';
	var MD_channel_look = 0;
	var XD_channel_look = 0;
	var MDuniqueid = '';
	var MDchannel = '';
	var MD_ring_seconds = 0;
	var MDlogEPOCH = 0;
	var VD_live_customer_call = 0;
	var VD_live_call_seconds = 0;
	var XD_live_customer_call = 0;
	var XD_live_call_seconds = 0;
	var open_dispo_screen = 0;
	var AgentDispoing = 0;
	var logout_stop_timeouts = 0;
	var VICIDIAL_allow_closers = '<? echo $VICIDIAL_allow_closers ?>';
	var VICIDIAL_closer_blended = '0';
	var VDstop_rec_after_each_call = '<? echo $VDstop_rec_after_each_call ?>';
	var phone_login = '<? echo $phone_login ?>';
	var phone_pass = '<? echo $phone_pass ?>';
	var user = '<? echo $VD_login ?>';
	var user_abb = '<? echo $user_abb ?>';
	var pass = '<? echo $VD_pass ?>';
	var campaign = '<? echo $VD_campaign ?>';
	var VICIDIAL_web_form_address_enc = '<? echo $VICIDIAL_web_form_address_enc ?>';
	var VICIDIAL_web_form_address = '<? echo $VICIDIAL_web_form_address ?>';
	var VDIC_web_form_address = '<? echo $VICIDIAL_web_form_address ?>';
	var status_A = '<? echo $status_A ?>';
	var status_B = '<? echo $status_B ?>';
	var status_C = '<? echo $status_C ?>';
	var status_D = '<? echo $status_D ?>';
	var status_E = '<? echo $status_E ?>';
	var auto_dial_level = '<? echo $auto_dial_level ?>';
	var dial_timeout = '<? echo $dial_timeout ?>';
	var dial_prefix = '<? echo $dial_prefix ?>';
	var campaign_cid = '<? echo $campaign_cid ?>';
	var campaign_vdad_exten = '<? echo $campaign_vdad_exten ?>';
	var campaign_leads_to_call = '<? echo $campaign_leads_to_call ?>';
	var epoch_sec = <? echo $STARTtime ?>;
	var dtmf_send_extension = '<? echo $dtmf_send_extension ?>';
	var recording_exten = '<? echo $recording_exten ?>';
	var park_on_extension = '<? echo $VICIDIAL_park_on_extension ?>';
	var park_count=0;
	var park_refresh=0;
	var customerparked=0;
	var check_n = 0;
	var conf_check_recheck = 0;
	var lastconf='';
	var lastcustchannel='';
	var lastxferchannel='';
	var custchannellive=0;
	var xferchannellive=0;
	var nochannelinsession=0;
	var agc_dial_prefix = '91';
	var conf_silent_prefix = '<? echo $conf_silent_prefix ?>';
	var menuheight = 30;
	var menuwidth = 30;
	var menufontsize = 8;
	var textareafontsize = 10;
	var check_s;
	var active_display = 1;
	var conf_channels_xtra_display = 0;
	var display_message = '';
	var Nactiveext;
	var Nbusytrunk;
	var Nbusyext;
	var extvalue = extension;
	var activeext_query;
	var busytrunk_query;
	var busyext_query;
	var busytrunkhangup_query;
	var busylocalhangup_query;
	var activeext_order='asc';
	var busytrunk_order='asc';
	var busyext_order='asc';
	var busytrunkhangup_order='asc';
	var busylocalhangup_order='asc';
	var xmlhttp=false;
	var XFER_channel = '';
	var XDcheck = '';
	var session_name = '<? echo $session_name ?>';
	var AutoDialReady = 0;
	var AutoDialWaiting = 0;
	var DialControl_auto_HTML = "<IMG SRC=\"./images/vdc_LB_pause_OFF.gif\" border=0 alt=\"Pause\"><a href=\"#\" onclick=\"AutoDialResumePause('VDADready');\"><IMG SRC=\"./images/vdc_LB_resume.gif\" border=0 alt=\"Resume\"></a>";
	var DialControl_auto_HTML_ready = "<a href=\"#\" onclick=\"AutoDialResumePause('VDADpause');\"><IMG SRC=\"./images/vdc_LB_pause.gif\" border=0 alt=\"Pause\"></a><IMG SRC=\"./images/vdc_LB_resume_OFF.gif\" border=0 alt=\"Resume\">";
	var DialControl_auto_HTML_OFF = "<IMG SRC=\"./images/vdc_LB_pause_OFF.gif\" border=0 alt=\"Pause\"><IMG SRC=\"./images/vdc_LB_resume_OFF.gif\" border=0 alt=\"Resume\">";
	var DialControl_manual_HTML = "<a href=\"#\" onclick=\"ManualDialNext();\"><IMG SRC=\"./images/vdc_LB_dialnextnumber.gif\" border=0 alt=\"Dial Next Number\"></a>";
	var image_blank = new Image();
		image_blank.src="./images/blank.gif";
	var image_livecall_OFF = new Image();
		image_livecall_OFF.src="./images/agc_live_call_OFF.gif";
	var image_livecall_ON = new Image();
		image_livecall_ON.src="./images/agc_live_call_ON.gif";
	var image_LB_dialnextnumber = new Image();
		image_LB_dialnextnumber.src="./images/vdc_LB_dialnextnumber.gif";
	var image_LB_hangupcustomer = new Image();
		image_LB_hangupcustomer.src="./images/vdc_LB_hangupcustomer.gif";
	var image_LB_transferconf = new Image();
		image_LB_transferconf.src="./images/vdc_LB_transferconf.gif";
	var image_LB_grabparkedcall = new Image();
		image_LB_grabparkedcall.src="./images/vdc_LB_grabparkedcall.gif";
	var image_LB_parkcall = new Image();
		image_LB_parkcall.src="./images/vdc_LB_parkcall.gif";
	var image_LB_webform = new Image();
		image_LB_webform.src="./images/vdc_LB_webform.gif";
	var image_LB_stoprecording = new Image();
		image_LB_stoprecording.src="./images/vdc_LB_stoprecording.gif";
	var image_LB_startrecording = new Image();
		image_LB_startrecording.src="./images/vdc_LB_startrecording.gif";
	var image_LB_pause = new Image();
		image_LB_pause.src="./images/vdc_LB_pause.gif";
	var image_LB_resume = new Image();
		image_LB_resume.src="./images/vdc_LB_resume.gif";
	var image_LB_senddtmf = new Image();
		image_LB_senddtmf.src="./images/vdc_LB_senddtmf.gif";
	var image_LB_dialnextnumber_OFF = new Image();
		image_LB_dialnextnumber_OFF.src="./images/vdc_LB_dialnextnumber_OFF.gif";
	var image_LB_hangupcustomer_OFF = new Image();
		image_LB_hangupcustomer_OFF.src="./images/vdc_LB_hangupcustomer_OFF.gif";
	var image_LB_transferconf_OFF = new Image();
		image_LB_transferconf_OFF.src="./images/vdc_LB_transferconf_OFF.gif";
	var image_LB_grabparkedcall_OFF = new Image();
		image_LB_grabparkedcall_OFF.src="./images/vdc_LB_grabparkedcall_OFF.gif";
	var image_LB_parkcall_OFF = new Image();
		image_LB_parkcall_OFF.src="./images/vdc_LB_parkcall_OFF.gif";
	var image_LB_webform_OFF = new Image();
		image_LB_webform_OFF.src="./images/vdc_LB_webform_OFF.gif";
	var image_LB_stoprecording_OFF = new Image();
		image_LB_stoprecording_OFF.src="./images/vdc_LB_stoprecording_OFF.gif";
	var image_LB_startrecording_OFF = new Image();
		image_LB_startrecording_OFF.src="./images/vdc_LB_startrecording_OFF.gif";
	var image_LB_pause_OFF = new Image();
		image_LB_pause_OFF.src="./images/vdc_LB_pause_OFF.gif";
	var image_LB_resume_OFF = new Image();
		image_LB_resume_OFF.src="./images/vdc_LB_resume_OFF.gif";
	var image_LB_senddtmf_OFF = new Image();
		image_LB_senddtmf_OFF.src="./images/vdc_LB_senddtmf_OFF.gif";



// ################################################################################
// Send Hangup command for Live call connected to phone now to Manager
	function livehangup_send_hangup(taskvar) 
		{
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			var queryCID = "HLagcW" + epoch_sec + user_abb;
			var hangupvalue = taskvar;
			livehangup_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=Hangup&format=text&channel=" + hangupvalue + "&queryCID=" + queryCID;
			xmlhttp.open('POST', 'manager_send.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(livehangup_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					Nactiveext = null;
					Nactiveext = xmlhttp.responseText;
					alert(xmlhttp.responseText);
					}
				}
			delete xmlhttp;
			}
		}

// ################################################################################
// park customer and place 3way call
	function xfer_park_dial()
		{
		mainxfer_send_redirect('PARK',lastcustchannel);

		SendManualDial('YES');
		}

// ################################################################################
// place 3way and customer into other conference and fake-hangup the lines
	function leave_3way_call()
		{
		mainxfer_send_redirect('3WAY');

		document.vicidial_form.callchannel.value = '';
		if( document.images ) { document.images['livecall'].src = image_livecall_OFF.src;}
		dialedcall_send_hangup();

		document.vicidial_form.xferchannel.value = '';
		xfercall_send_hangup();
		}

// ################################################################################
// filter manual dialstring and pass on to originate call
	function SendManualDial(taskFromConf)
		{
		if (taskFromConf == 'YES')
			{
			var manual_number = document.vicidial_form.xfernumber.value;
			var manual_string = manual_number.toString();
			var dial_conf_exten = session_id;
			}
		else
			{
			var manual_number = document.vicidial_form.xfernumber.value;
			var manual_string = manual_number.toString();
			}
		if (manual_string.length=='11')
			{manual_string = "9" + manual_string;}
		 else
			{
			if (manual_string.length=='10')
				{manual_string = "91" + manual_string;}
			 else
				{
				if (manual_string.length=='7')
					{manual_string = "9" + manual_string;}
				}
			}

		if (taskFromConf == 'YES')
			{basic_originate_call(manual_string,'NO','YES',dial_conf_exten);}
		else
			{basic_originate_call(manual_string,'NO','NO');}

		MD_ring_seconds=0;
		}

// ################################################################################
// Send Originate command to manager to place a phone call
	function basic_originate_call(tasknum,taskprefix,taskreverse,taskdialvalue) 
		{
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 

			if (taskprefix == 'NO') {var orig_prefix = '';}
			  else {var orig_prefix = agc_dial_prefix;}
			if (taskreverse == 'YES')
				{
				if (taskdialvalue.length < 2)
					{var dialnum = dialplan_number;}
				else
					{var dialnum = taskdialvalue;}
				var originatevalue = "Local/" + tasknum + "@" + ext_context;
				}
			  else 
				{
				var dialnum = tasknum;
				var originatevalue = protocol + "/" + extension;
				}
			var queryCID = "DVagcW" + epoch_sec + user_abb;

			VMCoriginate_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=Originate&format=text&channel=" + originatevalue + "&queryCID=" + queryCID + "&exten=" + orig_prefix + "" + dialnum + "&ext_context=" + ext_context + "&ext_priority=1";
			xmlhttp.open('POST', 'manager_send.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(VMCoriginate_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					alert(xmlhttp.responseText);

					if (taskdialvalue.length > 0)
						{
						XDnextCID = queryCID;
						MD_channel_look=1;
						XDcheck = 'YES';
						}
					}
				}
			delete xmlhttp;
			}
		}

// ################################################################################
// filter conf_dtmf send string and pass on to originate call
	function SendConfDTMF(taskconfdtmf)
		{
		var dtmf_number = document.vicidial_form.conf_dtmf.value;
		var dtmf_string = dtmf_number.toString();
		var conf_dtmf_room = taskconfdtmf;

		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			var queryCID = dtmf_string;
			VMCoriginate_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass  + "&ACTION=SysCIDOriginate&format=text&channel=" + dtmf_send_extension + "&queryCID=" + queryCID + "&exten=" + conf_silent_prefix + '' + conf_dtmf_room + "&ext_context=" + ext_context + "&ext_priority=1";
			xmlhttp.open('POST', 'manager_send.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(VMCoriginate_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
			//		alert(xmlhttp.responseText);
					}
				}
			delete xmlhttp;
			}
		document.vicidial_form.conf_dtmf.value = '';
		}

// ################################################################################
// Check to see if there are any channels live in the agent's conference meetme room
	function check_for_conf_calls(taskconfnum,taskforce)
		{
		custchannellive--;
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			checkconf_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&client=vdc&conf_exten=" + taskconfnum + "&auto_dial_level=" + auto_dial_level;
			xmlhttp.open('POST', 'conf_exten_check.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(checkconf_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					var check_conf = null;
					var LMAforce = taskforce;
					check_conf = xmlhttp.responseText;
				//	alert(checkconf_query);
				//	alert(xmlhttp.responseText);
					var check_ALL_array=check_conf.split("\n");
					var check_time_array=check_ALL_array[0].split("|");
					var Time_array = check_time_array[1].split("UnixTime: ");
					 UnixTime = Time_array[1];
					 UnixTime = parseInt(UnixTime);
					 UnixTimeMS = (UnixTime * 1000);
					t.setTime(UnixTimeMS);
					var check_conf_array=check_ALL_array[1].split("|");
					var live_conf_calls = check_conf_array[0];
					var conf_chan_array = check_conf_array[1].split(" ~");
					if ( (conf_channels_xtra_display == 1) || (conf_channels_xtra_display == 0) )
						{
						if (live_conf_calls > 0)
							{
							var loop_ct=0;
							var ARY_ct=0;
							var LMAalter=0;
							var LMAcontent_change=0;
							var LMAcontent_match=0;
							var conv_start=-1;
				//			var live_conf_HTML = "<font face=\"Arial,Helvetica\"><B>LIVE CALLS IN THIS CONFERENCE:</B></font><BR><TABLE WIDTH=500><TR BGCOLOR=#E6E6E6><TD><font class=\"log_title\">#</TD><TD><font class=\"log_title\">REMOTE CHANNEL</TD><TD><font class=\"log_title\">HANGUP</TD><TD><font class=\"log_title\">XFER</TD></TR>";
							var live_conf_HTML = "<font face=\"Arial,Helvetica\"><B>LIVE CALLS IN YOUR SESSION:</B></font><BR><TABLE WIDTH=500><TR BGCOLOR=#E6E6E6><TD><font class=\"log_title\">#</TD><TD><font class=\"log_title\">REMOTE CHANNEL</TD><TD><font class=\"log_title\">HANGUP</TD></TR>";
							if ( (LMAcount > live_conf_calls)  || (LMAcount < live_conf_calls) || (LMAforce > 0))
								{
								LMAe[0]=''; LMAe[1]=''; LMAe[2]=''; LMAe[3]=''; LMAe[4]=''; LMAe[5]=''; 
								LMAcount=0;   LMAcontent_change++;
								}
							while (loop_ct < live_conf_calls)
								{
								loop_ct++;
								loop_s = loop_ct.toString();
								if (loop_s.match(/1$|3$|5$|7$|9$/)) 
									{var row_color = '#DDDDFF';}
								else
									{var row_color = '#CCCCFF';}
								var conv_ct = (loop_ct + conv_start);
								var channelfieldA = conf_chan_array[conv_ct];
					//			live_conf_HTML = live_conf_HTML + "<tr bgcolor=\"" + row_color + "\"><td><font class=\"log_text\">" + loop_ct + "</td><td><font class=\"log_text\">" + channelfieldA + "</td><td><font class=\"log_text\"><a href=\"#\" onclick=\"livehangup_send_hangup('" + channelfieldA + "');return false;\">Hangup</td><td><font class=\"log_text\"><a href=\"#\" onclick=\"showMainXFER('MainXFERBox','" + channelfieldA + "');return false;\">XFER</td></tr>";
								live_conf_HTML = live_conf_HTML + "<tr bgcolor=\"" + row_color + "\"><td><font class=\"log_text\">" + loop_ct + "</td><td><font class=\"log_text\">" + channelfieldA + "</td><td><font class=\"log_text\"><a href=\"#\" onclick=\"livehangup_send_hangup('" + channelfieldA + "');return false;\">Hangup</td></tr>";

			//		var debugspan = document.getElementById("debugbottomspan").innerHTML;

								if (channelfieldA == lastcustchannel) {custchannellive++;}
								else
									{
									if(customerparked == 1)
										{custchannellive++;}
									}

			//		document.getElementById("debugbottomspan").innerHTML = debugspan + '<BR>' + channelfieldA + '|' + lastcustchannel + '|' + custchannellive + '|' + LMAcontent_change + '|' + LMAalter;

								if (!LMAe[ARY_ct]) 
									{LMAe[ARY_ct] = channelfieldA;   LMAcontent_change++;  LMAalter++;}
								else
									{
									if (LMAe[ARY_ct].length < 1) 
										{LMAe[ARY_ct] = channelfieldA;   LMAcontent_change++;  LMAalter++;}
									else
										{
										if (LMAe[ARY_ct] == channelfieldA) {LMAcontent_match++;}
										 else {LMAcontent_change++;   LMAe[ARY_ct] = channelfieldA;}
										}
									}
								if (LMAalter > 0) {LMAcount++;}
								
								ARY_ct++;
								}
	//	var debug_LMA = LMAcontent_match+"|"+LMAcontent_change+"|"+LMAcount+"|"+live_conf_calls+"|"+LMAe[0]+LMAe[1]+LMAe[2]+LMAe[3]+LMAe[4]+LMAe[5];
	//							document.getElementById("confdebug").innerHTML = debug_LMA + "<BR>";

							live_conf_HTML = live_conf_HTML + "</table>";

							if (LMAcontent_change > 0)
								{
								if (conf_channels_xtra_display == 1)
									{document.getElementById("outboundcallsspan").innerHTML = live_conf_HTML;}
								}
							nochannelinsession=0;
							}
						else
							{
							LMAe[0]=''; LMAe[1]=''; LMAe[2]=''; LMAe[3]=''; LMAe[4]=''; LMAe[5]=''; 
							LMAcount=0;
							if (conf_channels_xtra_display == 1)
								{
								if (document.getElementById("outboundcallsspan").innerHTML.length > 2)
									{
									document.getElementById("outboundcallsspan").innerHTML = '';
									}
								}
							custchannellive = -99;
							nochannelinsession++;
							}
						}
					}
				}
			delete xmlhttp;
			}
		}

// ################################################################################
// Send MonitorConf/StopMonitorConf command for recording of conferences
	function conf_send_recording(taskconfrectype,taskconfrec,taskconffile) 
		{
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			if (taskconfrectype == 'MonitorConf')
				{
				filename = filedate + "_" + user_abb;
				var query_recording_exten = recording_exten;
				var channelrec = "Local/" + conf_silent_prefix + '' + taskconfrec + "@" + ext_context;
				var conf_rec_start_html = "<a href=\"#\" onclick=\"conf_send_recording('StopMonitorConf','" + taskconfrec + "','" + filename + "');return false;\"><IMG SRC=\"./images/vdc_LB_stoprecording.gif\" border=0 alt=\"Stop Recording\"></a>";
				document.getElementById("RecordControl").innerHTML = conf_rec_start_html;
			}
			if (taskconfrectype == 'StopMonitorConf')
				{
				filename = taskconffile;
				var query_recording_exten = session_id;
				var channelrec = "Local/" + conf_silent_prefix + '' + taskconfrec + "@" + ext_context;
				var conf_rec_start_html = "<a href=\"#\" onclick=\"conf_send_recording('MonitorConf','" + taskconfrec + "','');return false;\"><IMG SRC=\"./images/vdc_LB_startrecording.gif\" border=0 alt=\"Start Recording\"></a>";
				document.getElementById("RecordControl").innerHTML = conf_rec_start_html;
				}
			confmonitor_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=" + taskconfrectype + "&format=text&channel=" + channelrec + "&filename=" + filename + "&exten=" + query_recording_exten + "&ext_context=" + ext_context + "&ext_priority=1";
			xmlhttp.open('POST', 'manager_send.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(confmonitor_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					var RClookResponse = null;
			//	document.getElementById("busycallsdebug").innerHTML = confmonitor_query;
			//		alert(xmlhttp.responseText);
					RClookResponse = xmlhttp.responseText;
					var RClookResponse_array=RClookResponse.split("\n");
					var RClookFILE = RClookResponse_array[1];
					var RClookID = RClookResponse_array[2];
					var RClookFILE_array = RClookFILE.split("Filename: ");
					var RClookID_array = RClookID.split("Recording_ID: ");
					if (RClookID_array.length > 0)
						{
						document.getElementById("RecordingFilename").innerHTML = RClookFILE_array[1];
						document.getElementById("RecordID").innerHTML = RClookID_array[1];
						}
					}
				}
			delete xmlhttp;
			}
		}

// ################################################################################
// Send Redirect command for live call to Manager sends phone name where call is going to
// Covers the following types: XFER, VMAIL, ENTRY, CONF, PARK, FROMPARK, XFERLOCAL, XFERINTERNAL, XFERBLIND
	function mainxfer_send_redirect(taskvar,taskxferconf) 
		{
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			var redirectvalue = MDchannel;
			if (redirectvalue.length < 2)
				{redirectvalue = lastcustchannel}
			if (taskvar == 'XFERBLIND')
				{
				var queryCID = "XBvdcW" + epoch_sec + user_abb;
				var blindxferdialstring = document.vicidial_form.xfernumber.value;
				if (blindxferdialstring.length=='11')
					{blindxferdialstring = dial_prefix + "" + blindxferdialstring;}
				 else
					{
					if (blindxferdialstring.length=='10')
						{blindxferdialstring = dial_prefix + "1" + blindxferdialstring;}
					 else
						{
						if (blindxferdialstring.length=='7')
							{blindxferdialstring = dial_prefix + ""  + blindxferdialstring;}
						}
					}
				if (blindxferdialstring.length<'2')
					{
					xferredirect_query='';
					taskvar = 'NOTHING';
					alert("Transfer number must have more than 1 digit:" + blindxferdialstring);
					}
				else
					{
					xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=RedirectVD&format=text&channel=" + redirectvalue + "&queryCID=" + queryCID + "&exten=" + blindxferdialstring + "&ext_context=" + ext_context + "&ext_priority=1&auto_dial_level=" + auto_dial_level + "&campaign=" + campaign + "&uniqueid=" + document.vicidial_form.uniqueid.value + "&lead_id=" + document.vicidial_form.lead_id.value + "&seconds=" + VD_live_call_seconds;
					}
				}
			if (taskvar == 'XFERINTERNAL') 
				{
				var closerxferinternal = '';
				taskvar = 'XFERLOCAL';
				}
			else 
				{
				var closerxferinternal = '9';
				}
			if (taskvar == 'XFERLOCAL')
				{
				var closerxfercamptail = '_L' + document.vicidial_form.xfercode.value;
				var queryCID = "XLvdcW" + epoch_sec + user_abb;
				// 		 "90009*CL_$campaign$park_exten_suffix**$lead_id**$phone_number*$user*";
				var redirectdestination = closerxferinternal + '90009*CL_' + campaign + '' + closerxfercamptail + '**' + document.vicidial_form.lead_id.value + '**' + document.vicidial_form.phone_number.value + '*' + user + '*';

				xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=RedirectVD&format=text&channel=" + redirectvalue + "&queryCID=" + queryCID + "&exten=" + redirectdestination + "&ext_context=" + ext_context + "&ext_priority=1&auto_dial_level=" + auto_dial_level + "&campaign=" + campaign + "&uniqueid=" + document.vicidial_form.uniqueid.value + "&lead_id=" + document.vicidial_form.lead_id.value + "&seconds=" + VD_live_call_seconds;
				}
			if (taskvar == 'XFER')
				{
				var queryCID = "LRvdcW" + epoch_sec + user_abb;
				var redirectdestination = document.vicidial_form.extension_xfer.value;
				xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=RedirectName&format=text&channel=" + redirectvalue + "&queryCID=" + queryCID + "&extenName=" + redirectdestination + "&ext_context=" + ext_context + "&ext_priority=1";
				}
			if (taskvar == 'VMAIL')
				{
				var queryCID = "LVvdcW" + epoch_sec + user_abb;
				var redirectdestination = document.vicidial_form.extension_xfer.value;
				xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=RedirectNameVmail&format=text&channel=" + redirectvalue + "&queryCID=" + queryCID + "&exten=" + voicemail_dump_exten + "&extenName=" + redirectdestination + "&ext_context=" + ext_context + "&ext_priority=1";
				}
			if (taskvar == 'ENTRY')
				{
				var queryCID = "LEvdcW" + epoch_sec + user_abb;
				var redirectdestination = document.vicidial_form.extension_xfer_entry.value;
				xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=Redirect&format=text&channel=" + redirectvalue + "&queryCID=" + queryCID + "&exten=" + redirectdestination + "&ext_context=" + ext_context + "&ext_priority=1";
				}
			if (taskvar == '3WAY')
				{
				var queryCID = "VXvdcW" + epoch_sec + user_abb;
				var redirectdestination = "NEXTAVAILABLE";
				var redirectXTRAvalue = XDchannel;
				xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=RedirectXtra&format=text&channel=" + redirectvalue + "&queryCID=" + queryCID + "&exten=" + redirectdestination + "&ext_context=" + ext_context + "&ext_priority=1&extrachannel=" + redirectXTRAvalue;
				}
			if (taskvar == 'PARK')
				{
				var queryCID = "LPvdcW" + epoch_sec + user_abb;
				var redirectdestination = taskxferconf;
				var parkedby = protocol + "/" + extension;
				xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=RedirectToPark&format=text&channel=" + redirectdestination + "&queryCID=" + queryCID + "&exten=" + park_on_extension + "&ext_context=" + ext_context + "&ext_priority=1&extenName=park&parkedby=" + parkedby;

				document.getElementById("ParkControl").innerHTML ="<a href=\"#\" onclick=\"mainxfer_send_redirect('FROMPARK','" + redirectdestination + "');return false;\"><IMG SRC=\"./images/vdc_LB_grabparkedcall.gif\" border=0 alt=\"Grab Parked Call\"></a>";
				customerparked=1;
				}
			if (taskvar == 'FROMPARK')
				{
				var queryCID = "FPvdcW" + epoch_sec + user_abb;
				var redirectdestination = taskxferconf;
				xferredirect_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&ACTION=RedirectFromPark&format=text&channel=" + redirectdestination + "&queryCID=" + queryCID + "&exten=" + session_id + "&ext_context=" + ext_context + "&ext_priority=1";

				document.getElementById("ParkControl").innerHTML ="<a href=\"#\" onclick=\"mainxfer_send_redirect('PARK','" + redirectdestination + "');return false;\"><IMG SRC=\"./images/vdc_LB_parkcall.gif\" border=0 alt=\"Park Call\"></a>";
				customerparked=0;
				}


			xmlhttp.open('POST', 'manager_send.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(xferredirect_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					Nactiveext = null;
					Nactiveext = xmlhttp.responseText;
			//		alert(xmlhttp.responseText);
					hideMainXFER();
					}
				}
			delete xmlhttp;
			}
		if ( (taskvar == 'XFERLOCAL') || (taskvar == 'XFERBLIND') )
			{
			document.vicidial_form.callchannel.value = '';
			if( document.images ) { document.images['livecall'].src = image_livecall_OFF.src;}
			dialedcall_send_hangup();
			}

		}

// ################################################################################
// Insert or update the vicidial_log entry for a customer call
	function DialLog(taskMDstage)
		{
		if (taskMDstage == "start") {var MDlogEPOCH = 0;}
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			manDIALlog_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=manDIALlogCALL&stage=" + taskMDstage + "&uniqueid=" + document.vicidial_form.uniqueid.value + 
			"&user=" + user + "&pass=" + pass + "&campaign=" + campaign + 
			"&lead_id=" + document.vicidial_form.lead_id.value + 
			"&list_id=" + document.vicidial_form.list_id.value + 
			"&length_in_sec=0&phone_code=" + document.vicidial_form.phone_code.value + 
			"&phone_number=" + document.vicidial_form.phone_number.value + 
			"&exten=" + extension + "&channel=" + lastcustchannel + "&start_epoch=" + MDlogEPOCH + "&auto_dial_level=" + auto_dial_level + "&VDstop_rec_after_each_call=" + VDstop_rec_after_each_call + "&conf_silent_prefix=" + conf_silent_prefix + "&protocol=" + protocol + "&extension=" + extension + "&ext_context=" + ext_context + "&conf_exten=" + session_id + "&user_abb=" + user_abb;
			xmlhttp.open('POST', 'vdc_db_query.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
		//		document.getElementById("busycallsdebug").innerHTML = "vdc_db_query.php?" + manDIALlog_query;
			xmlhttp.send(manDIALlog_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					var MDlogResponse = null;
				//	alert(xmlhttp.responseText);
					MDlogResponse = xmlhttp.responseText;
					var MDlogResponse_array=MDlogResponse.split("\n");
					MDlogLINE = MDlogResponse_array[0];
					if ( (MDlogLINE == "LOG NOT ENTERED") && (VDstop_rec_after_each_call != 1) )
						{
				//		alert("error: log not entered\n");
						}
					else
						{
						MDlogEPOCH = MDlogResponse_array[1];
				//		alert("VICIDIAL Call log entered:\n" + document.vicidial_form.uniqueid.value);
						if (VDstop_rec_after_each_call == 1)
							{
							var conf_rec_start_html = "<a href=\"#\" onclick=\"conf_send_recording('MonitorConf','" + session_id + "','');return false;\"><IMG SRC=\"./images/vdc_LB_startrecording.gif\" border=0 alt=\"Start Recording\"></a>";
							document.getElementById("RecordControl").innerHTML = conf_rec_start_html;
							
							MDlogRECORDINGS = MDlogResponse_array[3];
							if (MDlogRECORDINGS.length > 0)
								{
								var MDlogRECORDINGS_array=MDlogRECORDINGS.split("|");
								document.getElementById("RecordingFilename").innerHTML = MDlogRECORDINGS_array[2];
								document.getElementById("RecordID").innerHTML = MDlogRECORDINGS_array[3];
								}
							}
						}
					}
				}
			delete xmlhttp;
			}
		}

// ################################################################################
// Request lookup of manual dial channel
	function ManualDialCheckChannel(taskCheckOR)
		{
		if (taskCheckOR == 'YES')
			{
			var CIDcheck = XDnextCID;
			}
		else
			{
			var CIDcheck = MDnextCID;
			}
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			manDIALlook_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=manDIALlookCALL&conf_exten=" + session_id + "&user=" + user + "&pass=" + pass + "&MDnextCID=" + CIDcheck;
			xmlhttp.open('POST', 'vdc_db_query.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(manDIALlook_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					var MDlookResponse = null;
				//	alert(xmlhttp.responseText);
					MDlookResponse = xmlhttp.responseText;
					var MDlookResponse_array=MDlookResponse.split("\n");
					var MDlookCID = MDlookResponse_array[0];
					if (MDlookCID == "NO")
						{
						MD_ring_seconds++;
						document.getElementById("MainStatusSpan").innerHTML = " Calling: " + document.vicidial_form.phone_number.value + " UID: " + CIDcheck + " &nbsp; Waiting for Ring... " + MD_ring_seconds + " seconds";
				//		alert("channel not found yet:\n" + campaign);
						}
					else
						{
						var regMDL = new RegExp("^Local","ig");
						if (taskCheckOR == 'YES')
							{
							XDuniqueid = MDlookResponse_array[0];
							XDchannel = MDlookResponse_array[1];
							if ( (XDchannel.match(regMDL)) && (asterisk_version != '1.0.8') && (asterisk_version != '1.0.9') )
								{
								// bad grab of Local channel, try again
								MD_ring_seconds++;
								}
							else
								{
								document.vicidial_form.xferuniqueid.value	= MDlookResponse_array[0];
								document.vicidial_form.xferchannel.value	= MDlookResponse_array[1];
								lastxferchannel = MDlookResponse_array[1];
								document.vicidial_form.xferlength.value		= 0;

								XD_live_customer_call = 1;
								XD_live_call_seconds = 0;
								MD_channel_look=0;

								document.getElementById("MainStatusSpan").innerHTML = " Called 3rd party: " + document.vicidial_form.xfernumber.value + " UID: " + CIDcheck;

								document.getElementById("Leave3WayCall").innerHTML ="<a href=\"#\" onclick=\"leave_3way_call();return false;\"><IMG SRC=\"./images/vdc_XB_leave3waycall.gif\" border=0 alt=\"LEAVE 3-WAY CALL\"></a>";

								document.getElementById("DialWithCustomer").innerHTML ="<IMG SRC=\"./images/vdc_XB_dialwithcustomer_OFF.gif\" border=0 alt=\"Dial With Customer\">";

								document.getElementById("ParkCustomerDial").innerHTML ="<IMG SRC=\"./images/vdc_XB_parkcustomerdial_OFF.gif\" border=0 alt=\"Park Customer Dial\">";

								document.getElementById("HangupXferLine").innerHTML ="<a href=\"#\" onclick=\"xfercall_send_hangup();return false;\"><IMG SRC=\"./images/vdc_XB_hangupxferline.gif\" border=0 alt=\"Hangup Xfer Line\"></a>";

								document.getElementById("HangupBothLines").innerHTML ="<a href=\"#\" onclick=\"bothcall_send_hangup();return false;\"><IMG SRC=\"./images/vdc_XB_hangupbothlines.gif\" border=0 alt=\"Hangup Both Lines\"></a>";

								xferchannellive=1;
								XDcheck = '';
								}
							}
						else
							{
							MDuniqueid = MDlookResponse_array[0];
							MDchannel = MDlookResponse_array[1];
							if ( (MDchannel.match(regMDL)) && (asterisk_version != '1.0.8') && (asterisk_version != '1.0.9') )
								{
								// bad grab of Local channel, try again
								MD_ring_seconds++;
								}
							else
								{
								document.vicidial_form.uniqueid.value		= MDlookResponse_array[0];
								document.vicidial_form.callchannel.value	= MDlookResponse_array[1];
								lastcustchannel = MDlookResponse_array[1];
								if( document.images ) { document.images['livecall'].src = image_livecall_ON.src;}
								document.vicidial_form.seconds.value		= 0;

								VD_live_customer_call = 1;
								VD_live_call_seconds = 0;

								MD_channel_look=0;
								document.getElementById("MainStatusSpan").innerHTML = " Called: " + document.vicidial_form.phone_number.value + " UID: " + CIDcheck + " &nbsp;"; 

								document.getElementById("ParkControl").innerHTML ="<a href=\"#\" onclick=\"mainxfer_send_redirect('PARK','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_LB_parkcall.gif\" border=0 alt=\"Park Call\"></a>";

								document.getElementById("HangupControl").innerHTML = "<a href=\"#\" onclick=\"dialedcall_send_hangup();\"><IMG SRC=\"./images/vdc_LB_hangupcustomer.gif\" border=0 alt=\"Hangup Customer\"></a>";

								document.getElementById("XferControl").innerHTML = "<a href=\"#\" onclick=\"showDiv('TransferMain');\"><IMG SRC=\"./images/vdc_LB_transferconf.gif\" border=0 alt=\"Transfer - Conference\"></a>";

								document.getElementById("LocalCloser").innerHTML = "<a href=\"#\" onclick=\"mainxfer_send_redirect('XFERLOCAL','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_XB_localcloser.gif\" border=0 alt=\"LOCAL CLOSER\"></a>";

								document.getElementById("InternalCloser").innerHTML = "<a href=\"#\" onclick=\"mainxfer_send_redirect('XFERINTERNAL','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_XB_internalcloser.gif\" border=0 alt=\"INTERNAL CLOSER\"></a>";

								document.getElementById("DialBlindTransfer").innerHTML = "<a href=\"#\" onclick=\"mainxfer_send_redirect('XFERBLIND','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_XB_blindtransfer.gif\" border=0 alt=\"Dial Blind Transfer\"></a>";



								// INSERT VICIDIAL_LOG ENTRY FOR THIS CALL PROCESS
								DialLog("start");

								custchannellive=1;
								}
							}
						}
					}
				}
			delete xmlhttp;
			}

		if (MD_ring_seconds > 49) 
			{
			MD_channel_look=0;
			MD_ring_seconds=0;
			alert("Dial timed out, contact your system administrator\n");
			}

		}

// ################################################################################
// Send the Manual Dial Next Number request
	function ManualDialNext()
		{
		document.getElementById("DialControl").innerHTML = "<IMG SRC=\"./images/vdc_LB_dialnextnumber_OFF.gif\" border=0 alt=\"Dial Next Number\">";

		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			manDIALnext_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=manDIALnextCALL&conf_exten=" + session_id + "&user=" + user + "&pass=" + pass + "&campaign=" + campaign + "&ext_context=" + ext_context + "&dial_timeout=" + dial_timeout + "&dial_prefix=" + dial_prefix + "&campaign_cid=" + campaign_cid;
			xmlhttp.open('POST', 'vdc_db_query.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(manDIALnext_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					var MDnextResponse = null;
				//	alert(xmlhttp.responseText);
					MDnextResponse = xmlhttp.responseText;

					var MDnextResponse_array=MDnextResponse.split("\n");
					MDnextCID = MDnextResponse_array[0];
					if (MDnextCID == "HOPPER EMPTY")
						{
						alert("No more leads in the hopper for campaign:\n" + campaign);
						}
					else
						{
						document.vicidial_form.lead_id.value			= MDnextResponse_array[1];
						document.vicidial_form.vendor_lead_code.value	= MDnextResponse_array[4];
						document.vicidial_form.list_id.value			= MDnextResponse_array[5];
						document.vicidial_form.gmt_offset_now.value		= MDnextResponse_array[6];
						document.vicidial_form.phone_code.value			= MDnextResponse_array[7];
						document.vicidial_form.phone_number.value		= MDnextResponse_array[8];
						document.vicidial_form.title.value				= MDnextResponse_array[9];
						document.vicidial_form.first_name.value			= MDnextResponse_array[10];
						document.vicidial_form.middle_initial.value		= MDnextResponse_array[11];
						document.vicidial_form.last_name.value			= MDnextResponse_array[12];
						document.vicidial_form.address1.value			= MDnextResponse_array[13];
						document.vicidial_form.address2.value			= MDnextResponse_array[14];
						document.vicidial_form.address3.value			= MDnextResponse_array[15];
						document.vicidial_form.city.value				= MDnextResponse_array[16];
						document.vicidial_form.state.value				= MDnextResponse_array[17];
						document.vicidial_form.province.value			= MDnextResponse_array[18];
						document.vicidial_form.postal_code.value		= MDnextResponse_array[19];
						document.vicidial_form.country_code.value		= MDnextResponse_array[20];
						document.vicidial_form.gender.value				= MDnextResponse_array[21];
						document.vicidial_form.date_of_birth.value		= MDnextResponse_array[22];
						document.vicidial_form.alt_phone.value			= MDnextResponse_array[23];
						document.vicidial_form.email.value				= MDnextResponse_array[24];
						document.vicidial_form.security_phrase.value	= MDnextResponse_array[25];
						document.vicidial_form.comments.value			= MDnextResponse_array[26];
						document.vicidial_form.called_count.value		= MDnextResponse_array[27];

						document.getElementById("MainStatusSpan").innerHTML = " Calling: " + document.vicidial_form.phone_number.value + " UID: " + MDnextCID + " &nbsp; Waiting for Ring...";

						var web_form_vars = 
						"?lead_id=" + document.vicidial_form.lead_id.value + 
						"&vendor_id=" + document.vicidial_form.vendor_lead_code.value + 
						"&list_id=" + document.vicidial_form.list_id.value + 
						"&gmt_offset_now=" + document.vicidial_form.gmt_offset_now.value + 
						"&phone_code=" + document.vicidial_form.phone_code.value + 
						"&phone_number=" + document.vicidial_form.phone_number.value + 
						"&title=" + document.vicidial_form.title.value + 
						"&first_name=" + document.vicidial_form.first_name.value + 
						"&middle_initial=" + document.vicidial_form.middle_initial.value + 
						"&last_name=" + document.vicidial_form.last_name.value + 
						"&address1=" + document.vicidial_form.address1.value + 
						"&address2=" + document.vicidial_form.address2.value + 
						"&address3=" + document.vicidial_form.address3.value + 
						"&city=" + document.vicidial_form.city.value + 
						"&state=" + document.vicidial_form.state.value + 
						"&province=" + document.vicidial_form.province.value + 
						"&postal_code=" + document.vicidial_form.postal_code.value + 
						"&country_code=" + document.vicidial_form.country_code.value + 
						"&gender=" + document.vicidial_form.gender.value + 
						"&date_of_birth=" + document.vicidial_form.date_of_birth.value + 
						"&alt_phone=" + document.vicidial_form.alt_phone.value + 
						"&email=" + document.vicidial_form.email.value + 
						"&security_phrase=" + document.vicidial_form.security_phrase.value + 
						"&comments=" + document.vicidial_form.comments.value + 
						"&user=" + user + 
						"&pass=" + pass + 
						"&campaign=" + campaign + 
						"&phone_login=" + phone_login + 
						"&phone_pass=" + phone_pass + 
						"&fronter=" + user + 
						"&closer=" + user + 
						"&group=" + campaign + 
						"&channel_group=" + campaign + 
						"&SQLdate=" + SQLdate + 
						"&epoch=" + UnixTime + 
						"&uniqueid=" + document.vicidial_form.uniqueid.value + 
						"&customer_zap_channel=" + lastcustchannel + 
						"&server_ip=" + server_ip + 
						"&SIPexten=" + extension + 
						"&session_id=" + session_id + 
						"&phone=" + document.vicidial_form.phone_number.value + 
						"&parked_by=" + document.vicidial_form.lead_id.value;
						
						
// $VICIDIAL_web_QUERY_STRING =~ s/ /+/gi;
// $VICIDIAL_web_QUERY_STRING =~ s/\`|\~|\:|\;|\#|\'|\"|\{|\}|\(|\)|\*|\^|\%|\$|\!|\%|\r|\t|\n//gi;

						var regWFspace = new RegExp(" ","ig");
						web_form_vars = web_form_vars.replace(regWF, '');
						var regWF = new RegExp("\\`|\\~|\\:|\\;|\\#|\\'|\\\"|\\{|\\}|\\(|\\)|\\*|\\^|\\%|\\$|\\!|\\%|\\r|\\t|\\n","ig");
						web_form_vars = web_form_vars.replace(regWFspace, '+');
						web_form_vars = web_form_vars.replace(regWF, '');

						VDIC_web_form_address = VICIDIAL_web_form_address;

						document.getElementById("WebFormSpan").innerHTML = "<a href=\"" + VDIC_web_form_address + web_form_vars + "\" target=\"vdcwebform\" onMouseOver=\"WebFormRefresh();\"><IMG SRC=\"./images/vdc_LB_webform.gif\" border=0 alt=\"Web Form\"></a>\n";

						MD_channel_look=1;
						}
					}
				}
			delete xmlhttp;
			}
		}


// ################################################################################
// Set the client to READY and start looking for calls (VDADready, VDADpause)
	function AutoDialResumePause(taskaction)
		{
		if (taskaction == 'VDADready')
			{
			var VDRP_stage = 'READY';
			if (INgroupCOUNT > 0)
				{
				if (VICIDIAL_closer_blended == 0)
					{VDRP_stage = 'CLOSER';}
				else 
					{VDRP_stage = 'READY';}
				}
			AutoDialReady = 1;
			AutoDialWaiting = 1;
			document.getElementById("DialControl").innerHTML = DialControl_auto_HTML_ready;
			}
		else
			{
			var VDRP_stage = 'PAUSED';
			AutoDialReady = 0;
			AutoDialWaiting = 0;
			document.getElementById("DialControl").innerHTML = DialControl_auto_HTML;
			}

		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			autoDIALready_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=" + taskaction + "&user=" + user + "&pass=" + pass + "&stage=" + VDRP_stage;
			xmlhttp.open('POST', 'vdc_db_query.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(autoDIALready_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
			//		alert(xmlhttp.responseText);
					}
				}
			delete xmlhttp;
			}
		}


// ################################################################################
// Check to see if there is a call being sent from the auto-dialer to agent conf
	function check_for_auto_incoming()
		{
		document.vicidial_form.lead_id.value = '';
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			checkVDAI_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&user=" + user + "&pass=" + pass + "&campaign=" + campaign + "&ACTION=VDADcheckINCOMING";
			xmlhttp.open('POST', 'vdc_db_query.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(checkVDAI_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
					var check_incoming = null;
					check_incoming = xmlhttp.responseText;
				//	alert(checkVDAI_query);
				//	alert(xmlhttp.responseText);
					var check_VDIC_array=check_incoming.split("\n");
					if (check_VDIC_array[0] == '1')
						{
				//		alert(xmlhttp.responseText);
						AutoDialWaiting = 0;

						var VDIC_data_VDAC=check_VDIC_array[1].split("|");
						VDIC_web_form_address = VICIDIAL_web_form_address
						var VDIC_fronter='';

						var VDIC_data_VDIG=check_VDIC_array[2].split("|");
						if (VDIC_data_VDIG[0].length > 5)
							{VDIC_web_form_address = VDIC_data_VDIG[0];}
						var VDCL_group_name			= VDIC_data_VDIG[1];
						var VDCL_group_color		= VDIC_data_VDIG[2];
						var VDCL_fronter_display	= VDIC_data_VDIG[3];

						var VDIC_data_VDFR=check_VDIC_array[3].split("|");
						if ( (VDIC_data_VDFR[1].length > 1) && (VDCL_fronter_display == 'Y') )
							{VDIC_fronter = "  Fronter: " + VDIC_data_VDFR[0] + " - " + VDIC_data_VDFR[1];}
						
						document.vicidial_form.lead_id.value		= VDIC_data_VDAC[0];
						document.vicidial_form.uniqueid.value		= VDIC_data_VDAC[1];
						CIDcheck									= VDIC_data_VDAC[2];
						document.vicidial_form.callchannel.value	= VDIC_data_VDAC[3];
						lastcustchannel = VDIC_data_VDAC[3];
						if( document.images ) { document.images['livecall'].src = image_livecall_ON.src;}
						document.vicidial_form.seconds.value		= 0;

						VD_live_customer_call = 1;
						VD_live_call_seconds = 0;

						// INSERT VICIDIAL_LOG ENTRY FOR THIS CALL PROCESS
					//	DialLog("start");

						custchannellive=1;

						document.vicidial_form.vendor_lead_code.value	= check_VDIC_array[8];
						document.vicidial_form.list_id.value			= check_VDIC_array[9];
						document.vicidial_form.gmt_offset_now.value		= check_VDIC_array[10];
						document.vicidial_form.phone_code.value			= check_VDIC_array[11];
						document.vicidial_form.phone_number.value		= check_VDIC_array[12];
						document.vicidial_form.title.value				= check_VDIC_array[13];
						document.vicidial_form.first_name.value			= check_VDIC_array[14];
						document.vicidial_form.middle_initial.value		= check_VDIC_array[15];
						document.vicidial_form.last_name.value			= check_VDIC_array[16];
						document.vicidial_form.address1.value			= check_VDIC_array[17];
						document.vicidial_form.address2.value			= check_VDIC_array[18];
						document.vicidial_form.address3.value			= check_VDIC_array[19];
						document.vicidial_form.city.value				= check_VDIC_array[20];
						document.vicidial_form.state.value				= check_VDIC_array[21];
						document.vicidial_form.province.value			= check_VDIC_array[22];
						document.vicidial_form.postal_code.value		= check_VDIC_array[23];
						document.vicidial_form.country_code.value		= check_VDIC_array[24];
						document.vicidial_form.gender.value				= check_VDIC_array[25];
						document.vicidial_form.date_of_birth.value		= check_VDIC_array[26];
						document.vicidial_form.alt_phone.value			= check_VDIC_array[27];
						document.vicidial_form.email.value				= check_VDIC_array[28];
						document.vicidial_form.security_phrase.value	= check_VDIC_array[29];
						document.vicidial_form.comments.value			= check_VDIC_array[30];
						document.vicidial_form.called_count.value		= check_VDIC_array[31];

						document.getElementById("MainStatusSpan").innerHTML = " Incoming: " + document.vicidial_form.phone_number.value + " UID: " + CIDcheck + " &nbsp; " + VDIC_fronter; 

						if (VDIC_data_VDIG[1].length > 0)
							{
							if (VDIC_data_VDIG[2].length > 2)
								{
								document.getElementById("MainStatusSpan").style.background = VDIC_data_VDIG[2];
								}
							document.getElementById("MainStatusSpan").innerHTML = " Incoming: " + document.vicidial_form.phone_number.value + " Group: " + VDIC_data_VDIG[1] + " &nbsp; " + VDIC_fronter; 
							}

						document.getElementById("ParkControl").innerHTML ="<a href=\"#\" onclick=\"mainxfer_send_redirect('PARK','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_LB_parkcall.gif\" border=0 alt=\"Park Call\"></a>";

						document.getElementById("HangupControl").innerHTML = "<a href=\"#\" onclick=\"dialedcall_send_hangup();\"><IMG SRC=\"./images/vdc_LB_hangupcustomer.gif\" border=0 alt=\"Hangup Customer\"></a>";

						document.getElementById("XferControl").innerHTML = "<a href=\"#\" onclick=\"showDiv('TransferMain');\"><IMG SRC=\"./images/vdc_LB_transferconf.gif\" border=0 alt=\"Transfer - Conference\"></a>";

						document.getElementById("LocalCloser").innerHTML = "<a href=\"#\" onclick=\"mainxfer_send_redirect('XFERLOCAL','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_XB_localcloser.gif\" border=0 alt=\"LOCAL CLOSER\"></a>";

						document.getElementById("InternalCloser").innerHTML = "<a href=\"#\" onclick=\"mainxfer_send_redirect('XFERINTERNAL','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_XB_internalcloser.gif\" border=0 alt=\"INTERNAL CLOSER\"></a>";

						document.getElementById("DialBlindTransfer").innerHTML = "<a href=\"#\" onclick=\"mainxfer_send_redirect('XFERBLIND','" + lastcustchannel + "');return false;\"><IMG SRC=\"./images/vdc_XB_blindtransfer.gif\" border=0 alt=\"Dial Blind Transfer\"></a>";

						document.getElementById("DialControl").innerHTML = DialControl_auto_HTML_OFF;


						var web_form_vars = 
						"?lead_id=" + document.vicidial_form.lead_id.value + 
						"&vendor_id=" + document.vicidial_form.vendor_lead_code.value + 
						"&list_id=" + document.vicidial_form.list_id.value + 
						"&gmt_offset_now=" + document.vicidial_form.gmt_offset_now.value + 
						"&phone_code=" + document.vicidial_form.phone_code.value + 
						"&phone_number=" + document.vicidial_form.phone_number.value + 
						"&title=" + document.vicidial_form.title.value + 
						"&first_name=" + document.vicidial_form.first_name.value + 
						"&middle_initial=" + document.vicidial_form.middle_initial.value + 
						"&last_name=" + document.vicidial_form.last_name.value + 
						"&address1=" + document.vicidial_form.address1.value + 
						"&address2=" + document.vicidial_form.address2.value + 
						"&address3=" + document.vicidial_form.address3.value + 
						"&city=" + document.vicidial_form.city.value + 
						"&state=" + document.vicidial_form.state.value + 
						"&province=" + document.vicidial_form.province.value + 
						"&postal_code=" + document.vicidial_form.postal_code.value + 
						"&country_code=" + document.vicidial_form.country_code.value + 
						"&gender=" + document.vicidial_form.gender.value + 
						"&date_of_birth=" + document.vicidial_form.date_of_birth.value + 
						"&alt_phone=" + document.vicidial_form.alt_phone.value + 
						"&email=" + document.vicidial_form.email.value + 
						"&security_phrase=" + document.vicidial_form.security_phrase.value + 
						"&comments=" + document.vicidial_form.comments.value + 
						"&user=" + user + 
						"&pass=" + pass + 
						"&campaign=" + campaign + 
						"&phone_login=" + phone_login + 
						"&phone_pass=" + phone_pass + 
						"&fronter=" + user + 
						"&closer=" + user + 
						"&group=" + campaign + 
						"&channel_group=" + campaign + 
						"&SQLdate=" + SQLdate + 
						"&epoch=" + UnixTime + 
						"&uniqueid=" + document.vicidial_form.uniqueid.value + 
						"&customer_zap_channel=" + lastcustchannel + 
						"&server_ip=" + server_ip + 
						"&SIPexten=" + extension + 
						"&session_id=" + session_id + 
						"&phone=" + document.vicidial_form.phone_number.value + 
						"&parked_by=" + document.vicidial_form.lead_id.value;
						
						var regWFspace = new RegExp(" ","ig");
						web_form_vars = web_form_vars.replace(regWF, '');
						var regWF = new RegExp("\\`|\\~|\\:|\\;|\\#|\\'|\\\"|\\{|\\}|\\(|\\)|\\*|\\^|\\%|\\$|\\!|\\%|\\r|\\t|\\n","ig");
						web_form_vars = web_form_vars.replace(regWFspace, '+');
						web_form_vars = web_form_vars.replace(regWF, '');

						document.getElementById("WebFormSpan").innerHTML = "<a href=\"" + VDIC_web_form_address + web_form_vars + "\" target=\"vdcwebform\" onMouseOver=\"WebFormRefresh();\"><IMG SRC=\"./images/vdc_LB_webform.gif\" border=0 alt=\"Web Form\"></a>\n";

						}
					else
						{
						// do nothing
						}
					}
				}
			delete xmlhttp;
			}
		}


// ################################################################################
// refresh the content of the web form URL
	function WebFormRefresh(taskrefresh) 
		{
		var web_form_vars = 
		"?lead_id=" + document.vicidial_form.lead_id.value + 
		"&vendor_id=" + document.vicidial_form.vendor_lead_code.value + 
		"&list_id=" + document.vicidial_form.list_id.value + 
		"&gmt_offset_now=" + document.vicidial_form.gmt_offset_now.value + 
		"&phone_code=" + document.vicidial_form.phone_code.value + 
		"&phone_number=" + document.vicidial_form.phone_number.value + 
		"&title=" + document.vicidial_form.title.value + 
		"&first_name=" + document.vicidial_form.first_name.value + 
		"&middle_initial=" + document.vicidial_form.middle_initial.value + 
		"&last_name=" + document.vicidial_form.last_name.value + 
		"&address1=" + document.vicidial_form.address1.value + 
		"&address2=" + document.vicidial_form.address2.value + 
		"&address3=" + document.vicidial_form.address3.value + 
		"&city=" + document.vicidial_form.city.value + 
		"&state=" + document.vicidial_form.state.value + 
		"&province=" + document.vicidial_form.province.value + 
		"&postal_code=" + document.vicidial_form.postal_code.value + 
		"&country_code=" + document.vicidial_form.country_code.value + 
		"&gender=" + document.vicidial_form.gender.value + 
		"&date_of_birth=" + document.vicidial_form.date_of_birth.value + 
		"&alt_phone=" + document.vicidial_form.alt_phone.value + 
		"&email=" + document.vicidial_form.email.value + 
		"&security_phrase=" + document.vicidial_form.security_phrase.value + 
		"&comments=" + document.vicidial_form.comments.value + 
		"&user=" + user + 
		"&pass=" + pass + 
		"&campaign=" + campaign + 
		"&phone_login=" + phone_login + 
		"&phone_pass=" + phone_pass + 
		"&fronter=" + user + 
		"&closer=" + user + 
		"&group=" + campaign + 
		"&channel_group=" + campaign + 
		"&SQLdate=" + SQLdate + 
		"&epoch=" + UnixTime + 
		"&uniqueid=" + document.vicidial_form.uniqueid.value + 
		"&customer_zap_channel=" + lastcustchannel + 
		"&server_ip=" + server_ip + 
		"&SIPexten=" + extension + 
		"&session_id=" + session_id + 
		"&phone=" + document.vicidial_form.phone_number.value + 
		"&parked_by=" + document.vicidial_form.lead_id.value;
		
		var regWFspace = new RegExp(" ","ig");
		web_form_vars = web_form_vars.replace(regWF, '');
		var regWF = new RegExp("\\`|\\~|\\:|\\;|\\#|\\'|\\\"|\\{|\\}|\\(|\\)|\\*|\\^|\\%|\\$|\\!|\\%|\\r|\\t|\\n","ig");
		web_form_vars = web_form_vars.replace(regWFspace, '+');
		web_form_vars = web_form_vars.replace(regWF, '');

		if (taskrefresh == 'OUT')
			{
			document.getElementById("WebFormSpan").innerHTML = "<a href=\"" + VDIC_web_form_address + web_form_vars + "\" target=\"vdcwebform\" onMouseOver=\"WebFormRefresh('IN');\"><IMG SRC=\"./images/vdc_LB_webform.gif\" border=0 alt=\"Web Form\"></a>\n";
			}
		else 
			{
			document.getElementById("WebFormSpan").innerHTML = "<a href=\"" + VDIC_web_form_address + web_form_vars + "\" target=\"vdcwebform\" onMouseOut=\"WebFormRefresh('OUT');\"><IMG SRC=\"./images/vdc_LB_webform.gif\" border=0 alt=\"Web Form\"></a>\n";
			}
		}


// ################################################################################
// Start Hangup Functions for both 
	function bothcall_send_hangup() 
		{
		if (lastcustchannel.length > 3)
			{dialedcall_send_hangup();}
		if (lastxferchannel.length > 3)
			{xfercall_send_hangup();}
		}

// ################################################################################
// Send Hangup command for customer call connected to the conference now to Manager
	function dialedcall_send_hangup() 
		{
		var form_cust_channel = document.vicidial_form.callchannel.value;
		var customer_channel = lastcustchannel;
		var process_post_hangup=0;
		if (form_cust_channel.length > 3)
			{
			var xmlhttp=false;
			/*@cc_on @*/
			/*@if (@_jscript_version >= 5)
			// JScript gives us Conditional compilation, we can cope with old IE versions.
			// and security blocked creation of the objects.
			 try {
			  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
			 } catch (e) {
			  try {
			   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
			  } catch (E) {
			   xmlhttp = false;
			  }
			 }
			@end @*/
			if (!xmlhttp && typeof XMLHttpRequest!='undefined')
				{
				xmlhttp = new XMLHttpRequest();
				}
			if (xmlhttp) 
				{ 
				var queryCID = "HLvdcW" + epoch_sec + user_abb;
				var hangupvalue = customer_channel;
				custhangup_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=Hangup&format=text&user=" + user + "&pass=" + pass + "&channel=" + hangupvalue + "&queryCID=" + queryCID;
				xmlhttp.open('POST', 'manager_send.php'); 
				xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
				xmlhttp.send(custhangup_query); 
				xmlhttp.onreadystatechange = function() 
					{ 
					if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
						{
						Nactiveext = null;
						Nactiveext = xmlhttp.responseText;
				//		alert(xmlhttp.responseText);
						}
					}
				process_post_hangup=1;
				delete xmlhttp;
				}
			}
			else {process_post_hangup=1;}
			if (process_post_hangup==1)
			{
			VD_live_customer_call = 0;
			VD_live_call_seconds = 0;
			MD_ring_seconds = 0;

		//	UPDATE VICIDIAL_LOG ENTRY FOR THIS CALL PROCESS
			DialLog("end");
			open_dispo_screen=1;
		//  DEACTIVATE CHANNEL-DEPENDANT BUTTONS AND VARIABLES
			document.vicidial_form.callchannel.value = "";
			lastcustchannel='';
			if( document.images ) { document.images['livecall'].src = image_livecall_OFF.src;}
			document.getElementById("WebFormSpan").innerHTML = "<IMG SRC=\"./images/vdc_LB_webform_OFF.gif\" border=0 alt=\"Web Form\">";
			document.getElementById("ParkControl").innerHTML = "<IMG SRC=\"./images/vdc_LB_parkcall_OFF.gif\" border=0 alt=\"Park Call\">";
			document.getElementById("HangupControl").innerHTML = "<IMG SRC=\"./images/vdc_LB_hangupcustomer_OFF.gif\" border=0 alt=\"Hangup Customer\">";
			document.getElementById("XferControl").innerHTML = "<IMG SRC=\"./images/vdc_LB_transferconf_OFF.gif\" border=0 alt=\"Transfer - Conference\">";
			document.getElementById("LocalCloser").innerHTML = "<IMG SRC=\"./images/vdc_XB_localcloser_OFF.gif\" border=0 alt=\"LOCAL CLOSER\">";
			document.getElementById("InternalCloser").innerHTML = "<IMG SRC=\"./images/vdc_XB_internalcloser_OFF.gif\" border=0 alt=\"INTERNAL CLOSER\">";
			document.getElementById("DialBlindTransfer").innerHTML = "<IMG SRC=\"./images/vdc_XB_blindtransfer_OFF.gif\" border=0 alt=\"Dial Blind Transfer\">";
			document.vicidial_form.custdatetime.value		= '';

			if (auto_dial_level == 0)
				{
				document.getElementById("DialControl").innerHTML = "<a href=\"#\" onclick=\"ManualDialNext();\"><IMG SRC=\"./images/vdc_LB_dialnextnumber.gif\" border=0 alt=\"Dial Next Number\"></a>";
				}
			else
				{
				document.getElementById("MainStatusSpan").style.background = "#E0C2D6";
				document.getElementById("DialControl").innerHTML = DialControl_auto_HTML_OFF;
				}

			hideDiv('TransferMain');

			}
		}

// ################################################################################
// Send Hangup command for 3rd party call connected to the conference now to Manager
	function xfercall_send_hangup() 
		{
		var xferchannel = document.vicidial_form.xferchannel.value;
		var xfer_channel = lastxferchannel;
		var process_post_hangup=0;
		if (xferchannel.length > 3)
			{
			var xmlhttp=false;
			/*@cc_on @*/
			/*@if (@_jscript_version >= 5)
			// JScript gives us Conditional compilation, we can cope with old IE versions.
			// and security blocked creation of the objects.
			 try {
			  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
			 } catch (e) {
			  try {
			   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
			  } catch (E) {
			   xmlhttp = false;
			  }
			 }
			@end @*/
			if (!xmlhttp && typeof XMLHttpRequest!='undefined')
				{
				xmlhttp = new XMLHttpRequest();
				}
			if (xmlhttp) 
				{ 
				var queryCID = "HXvdcW" + epoch_sec + user_abb;
				var hangupvalue = xfer_channel;
				custhangup_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=Hangup&format=text&user=" + user + "&pass=" + pass + "&channel=" + hangupvalue + "&queryCID=" + queryCID;
				xmlhttp.open('POST', 'manager_send.php'); 
				xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
				xmlhttp.send(custhangup_query); 
				xmlhttp.onreadystatechange = function() 
					{ 
					if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
						{
						Nactiveext = null;
						Nactiveext = xmlhttp.responseText;
				//		alert(xmlhttp.responseText);
						}
					}
				process_post_hangup=1;
				delete xmlhttp;
				}
			}
			else {process_post_hangup=1;}
			if (process_post_hangup==1)
			{
			XD_live_customer_call = 0;
			XD_live_call_seconds = 0;
			MD_ring_seconds = 0;
			MD_channel_look=0;
			XDnextCID = '';
			XDcheck = '';
			xferchannellive=0;

		//  DEACTIVATE CHANNEL-DEPENDANT BUTTONS AND VARIABLES
			document.vicidial_form.xferchannel.value = "";
			lastxferchannel='';

			document.getElementById("Leave3WayCall").innerHTML ="<IMG SRC=\"./images/vdc_XB_leave3waycall_OFF.gif\" border=0 alt=\"LEAVE 3-WAY CALL\">";

			document.getElementById("DialWithCustomer").innerHTML ="<a href=\"#\" onclick=\"SendManualDial('YES');return false;\"><IMG SRC=\"./images/vdc_XB_dialwithcustomer.gif\" border=0 alt=\"Dial With Customer\"></a>";

			document.getElementById("ParkCustomerDial").innerHTML ="<a href=\"#\" onclick=\"xfer_park_dial();return false;\"><IMG SRC=\"./images/vdc_XB_parkcustomerdial.gif\" border=0 alt=\"Park Customer Dial\"></a>";

			document.getElementById("HangupXferLine").innerHTML ="<IMG SRC=\"./images/vdc_XB_hangupxferline_OFF.gif\" border=0 alt=\"Hangup Xfer Line\">";

			document.getElementById("HangupBothLines").innerHTML ="<a href=\"#\" onclick=\"bothcall_send_hangup();return false;\"><IMG SRC=\"./images/vdc_XB_hangupbothlines.gif\" border=0 alt=\"Hangup Both Lines\"></a>";
			}
		}

// ################################################################################
// Update vicidial_list lead record with all altered values from form
	function CustomerData_update()
		{
		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			VLupdate_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=updateLEAD&format=text&user=" + user + "&pass=" + pass + 
			"&lead_id=" + document.vicidial_form.lead_id.value + 
			"&vendor_lead_code=" + document.vicidial_form.vendor_lead_code.value + 
			"&phone_number=" + document.vicidial_form.phone_number.value + 
			"&title=" + document.vicidial_form.title.value + 
			"&first_name=" + document.vicidial_form.first_name.value + 
			"&middle_initial=" + document.vicidial_form.middle_initial.value + 
			"&last_name=" + document.vicidial_form.last_name.value + 
			"&address1=" + document.vicidial_form.address1.value + 
			"&address2=" + document.vicidial_form.address2.value + 
			"&address3=" + document.vicidial_form.address3.value + 
			"&city=" + document.vicidial_form.city.value + 
			"&state=" + document.vicidial_form.state.value + 
			"&province=" + document.vicidial_form.province.value + 
			"&postal_code=" + document.vicidial_form.postal_code.value + 
			"&country_code=" + document.vicidial_form.country_code.value + 
			"&gender=" + document.vicidial_form.gender.value + 
			"&date_of_birth=" + document.vicidial_form.date_of_birth.value + 
			"&alt_phone=" + document.vicidial_form.alt_phone.value + 
			"&email=" + document.vicidial_form.email.value + 
			"&security_phrase=" + document.vicidial_form.security_phrase.value + 
			"&comments=" + document.vicidial_form.comments.value;
			xmlhttp.open('POST', 'vdc_db_query.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(VLupdate_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
				//	alert(xmlhttp.responseText);
					}
				}
			delete xmlhttp;
			}

		}

// ################################################################################
// Generate the Call Disposition Chooser panel
	function DispoSelectContent_create(taskDSgrp,taskDSstage)
		{
		AgentDispoing = 1;
		var VD_statuses_ct_half = parseInt(VD_statuses_ct / 2);
		var dispo_HTML = "<table cellpadding=5 cellspacing=5 width=500><tr><td colspan=2><B>CALL DISPOSITION</B></td></tr><tr><td bgcolor=\"#99FF99\" height=300 width=240 valign=top><font class=\"log_text\"><span id=DispoSelectA>";
		var loop_ct = 0;
		while (loop_ct < VD_statuses_ct)
			{
			if (taskDSgrp == VARstatuses[loop_ct]) 
				{
				dispo_HTML = dispo_HTML + "<font size=3 style=\"BACKGROUND-COLOR: #FFFFCC\"><b><a href=\"#\" onclick=\"DispoSelect_submit();return false;\">" + VARstatuses[loop_ct] + " - " + VARstatusnames[loop_ct] + "</a></b></font><BR><BR>";
				}
			else
				{
				dispo_HTML = dispo_HTML + "<a href=\"#\" onclick=\"DispoSelectContent_create('" + VARstatuses[loop_ct] + "','ADD');return false;\">" + VARstatuses[loop_ct] + " - " + VARstatusnames[loop_ct] + "</a><BR><BR>";
				}
			if (loop_ct == VD_statuses_ct_half) 
				{dispo_HTML = dispo_HTML + "</span></font></td><td bgcolor=\"#99FF99\" height=300 width=240 valign=top><font class=\"log_text\"><span id=DispoSelectB>";}
			loop_ct++;
			}
		dispo_HTML = dispo_HTML + "</span></font></td></tr></table>";

		if (taskDSstage == 'RESET') {document.vicidial_form.DispoSelection.value = '';}
		else {document.vicidial_form.DispoSelection.value = taskDSgrp;}
		
		document.getElementById("DispoSelectContent").innerHTML = dispo_HTML;
		}

// ################################################################################
// Update vicidial_list lead record with disposition selection
	function DispoSelect_submit()
		{

		var DispoChoice = document.vicidial_form.DispoSelection.value;

		if (DispoChoice.length < 1) {alert("You Must Select a Disposition");}
		else
			{
			var xmlhttp=false;
			/*@cc_on @*/
			/*@if (@_jscript_version >= 5)
			// JScript gives us Conditional compilation, we can cope with old IE versions.
			// and security blocked creation of the objects.
			 try {
			  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
			 } catch (e) {
			  try {
			   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
			  } catch (E) {
			   xmlhttp = false;
			  }
			 }
			@end @*/
			if (!xmlhttp && typeof XMLHttpRequest!='undefined')
				{
				xmlhttp = new XMLHttpRequest();
				}
			if (xmlhttp) 
				{ 
				DSupdate_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=updateDISPO&format=text&user=" + user + "&pass=" + pass + "&dispo_choice=" + DispoChoice + "&lead_id=" + document.vicidial_form.lead_id.value + "&auto_dial_level=" + auto_dial_level;
				xmlhttp.open('POST', 'vdc_db_query.php'); 
				xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
				xmlhttp.send(DSupdate_query); 
				xmlhttp.onreadystatechange = function() 
					{ 
					if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
						{
				//		alert(xmlhttp.responseText);
						}
					}
				delete xmlhttp;
				}
			// CLEAR ALL FORM VARIABLES
			document.vicidial_form.lead_id.value		='';
			document.vicidial_form.vendor_lead_code.value='';
			document.vicidial_form.list_id.value		='';
			document.vicidial_form.gmt_offset_now.value	='';
			document.vicidial_form.phone_code.value		='';
			document.vicidial_form.phone_number.value	='';
			document.vicidial_form.title.value			='';
			document.vicidial_form.first_name.value		='';
			document.vicidial_form.middle_initial.value	='';
			document.vicidial_form.last_name.value		='';
			document.vicidial_form.address1.value		='';
			document.vicidial_form.address2.value		='';
			document.vicidial_form.address3.value		='';
			document.vicidial_form.city.value			='';
			document.vicidial_form.state.value			='';
			document.vicidial_form.province.value		='';
			document.vicidial_form.postal_code.value	='';
			document.vicidial_form.country_code.value	='';
			document.vicidial_form.gender.value			='';
			document.vicidial_form.date_of_birth.value	='';
			document.vicidial_form.alt_phone.value		='';
			document.vicidial_form.email.value			='';
			document.vicidial_form.security_phrase.value='';
			document.vicidial_form.comments.value		='';
			document.vicidial_form.called_count.value	='';

			hideDiv('DispoSelectBox');
			AgentDispoing = 0;

			if (document.vicidial_form.DispoSelectStop.checked==true)
				{
				if (auto_dial_level != '0')
					{
					AutoDialWaiting = 0;
					AutoDialResumePause("VDADpause");
			//		document.getElementById("DialControl").innerHTML = DialControl_auto_HTML;
					}
				VICIDIAL_pause_calling = 1;
				}
			else
				{
				if (auto_dial_level != '0')
					{
					AutoDialWaiting = 1;
					AutoDialResumePause("VDADready");
			//		document.getElementById("DialControl").innerHTML = DialControl_auto_HTML_ready;
					}
				}
			}
		}

// ################################################################################
// Show message that customer has hungup the call before agent has
	function CustomerChannelGone()
		{
		showDiv('CustomerGoneBox');

		document.vicidial_form.callchannel.value = '';
		document.getElementById("CustomerGoneChannel").innerHTML = lastcustchannel;
		if( document.images ) { document.images['livecall'].src = image_livecall_OFF.src;}
		WaitingForNextStep=1;
		}
	function CustomerGoneOK()
		{
		hideDiv('CustomerGoneBox');
		WaitingForNextStep=0;
		custchannellive=0;
		}
// ################################################################################
// Show message that there are no voice channels in the VICIDIAL session
	function NoneInSession()
		{
		showDiv('NoneInSessionBox');

		document.getElementById("NoneInSessionID").innerHTML = session_id;
		WaitingForNextStep=1;
		}
	function NoneInSessionOK()
		{
		hideDiv('NoneInSessionBox');
		WaitingForNextStep=0;
		nochannelinsession=0;
		}

// ################################################################################
// Generate the Closer In Group Chooser panel
	function CloserSelectContent_create()
		{
		var live_CSC_HTML = "<table cellpadding=5 cellspacing=5 width=500><tr><td><B>GROUPS NOT SELECTED</B></td><td><B>SELECTED GROUPS</B></td></tr><tr><td bgcolor=\"#99FF99\" height=300 width=240 valign=top><font class=\"log_text\"><span id=CloserSelectAdd>";
		var loop_ct = 0;
		while (loop_ct < INgroupCOUNT)
			{
			live_CSC_HTML = live_CSC_HTML + "<a href=\"#\" onclick=\"CloserSelect_change('" + VARingroups[loop_ct] + "','ADD');return false;\">" + VARingroups[loop_ct] + "<BR>";
			loop_ct++;
			}
		live_CSC_HTML = live_CSC_HTML + "</span></font></td><td bgcolor=\"#99FF99\" height=300 width=240 valign=top><font class=\"log_text\"><span id=CloserSelectDelete></span></font></td></tr></table>";

		document.vicidial_form.CloserSelectList.value = '';
		document.getElementById("CloserSelectContent").innerHTML = live_CSC_HTML;
		}

// ################################################################################
// Move a Closer In Group record to the selected column or reverse
	function CloserSelect_change(taskCSgrp,taskCSchange)
		{
		var CloserSelectListValue = document.vicidial_form.CloserSelectList.value;
		var CSCchange = 0;
		var regCS = new RegExp(" "+taskCSgrp+" ","ig");
		if ( (CloserSelectListValue.match(regCS)) && (CloserSelectListValue.length > 4) )
			{
			if (taskCSchange == 'DELETE') {CSCchange = 1;}
			}
		else
			{
			if (taskCSchange == 'ADD') {CSCchange = 1;}
			}

	//	alert(taskCSgrp+"|"+taskCSchange+"|"+CloserSelectListValue.length+"|"+CSCchange+"|"+CSCcolumn)

		if (CSCchange==1) 
			{
			var loop_ct = 0;
			var CSCcolumn = '';
			var live_CSC_HTML_ADD = '';
			var live_CSC_HTML_DELETE = '';
			var live_CSC_LIST_value = " ";
			while (loop_ct < INgroupCOUNT)
				{
				var regCSL = new RegExp(" "+VARingroups[loop_ct]+" ","ig");
				if (CloserSelectListValue.match(regCSL)) {CSCcolumn = 'DELETE';}
				else {CSCcolumn = 'ADD';}
				if ( (VARingroups[loop_ct] == taskCSgrp) && (taskCSchange == 'DELETE') ) {CSCcolumn = 'ADD';}
				if ( (VARingroups[loop_ct] == taskCSgrp) && (taskCSchange == 'ADD') ) {CSCcolumn = 'DELETE';}
					

				if (CSCcolumn == 'DELETE')
					{
					live_CSC_HTML_DELETE = live_CSC_HTML_DELETE + "<a href=\"#\" onclick=\"CloserSelect_change('" + VARingroups[loop_ct] + "','DELETE');return false;\">" + VARingroups[loop_ct] + "<BR>";
					live_CSC_LIST_value = live_CSC_LIST_value + VARingroups[loop_ct] + " ";
					}
				else
					{
					live_CSC_HTML_ADD = live_CSC_HTML_ADD + "<a href=\"#\" onclick=\"CloserSelect_change('" + VARingroups[loop_ct] + "','ADD');return false;\">" + VARingroups[loop_ct] + "<BR>";
					}
				loop_ct++;
				}

			document.vicidial_form.CloserSelectList.value = live_CSC_LIST_value;
			document.getElementById("CloserSelectAdd").innerHTML = live_CSC_HTML_ADD;
			document.getElementById("CloserSelectDelete").innerHTML = live_CSC_HTML_DELETE;
			}
		}

// ################################################################################
// Update vicidial_live_agents record with closer in group choices
	function CloserSelect_submit()
		{
		if (document.vicidial_form.CloserSelectBlended.checked==true)
			{VICIDIAL_closer_blended = 1;}

		var CloserSelectChoices = document.vicidial_form.CloserSelectList.value;

		var xmlhttp=false;
		/*@cc_on @*/
		/*@if (@_jscript_version >= 5)
		// JScript gives us Conditional compilation, we can cope with old IE versions.
		// and security blocked creation of the objects.
		 try {
		  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
		 } catch (e) {
		  try {
		   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
		  } catch (E) {
		   xmlhttp = false;
		  }
		 }
		@end @*/
		if (!xmlhttp && typeof XMLHttpRequest!='undefined')
			{
			xmlhttp = new XMLHttpRequest();
			}
		if (xmlhttp) 
			{ 
			CSCupdate_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=regCLOSER&format=text&user=" + user + "&pass=" + pass + "&closer_choice=" + CloserSelectChoices + "-";
			xmlhttp.open('POST', 'vdc_db_query.php'); 
			xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
			xmlhttp.send(CSCupdate_query); 
			xmlhttp.onreadystatechange = function() 
				{ 
				if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
					{
		//			alert(xmlhttp.responseText);
					}
				}
			delete xmlhttp;
			}

		hideDiv('CloserSelectBox');
		MainPanelToFront();
		CloserSelecting = 0;
		}


// ################################################################################
// Log the user out of the system, if active call or active dial is occuring, don't let them.
	function Logout()
		{
		if (MD_channel_look==1)
			{alert("You cannot log out during a Dial attempt. \nWait 50 seconds for the dial to fail out if it is not answered");}
		else
			{
			if (VD_live_customer_call==1)
				{
				alert("STILL A LIVE CALL! Hang it up then you can log out.\n" + VD_live_customer_call);
				}
			else
				{
				var xmlhttp=false;
				/*@cc_on @*/
				/*@if (@_jscript_version >= 5)
				// JScript gives us Conditional compilation, we can cope with old IE versions.
				// and security blocked creation of the objects.
				 try {
				  xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
				 } catch (e) {
				  try {
				   xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
				  } catch (E) {
				   xmlhttp = false;
				  }
				 }
				@end @*/
				if (!xmlhttp && typeof XMLHttpRequest!='undefined')
					{
					xmlhttp = new XMLHttpRequest();
					}
				if (xmlhttp) 
					{ 
					VDlogout_query = "server_ip=" + server_ip + "&session_name=" + session_name + "&ACTION=userLOGOUT&format=text&user=" + user + "&pass=" + pass + "&campaign=" + campaign + "&conf_exten=" + session_id + "&extension=" + extension + "&protocol=" + protocol;
					xmlhttp.open('POST', 'vdc_db_query.php'); 
					xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded; charset=UTF-8');
					xmlhttp.send(VDlogout_query); 
					xmlhttp.onreadystatechange = function() 
						{ 
						if (xmlhttp.readyState == 4 && xmlhttp.status == 200) 
							{
				//			alert(xmlhttp.responseText);
							}
						}
					delete xmlhttp;
					}

				hideDiv('MainPanel');
				showDiv('LogoutBox');

				document.getElementById("LogoutBoxLink").innerHTML = "<a href=\"" + agcDIR + "?relogin=YES&session_epoch=" + epoch_sec + "&session_id=" + session_id + "&session_name=" + session_name + "&VD_login=" + user + "&VD_campaign=" + campaign + "&phone_login=" + phone_login + "&phone_pass=" + phone_pass + "&VD_pass=" + pass + "\">CLICK HERE TO LOG IN AGAIN</a>\n";

				logout_stop_timeouts = 1;
					
				//	window.location= agcDIR + "?relogin=YES&session_epoch=" + epoch_sec + "&session_id=" + session_id + "&session_name=" + session_name + "&VD_login=" + user + "&VD_campaign=" + campaign + "&phone_login=" + phone_login + "&phone_pass=" + phone_pass + "&VD_pass=" + pass;

				}
			}

		}


// ################################################################################
// GLOBAL FUNCTIONS
	function start_all_refresh()
		{
		if (VICIDIAL_closer_login_checked==0)
			{
			hideDiv('MainXFERBox');
			hideDiv('MainPanel');
			hideDiv('DispoSelectBox');
			hideDiv('LogoutBox');
			hideDiv('CustomerGoneBox');
			hideDiv('NoneInSessionBox');
			hideDiv('TransferMain');
			document.getElementById("sessionIDspan").innerHTML = session_id;

			if (INgroupCOUNT > 0)
				{
				showDiv('CloserSelectBox');
				var CloserSelecting = 1;
				CloserSelectContent_create();
				}
			else
				{
				hideDiv('CloserSelectBox');
				MainPanelToFront();
				var CloserSelecting = 0;
				}
			VICIDIAL_closer_login_checked = 1;
			}
		else
			{
			var WaitingForNextStep=0;
			if (CloserSelecting==1)	{WaitingForNextStep=1;}
			if (open_dispo_screen==1)
				{
				CustomerData_update();
				showDiv('DispoSelectBox');
				DispoSelectContent_create('','RESET');
				WaitingForNextStep=1;
				open_dispo_screen=0;
				document.getElementById("DispoSelectPhone").innerHTML = document.vicidial_form.phone_number.value;
				}
			if (AgentDispoing==1)	
				{
				WaitingForNextStep=1;
				check_for_conf_calls(session_id, '0');
				}
			if (logout_stop_timeouts==1)	{WaitingForNextStep=1;}
			if ( (custchannellive < -3) && (lastcustchannel.length > 3) ) {CustomerChannelGone();}
			if (nochannelinsession > 5) {NoneInSession();}
			if (WaitingForNextStep==0)
				{
				// check for live channels in conference room and get current datetime
				check_for_conf_calls(session_id, '0');

				if (AutoDialWaiting == 1)
					{
					check_for_auto_incoming();
					}
				// look for a channel name for the manually dialed call
				if (MD_channel_look==1)
					{
					ManualDialCheckChannel(XDcheck);
					}
				if (VD_live_customer_call==1)
					{
					VD_live_call_seconds++;
					document.vicidial_form.seconds.value		= VD_live_call_seconds;
					}
				if (XD_live_customer_call==1)
					{
					XD_live_call_seconds++;
					document.vicidial_form.xferlength.value		= XD_live_call_seconds;
					}

				if (active_display==1)
					{
					check_s = check_n.toString();
						if ( (check_s.match(/00$/)) || (check_n<2) ) 
							{
						//	check_for_conf_calls();
							}
					}
				if (check_n<2) 
					{
					}
				else
					{
				//	check_for_live_calls();
					check_s = check_n.toString();
					if ( (park_refresh > 0) && (check_s.match(/0$|5$/)) ) 
						{
					//	parked_calls_display_refresh();
					}
					}
				}
			}
		setTimeout("all_refresh()", refresh_interval);
		}
	function all_refresh()
		{
		epoch_sec++;
		check_n++;
		var year= t.getYear()
		var month= t.getMonth()
			month++;
		var daym= t.getDate()
		var hours = t.getHours();
		var min = t.getMinutes();
		var sec = t.getSeconds();
		if (year < 1000) {year+=1900}
		if (month< 10) {month= "0" + month}
		if (daym< 10) {daym= "0" + daym}
		if (hours < 10) {hours = "0" + hours;}
		if (min < 10) {min = "0" + min;}
		if (sec < 10) {sec = "0" + sec;}
		filedate = year + month + daym + "-" + hours + min + sec;
		SQLdate = year + "-" + month + "-" + daym + " " + hours + ":" + min + ":" + sec;
		document.getElementById("status").innerHTML = year + "-" + month + "-" + daym + " " + hours + ":" + min + ":" + sec  + display_message;
		if (VD_live_customer_call==1)
			{
			var customer_gmt = document.vicidial_form.gmt_offset_now.value;
			var AMPM = 'AM';
			var customer_gmt_diff = (customer_gmt - local_gmt);
			var UnixTimec = (UnixTime + (3600 * customer_gmt_diff));
			var UnixTimeMSc = (UnixTimec * 1000);
			c.setTime(UnixTimeMSc);
			var Cmon= t.getMonth()
				Cmon++;
			var Cdaym= t.getDate()
			var Chours = t.getHours();
			var Cmin = t.getMinutes();
			var Csec = t.getSeconds();
			if (Cmon < 10) {Cmon= "0" + Cmon}
			if (Cdaym < 10) {Cdaym= "0" + Cdaym}
			if (Chours < 10) {Chours = "0" + Chours;}
			if (Cmin < 10) {Cmin = "0" + Cmin;}
			if (Csec < 10) {Csec = "0" + Csec;}
			if (Cmon == 0) {Cmon = "JAN";}
			if (Cmon == 1) {Cmon = "FEB";}
			if (Cmon == 2) {Cmon = "MAR";}
			if (Cmon == 3) {Cmon = "APR";}
			if (Cmon == 4) {Cmon = "MAY";}
			if (Cmon == 5) {Cmon = "JUN";}
			if (Cmon == 6) {Cmon = "JLY";}
			if (Cmon == 7) {Cmon = "AUG";}
			if (Cmon == 8) {Cmon = "SEP";}
			if (Cmon == 9) {Cmon = "OCT";}
			if (Cmon == 10) {Cmon = "NOV";}
			if (Cmon == 11) {Cmon = "DEC";}
			if (Chours > 12) {Chours = (Chours - 12);   AMPM = 'PM';}
			if (Cmin < 10) {Cmin = "0" + Cmin;}
			if (Csec < 10) {Csec = "0" + Csec;}

			var customer_local_time = Cmon + " " + Cdaym + "   " + Chours + ":" + Cmin + ":" + Csec + " " + AMPM;
			document.vicidial_form.custdatetime.value		= customer_local_time;
			}
		start_all_refresh();
		}
	function pause()	// Pauses the refreshing of the lists
		{active_display=2;  display_message='  * ACTIVE DISPLAY PAUSED *';}
	function start()	// resumes the refreshing of the lists
		{active_display=1;  display_message='';}
	function faster()	// lowers by 1000 milliseconds the time until the next refresh
		{
		 if (refresh_interval>1001)
			{refresh_interval=(refresh_interval - 1000);}
		}
	function slower()	// raises by 1000 milliseconds the time until the next refresh
		{
		refresh_interval=(refresh_interval + 1000);
		}

	// activeext-specific functions
	function activeext_force_refresh()	// forces immediate refresh of list content
		{getactiveext();}
	function activeext_order_asc()	// changes order of activeext list to ascending
		{
		activeext_order="asc";   getactiveext();
		desc_order_HTML ='<a href="#" onclick="activeext_order_desc();return false;">ORDER</a>';
		document.getElementById("activeext_order").innerHTML = desc_order_HTML;
		}
	function activeext_order_desc()	// changes order of activeext list to descending
		{
		activeext_order="desc";   getactiveext();
		asc_order_HTML ='<a href="#" onclick="activeext_order_asc();return false;">ORDER</a>';
		document.getElementById("activeext_order").innerHTML = asc_order_HTML;
		}

	// busytrunk-specific functions
	function busytrunk_force_refresh()	// forces immediate refresh of list content
		{getbusytrunk();}
	function busytrunk_order_asc()	// changes order of busytrunk list to ascending
		{
		busytrunk_order="asc";   getbusytrunk();
		desc_order_HTML ='<a href="#" onclick="busytrunk_order_desc();return false;">ORDER</a>';
		document.getElementById("busytrunk_order").innerHTML = desc_order_HTML;
		}
	function busytrunk_order_desc()	// changes order of busytrunk list to descending
		{
		busytrunk_order="desc";   getbusytrunk();
		asc_order_HTML ='<a href="#" onclick="busytrunk_order_asc();return false;">ORDER</a>';
		document.getElementById("busytrunk_order").innerHTML = asc_order_HTML;
		}
	function busytrunkhangup_force_refresh()	// forces immediate refresh of list content
		{busytrunkhangup();}

	// busyext-specific functions
	function busyext_force_refresh()	// forces immediate refresh of list content
		{getbusyext();}
	function busyext_order_asc()	// changes order of busyext list to ascending
		{
		busyext_order="asc";   getbusyext();
		desc_order_HTML ='<a href="#" onclick="busyext_order_desc();return false;">ORDER</a>';
		document.getElementById("busyext_order").innerHTML = desc_order_HTML;
		}
	function busyext_order_desc()	// changes order of busyext list to descending
		{
		busyext_order="desc";   getbusyext();
		asc_order_HTML ='<a href="#" onclick="busyext_order_asc();return false;">ORDER</a>';
		document.getElementById("busyext_order").innerHTML = asc_order_HTML;
		}
	function busylocalhangup_force_refresh()	// forces immediate refresh of list content
		{busylocalhangup();}


	// functions to hide and show different DIVs
	function showDiv(divvar) 
		{
		if (document.getElementById(divvar))
			{
			divref = document.getElementById(divvar).style;
			divref.visibility = 'visible';
			}
		}
	function hideDiv(divvar)
		{
		if (document.getElementById(divvar))
			{
			divref = document.getElementById(divvar).style;
			divref.visibility = 'hidden';
			}
		}

	function showMainXFER(divvar,taskxferchan,taskxferchanmain) 
		{
		document.getElementById("MainXFERBox").style.visibility = 'visible';
		getactiveext("MainXFERBox");
		conference_list_display_refresh("MainXFERconfContent");
		var XFER_channel = taskxferchan;
		document.vicidial_form.H_XFER_channel.value = XFER_channel;
		document.vicidial_form.M_XFER_channel.value = taskxferchanmain;
		document.getElementById("MainXFERChannel").innerHTML = XFER_channel;
		}
	function hideMainXFER(divvar) 
		{
		document.getElementById("MainXFERBox").style.visibility = 'hidden';
		var XFER_channel = '';
		document.vicidial_form.H_XFER_channel.value = '';
		document.vicidial_form.M_XFER_channel.value = '';
		document.getElementById("MainXFERChannel").innerHTML = '';
		}
	function conf_channels_detail(divvar) 
		{
		if (divvar == 'SHOW')
			{
			conf_channels_xtra_display = 1;
			document.getElementById("busycallsdisplay").innerHTML = "<a href=\"#\"  onclick=\"conf_channels_detail('HIDE');\">Hide conference call channel information</a>";
			LMAe[0]=''; LMAe[1]=''; LMAe[2]=''; LMAe[3]=''; LMAe[4]=''; LMAe[5]=''; 
			LMAcount=0;
			}
		else
			{
			conf_channels_xtra_display = 0;
			document.getElementById("busycallsdisplay").innerHTML = "<a href=\"#\"  onclick=\"conf_channels_detail('SHOW');\">Show conference call channel information</a>";
			document.getElementById("outboundcallsspan").innerHTML = '';
			LMAe[0]=''; LMAe[1]=''; LMAe[2]=''; LMAe[3]=''; LMAe[4]=''; LMAe[5]=''; 
			LMAcount=0;
			}
		}


	function MainPanelToFront()
		{
		showDiv('MainPanel');
		if (auto_dial_level == 0)
			{document.getElementById("DialControl").innerHTML = DialControl_manual_HTML;}
		else
			{document.getElementById("DialControl").innerHTML = DialControl_auto_HTML;}
		}

	</script>

    <STYLE type="text/css">
    </STYLE>


<style type="text/css">
<!--
	div.scroll_log {height: 135px; width: 600px; overflow: scroll;}
	div.scroll_park {height: 400px; width: 620px; overflow: scroll;}
	div.scroll_list {height: 400px; width: 140px; overflow: scroll;}
   .body_text {font-size: 13px;  font-family: sans-serif;}
   .body_small {font-size: 11px;  font-family: sans-serif;}
   .body_tiny {font-size: 10px;  font-family: sans-serif;}
   .log_text {font-size: 11px;  font-family: monospace;}
   .log_title {font-size: 12px;  font-family: monospace; font-weight: bold;}
   .sh_text {font-size: 14px;  font-family: sans-serif; font-weight: bold;}
   .sb_text {font-size: 12px;  font-family: sans-serif;}
   .ON_conf {font-size: 11px;  font-family: monospace; color: black ; background: #FFFF99}
   .OFF_conf {font-size: 11px;  font-family: monospace; color: black ; background: #FFCC77}
   .cust_form {font-family : sans-serif; font-size : 10px}

-->
</style>
<?
echo "</head>\n";


?>
<BODY onload="all_refresh();">
<FORM name=vicidial_form>
<span style="position:absolute;left:0px;top:0px;z-index:1;" id="Header">
<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0 BGCOLOR=white WIDTH=640 MARGINWIDTH=0 MARGINHEIGHT=0 LEFTMARGIN=0 TOPMARGIN=0 VALIGN=TOP ALIGN=LEFT>
<TR VALIGN=TOP ALIGN=LEFT><TD COLSPAN=2 VALIGN=TOP ALIGN=LEFT>
<INPUT TYPE=HIDDEN NAME=extension>
<font class="body_text">
<?	echo "Logged in as User: $VD_login on Phone: $SIP_user to campaign: $VD_campaign&nbsp; \n"; ?>
</TD><TD COLSPAN=2 VALIGN=TOP ALIGN=RIGHT><font class="body_text"><?	echo "<a href=\"#\" onclick=\"Logout();return false;\">LOGOUT</a>\n"; ?>
</TD></TR>
<TR VALIGN=TOP ALIGN=LEFT>
<TD ALIGN=LEFT WIDTH=117><A HREF="#" onclick="MainPanelToFront();"><IMG SRC="./images/vdc_tab_vicidial.gif" ALT="VICIDIAL" WIDTH=117 HEIGHT=30 BORDER=0></A></TD>
<TD WIDTH=414 VALIGN=MIDDLE ALIGN=CENTER><font class="body_text"> &nbsp; <span id=status>LIVE</span> &nbsp; &nbsp; session ID: <span id=sessionIDspan></span></TD>
<TD WIDTH=109><IMG SRC="./images/agc_live_call_OFF.gif" NAME=livecall ALT="Live Call" WIDTH=109 HEIGHT=30 BORDER=0></TD>
</TR></TABLE>
</SPAN>


<span style="position:absolute;left:0px;top:12px;z-index:24;" id="NoneInSessionBox">
    <table border=1 bgcolor="#CCFFFF" width=600 height=500><TR><TD align=center> Noone is in your session: <span id="NoneInSessionID"></span><BR>
	<a href="#" onclick="NoneInSessionOK();return false;">OK</a>
	</TD></TR></TABLE>
</span>

<span style="position:absolute;left:0px;top:0px;z-index:25;" id="CustomerGoneBox">
    <table border=1 bgcolor="#CCFFFF" width=650 height=500><TR><TD align=center> Customer has hung up: <span id="CustomerGoneChannel"></span><BR>
	<a href="#" onclick="CustomerGoneOK();return false;">OK</a>
	</TD></TR></TABLE>
</span>

<span style="position:absolute;left:0px;top:0px;z-index:26;" id="LogoutBox">
    <table border=1 bgcolor="#FFFFFF" width=650 height=500><TR><TD align=center><BR><span id="LogoutBoxLink">Logout</span></TD></TR></TABLE>
</span>


<span style="position:absolute;left:0px;top:0px;z-index:27;" id="DispoSelectBox">
    <table border=1 bgcolor="#CCFFCC" width=650 height=460><TR><TD align=center VALIGN=top> DISPOSITION CALL :<span id="DispoSelectPhone"></span><BR>
	<span id="DispoSelectContent"> End-of-call Disposition Selection </span>
	<input type=hidden name=DispoSelection><BR>
	<input type=checkbox name=DispoSelectStop size=1 value="0"> STOP CALLING <BR>
	<a href="#" onclick="DispoSelectContent_create('','RESET');return false;">Reset</a> | 
	<a href="#" onclick="DispoSelect_submit();return false;">SUBMIT</a>
	<BR><BR><BR><BR> &nbsp; 
	</TD></TR></TABLE>
</span>

<span style="position:absolute;left:0px;top:0px;z-index:28;" id="CloserSelectBox">
    <table border=1 bgcolor="#CCFFCC" width=650 height=460><TR><TD align=center VALIGN=top> CLOSER INBOUND GROUP SELECTION <BR>
	<span id="CloserSelectContent"> Closer Inbound Group Selection </span>
	<input type=hidden name=CloserSelectList><BR>
	<input type=checkbox name=CloserSelectBlended size=1 value="0"> BLENDED CALLING(outbound activated) <BR>
	<a href="#" onclick="CloserSelectContent_create();return false;">Reset</a> | 
	<a href="#" onclick="CloserSelect_submit();return false;">SUBMIT</a>
	<BR><BR><BR><BR> &nbsp; 
	</TD></TR></TABLE>
</span>

<span style="position:absolute;left:80px;top:12px;z-index:42;" id="MainXFERBox">
	<input type=hidden name=H_XFER_channel>
	<input type=hidden name=M_XFER_channel>
    <table border=0 bgcolor="#FFFFCC" width=600 height=500 cellpadding=3><TR><TD COLSPAN=3 ALIGN=CENTER><b> LIVE CALL TRANSFER</b> <BR>Channel to be transferred: <span id="MainXFERChannel">channel</span><BR></tr>
	<tr><td>Extensions:<BR><span id="MainXFERContent"> Extensions Menu </span></td>
	<td>
	<BR>
	<a href="#" onclick="mainxfer_send_redirect('XFER');return false;">Send to selected extension</a> <BR><BR>
	<a href="#" onclick="mainxfer_send_redirect('VMAIL');return false;">Send to selected vmail box</a> <BR><BR>
	<a href="#" onclick="mainxfer_send_redirect('ENTRY');return false;">Send to this number</a>:<BR><input type=text name=extension_xfer_entry size=20 maxlength=50> <BR><BR>
	<a href="#" onclick="getactiveext('MainXFERBox');return false;">Refresh</a> <BR><BR><BR>
	<a href="#" onclick="hideMainXFER('MainXFERBox');">Back to MAIN</a> <BR><BR>
	</TD>
	<TD>Conferences:<BR><font size=1>(click on a number below to send to a conference)<BR><input type=checkbox name=MainXFERconfXTRA size=1 value="1"> Send my channel too<div class="scroll_list" id="MainXFERconfContent"> Conferences Menu </div></td></TR></TABLE>
</span>



<!-- BEGIN *********   Here is the main VICIDIAL display panel -->
<span  style="position:absolute;left:0px;top:46px;z-index:10;" id="MainPanel">
<TABLE border=0 BGCOLOR="#E0C2D6" width=640>
<TR><TD colspan=3><font class="body_text"> STATUS: <span id="MainStatusSpan"></span></font></TD></TR>
<tr><td colspan=3><span id="busycallsdebug"></span></td></tr>
<tr><td width=150 align=left valign=top>
<font class="body_text"><center>
<span STYLE="background-color: #CCFFCC" id="DialControl"><a href="#" onclick="ManualDialNext();"><IMG SRC="./images/vdc_LB_dialnextnumber_OFF.gif" border=0 alt="Dial Next Number"></a></span><BR>
RECORDING FILE:<BR>
</center>
<font class="body_tiny"><span id="RecordingFilename"></span></font><BR>
RECORD ID: <font class="body_small"><span id="RecordID"></span></font><BR>
<center>
<!-- <a href=\"#\" onclick=\"conf_send_recording('MonitorConf','" + head_conf + "','');return false;\">Record</a> -->
<span STYLE="background-color: #CCCCCC" id="RecordControl"><a href="#" onclick="conf_send_recording('MonitorConf','<?=$session_id ?>','');return false;"><IMG SRC="./images/vdc_LB_startrecording.gif" border=0 alt="Start Recording"></a></span><BR>
<span id="SpacerSpanA"><IMG SRC="./images/blank.gif" width=145 height=16 border=0></span><BR>
<span STYLE="background-color: #FFFFFF" id="WebFormSpan"><IMG SRC="./images/vdc_LB_webform_OFF.gif" border=0 alt="Web Form"></span><BR>
<span id="SpacerSpanB"><IMG SRC="./images/blank.gif" width=145 height=16 border=0></span><BR>
<span STYLE="background-color: #CCCCCC" id="ParkControl"><IMG SRC="./images/vdc_LB_parkcall_OFF.gif" border=0 alt="Park Call"></span><BR>
<span STYLE="background-color: #CCCCCC" id="XferControl"><IMG SRC="./images/vdc_LB_transferconf_OFF.gif" border=0 alt="Transfer - Conference"></span><BR>
<span id="SpacerSpanC"><IMG SRC="./images/blank.gif" width=145 height=16 border=0></span><BR>
<!-- <span STYLE="background-color: #CCCCCC" id="LineControl">HUNGUP | STILL LIVE</span><BR> -->
<span STYLE="background-color: #FFCCFF" id="HangupControl"><IMG SRC="./images/vdc_LB_hangupcustomer_OFF.gif" border=0 alt="Hangup Customer"></span><BR>
<span id="SpacerSpanD"><IMG SRC="./images/blank.gif" width=145 height=16 border=0></span><BR>
<span STYLE="background-color: #CCCCCC" id="SendDTMF"><a href="#" onclick="SendConfDTMF('<?=$session_id ?>');return false;"><IMG SRC="./images/vdc_LB_senddtmf.gif" border=0 alt="Send DTMF"></a>  <input type=text size=5 name=conf_dtmf class="cust_form" value=""></span><BR>
</center>
</font>
</td>
<td width=480 align=left>
<input type=hidden name=lead_id value="">
<input type=hidden name=list_id value="">
<input type=hidden name=called_count value="">
<input type=hidden name=gmt_offset_now value="">
<input type=hidden name=gender value="">
<input type=hidden name=date_of_birth value="">
<input type=hidden name=country_code value="">
<input type=hidden name=uniqueid value="">
<table><tr>
<td align=right><font class="body_text"> Seconds: </td>
<td align=left><font class="body_text"><input type=text size=3 name=seconds class="cust_form" value="">&nbsp; Channel: <input type=text size=6 name=callchannel class="cust_form" value="">&nbsp; Cust Time: <input type=text size=22 name=custdatetime class="cust_form" value=""></td>
</tr><tr>
<td colspan=2 align=center> Customer Information:</td>
</tr><tr>
<td align=right><font class="body_text"> Title: </td>
<td align=left><font class="body_text"><input type=text size=4 name=title maxlength=4 class="cust_form" value="">&nbsp; First: <input type=text size=12 name=first_name maxlength=30 class="cust_form" value="">&nbsp; MI: <input type=text size=1 name=middle_initial maxlength=1 class="cust_form" value="">&nbsp; Last: <input type=text size=15 name=last_name maxlength=30 class="cust_form" value=""></td>
</tr><tr>
<td align=right><font class="body_text"> Address1: </td>
<td align=left><font class="body_text"><input type=text size=50 name=address1 maxlength=100 class="cust_form" value=""></td>
</tr><tr>
<td align=right><font class="body_text"> Address2: </td>
<td align=left><font class="body_text"><input type=text size=17 name=address2 maxlength=100 class="cust_form" value="">&nbsp; Address3: <input type=text size=25 name=address3 maxlength=100 class="cust_form" value=""></td>
</tr><tr>
<td align=right><font class="body_text"> City: </td>
<td align=left><font class="body_text"><input type=text size=20 name=city maxlength=50 class="cust_form" value="">&nbsp; State: <input type=text size=2 name=state maxlength=2 class="cust_form" value="">&nbsp; PostCode: <input type=text size=9 name=postal_code maxlength=10 class="cust_form" value=""></td>
</tr><tr>
<td align=right><font class="body_text"> Province: </td>
<td align=left><font class="body_text"><input type=text size=20 name=province maxlength=50 class="cust_form" value="">&nbsp; Vendor ID: <input type=text size=15 name=vendor_lead_code maxlength=20 class="cust_form" value=""></td>
</tr><tr>
<td align=right><font class="body_text"> Phone: </td>
<td align=left><font class="body_text"><input type=text size=11 name=phone_number maxlength=10 class="cust_form" value="">&nbsp; DialCode: <input type=text size=4 name=phone_code maxlength=10 class="cust_form" value="">&nbsp; Alt. Phone: <input type=text size=11 name=alt_phone maxlength=10 class="cust_form" value=""></td>
</tr><tr>
<td align=right><font class="body_text"> Show: </td>
<td align=left><font class="body_text"><input type=text size=20 name=security_phrase maxlength=100 class="cust_form" value="">&nbsp; Email: <input type=text size=25 name=email maxlength=70 class="cust_form" value=""></td>
</tr><tr>
<td align=right><font class="body_text"> Comments: </td>
<td align=left><font class="body_text"><input type=text size=65 name=comments maxlength=255 class="cust_form" value=""></td>
</tr></table>
</font>
</td>
<td width=1 align=center>
</td>
</tr>
<tr><td align=left colspan=3>

<div id="TransferMain">
	<table bgcolor="#CCCCFF" width=630><tr>
	<td align=left>
	<font class="body_text">
	 <IMG SRC="./images/vdc_XB_header.gif" border=0 alt="Transfer - Conference"><BR>
	<span STYLE="background-color: #CCCCCC" id="InternalCloser"><IMG SRC="./images/vdc_XB_internalcloser.gif" border=0 alt="INTERNAL CLOSER"></span>
	<span STYLE="background-color: #CCCCCC" id="LocalCloser"><IMG SRC="./images/vdc_XB_localcloser_OFF.gif" border=0 alt="LOCAL CLOSER"></span> 
	<span STYLE="background-color: #CCCCCC" id="CloserCode"><IMG SRC="./images/vdc_XB_code.gif" border=0 alt="CODE"> <input type=text size=1 name=xfercode maxlength=2 class="cust_form"></span>
	<span STYLE="background-color: #CCCCCC" id="HangupXferLine"><IMG SRC="./images/vdc_XB_hangupxferline_OFF.gif" border=0 alt="Hangup Xfer Line"></span>
	<span STYLE="background-color: #CCCCCC" id="HangupBothLines"><a href="#" onclick="bothcall_send_hangup();return false;"><IMG SRC="./images/vdc_XB_hangupbothlines.gif" border=0 alt="Hangup Both Lines"></a></span>
	
	<BR>

	<IMG SRC="./images/vdc_XB_number.gif" border=0 alt="Number to call"> <input type=text size=12 name=xfernumber maxlength=15 class="cust_form"> &nbsp; &nbsp; 
	<IMG SRC="./images/vdc_XB_seconds.gif" border=0 alt="seconds"> <input type=text size=2 name=xferlength maxlength=4 class="cust_form"> &nbsp; &nbsp; 
	<IMG SRC="./images/vdc_XB_channel.gif" border=0 alt="channel"> <input type=text size=12 name=xferchannel maxlength=100 class="cust_form"> &nbsp; &nbsp; 
	<input type=hidden name=xferuniqueid>
	
	<BR>

	<span STYLE="background-color: #CCCCCC" id="DialWithCustomer"><a href="#" onclick="SendManualDial('YES');return false;"><IMG SRC="./images/vdc_XB_dialwithcustomer.gif" border=0 alt="Dial With Customer"></a></span> 
	<span STYLE="background-color: #CCCCCC" id="ParkCustomerDial"><a href="#" onclick="xfer_park_dial();return false;"><IMG SRC="./images/vdc_XB_parkcustomerdial.gif" border=0 alt="Park Customer Dial"></a></span> 
	<span STYLE="background-color: #CCCCCC" id="Leave3WayCall"><IMG SRC="./images/vdc_XB_leave3waycall_OFF.gif" border=0 alt="LEAVE 3-WAY CALL"></span> 
	<span STYLE="background-color: #CCCCCC" id="DialBlindTransfer"><IMG SRC="./images/vdc_XB_blindtransfer_OFF.gif" border=0 alt="Dial Blind Transfer"></span>
	</font>
	</td>
	</tr></table>
</div>

</td></tr>

<tr><td align=left colspan=3><font face="Arial,Helvetica" size=1>VICIDIAL web-client version: <? echo $version ?> &nbsp; &nbsp; build: <? echo $build ?> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; server: <? echo $server_ip ?></font></td></tr>
<tr><td colspan=3><font class="body_small"><span id="busycallsdisplay"><a href="#"  onclick="conf_channels_detail('SHOW');">Show conference call channel information</a></span></font></td></tr>
<tr><td colspan=3><span id="outboundcallsspan"></span></td></tr>

<tr><td colspan=3>
<font class="body_small">
<span id="debugbottomspan"></span>
</font>
</td></tr>
</TABLE>
</span>
<!-- END *********   Here is the main VICIDIAL display panel -->





</TD></TR></TABLE>

</FORM>
</body>
</html>

<?
	
exit; 



?>





