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
###  - $ACTION - ('regCLOSER','manDIALnextCALL','manDIALlookCALL','manDIALlogCALL','userLOGOUT','updateDISPO')
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
###

# changes
# 50629-1044 First build of script
# 50630-1422 Added manual dial action and MD channel lookup
# 50701-1451 Added dial log for start and end of vicidial calls
# 50705-1239 Added call disposition update
# 50804-1627 Fixed updateDispo to update vicidial_log entry
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


# default optional vars if not set
if (!$format)	{$format="text";}
if ($format == 'debug')	{$DB=1;}
if (!$ACTION)	{$ACTION="refresh";}

$version = '0.0.5';
$build = '50804-1627';
$STARTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$CIDdate = date("mdHis");
if (!$query_date) {$query_date = $NOW_DATE;}

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
echo "<title>VICIDIAL Database Query Script";
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
	$MT[0]='';
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
### manDIALnextCALL - for manual VICIDIAL dialing this will grab the next lead
###                   in the campaign, reserve it, send data back to client and
###                   place the call by inserting into vicidial_manager
################################################################################
if ($ACTION == 'manDIALnextCALL')
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

			
			### prepare variables to place manual call from VICIDIAL
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
### manDIALlookCALL - for manual VICIDIAL dialing this will attempt to look up
###                   the trunk channel that the call was placed on
################################################################################
if ($ACTION == 'manDIALlookCALL')
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
		}
	else
		{
		echo "NO\n";
		}
	}
}



################################################################################
### manDIALlogCALL - for manual VICIDIAL logging of calls places record in
###                  vicidial_log and then sends process to call_log entry
################################################################################
if ($ACTION == 'manDIALlogCALL')
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
		##### insert log into vicidial_log for manual VICIDIAL call
		$stmt="INSERT INTO vicidial_log (uniqueid,lead_id,list_id,campaign_id,call_date,start_epoch,status,phone_code,phone_number,user,comments,processed) values('$uniqueid','$lead_id','$list_id','$campaign','$NOW_TIME','$STARTtime','INCALL','$phone_code','$phone_number','$user','MANUAL','N');";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);

		if ($affected_rows > 0)
			{
			echo "VICIDIAL_LOG Inserted: $uniqueid|$channel|$NOW_TIME\n";
			echo "$STARTtime\n";
			}
		else
			{
			echo "LOG NOT ENTERED\n";
			}

	#	##### insert log into call_log for manual VICIDIAL call
	#	$stmt = "INSERT INTO call_log (uniqueid,channel,server_ip,extension,number_dialed,caller_code,start_time,start_epoch) values('$uniqueid','$channel','$server_ip','$exten','$phone_code$phone_number','MD $user $lead_id','$NOW_TIME','$STARTtime')";
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
			##### look for the channel in the UPDATED vicidial_manager record of the call initiation
			$stmt="SELECT start_epoch FROM vicidial_log where uniqueid='$uniqueid' and lead_id='$lead_id';";
			$rslt=mysql_query($stmt, $link);
			if ($DB) {echo "$stmt\n";}
			$VM_mancall_ct = mysql_num_rows($rslt);
			if ($VM_mancall_ct > 0)
				{
				$row=mysql_fetch_row($rslt);
				$start_epoch =$row[0];
				$length_in_sec = ($STARTtime - $start_epoch);
				}
			else
				{
				$length_in_sec = 0;
				}
			}
		else {$length_in_sec = ($STARTtime - $start_epoch);}
		
		##### look for the channel in the UPDATED vicidial_manager record of the call initiation
		$stmt="UPDATE vicidial_log set end_epoch='$STARTtime', length_in_sec='$length_in_sec' where uniqueid='$uniqueid' and lead_id='$lead_id';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$affected_rows = mysql_affected_rows($link);

		if ($affected_rows > 0)
			{
			echo "$uniqueid\n$channel";
			}
		else
			{
			echo "LOG NOT ENTERED\n";
			}
		}

	}
}


################################################################################
### userLOGOUT - Logs the user out of VICIDIAL client, deleting db records and 
###              inserting into vicidial_user_log
################################################################################
if ($ACTION == 'userLOGOUT')
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
	$stmt="INSERT INTO vicidial_user_log values('','$user','LOGOUT','$campaign','$NOW_TIME','$STARTtime');";
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

	echo "$vul_insert|$vc_remove|$vla_delete|$wcs_delete\n";
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
	echo "Lead $lead_id has been changed to $dispo_choice status\n";
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
	$stmt="UPDATE vicidial_list set vendor_lead_code='$vendor_lead_code', title='$title', first_name='$first_name', middle_initial='$middle_initial', last_name='$last_name', address1='$address1', address2='$address2', address3='$address3', city='$city', state='$state', province='$province', postal_code='$postal_code', country_code='$country_code', gender='$gender', date_of_birth='$date_of_birth', alt_phone='$alt_phone', email='$email', security_phrase='$security_phrase', comments='$comments' where lead_id='$lead_id';";
		if ($format=='debug') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	}
	echo "Lead $lead_id information has been updated\n";
}


if ($format=='debug') 
{
$ENDtime = date("U");
$RUNtime = ($ENDtime - $STARTtime);
echo "\n<!-- script runtime: $RUNtime seconds -->";
echo "\n</body>\n</html>\n";
}
	
exit; 

?>
