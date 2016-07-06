<?
### vdc_db_query.php

### This script is designed purely to send whether the meetme conference has live channels connected and which they are
### This script depends on the server_ip being sent and also needs to have a valid user/pass from the vicidial_users table
### 
### required variables:
###  - $server_ip
###  - $session_name
###  - $user
###  - $pass
### optional variables:
###  - $format - ('text','debug')
###  - $ACTION - ('regCLOSER','manDiaLnextCALL','manDiaLskip','manDiaLonly','manDiaLlookCALL','manDiaLlogCALL','userLOGout','updateDISPO','VDADpause','VDADready','VDADcheckINCOMING')
###  - $stage - ('start','finish')
###  - $closer_choice - ('CL_TESTCAMP_L CL_OUT123_L -')
###  - $conf_exten - ('8600011',...)
###  - $exten - ('123test',...)
###  - $ext_context - ('default','demo',...)
###  - $ext_priority - ('1','2',...)
###  - $campaign - ('testcamp',...)
###  - $dial_timeout - ('60','26',...)
###  - $dial_prefix - ('9','8',...)
###  - $campaign_cid - ('3125551212','0000000000',...)
###  - $MDnextCID - ('M06301413000000002',...)
###  - $uniqueid - ('1120232758.2406800',...)
###  - $lead_id - ('36524',...)
###  - $list_id - ('101','123456',...)
###  - $length_in_sec - ('12',...)
###  - $phone_code - ('1',...)
###  - $phone_number - ('3125551212',...)
###  - $channel - ('Zap/12-1',...)
###  - $start_epoch - ('1120236911',...)
###  - $vendor_lead_code - ('1234test',...)
###  - $title - ('Mr.',...)
###  - $first_name - ('Bob',...)
###  - $middle_initial - ('L',...)
###  - $last_name - ('Wilson',...)
###  - $address1 - ('1324 Main St.',...)
###  - $address2 - ('Apt. 12',...)
###  - $address3 - ('co Robert Wilson',...)
###  - $city - ('Chicago',...)
###  - $state - ('IL',...)
###  - $province - ('NA',...)
###  - $postal_code - ('60054',...)
###  - $country_code - ('USA',...)
###  - $gender - ('M',...)
###  - $date_of_birth - ('1970-01-01',...)
###  - $alt_phone - ('3125551213',...)
###  - $email - ('bob@bob.com',...)
###  - $security_phrase - ('Hello',...)
###  - $comments - ('Good Customer',...)
###  - $auto_dial_level - ('0','1','1.2',...)
###  - $VDstop_rec_after_each_call - ('0','1')
###  - $conf_silent_prefix - ('7','8','',...)
###  - $extension - ('123','user123','25-1',...)
###  - $protocol - ('Zap','SIP','IAX2',...)
###  - $user_abb - ('1234','6666',...)
###  - $preview - ('YES','NO',...)
###  - $called_count - ('0','1','2',...)
###  - $agent_log_id - ('123456',...)
###  - $agent_log - ('NO',...)
###

# changes
# 50629-1044 First build of script
# 50630-1422 Added manual dial action and MD channel lookup
# 50701-1451 Added dial log for start and end of vicidial calls
# 50705-1239 Added call disposition update
# 50804-1627 Fixed updateDispo to update vicidial_log entry
# 50816-1605 Added VDADpause/ready for auto dialing
# 50816-1811 Added basic autodial call pickup functions
# 50817-1005 Altered logging functions to accomodate auto_dialing
# 50818-1305 Added stop-all-recordings-after-each-vicidial-call option
# 50818-1411 Added hangup of agent phone after Logout
# 50901-1315 Fixed CLOSER IN-GROUP Web Form bug
# 50902-1507 Fixed CLOSER log length_in_sec bug
# 50902-1730 Added functions for manual preview dialing and revert
# 50913-1214 Added agent random update to leadupdate
# 51020-1421 Added agent_log_id framework for detailed agent activity logging
# 51021-1717 Allows for multi-line comments (changes \n to !N in database)
#

require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
$user=$_GET["user"];					if (!$user) {$user=$_POST["user"];}
$pass=$_GET["pass"];					if (!$pass) {$pass=$_POST["pass"];}
$server_ip=$_GET["server_ip"];			if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$session_name=$_GET["session_name"];	if (!$session_name) {$session_name=$_POST["session_name"];}
$format=$_GET["format"];				if (!$format) {$format=$_POST["format"];}
$ACTION=$_GET["ACTION"];				if (!$ACTION) {$ACTION=$_POST["ACTION"];}
$stage=$_GET["stage"];					if (!$stage) {$stage=$_POST["stage"];}
$closer_choice=$_GET["closer_choice"];	if (!$closer_choice) {$closer_choice=$_POST["closer_choice"];}
$conf_exten=$_GET["conf_exten"];		if (!$conf_exten) {$conf_exten=$_POST["conf_exten"];}
$exten=$_GET["exten"];					if (!$exten) {$exten=$_POST["exten"];}
$ext_context=$_GET["ext_context"];		if (!$ext_context) {$ext_context=$_POST["ext_context"];}
$ext_priority=$_GET["ext_priority"];	if (!$ext_priority) {$ext_priority=$_POST["ext_priority"];}
$campaign=$_GET["campaign"];			if (!$campaign) {$campaign=$_POST["campaign"];}
$dial_timeout=$_GET["dial_timeout"];	if (!$dial_timeout) {$dial_timeout=$_POST["dial_timeout"];}
$dial_prefix=$_GET["dial_prefix"];		if (!$dial_prefix) {$dial_prefix=$_POST["dial_prefix"];}
$campaign_cid=$_GET["campaign_cid"];	if (!$campaign_cid) {$campaign_cid=$_POST["campaign_cid"];}
$MDnextCID=$_GET["MDnextCID"];			if (!$MDnextCID) {$MDnextCID=$_POST["MDnextCID"];}
$uniqueid=$_GET["uniqueid"];			if (!$uniqueid) {$uniqueid=$_POST["uniqueid"];}
$lead_id=$_GET["lead_id"];				if (!$lead_id) {$lead_id=$_POST["lead_id"];}
$list_id=$_GET["list_id"];				if (!$list_id) {$list_id=$_POST["list_id"];}
$length_in_sec=$_GET["length_in_sec"];	if (!$length_in_sec) {$length_in_sec=$_POST["length_in_sec"];}
$phone_code=$_GET["phone_code"];		if (!$phone_code) {$phone_code=$_POST["phone_code"];}
$phone_number=$_GET["phone_number"];	if (!$phone_number) {$phone_number=$_POST["phone_number"];}
$channel=$_GET["channel"];				if (!$channel) {$channel=$_POST["channel"];}
$start_epoch=$_GET["start_epoch"];		if (!$start_epoch) {$start_epoch=$_POST["start_epoch"];}
$dispo_choice=$_GET["dispo_choice"];	if (!$dispo_choice) {$dispo_choice=$_POST["dispo_choice"];}
$vendor_lead_code=$_GET["vendor_lead_code"];	if (!$vendor_lead_code) {$vendor_lead_code=$_POST["vendor_lead_code"];}
$title=$_GET["title"];					if (!$title) {$title=$_POST["title"];}
$first_name=$_GET["first_name"];		if (!$first_name) {$first_name=$_POST["first_name"];}
$middle_initial=$_GET["middle_initial"];		if (!$middle_initial) {$middle_initial=$_POST["middle_initial"];}
$last_name=$_GET["last_name"];			if (!$last_name) {$last_name=$_POST["last_name"];}
$address1=$_GET["address1"];			if (!$address1) {$address1=$_POST["address1"];}
$address2=$_GET["address2"];			if (!$address2) {$address2=$_POST["address2"];}
$address3=$_GET["address3"];			if (!$address3) {$address3=$_POST["address3"];}
$city=$_GET["city"];					if (!$city) {$city=$_POST["city"];}
$state=$_GET["state"];					if (!$state) {$state=$_POST["state"];}
$province=$_GET["province"];			if (!$province) {$province=$_POST["province"];}
$postal_code=$_GET["postal_code"];		if (!$postal_code) {$postal_code=$_POST["postal_code"];}
$country_code=$_GET["country_code"];	if (!$country_code) {$country_code=$_POST["country_code"];}
$gender=$_GET["gender"];				if (!$gender) {$gender=$_POST["gender"];}
$date_of_birth=$_GET["date_of_birth"];	if (!$date_of_birth) {$date_of_birth=$_POST["date_of_birth"];}
$alt_phone=$_GET["alt_phone"];			if (!$alt_phone) {$alt_phone=$_POST["alt_phone"];}
$email=$_GET["email"];					if (!$email) {$email=$_POST["email"];}
$security_phrase=$_GET["security_phrase"];		if (!$security_phrase) {$security_phrase=$_POST["security_phrase"];}
$comments=$_GET["comments"];			if (!$comments) {$comments=$_POST["comments"];}
$auto_dial_level=$_GET["auto_dial_level"];	if (!$auto_dial_level) {$auto_dial_level=$_POST["auto_dial_level"];}
$VDstop_rec_after_each_call=$_GET["VDstop_rec_after_each_call"];	if (!$VDstop_rec_after_each_call) {$VDstop_rec_after_each_call=$_POST["VDstop_rec_after_each_call"];}
$conf_silent_prefix=$_GET["conf_silent_prefix"];	if (!$conf_silent_prefix) {$conf_silent_prefix=$_POST["conf_silent_prefix"];}
$extension=$_GET["extension"];			if (!$extension) {$extension=$_POST["extension"];}
$protocol=$_GET["protocol"];			if (!$protocol) {$protocol=$_POST["protocol"];}
$user_abb=$_GET["user_abb"];			if (!$user_abb) {$user_abb=$_POST["user_abb"];}
$preview=$_GET["preview"];				if (!$preview) {$preview=$_POST["preview"];}
$called_count=$_GET["called_count"];	if (!$called_count) {$called_count=$_POST["called_count"];}
$agent_log_id=$_GET["agent_log_id"];	if (!$agent_log_id) {$agent_log_id=$_POST["agent_log_id"];}
$agent_log=$_GET["agent_log"];			if (!$agent_log) {$agent_log=$_POST["agent_log"];}


# default optional vars if not set
if (!$format)	{$format="text";}
if ($format == 'debug')	{$DB=1;}
if (!$ACTION)	{$ACTION="refresh";}

$version = '0.0.16';
$build = '51021-1717';
$StarTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$CIDdate = date("mdHis");
if (!$query_date) {$query_date = $NOW_DATE;}
$MT[0]='';

$stmt="SELECT count(*) from vicidial_users where user='$user' and pass='$pass' and user_level > 0;";
if ($DB) {echo "|$stmt|\n";}
$rslt=mysql_query($stmt, $link);
$row=mysql_fetch_row($rslt);
$auth=$row[0];

if( (strlen($user)<2) or (strlen($pass)<2) or (!$auth))
{
echo "Invalid Username/Password: |$user|$pass|\n";
exit;
}
else
{

if( ( (strlen($server_ip)<6) or (!$server_ip) ) or ( (strlen($session_name)<12) or (!$session_name) ) )
	{
	echo "Invalid server_ip: |$server_ip|  or  Invalid session_name: |$session_name|\n";
	exit;
	}
else
	{
	$stmt="SELECT count(*) from web_client_sessions where session_name='$session_name' and server_ip='$server_ip';";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$SNauth=$row[0];
	  if(!$SNauth)
		{
		echo "Invalid session_name: |$session_name|$server_ip|\n";
		exit;
		}
	  else
		{
		# do nothing for now
		}
	}
}

if ($format=='debug')
{
echo "<html>\n";
echo "<head>\n";
echo "<!-- VERSION: $version     BUILD: $build    USER: $user   server_ip: $server_ip-->\n";
echo "<title>VICIDiaL Database Query Script";
echo "</title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
}


################################################################################
### regCLOSER - update the vicidial_live_agents table to reflect the closer
###             inbound choices made upon login
################################################################################
if ($ACTION == 'regCLOSER')
{
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($closer_choice)<1) || (strlen($user)<1) )
	{
	$channel_live=0;
	echo "Group Choice $closer_choice is not valid\n";
	exit;
	}
	else
	{
	$stmt="UPDATE vicidial_live_agents set closer_campaigns='$closer_choice' where user='$user' and server_ip='$server_ip';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	}
	echo "Closer In Group Choice $closer_choice has been registered to user $user\n";
}


################################################################################
### manDiaLnextCALL - for manual VICIDiaL dialing this will grab the next lead
###                   in the campaign, reserve it, send data back to client and
###                   place the call by inserting into vicidial_manager
################################################################################
if ($ACTION == 'manDiaLnextCaLL')
{
	$MT[0]='';
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($conf_exten)<1) || (strlen($campaign)<1)  || (strlen($ext_context)<1) )
	{
	$channel_live=0;
	echo "HOPPER EMPTY\n";
	echo "Conf Exten $conf_exten or campaign $campaign or ext_context $ext_context is not valid\n";
	exit;
	}
	else
	{
	### grab the next lead in the hopper for this campaign and reserve it for the user
	$stmt = "UPDATE vicidial_hopper set status='QUEUE', user='$user' where campaign_id='$campaign' and status='READY' order by hopper_id LIMIT 1";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$affected_rows = mysql_affected_rows($link);

	if ($affected_rows > 0)
		{
			##### grab the lead_id of the reserved user in vicidial_hopper
			$stmt="SELECT lead_id FROM vicidial_hopper where campaign_id='$campaign' and status='QUEUE' and user='$user' LIMIT 1;";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$hopper_leadID_ct = mysql_num_rows($rslt);
			if ($hopper_leadID_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
				$lead_id =$row[0];
				}

			##### grab the data from vicidial_list for the lead_id
			$stmt="SELECT * FROM vicidial_list where lead_id='$lead_id' LIMIT 1;";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$list_lead_ct = mysql_num_rows($rslt);
			if ($list_lead_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
			#	$lead_id		= trim("$row[0]");
				$dispo			= trim("$row[3]");
				$tsr			= trim("$row[4]");
				$vendor_id		= trim("$row[5]");
				$list_id		= trim("$row[7]");
				$gmt_offset_now	= trim("$row[8]");
				$phone_code		= trim("$row[10]");
				$phone_number	= trim("$row[11]");
				$title			= trim("$row[12]");
				$first_name		= trim("$row[13]");
				$middle_initial	= trim("$row[14]");
				$last_name		= trim("$row[15]");
				$address1		= trim("$row[16]");
				$address2		= trim("$row[17]");
				$address3		= trim("$row[18]");
				$city			= trim("$row[19]");
				$state			= trim("$row[20]");
				$province		= trim("$row[21]");
				$postal_code	= trim("$row[22]");
				$country_code	= trim("$row[23]");
				$gender			= trim("$row[24]");
				$date_of_birth	= trim("$row[25]");
				$alt_phone		= trim("$row[26]");
				$email			= trim("$row[27]");
				$security		= trim("$row[28]");
				$comments		= trim("$row[29]");
				$called_count	= trim("$row[30]");
				}

			$called_count++;

			### flag the lead as called and change it's status to INCALL
			$stmt = "UPDATE vicidial_list set status='INCALL', called_since_last_reset='Y', called_count='$called_count',user='$user' where lead_id='$lead_id';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);

			### delete the lead from the hopper
			$stmt = "DELETE FROM vicidial_hopper where lead_id='$lead_id';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);

		
			### if preview dialing, do not send the call	
			if ( (strlen($preview)<1) || ($preview == 'NO') )
				{
				### prepare variables to place manual call from VICIDiaL
				$CCID_on=0;   $CCID='';
				$local_DEF = 'Local/';
				$local_AMP = '@';
				$Local_out_prefix = '9';
				$Local_dial_timeout = '60';
				if ($dial_timeout > 4) {$Local_dial_timeout = $dial_timeout;}
				$Local_dial_timeout = ($Local_dial_timeout * 1000);
				if (strlen($dial_prefix) > 0) {$Local_out_prefix = "$dial_prefix";}
				if (strlen($campaign_cid) > 6) {$CCID = "$campaign_cid";   $CCID_on++;}
				if (eregi("x",$dial_prefix)) {$Local_out_prefix = '';}

				$PADlead_id = sprintf("%09s", $lead_id);
					while (strlen($PADlead_id) > 9) {$PADlead_id = substr("$PADlead_id", 0, -1);}

				# Create unique calleridname to track the call: MmmddhhmmssLLLLLLLLL
					$MqueryCID = "M$CIDdate$PADlead_id";
				if ($CCID_on) {$CIDstring = "\"$MqueryCID\" <$CCID>";}
				else {$CIDstring = "$MqueryCID";}

				### insert the call action into the vicidial_manager table to initiate the call
				#	$stmt = "INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$MqueryCID','Exten: $conf_exten','Context: $ext_context','Channel: $local_DEF$Local_out_prefix$phone_code$phone_number$local_AMP$ext_context','Priority: 1','Callerid: $CIDstring','Timeout: $Local_dial_timeout','','','','');";
				$stmt = "INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$MqueryCID','Exten: $Local_out_prefix$phone_code$phone_number','Context: $ext_context','Channel: $local_DEF$conf_exten$local_AMP$ext_context','Priority: 1','Callerid: $CIDstring','Timeout: $Local_dial_timeout','','','','');";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				}

			$comments = eregi_replace("\r",'',$comments);
			$comments = eregi_replace("\n",'!N',$comments);
			echo "$MqueryCID\n";
			echo "$lead_id\n";
			echo "$dispo\n";
			echo "$tsr\n";
			echo "$vendor_id\n";
			echo "$list_id\n";
			echo "$gmt_offset_now\n";
			echo "$phone_code\n";
			echo "$phone_number\n";
			echo "$title\n";
			echo "$first_name\n";
			echo "$middle_initial\n";
			echo "$last_name\n";
			echo "$address1\n";
			echo "$address2\n";
			echo "$address3\n";
			echo "$city\n";
			echo "$state\n";
			echo "$province\n";
			echo "$postal_code\n";
			echo "$country_code\n";
			echo "$gender\n";
			echo "$date_of_birth\n";
			echo "$alt_phone\n";
			echo "$email\n";
			echo "$security\n";
			echo "$comments\n";
			echo "$called_count\n";

		}
		else
		{
		echo "HOPPER EMPTY\n";
		}
	}
}


################################################################################
### manDiaLskip - for manual VICIDiaL dialing this skips the lead that was
###               previewed in the step above and puts it back in orig status
################################################################################
if ($ACTION == 'manDiaLskip')
{
	$MT[0]='';
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($stage)<1) || (strlen($called_count)<1) || (strlen($lead_id)<1) )
	{
		$channel_live=0;
		echo "LEAD NOT REVERTED\n";
		echo "Conf Exten $conf_exten or campaign $campaign or ext_context $ext_context is not valid\n";
		exit;
	}
	else
	{
		$called_count = ($called_count - 1);
		### flag the lead as called and change it's status to INCALL
		$stmt = "UPDATE vicidial_list set status='$stage', called_count='$called_count',user='$user' where lead_id='$lead_id';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);


		echo "LEAD REVERTED\n";
	}
}


################################################################################
### manDiaLonly - for manual VICIDiaL dialing this sends the call that was
###               previewed in the step above
################################################################################
if ($ACTION == 'manDiaLonly')
{
	$MT[0]='';
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($conf_exten)<1) || (strlen($campaign)<1) || (strlen($ext_context)<1) || (strlen($phone_number)<1) || (strlen($lead_id)<1) )
	{
		$channel_live=0;
		echo "CALL NOT PLACED\n";
		echo "Conf Exten $conf_exten or campaign $campaign or ext_context $ext_context is not valid\n";
		exit;
	}
	else
	{
		### prepare variables to place manual call from VICIDiaL
		$CCID_on=0;   $CCID='';
		$local_DEF = 'Local/';
		$local_AMP = '@';
		$Local_out_prefix = '9';
		$Local_dial_timeout = '60';
		if ($dial_timeout > 4) {$Local_dial_timeout = $dial_timeout;}
		$Local_dial_timeout = ($Local_dial_timeout * 1000);
		if (strlen($dial_prefix) > 0) {$Local_out_prefix = "$dial_prefix";}
		if (strlen($campaign_cid) > 6) {$CCID = "$campaign_cid";   $CCID_on++;}
		if (eregi("x",$dial_prefix)) {$Local_out_prefix = '';}

		$PADlead_id = sprintf("%09s", $lead_id);
			while (strlen($PADlead_id) > 9) {$PADlead_id = substr("$PADlead_id", 0, -1);}

		# Create unique calleridname to track the call: MmmddhhmmssLLLLLLLLL
			$MqueryCID = "M$CIDdate$PADlead_id";
		if ($CCID_on) {$CIDstring = "\"$MqueryCID\" <$CCID>";}
		else {$CIDstring = "$MqueryCID";}

		### insert the call action into the vicidial_manager table to initiate the call
		#	$stmt = "INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$MqueryCID','Exten: $conf_exten','Context: $ext_context','Channel: $local_DEF$Local_out_prefix$phone_code$phone_number$local_AMP$ext_context','Priority: 1','Callerid: $CIDstring','Timeout: $Local_dial_timeout','','','','');";
		$stmt = "INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Originate','$MqueryCID','Exten: $Local_out_prefix$phone_code$phone_number','Context: $ext_context','Channel: $local_DEF$conf_exten$local_AMP$ext_context','Priority: 1','Callerid: $CIDstring','Timeout: $Local_dial_timeout','','','','');";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);

		echo "$MqueryCID\n";
	}
}


################################################################################
### manDiaLlookCALL - for manual VICIDiaL dialing this will attempt to look up
###                   the trunk channel that the call was placed on
################################################################################
if ($ACTION == 'manDiaLlookCaLL')
{
	$MT[0]='';
	$row='';   $rowx='';
if (strlen($MDnextCID)<18)
	{
	echo "NO\n";
	echo "MDnextCID $MDnextCID is not valid\n";
	exit;
	}
else
	{
	##### look for the channel in the UPDATED vicidial_manager record of the call initiation
	$stmt="SELECT uniqueid,channel FROM vicidial_manager where callerid='$MDnextCID' and server_ip='$server_ip' and status='UPDATED' LIMIT 1;";
	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}
	$VM_mancall_ct = mysql_num_rows($rslt);
	if ($VM_mancall_ct > 0)
		{
		$row=mysql_fetch_row($rslt);
		$uniqueid =$row[0];
		$channel =$row[1];
		echo "$uniqueid\n$channel";

		$wait_sec=0;
		$stmt = "select wait_epoch,wait_sec from vicidial_agent_log where agent_log_id='$agent_log_id';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$VDpr_ct = mysql_num_rows($rslt);
		if ($VDpr_ct > 0)
			{
			$row=mysql_fetch_row($rslt);
			$wait_sec = (($StarTtime - $row[0]) + $row[1]);
			}
		$stmt="UPDATE vicidial_agent_log set wait_sec='$wait_sec',wait_epoch='$StarTtime',talk_epoch='$StarTtime',lead_id='$lead_id' where agent_log_id='$agent_log_id';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		}
	else
		{
		echo "NO\n";
		}
	}
}



################################################################################
### manDiaLlogCALL - for manual VICIDiaL logging of calls places record in
###                  vicidial_log and then sends process to call_log entry
################################################################################
if ($ACTION == 'manDiaLlogCaLL')
{
	$MT[0]='';
	$row='';   $rowx='';

if ($stage == "start")
	{
	if ( (strlen($uniqueid)<1) || (strlen($lead_id)<1) || (strlen($list_id)<1) || (strlen($phone_number)<1) || (strlen($campaign)<1) )
		{
		echo "LOG NOT ENTERED\n";
		echo "uniqueid $uniqueid or lead_id: $lead_id or list_id: $list_id or phone_number: $phone_number or campaign: $campaign is not valid\n";
		exit;
		}
	else
		{
		##### insert log into vicidial_log for manual VICIDiaL call
		$stmt="INSERT INTO vicidial_log (uniqueid,lead_id,list_id,campaign_id,call_date,start_epoch,status,phone_code,phone_number,user,comments,processed) values('$uniqueid','$lead_id','$list_id','$campaign','$NOW_TIME','$StarTtime','INCALL','$phone_code','$phone_number','$user','MANUAL','N');";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);

		if ($affected_rows > 0)
			{
			echo "VICIDiaL_LOG Inserted: $uniqueid|$channel|$NOW_TIME\n";
			echo "$StarTtime\n";
			}
		else
			{
			echo "LOG NOT ENTERED\n";
			}

	#	##### insert log into call_log for manual VICIDiaL call
	#	$stmt = "INSERT INTO call_log (uniqueid,channel,server_ip,extension,number_dialed,caller_code,start_time,start_epoch) values('$uniqueid','$channel','$server_ip','$exten','$phone_code$phone_number','MD $user $lead_id','$NOW_TIME','$StarTtime')";
	#	if ($DB) {echo "$stmt\n";}
	#	$rslt=mysql_query($stmt, $link);
	#	$affected_rows = mysql_affected_rows($link);

	#	if ($affected_rows > 0)
	#		{
	#		echo "CALL_LOG Inserted: $uniqueid|$channel|$NOW_TIME";
	#		}
	#	else
	#		{
	#		echo "LOG NOT ENTERED\n";
	#		}
		}
	}

if ($stage == "end")
	{
	if ( (strlen($uniqueid)<1) || (strlen($lead_id)<1) )
		{
		echo "LOG NOT ENTERED\n";
		echo "uniqueid $uniqueid or lead_id: $lead_id is not valid\n";
		exit;
		}
	else
		{
		if ($start_epoch < 1000)
			{
			if (eregi("CLOSER",$campaign))
				{
				##### look for the channel in the UPDATED vicidial_manager record of the call initiation
				$stmt="SELECT start_epoch FROM vicidial_closer_log where phone_number='$phone_number' and lead_id='$lead_id' and user='$user';";
				}
			else
				{
				##### look for the channel in the UPDATED vicidial_manager record of the call initiation
				$stmt="SELECT start_epoch FROM vicidial_log where uniqueid='$uniqueid' and lead_id='$lead_id';";
				}
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$VM_mancall_ct = mysql_num_rows($rslt);
			if ($VM_mancall_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
				$start_epoch =$row[0];
				$length_in_sec = ($StarTtime - $start_epoch);
				}
			else
				{
				$length_in_sec = 0;
				}
			}
		else {$length_in_sec = ($StarTtime - $start_epoch);}
		
		if (eregi("CLOSER",$campaign))
			{
			$stmt = "UPDATE vicidial_closer_log set end_epoch='$StarTtime', length_in_sec='$length_in_sec',status='DONE' where lead_id='$lead_id' order by start_epoch desc limit 1;";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			}
		if ($auto_dial_level > 0)
			{
			### delete call record from  vicidial_auto_calls
			$stmt = "DELETE from vicidial_auto_calls where uniqueid='$uniqueid';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);

			$stmt = "UPDATE vicidial_live_agents set status='PAUSED',lead_id='',uniqueid=0,callerid='',channel='',last_call_finish='$NOW_TIME' where user='$user' and server_ip='$server_ip';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			}

		##### look for the channel in the UPDATED vicidial_manager record of the call initiation
		$stmt="UPDATE vicidial_log set end_epoch='$StarTtime', length_in_sec='$length_in_sec' where uniqueid='$uniqueid' and lead_id='$lead_id';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);

		if ($affected_rows > 0)
			{
			echo "$uniqueid\n$channel\n";
			}
		else
			{
			echo "LOG NOT ENTERED\n\n";
			}
		}

	echo "$VDstop_rec_after_each_call|$extension|$conf_silent_prefix|$conf_exten|$user_abb|\n";

	##### if VICIDiaL call and hangup_after_each_call activated, find all recording 
	##### channels and hang them up while entering info into recording_log and 
	##### returning filename/recordingID
	if ($VDstop_rec_after_each_call == 1)
		{
		$local_DEF = 'Local/';
		$local_AMP = '@';
		$total_rec=0;
		$loop_count=0;
		$stmt="SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and extension = '$conf_exten' order by channel desc;";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		if ($rslt) {$rec_list = mysql_num_rows($rslt);}
			while ($rec_list>$loop_count)
			{
			$row=mysql_fetch_row($rslt);
			if (preg_match("/Local\/$conf_silent_prefix$conf_exten\@/i",$row[0]))
				{
				$rec_channels[$total_rec] = "$row[0]";
				$total_rec++;
				}
			if ($format=='debug') {echo "\n<!-- $row[0] -->";}
			$loop_count++; 
			}

		$total_recFN=0;
		$loop_count=0;
		$filename=$MT;		# not necessary : and cmd_line_f LIKE \"%_$user_abb\"
		$stmt="SELECT cmd_line_f FROM vicidial_manager where server_ip='$server_ip' and action='Originate' and cmd_line_b = 'Channel: $local_DEF$conf_silent_prefix$conf_exten$local_AMP$ext_context' order by entry_date desc limit $total_rec;";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		if ($rslt) {$recFN_list = mysql_num_rows($rslt);}
			while ($recFN_list>$loop_count)
			{
			$row=mysql_fetch_row($rslt);
			$filename[$total_recFN] = preg_replace("/Callerid: /i","",$row[0]);
			if ($format=='debug') {echo "\n<!-- $row[0] -->";}
			$total_recFN++;
			$loop_count++; 
			}

		$loop_count=0;
		while($loop_count < $total_rec)
			{
			if (strlen($rec_channels[$loop_count])>5)
				{
				$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Hangup','RH12345$StarTtime$loop_count','Channel: $rec_channels[$loop_count]','','','','','','','','','');";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);

				echo "REC_STOP|$rec_channels[$loop_count]|$filename[$loop_count]|";
				if (strlen($filename)>2)
					{
					$stmt="SELECT recording_id,start_epoch FROM recording_log where filename='$filename[$loop_count]'";
						if ($format=='debug') {echo "\n<!-- $stmt -->";}
					$rslt=mysql_query($stmt, $link);
					if ($rslt) {$fn_count = mysql_num_rows($rslt);}
					if ($fn_count)
						{
						$row=mysql_fetch_row($rslt);
						$recording_id = $row[0];
						$start_time = $row[1];

						$length_in_sec = ($StarTtime - $start_time);
						$length_in_min = ($length_in_sec / 60);
						$length_in_min = sprintf("%8.2f", $length_in_min);

						$stmt="UPDATE recording_log set end_time='$NOW_TIME',end_epoch='$StarTtime',length_in_sec=$length_in_sec,length_in_min='$length_in_min' where filename='$filename[$loop_count]' and end_epoch is NULL;";
							if ($format=='debug') {echo "\n<!-- $stmt -->";}
						$rslt=mysql_query($stmt, $link);

						echo "$recording_id|$length_in_min|";
						}
					else {echo "||";}
					}
				else {echo "||";}
				echo "\n";
				}
			$loop_count++;
			}
		}


	$talk_sec=0;
	$StarTtime = date("U");
	$stmt = "select talk_epoch,talk_sec from vicidial_agent_log where agent_log_id='$agent_log_id';";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$VDpr_ct = mysql_num_rows($rslt);
	if ($VDpr_ct > 0)
		{
		$row=mysql_fetch_row($rslt);
		$talk_sec = (($StarTtime - $row[0]) + $row[1]);
		}
	$stmt="UPDATE vicidial_agent_log set talk_sec='$talk_sec',talk_epoch='$StarTtime',dispo_epoch='$StarTtime' where agent_log_id='$agent_log_id';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);

	}
}


################################################################################
### VDADcheckINCOMING - for auto-dial VICIDiaL dialing this will check for calls
###                     in the vicidial_live_agents table in QUEUE status, then
###                     lookup the lead info and pass it back to vicidial.php
################################################################################
if ($ACTION == 'VDADcheckINCOMING')
{
	$MT[0]='';
	$row='';   $rowx='';
	$channel_live=1;
	if ( (strlen($campaign)<1) || (strlen($server_ip)<1) )
	{
	$channel_live=0;
	echo "0\n";
	echo "Campaign $campaign is not valid\n";
	exit;
	}
	else
	{
	### grab the next lead in the hopper for this campaign and reserve it for the user
	$stmt = "SELECT lead_id,uniqueid,callerid,channel FROM vicidial_live_agents where server_ip = '$server_ip' and user='$user' and campaign_id='$campaign' and status='QUEUE';";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$queue_leadID_ct = mysql_num_rows($rslt);

	if ($queue_leadID_ct > 0)
		{
		$row=mysql_fetch_row($rslt);
		$lead_id	=$row[0];
		$uniqueid	=$row[1];
		$callerid	=$row[2];
		$channel	=$row[3];
		echo "1\n";
		echo "$lead_id|$uniqueid|$callerid|$channel|\n";

		### update the agent status to INCALL in vicidial_live_agents
		$stmt = "UPDATE vicidial_live_agents set status='INCALL',last_call_time='$NOW_TIME' where user='$user' and server_ip='$server_ip';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);

		##### grab the data from vicidial_list for the lead_id
		$stmt="SELECT * FROM vicidial_list where lead_id='$lead_id' LIMIT 1;";
		$rslt=mysql_query($stmt, $link);
		if ($DB) {echo "$stmt\n";}
		$list_lead_ct = mysql_num_rows($rslt);
		if ($list_lead_ct > 0)
			{
			$row=mysql_fetch_row($rslt);
		#	$lead_id		= trim("$row[0]");
			$dispo			= trim("$row[3]");
			$tsr			= trim("$row[4]");
			$vendor_id		= trim("$row[5]");
			$list_id		= trim("$row[7]");
			$gmt_offset_now	= trim("$row[8]");
			$phone_code		= trim("$row[10]");
			$phone_number	= trim("$row[11]");
			$title			= trim("$row[12]");
			$first_name		= trim("$row[13]");
			$middle_initial	= trim("$row[14]");
			$last_name		= trim("$row[15]");
			$address1		= trim("$row[16]");
			$address2		= trim("$row[17]");
			$address3		= trim("$row[18]");
			$city			= trim("$row[19]");
			$state			= trim("$row[20]");
			$province		= trim("$row[21]");
			$postal_code	= trim("$row[22]");
			$country_code	= trim("$row[23]");
			$gender			= trim("$row[24]");
			$date_of_birth	= trim("$row[25]");
			$alt_phone		= trim("$row[26]");
			$email			= trim("$row[27]");
			$security		= trim("$row[28]");
			$comments		= trim("$row[29]");
			$called_count	= trim("$row[30]");
			}

		### update the lead status to INCALL
		$stmt = "UPDATE vicidial_list set status='INCALL', user='$user' where lead_id='$lead_id';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);

		### update the log status to INCALL
		$stmt = "UPDATE vicidial_log set user='$user', comments='AUTO', list_id='$list_id', status='INCALL' where lead_id='$lead_id' and uniqueid='$uniqueid';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);

		if (eregi("CLOSER",$campaign))
			{
			### update the vicidial_closer_log user to INCALL
			$stmt = "UPDATE vicidial_closer_log set user='$user', comments='AUTO', list_id='$list_id', status='INCALL' where lead_id='$lead_id' order by closecallid desc limit 1;";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);

			$stmt = "select campaign_id from vicidial_auto_calls where callerid = '$callerid' order by call_time desc limit 1;";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$VDAC_cid_ct = mysql_num_rows($rslt);
			if ($list_lead_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
				$VDADchannel_group	=$row[0];
				}

			$stmt = "select count(*) from vicidial_log where lead_id='$lead_id' and uniqueid='$uniqueid';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$VDL_cid_ct = mysql_num_rows($rslt);
			if ($VDL_cid_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
				$VDCL_front_VDlog	=$row[0];
				}

			$stmt = "select * from vicidial_inbound_groups where group_id='$VDADchannel_group';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$VDIG_cid_ct = mysql_num_rows($rslt);
			if ($VDIG_cid_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
				$VDCL_group_name		= $row[1];
				$VDCL_group_color		= $row[2];
				$VDCL_group_web			= $row[4];
				$VDCL_fronter_display	= $row[7];
				}
			### if web form is set then send on to vicidial.php for override of WEB_FORM address
			if (strlen($VDCL_group_web)>5) {echo "$VDCL_group_web|$VDCL_group_name|$VDCL_group_color|$VDCL_fronter_display|$VDADchannel_group|\n";}
			else {echo "|$VDCL_group_name|$VDCL_group_color|$VDCL_fronter_display|$VDADchannel_group|\n";}

			$stmt = "SELECT full_name from vicidial_users where user='$tsr';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$VDU_cid_ct = mysql_num_rows($rslt);
			if ($VDU_cid_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
				$fronter_full_name		= $row[0];
				echo "$fronter_full_name|$tsr\n";
				}
			else {echo "|$tsr\n";}
			}
		else {echo "||||\n|\n";}

		$comments = eregi_replace("\r",'',$comments);
		$comments = eregi_replace("\n",'!N',$comments);
		echo "$callerid\n";
		echo "$lead_id\n";
		echo "$dispo\n";
		echo "$tsr\n";
		echo "$vendor_id\n";
		echo "$list_id\n";
		echo "$gmt_offset_now\n";
		echo "$phone_code\n";
		echo "$phone_number\n";
		echo "$title\n";
		echo "$first_name\n";
		echo "$middle_initial\n";
		echo "$last_name\n";
		echo "$address1\n";
		echo "$address2\n";
		echo "$address3\n";
		echo "$city\n";
		echo "$state\n";
		echo "$province\n";
		echo "$postal_code\n";
		echo "$country_code\n";
		echo "$gender\n";
		echo "$date_of_birth\n";
		echo "$alt_phone\n";
		echo "$email\n";
		echo "$security\n";
		echo "$comments\n";
		echo "$called_count\n";


		$wait_sec=0;
		$StarTtime = date("U");
		$stmt = "select wait_epoch,wait_sec from vicidial_agent_log where agent_log_id='$agent_log_id';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$VDpr_ct = mysql_num_rows($rslt);
		if ($VDpr_ct > 0)
			{
			$row=mysql_fetch_row($rslt);
			$wait_sec = (($StarTtime - $row[0]) + $row[1]);
			}
		$stmt="UPDATE vicidial_agent_log set wait_sec='$wait_sec',talk_epoch='$StarTtime',lead_id='$lead_id' where agent_log_id='$agent_log_id';";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		}
		else
		{
		echo "0\n";
	#	echo "No calls in QUEUE for $user on $server_ip\n";
		exit;
		}
	}
}


################################################################################
### userLOGout - Logs the user out of VICIDiaL client, deleting db records and 
###              inserting into vicidial_user_log
################################################################################
if ($ACTION == 'userLOGout')
{
	$MT[0]='';
	$row='';   $rowx='';
if ( (strlen($campaign)<1) || (strlen($conf_exten)<1) )
	{
	echo "NO\n";
	echo "campaign $campaign or conf_exten $conf_exten is not valid\n";
	exit;
	}
else
	{
	##### Insert a LOGOUT record into the user log
	$stmt="INSERT INTO vicidial_user_log values('','$user','LOGOUT','$campaign','$NOW_TIME','$StarTtime');";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$vul_insert = mysql_affected_rows($link);

	##### Remove the reservation on the vicidial_conferences meetme room
	$stmt="UPDATE vicidial_conferences set extension='' where server_ip='$server_ip' and conf_exten='$session_id';";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$vc_remove = mysql_affected_rows($link);

	##### Delete the vicidial_live_agents record for this session
	$stmt="DELETE from vicidial_live_agents where server_ip='$server_ip' and user ='$user';";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$vla_delete = mysql_affected_rows($link);

	##### Delete the web_client_sessions
	$stmt="DELETE from web_client_sessions where server_ip='$server_ip' and session_name ='$session_name';";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$wcs_delete = mysql_affected_rows($link);

	##### Hangup the client phone
	$stmt="SELECT channel FROM live_sip_channels where server_ip = '$server_ip' and channel LIKE \"$protocol/$extension%\" order by channel desc;";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) 
		{
		$row=mysql_fetch_row($rslt);
		$agent_channel = "$row[0]";
		if ($format=='debug') {echo "\n<!-- $row[0] -->";}
		$stmt="INSERT INTO vicidial_manager values('','','$NOW_TIME','NEW','N','$server_ip','','Hangup','RH123459$StarTtime','Channel: $agent_channel','','','','','','','','','');";
			if ($format=='debug') {echo "\n<!-- $stmt -->";}
		$rslt=mysql_query($stmt, $link);
		}

	echo "$vul_insert|$vc_remove|$vla_delete|$wcs_delete|$agent_channel\n";
	}
}


################################################################################
### updateDISPO - update the vicidial_list table to reflect the agent choice of
###               call disposition for that leand
################################################################################
if ($ACTION == 'updateDISPO')
{
	$MT[0]='';
	$row='';   $rowx='';
	if ( (strlen($dispo_choice)<1) || (strlen($lead_id)<1) )
	{
	echo "Dispo Choice $dispo or lead_id $lead_id is not valid\n";
	exit;
	}
	else
	{
	$stmt="UPDATE vicidial_list set status='$dispo_choice', user='$user' where lead_id='$lead_id';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);

	$stmt="UPDATE vicidial_log set status='$dispo_choice' where lead_id='$lead_id' and user='$user' order by uniqueid desc limit 1;";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	}

	$dispo_sec=0;
	$StarTtime = date("U");
	$stmt = "select dispo_epoch,dispo_sec from vicidial_agent_log where agent_log_id='$agent_log_id';";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$VDpr_ct = mysql_num_rows($rslt);
	if ($VDpr_ct > 0)
		{
		$row=mysql_fetch_row($rslt);
		$dispo_sec = (($StarTtime - $row[0]) + $row[1]);
		}
	$stmt="UPDATE vicidial_agent_log set dispo_sec='$dispo_sec',dispo_epoch='$StarTtime',status='$dispo_choice' where agent_log_id='$agent_log_id';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);

	$stmt="INSERT INTO vicidial_agent_log (user,server_ip,event_time,campaign_id,pause_epoch,pause_sec,wait_epoch) values('$user','$server_ip','$NOW_TIME','$campaign','$StarTtime','0','$StarTtime');";
	if ($DB) {echo "$stmt\n";}
	$rslt=mysql_query($stmt, $link);
	$affected_rows = mysql_affected_rows($link);
	$agent_log_id = mysql_insert_id();

	echo "Lead $lead_id has been changed to $dispo_choice Status\n";
	echo "Next agent_log_id:\n";
	echo "$agent_log_id\n";
}


################################################################################
### updateLEAD - update the vicidial_list table to reflect the values that are
###              in the agents screen at time of call hangup
################################################################################
if ($ACTION == 'updateLEAD')
{
	$MT[0]='';
	$row='';   $rowx='';
	if ( (strlen($phone_number)<1) || (strlen($lead_id)<1) )
	{
	echo "phone_number $phone_number or lead_id $lead_id is not valid\n";
	exit;
	}
	else
	{
	$comments = eregi_replace("\r",'',$comments);
	$comments = eregi_replace("\n",'!N',$comments);

	$stmt="UPDATE vicidial_list set vendor_lead_code='$vendor_lead_code', title='$title', first_name='$first_name', middle_initial='$middle_initial', last_name='$last_name', address1='$address1', address2='$address2', address3='$address3', city='$city', state='$state', province='$province', postal_code='$postal_code', country_code='$country_code', gender='$gender', date_of_birth='$date_of_birth', alt_phone='$alt_phone', email='$email', security_phrase='$security_phrase', comments='$comments' where lead_id='$lead_id';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);

	$random = (rand(1000000, 9999999) + 10000000);
	$stmt="UPDATE vicidial_live_agents set random_id='$random' where user='$user' and server_ip='$server_ip';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);

	}
	echo "Lead $lead_id information has been updated\n";
}


################################################################################
### VDADpause - update the vicidial_live_agents table to show that the agent is
###  or ready   now active and ready to take calls
################################################################################
if ( ($ACTION == 'VDADpause') || ($ACTION == 'VDADready') )
{
	$MT[0]='';
	$row='';   $rowx='';
	if ( (strlen($stage)<2) || (strlen($server_ip)<1) )
	{
	echo "stage $stage is not valid\n";
	exit;
	}
	else
	{
	$random = (rand(1000000, 9999999) + 10000000);
	$stmt="UPDATE vicidial_live_agents set status='$stage',lead_id='',uniqueid=0,callerid='',channel='', random_id='$random' where user='$user' and server_ip='$server_ip';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);

	if ($agent_log == 'NO')
		{$donothing=1;}
	else
		{
		$pause_sec=0;
		$stmt = "select pause_epoch,pause_sec from vicidial_agent_log where agent_log_id='$agent_log_id';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$VDpr_ct = mysql_num_rows($rslt);
		if ($VDpr_ct > 0)
			{
			$row=mysql_fetch_row($rslt);
			$pause_sec = (($StarTtime - $row[0]) + $row[1]);
			}
		if ($ACTION == 'VDADready')
			{
			$stmt="UPDATE vicidial_agent_log set pause_sec='$pause_sec',wait_epoch='$StarTtime' where agent_log_id='$agent_log_id';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			}
		if ($ACTION == 'VDADpause')
			{
			$stmt="UPDATE vicidial_agent_log set pause_sec='$pause_sec',pause_epoch='$StarTtime' where agent_log_id='$agent_log_id';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			}
		}
	}
	echo "Agent $user is now in status $stage\n";
}


if ($format=='debug') 
{
$ENDtime = date("U");
$RUNtime = ($ENDtime - $StarTtime);
echo "\n<!-- script runtime: $RUNtime seconds -->";
echo "\n</body>\n</html>\n";
}
	
exit; 

?>
