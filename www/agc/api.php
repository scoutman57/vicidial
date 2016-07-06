<?php
# api.php
# 
# Copyright (C) 2009  Matt Florell <vicidial@gmail.com>    LICENSE: AGPLv2
#
# This script is designed as an API(Application Programming Interface) to allow
# other programs to interact with the VICIDIAL Agent screen
# 
# required variables:
#  - $user
#  - $pass
#  - $agent_user
#  - $function - ('external_hangup','external_status','external_pause','external_dial','change_ingroups')
#  - $value
#  - $vendor_id
#  - $focus
#  - $preview
#  - $notes
#  - $phone_code
#  - $search
#  - $group_alias
#  - $dial_prefix
#  - $source - ('vtiger','webform','adminweb')
#  - $format - ('text','debug')
#  - $vtiger_callback - ('YES','NO')
#  - $blended - ('YES','NO')
#  - $ingroup_choices - (' TEST_IN SALESLINE -')
#  - $set_as_default - ('YES','NO')
#  - $alt_user

# CHANGELOG:
# 80703-2225 - First build of script
# 90116-1229 - Added external_pause and external_dial functions
# 90118-1051 - Added logging of API functions
# 90128-0229 - Added vendor_id to dial function
# 90303-0723 - Added group alias and dial prefix
# 90407-1920 - Added vtiger_callback option for external_dial function
# 90508-0727 - Changed to PHP long tags
# 90522-0506 - Security fix
# 91130-1307 - Added change_ingroups(Manager InGroup change feature)
# 91211-1805 - Added st_login_log and st_get_agent_active_lead functions, added alt_user
# 91228-1059 - Added update_fields function
#

$version = '2.2.0-11';
$build = '91228-1059';

require("dbconnect.php");

$query_string = getenv("QUERY_STRING");

### If you have globals turned off uncomment these lines
if (isset($_GET["user"]))						{$user=$_GET["user"];}
	elseif (isset($_POST["user"]))				{$user=$_POST["user"];}
if (isset($_GET["pass"]))						{$pass=$_GET["pass"];}
	elseif (isset($_POST["pass"]))				{$pass=$_POST["pass"];}
if (isset($_GET["agent_user"]))					{$agent_user=$_GET["agent_user"];}
	elseif (isset($_POST["agent_user"]))		{$agent_user=$_POST["agent_user"];}
if (isset($_GET["function"]))					{$function=$_GET["function"];}
	elseif (isset($_POST["function"]))			{$function=$_POST["function"];}
if (isset($_GET["value"]))						{$value=$_GET["value"];}
	elseif (isset($_POST["value"]))				{$value=$_POST["value"];}
if (isset($_GET["vendor_id"]))					{$vendor_id=$_GET["vendor_id"];}
	elseif (isset($_POST["vendor_id"]))			{$vendor_id=$_POST["vendor_id"];}
if (isset($_GET["focus"]))						{$focus=$_GET["focus"];}
	elseif (isset($_POST["focus"]))				{$focus=$_POST["focus"];}
if (isset($_GET["preview"]))					{$preview=$_GET["preview"];}
	elseif (isset($_POST["preview"]))			{$preview=$_POST["preview"];}
if (isset($_GET["notes"]))						{$notes=$_GET["notes"];}
	elseif (isset($_POST["notes"]))				{$notes=$_POST["notes"];}
if (isset($_GET["phone_code"]))					{$phone_code=$_GET["phone_code"];}
	elseif (isset($_POST["phone_code"]))		{$phone_code=$_POST["phone_code"];}
if (isset($_GET["search"]))						{$search=$_GET["search"];}
	elseif (isset($_POST["search"]))			{$search=$_POST["search"];}
if (isset($_GET["group_alias"]))				{$group_alias=$_GET["group_alias"];}
	elseif (isset($_POST["group_alias"]))		{$group_alias=$_POST["group_alias"];}
if (isset($_GET["dial_prefix"]))				{$dial_prefix=$_GET["dial_prefix"];}
	elseif (isset($_POST["dial_prefix"]))		{$dial_prefix=$_POST["dial_prefix"];}
if (isset($_GET["source"]))						{$source=$_GET["source"];}
	elseif (isset($_POST["source"]))			{$source=$_POST["source"];}
if (isset($_GET["format"]))						{$format=$_GET["format"];}
	elseif (isset($_POST["format"]))			{$format=$_POST["format"];}
if (isset($_GET["vtiger_callback"]))			{$vtiger_callback=$_GET["vtiger_callback"];}
	elseif (isset($_POST["vtiger_callback"]))	{$vtiger_callback=$_POST["vtiger_callback"];}
if (isset($_GET["blended"]))					{$blended=$_GET["blended"];}
	elseif (isset($_POST["blended"]))			{$blended=$_POST["blended"];}
if (isset($_GET["ingroup_choices"]))			{$ingroup_choices=$_GET["ingroup_choices"];}
	elseif (isset($_POST["ingroup_choices"]))	{$ingroup_choices=$_POST["ingroup_choices"];}
if (isset($_GET["set_as_default"]))				{$set_as_default=$_GET["set_as_default"];}
	elseif (isset($_POST["set_as_default"]))	{$set_as_default=$_POST["set_as_default"];}
if (isset($_GET["alt_user"]))					{$alt_user=$_GET["alt_user"];}
	elseif (isset($_POST["alt_user"]))			{$alt_user=$_POST["alt_user"];}
if (isset($_GET["lead_id"]))					{$lead_id=$_GET["lead_id"];}
	elseif (isset($_POST["lead_id"]))			{$lead_id=$_POST["lead_id"];}
if (isset($_GET["phone_number"]))				{$phone_number=$_GET["phone_number"];}
	elseif (isset($_POST["phone_number"]))		{$phone_number=$_POST["phone_number"];}
if (isset($_GET["vendor_lead_code"]))			{$vendor_lead_code=$_GET["vendor_lead_code"];}
	elseif (isset($_POST["vendor_lead_code"]))	{$vendor_lead_code=$_POST["vendor_lead_code"];}
if (isset($_GET["source_id"]))					{$source_id=$_GET["source_id"];}
	elseif (isset($_POST["source_id"]))			{$source_id=$_POST["source_id"];}
if (isset($_GET["gmt_offset_now"]))				{$gmt_offset_now=$_GET["gmt_offset_now"];}
	elseif (isset($_POST["gmt_offset_now"]))	{$gmt_offset_now=$_POST["gmt_offset_now"];}
if (isset($_GET["title"]))						{$title=$_GET["title"];}
	elseif (isset($_POST["title"]))				{$title=$_POST["title"];}
if (isset($_GET["first_name"]))					{$first_name=$_GET["first_name"];}
	elseif (isset($_POST["first_name"]))		{$first_name=$_POST["first_name"];}
if (isset($_GET["middle_initial"]))				{$middle_initial=$_GET["middle_initial"];}
	elseif (isset($_POST["middle_initial"]))	{$middle_initial=$_POST["middle_initial"];}
if (isset($_GET["last_name"]))					{$last_name=$_GET["last_name"];}
	elseif (isset($_POST["last_name"]))			{$last_name=$_POST["last_name"];}
if (isset($_GET["address1"]))					{$address1=$_GET["address1"];}
	elseif (isset($_POST["address1"]))			{$address1=$_POST["address1"];}
if (isset($_GET["address2"]))					{$address2=$_GET["address2"];}
	elseif (isset($_POST["address2"]))			{$address2=$_POST["address2"];}
if (isset($_GET["address3"]))					{$address3=$_GET["address3"];}
	elseif (isset($_POST["address3"]))			{$address3=$_POST["address3"];}
if (isset($_GET["city"]))						{$city=$_GET["city"];}
	elseif (isset($_POST["city"]))				{$city=$_POST["city"];}
if (isset($_GET["state"]))						{$state=$_GET["state"];}
	elseif (isset($_POST["state"]))				{$state=$_POST["state"];}
if (isset($_GET["province"]))					{$province=$_GET["province"];}
	elseif (isset($_POST["province"]))			{$province=$_POST["province"];}
if (isset($_GET["postal_code"]))				{$postal_code=$_GET["postal_code"];}
	elseif (isset($_POST["postal_code"]))		{$postal_code=$_POST["postal_code"];}
if (isset($_GET["country_code"]))				{$country_code=$_GET["country_code"];}
	elseif (isset($_POST["country_code"]))		{$country_code=$_POST["country_code"];}
if (isset($_GET["gender"]))						{$gender=$_GET["gender"];}
	elseif (isset($_POST["gender"]))			{$gender=$_POST["gender"];}
if (isset($_GET["date_of_birth"]))				{$date_of_birth=$_GET["date_of_birth"];}
	elseif (isset($_POST["date_of_birth"]))		{$date_of_birth=$_POST["date_of_birth"];}
if (isset($_GET["alt_phone"]))					{$alt_phone=$_GET["alt_phone"];}
	elseif (isset($_POST["alt_phone"]))			{$alt_phone=$_POST["alt_phone"];}
if (isset($_GET["email"]))						{$email=$_GET["email"];}
	elseif (isset($_POST["email"]))				{$email=$_POST["email"];}
if (isset($_GET["security_phrase"]))			{$security_phrase=$_GET["security_phrase"];}
	elseif (isset($_POST["security_phrase"]))	{$security_phrase=$_POST["security_phrase"];}
if (isset($_GET["comments"]))					{$comments=$_GET["comments"];}
	elseif (isset($_POST["comments"]))			{$comments=$_POST["comments"];}
if (isset($_GET["rank"]))						{$rank=$_GET["rank"];}
	elseif (isset($_POST["rank"]))				{$rank=$_POST["rank"];}
if (isset($_GET["owner"]))						{$owner=$_GET["owner"];}
	elseif (isset($_POST["owner"]))				{$owner=$_POST["owner"];}

header ("Content-type: text/html; charset=utf-8");
header ("Cache-Control: no-cache, must-revalidate");  // HTTP/1.1
header ("Pragma: no-cache");                          // HTTP/1.0

#############################################
##### START SYSTEM_SETTINGS LOOKUP #####
$stmt = "SELECT use_non_latin FROM system_settings;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$qm_conf_ct = mysql_num_rows($rslt);
if ($qm_conf_ct > 0)
	{
	$row=mysql_fetch_row($rslt);
	$non_latin =					$row[0];
	}
##### END SETTINGS LOOKUP #####
###########################################

$ingroup_choices = ereg_replace("\+"," ",$ingroup_choices);
$query_string = ereg_replace("'|\"|\\\\|;","",$query_string);

if ($non_latin < 1)
	{
	$user=ereg_replace("[^0-9a-zA-Z]","",$user);
	$pass=ereg_replace("[^0-9a-zA-Z]","",$pass);
	$agent_user=ereg_replace("[^0-9a-zA-Z]","",$agent_user);
	$function = ereg_replace("[^-\_0-9a-zA-Z]","",$function);
	$value = ereg_replace("[^-\_0-9a-zA-Z]","",$value);
	$vendor_id = ereg_replace("[^-\_0-9a-zA-Z]","",$vendor_id);
	$focus = ereg_replace("[^-\_0-9a-zA-Z]","",$focus);
	$preview = ereg_replace("[^-\_0-9a-zA-Z]","",$preview);
		$notes = ereg_replace("\+"," ",$notes);
	$notes = ereg_replace("[^ -\.\_0-9a-zA-Z]","",$notes);
	$phone_code = ereg_replace("[^0-9X]","",$phone_code);
	$search = ereg_replace("[^-\_0-9a-zA-Z]","",$search);
	$group_alias = ereg_replace("[^0-9a-zA-Z]","",$group_alias);
	$dial_prefix = ereg_replace("[^0-9a-zA-Z]","",$dial_prefix);
	$source = ereg_replace("[^0-9a-zA-Z]","",$source);
	$format = ereg_replace("[^0-9a-zA-Z]","",$format);
	$vtiger_callback = ereg_replace("[^A-Z]","",$vtiger_callback);
	$blended = ereg_replace("[^A-Z]","",$blended);
	$ingroup_choices = ereg_replace("[^ -\_0-9a-zA-Z]","",$ingroup_choices);
	$set_as_default = ereg_replace("[^A-Z]","",$set_as_default);
	$phone_number = ereg_replace("[^0-9]","",$phone_number);
	$address1 = ereg_replace("[^ -\_0-9a-zA-Z]","",$address1);
	$address2 = ereg_replace("[^ -\_0-9a-zA-Z]","",$address2);
	$address3 = ereg_replace("[^ -\_0-9a-zA-Z]","",$address3);
	$alt_phone = ereg_replace("[^ -\_0-9a-zA-Z]","",$alt_phone);
	$city = ereg_replace("[^ -\_0-9a-zA-Z]","",$city);
	$comments = ereg_replace("[^ -\_0-9a-zA-Z]","",$comments);
	$country_code = ereg_replace("[^A-Z]","",$country_code);
	$date_of_birth = ereg_replace("[^ -\_0-9]","",$date_of_birth);
	$email = ereg_replace("[^-\.\:\/\@\_0-9a-zA-Z]","",$email);
	$first_name = ereg_replace("[^ -\_0-9a-zA-Z]","",$first_name);
	$gender = ereg_replace("[^A-Z]","",$gender);
	$gmt_offset_now = ereg_replace("[^ \.-\_0-9]","",$gmt_offset_now);
	$last_name = ereg_replace("[^ -\_0-9a-zA-Z]","",$last_name);
	$lead_id = ereg_replace("[^0-9]","",$lead_id);
	$middle_initial = ereg_replace("[^ -\_0-9a-zA-Z]","",$middle_initial);
	$province = ereg_replace("[^ -\.\_0-9a-zA-Z]","",$province);
	$security_phrase = ereg_replace("[^ -\.\_0-9a-zA-Z]","",$security_phrase);
	$source_id = ereg_replace("[^ -\.\_0-9a-zA-Z]","",$source_id);
	$state = ereg_replace("[^ -\_0-9a-zA-Z]","",$state);
	$title = ereg_replace("[^ -\_0-9a-zA-Z]","",$title);
	$vendor_lead_code = ereg_replace("[^ -\.\_0-9a-zA-Z]","",$vendor_lead_code);
	$rank = ereg_replace("[^-0-9]","",$rank);
	$owner = ereg_replace("[^-\.\:\/\@\_0-9a-zA-Z]","",$owner);
	}
else
	{
	$user = ereg_replace("'|\"|\\\\|;","",$user);
	$pass = ereg_replace("'|\"|\\\\|;","",$pass);
	$source = ereg_replace("'|\"|\\\\|;","",$source);
	$agent_user = ereg_replace("'|\"|\\\\|;","",$agent_user);
	$alt_user = ereg_replace("'|\"|\\\\|;","",$alt_user);
	}

### date and fixed variables
$epoch = date("U");
$StarTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$CIDdate = date("mdHis");
$ENTRYdate = date("YmdHis");
$MT[0]='';
$api_script = 'agent';
$api_logging = 1;


################################################################################
### BEGIN - version - show version and date information for the API
################################################################################
if ($function == 'version')
	{
	$data = "VERSION: $version|BUILD: $build|DATE: $NOW_TIME|EPOCH: $StarTtime";
	$result = 'SUCCESS';
	echo "$data\n";
	api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
	exit;
	}
################################################################################
### END - version
################################################################################





################################################################################
### BEGIN - user validation section
################################################################################

if ($ACTION == 'LogiNCamPaigns')
	{
	$skip_user_validation=1;
	}
else
	{
	if(strlen($source)<2)
		{
		$result = 'ERROR';
		$result_reason = "Invalid Source";
		echo "$result: $result_reason - $source\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		$stmt="SELECT count(*) from vicidial_users where user='$user' and pass='$pass' and vdc_agent_api_access = '1';";
		if ($DB) {echo "|$stmt|\n";}
		if ($non_latin > 0) {$rslt=mysql_query("SET NAMES 'UTF8'");}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		$auth=$row[0];

		if( (strlen($user)<2) or (strlen($pass)<2) or ($auth==0))
			{
			$result = 'ERROR';
			$result_reason = "Invalid Username/Password";
			echo "$result: $result_reason: |$user|$pass|$auth|\n";
			$data = "$user|$pass|$auth";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			exit;
			}
		else
			{
			$stmt="SELECT count(*) from system_settings where vdc_agent_api_active='1';";
			if ($DB) {echo "|$stmt|\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$SNauth=$row[0];
			if($SNauth==0)
				{
				$result = 'ERROR';
				$result_reason = "System API NOT ACTIVE";
				echo "$result: $result_reason\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				exit;
				}
			else
				{
				# do nothing for now
				}
			}
		}
	}

if ($format=='debug')
	{
	echo "<html>\n";
	echo "<head>\n";
	echo "<!-- VERSION: $version     BUILD: $build    USER: $user\n";
	echo "<title>VICIDiaL Agent API";
	echo "</title>\n";
	echo "</head>\n";
	echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
	}
################################################################################
### END - user validation section
################################################################################





################################################################################
### BEGIN - external_hangup - hang up the active agent call
################################################################################
if ($function == 'external_hangup')
	{
	if ( (strlen($value)<1) or ( (strlen($agent_user)<1) and (strlen($alt_user)<2) ) )
		{
		$result = 'ERROR';
		$result_reason = "external_hangup not valid";
		echo "$result: $result_reason - $value|$agent_user\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		if (strlen($alt_user)>1)
			{
			$stmt = "select count(*) from vicidial_users where custom_three='$alt_user';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select user from vicidial_users where custom_three='$alt_user' order by user;";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				$agent_user = $row[0];
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "no user found";
				echo "$result: $result_reason - $alt_user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		$stmt = "select count(*) from vicidial_live_agents where user='$agent_user';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt="UPDATE vicidial_live_agents set external_hangup='$value' where user='$agent_user';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$result = 'SUCCESS';
			$result_reason = "external_hangup function set";
			echo "$result: $result_reason - $value|$agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "agent_user is not logged in";
			echo "$result: $result_reason - $agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - external_hangup
################################################################################





################################################################################
### BEGIN - external_status - set the dispo code or status for a call and move on
################################################################################
if ($function == 'external_status')
	{
	if ( (strlen($value)<1) or ( (strlen($agent_user)<1) and (strlen($alt_user)<2) ) )
		{
		$result = 'ERROR';
		$result_reason = "external_status not valid";
		echo "$result: $result_reason - $value|$agent_user\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		if (strlen($alt_user)>1)
			{
			$stmt = "select count(*) from vicidial_users where custom_three='$alt_user';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select user from vicidial_users where custom_three='$alt_user' order by user;";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				$agent_user = $row[0];
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "no user found";
				echo "$result: $result_reason - $alt_user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		$stmt = "select count(*) from vicidial_live_agents where user='$agent_user';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt="UPDATE vicidial_live_agents set external_status='$value' where user='$agent_user';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$result = 'SUCCESS';
			$result_reason = "external_status function set";
			echo "$result: $result_reason - $value|$agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "agent_user is not logged in";
			echo "$result: $result_reason - $agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - external_status
################################################################################





################################################################################
### BEGIN - external_pause - pause or resume the agent
################################################################################
if ($function == 'external_pause')
	{
	if ( (strlen($value)<1) or ( (strlen($agent_user)<1) and (strlen($alt_user)<1) ) or (!ereg("PAUSE|RESUME",$value)) )
		{
		$result = 'ERROR';
		$result_reason = "external_pause not valid";
		echo "$result: $result_reason - $value|$agent_user\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		if (strlen($alt_user)>1)
			{
			$stmt = "select count(*) from vicidial_users where custom_three='$alt_user';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select user from vicidial_users where custom_three='$alt_user' order by user;";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				$agent_user = $row[0];
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "no user found";
				echo "$result: $result_reason - $alt_user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		$stmt = "select count(*) from vicidial_live_agents where user='$agent_user';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			if (ereg("RESUME",$value))
				{
				$stmt = "select count(*) from vicidial_live_agents where user='$agent_user' and status IN('READY','QUEUE','INCALL','CLOSER');";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				if ($row[0] > 0)
					{
					$result = 'ERROR';
					$result_reason = "external_pause agent is not paused";
					echo "$result: $result_reason - $value|$agent_user\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					exit;
					}
				}
			$stmt="UPDATE vicidial_live_agents set external_pause='$value!$epoch' where user='$agent_user';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);
			$result = 'SUCCESS';
			$result_reason = "external_pause function set";
			echo "$result: $result_reason - $value|$epoch|$agent_user\n";
			$data = "$epoch";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "agent_user is not logged in";
			echo "$result: $result_reason - $agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - external_pause
################################################################################





################################################################################
### BEGIN - external_dial - place a manual dial phone call
################################################################################
if ($function == 'external_dial')
	{
	$value = ereg_replace("[^0-9]","",$value);

	if ( (strlen($value)<2) or ( (strlen($agent_user)<2) and (strlen($alt_user)<2) ) or (strlen($search)<2) or (strlen($preview)<2) or (strlen($focus)<2) )
		{
		$result = 'ERROR';
		$result_reason = "external_dial not valid";
		$data = "$phone_code|$search|$preview|$focus";
		echo "$result: $result_reason - $value|$data|$agent_user|$alt_user\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		if (strlen($alt_user)>1)
			{
			$stmt = "select count(*) from vicidial_users where custom_three='$alt_user';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select user from vicidial_users where custom_three='$alt_user' order by user;";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				$agent_user = $row[0];
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "no user found";
				echo "$result: $result_reason - $alt_user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		$stmt = "select count(*) from vicidial_live_agents where user='$agent_user';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt = "select count(*) from vicidial_live_agents where user='$agent_user' and status='PAUSED' and lead_id < 1;";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select count(*) from vicidial_users where user='$agent_user' and agentcall_manual='1';";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				if ($row[0] > 0)
					{
					if (strlen($group_alias)>1)
						{
						$stmt = "select caller_id_number from groups_alias where group_alias_id='$group_alias';";
						if ($DB) {echo "$stmt\n";}
						$rslt=mysql_query($stmt, $link);
						$VDIG_cidnum_ct = mysql_num_rows($rslt);
						if ($VDIG_cidnum_ct > 0)
							{
							$row=mysql_fetch_row($rslt);
							$caller_id_number	= $row[0];
							if ($caller_id_number < 4)
								{
								$result = 'ERROR';
								$result_reason = "caller_id_number from group_alias is not valid";
								$data = "$group_alias|$caller_id_number";
								echo "$result: $result_reason - $agent_user|$data\n";
								api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
								exit;
								}
							}
						else
							{
							$result = 'ERROR';
							$result_reason = "group_alias is not valid";
							$data = "$group_alias";
							echo "$result: $result_reason - $agent_user|$data\n";
							api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
							exit;
							}
						}

					####### Begin Vtiger CallBack Launching #######
					$vtiger_callback_id='';
					if ( (eregi("YES",$vtiger_callback)) and (preg_match("/^99/",$value)) )
						{
						$value = preg_replace("/^99/",'',$value);
						$value = ($value + 0);

						$stmt = "SELECT enable_vtiger_integration,vtiger_server_ip,vtiger_dbname,vtiger_login,vtiger_pass,vtiger_url FROM system_settings;";
						$rslt=mysql_query($stmt, $link);
						$ss_conf_ct = mysql_num_rows($rslt);
						if ($ss_conf_ct > 0)
							{
							$row=mysql_fetch_row($rslt);
							$enable_vtiger_integration =	$row[0];
							$vtiger_server_ip	=			$row[1];
							$vtiger_dbname =				$row[2];
							$vtiger_login =					$row[3];
							$vtiger_pass =					$row[4];
							$vtiger_url =					$row[5];
							}

						if ($enable_vtiger_integration > 0)
							{
							$stmt = "SELECT campaign_id FROM vicidial_live_agents where user='$agent_user';";
							$rslt=mysql_query($stmt, $link);
							$vtc_camp_ct = mysql_num_rows($rslt);
							if ($vtc_camp_ct > 0)
								{
								$row=mysql_fetch_row($rslt);
								$campaign_id =		$row[0];
								}
							$stmt = "SELECT vtiger_search_category,vtiger_create_call_record,vtiger_create_lead_record,vtiger_search_dead,vtiger_status_call FROM vicidial_campaigns where campaign_id='$campaign_id';";
							$rslt=mysql_query($stmt, $link);
							$vtc_conf_ct = mysql_num_rows($rslt);
							if ($vtc_conf_ct > 0)
								{
								$row=mysql_fetch_row($rslt);
								$vtiger_search_category =		$row[0];
								$vtiger_create_call_record =	$row[1];
								$vtiger_create_lead_record =	$row[2];
								$vtiger_search_dead =			$row[3];
								$vtiger_status_call =			$row[4];
								}

							### connect to your vtiger database
							$linkV=mysql_connect("$vtiger_server_ip", "$vtiger_login","$vtiger_pass");
							if (!$linkV) {die("Could not connect: $vtiger_server_ip|$vtiger_dbname|$vtiger_login|$vtiger_pass" . mysql_error());}
							mysql_select_db("$vtiger_dbname", $linkV);

							# make sure the ID is present in Vtiger database as an account
							$stmt="SELECT count(*) from vtiger_seactivityrel where activityid='$value';";
							if ($DB) {echo "$stmt\n";}
							$rslt=mysql_query($stmt, $linkV);
							$vt_act_ct = mysql_num_rows($rslt);
							if ($vt_act_ct > 0)
								{
								$row=mysql_fetch_row($rslt);
								$activity_check = $row[0];
								}
							if ($activity_check > 0)
								{
								$stmt="SELECT crmid from vtiger_seactivityrel where activityid='$value';";
								if ($DB) {echo "$stmt\n";}
								$rslt=mysql_query($stmt, $linkV);
								$vt_actsel_ct = mysql_num_rows($rslt);
								if ($vt_actsel_ct > 0)
									{
									$row=mysql_fetch_row($rslt);
									$vendor_id = $row[0];
									}
								if (strlen($vendor_id) > 0)
									{
									$stmt="SELECT phone from vtiger_account where accountid='$vendor_id';";
									if ($DB) {echo "$stmt\n";}
									$rslt=mysql_query($stmt, $linkV);
									$vt_acct_ct = mysql_num_rows($rslt);
									if ($vt_acct_ct > 0)
										{
										$row=mysql_fetch_row($rslt);
										$vtiger_callback_id="$value";
										$value = $row[0];
										}
									}
								}
							else
								{
								$result = 'ERROR';
								$result_reason = "vtiger callback activity does not exist in vtiger system";
								echo "$result: $result_reason - $value\n";
								api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
								exit;
								}
							}
						}
					####### End Vtiger CallBack Launching #######

					### If no errors, run the update to place the call ###
					$stmt="UPDATE vicidial_live_agents set external_dial='$value!$phone_code!$search!$preview!$focus!$vendor_id!$epoch!$dial_prefix!$group_alias!$caller_id_number!$vtiger_callback_id' where user='$agent_user';";
						if ($format=='debug') {echo "\n<!-- $stmt -->";}
					$rslt=mysql_query($stmt, $link);
					$result = 'SUCCESS';
					$result_reason = "external_dial function set";
					$data = "$phone_code|$search|$preview|$focus|$vendor_id|$epoch|$dial_prefix|$group_alias|$caller_id_number";
					echo "$result: $result_reason - $value|$agent_user|$data\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					}
				else
					{
					$result = 'ERROR';
					$result_reason = "agent_user is not allowed to place manual dial calls";
					echo "$result: $result_reason - $agent_user\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					}
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "agent_user is not paused";
				echo "$result: $result_reason - $agent_user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "agent_user is not logged in";
			echo "$result: $result_reason - $agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - external_dial
################################################################################





################################################################################
### BEGIN - change_ingroups - change selected in-groups for logged-in agent
################################################################################
if ($function == 'change_ingroups')
	{
	$value = ereg_replace("[^A-Z]","",$value);

	if ( (strlen($blended)<2) or (strlen($agent_user)<2) or (strlen($value)<3) )
		{
		$result = 'ERROR';
		$result_reason = "change_ingroups not valid";
		$data = "$value|$blended|$ingroup_choices";
		echo "$result: $result_reason - $data|$agent_user\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		$stmt = "select count(*) from vicidial_live_agents where user='$agent_user';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt = "select count(*) from vicidial_live_agents vla, vicidial_campaigns vc where user='$agent_user' and campaign_allow_inbound='Y' and vla.campaign_id=vc.campaign_id;";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select count(*) from vicidial_users where user='$user' and change_agent_campaign='1';";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				if ($row[0] > 0)
					{
					if ($blended == 'YES')
						{
						$stmt = "select count(*) from vicidial_live_agents vla, vicidial_campaigns vc where user='$agent_user' and dial_method IN('MANUAL','INBOUND_MAN') and vla.campaign_id=vc.campaign_id;";
						if ($DB) {echo "$stmt\n";}
						$rslt=mysql_query($stmt, $link);
						$row=mysql_fetch_row($rslt);
						if ($row[0] > 0)
							{
							$result = 'ERROR';
							$result_reason = "campaign dial_method does not allow outbound autodial";
							$data = "$blended";
							echo "$result: $result_reason - $agent_user|$data\n";
							api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
							exit;
							}
						}
					if (strlen($ingroup_choices)>0)
						{
						$in_groups_pre = preg_replace('/-$/','',$ingroup_choices);
						$in_groups = explode(" ",$in_groups_pre);
						$in_groups_ct = count($in_groups);
						$k=1;
						while ($k < $in_groups_ct)
							{
							if (strlen($in_groups[$k])>1)
								{
								$stmt="SELECT count(*) FROM vicidial_inbound_groups where group_id='$in_groups[$k]';";
								$rslt=mysql_query($stmt, $link);
								if ($DB) {echo "$stmt\n";}
								$row=mysql_fetch_row($rslt);
								if ($row[0] < 1)
									{
									$result = 'ERROR';
									$result_reason = "ingroup does not exist";
									$data = "$in_groups[$k]|$ingroup_choices";
									echo "$result: $result_reason - $agent_user|$data\n";
									api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
									exit;
									}
								}
							$k++;
							}
						}
					if ( (strlen($ingroup_choices) < 1) and ( ($value == 'ADD') or ($value == 'REMOVE') ) )
						{
						$result = 'ERROR';
						$result_reason = "ingroup_choices are required for ADD and REMOVE values";
						$data = "$value|$ingroup_choices";
						echo "$result: $result_reason - $agent_user|$data\n";
						api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
						exit;
						}

					if ($value == 'ADD')
						{
						$stmt = "select closer_campaigns from vicidial_live_agents where user='$agent_user';";
						if ($DB) {echo "$stmt\n";}
						$rslt=mysql_query($stmt, $link);
						$row=mysql_fetch_row($rslt);
						$closer_groups_pre = preg_replace('/-$/','',$row[0]);
						$closer_groups = explode(" ",$closer_groups_pre);
						$closer_groups_ct = count($closer_groups);

						$in_groups_pre = preg_replace('/-$/','',$ingroup_choices);
						$in_groups = explode(" ",$in_groups_pre);
						$in_groups_ct = count($in_groups);
						$k=1;
						while ($k < $in_groups_ct)
							{
							$duplicate_group=0;
							if (strlen($in_groups[$k])>1)
								{
								$m=0;
								while ($m < $closer_groups_ct)
									{
									if (strlen($closer_groups[$m])>1)
										{
										if ($closer_groups[$m] == $in_groups[$k])
											{$duplicate_group++;}
										}
									$m++;
									}
								if ($duplicate_group < 1)
									{
									$closer_groups[$closer_groups_ct] = $in_groups[$k];
									$closer_groups_ct++;
									}
								}
							$k++;
							}

						$m=0;
						$NEWcloser_groups=' ';
						while ($m < $closer_groups_ct)
							{
							if (strlen($closer_groups[$m])>1)
								{
								$NEWcloser_groups .= "$closer_groups[$m] ";
								}
							$m++;
							}
						$NEWcloser_groups .= '-';
						$ingroup_choices = $NEWcloser_groups;
						}

					if ($value == 'REMOVE')
						{
						$stmt = "select closer_campaigns from vicidial_live_agents where user='$agent_user';";
						if ($DB) {echo "$stmt\n";}
						$rslt=mysql_query($stmt, $link);
						$row=mysql_fetch_row($rslt);
						$closer_groups_list = $row[0];
						$closer_groups_pre = preg_replace('/-$/','',$row[0]);
						$closer_groups = explode(" ",$closer_groups_pre);
						$closer_groups_ct = count($closer_groups);

						$in_groups_pre = preg_replace('/-$/','',$ingroup_choices);
						$in_groups = explode(" ",$in_groups_pre);
						$in_groups_ct = count($in_groups);
						$k=1;
						while ($k < $in_groups_ct)
							{
							$duplicate_group=0;
							if (strlen($in_groups[$k])>1)
								{
								$m=0;
								while ($m < $closer_groups_ct)
									{
									if (strlen($closer_groups[$m])>1)
										{
										if ($closer_groups[$m] == $in_groups[$k])
											{$duplicate_group++;}
										}
									$m++;
									}
								if ($duplicate_group > 0)
									{
									$closer_groups_list = preg_replace("/ $in_groups[$k] /",' ',$closer_groups_list);
									}
								}
							$k++;
							}

						$ingroup_choices = $closer_groups_list;
						}

					### If no errors, run the update to change selected ingroups ###
					$external_blended=0;
					if ($blended == 'YES')
						{$external_blended=1;}

					$stmt="UPDATE vicidial_live_agents set external_ingroups='$ingroup_choices',external_blended='$external_blended',external_igb_set_user='$user',manager_ingroup_set='SET' where user='$agent_user';";
						if ($format=='debug') {echo "\n<!-- $stmt -->";}
					$rslt=mysql_query($stmt, $link);

					$default_data = "";
					if ($set_as_default == 'YES')
						{
						$stmt="UPDATE vicidial_users set closer_campaigns='$ingroup_choices',closer_default_blended='$external_blended' where user='$agent_user';";
							if ($format=='debug') {echo "\n<!-- $stmt -->";}
						$rslt=mysql_query($stmt, $link);
						$default_data = "User settings set as default";
						}

					$result = 'SUCCESS';
					$result_reason = "change_ingroups function set";
					$data = "$ingroup_choices|$blended|$default_data";
					echo "$result: $result_reason - $user|$agent_user|$data\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					}
				else
					{
					$result = 'ERROR';
					$result_reason = "user is not allowed to change agent in-groups";
					echo "$result: $result_reason - $user\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					}
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "campaign does not allow inbound calls";
				echo "$result: $result_reason - $agent_user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "agent_user is not logged in";
			echo "$result: $result_reason - $agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - change_ingroups
################################################################################





################################################################################
### BEGIN - update_fields
################################################################################
if ($function == 'update_fields')
	{
	if (strlen($agent_user)<1)
		{
		$result = 'ERROR';
		$result_reason = "st_login_log not valid";
		$data = "$agent_user";
		echo "$result: $result_reason - $data\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		$stmt = "select count(*) from vicidial_live_agents where user='$agent_user';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt = "select count(*) from vicidial_users where user='$user' and modify_leads='1';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select lead_id from vicidial_live_agents where user='$agent_user';";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				$lead_id = $row[0];
				if ($lead_id > 0)
					{
					$fieldsSQL='';
					$fieldsLISTS='';
					$field_set=0;
					if (ereg('phone_code',$query_string))
						{
						if ($DB) {echo "phone_code set to $phone_code\n";}
						$fieldsSQL .= "phone_code='$phone_code',";
						$fieldsLIST .= "phone_code,";
						$field_set++;
						}
					if (ereg('address1',$query_string))
						{
						if ($DB) {echo "address1 set to $address1\n";}
						$fieldsSQL .= "address1='$address1',";
						$fieldsLIST .= "address1,";
						$field_set++;
						}
					if (ereg('address2',$query_string))
						{
						if ($DB) {echo "address2 set to $address2\n";}
						$fieldsSQL .= "address2='$address2',";
						$fieldsLIST .= "address2,";
						$field_set++;
						}
					if (ereg('address3',$query_string))
						{
						if ($DB) {echo "address3 set to $address3\n";}
						$fieldsSQL .= "address3='$address3',";
						$fieldsLIST .= "address3,";
						$field_set++;
						}
					if (ereg('alt_phone',$query_string))
						{
						if ($DB) {echo "alt_phone set to $alt_phone\n";}
						$fieldsSQL .= "alt_phone='$alt_phone',";
						$fieldsLIST .= "alt_phone,";
						$field_set++;
						}
					if (ereg('city',$query_string))
						{
						if ($DB) {echo "city set to $city\n";}
						$fieldsSQL .= "city='$city',";
						$fieldsLIST .= "city,";
						$field_set++;
						}
					if (ereg('comments',$query_string))
						{
						if ($DB) {echo "comments set to $comments\n";}
						$fieldsSQL .= "comments='$comments',";
						$fieldsLIST .= "comments,";
						$field_set++;
						}
					if (ereg('country_code',$query_string))
						{
						if ($DB) {echo "country_code set to $country_code\n";}
						$fieldsSQL .= "country_code='$country_code',";
						$fieldsLIST .= "country_code,";
						$field_set++;
						}
					if (ereg('date_of_birth',$query_string))
						{
						if ($DB) {echo "date_of_birth set to $date_of_birth\n";}
						$fieldsSQL .= "date_of_birth='$date_of_birth',";
						$fieldsLIST .= "date_of_birth,";
						$field_set++;
						}
					if (ereg('email',$query_string))
						{
						if ($DB) {echo "email set to $email\n";}
						$fieldsSQL .= "email='$email',";
						$fieldsLIST .= "email,";
						$field_set++;
						}
					if (ereg('first_name',$query_string))
						{
						if ($DB) {echo "first_name set to $first_name\n";}
						$fieldsSQL .= "first_name='$first_name',";
						$fieldsLIST .= "first_name,";
						$field_set++;
						}
					if (ereg('gender',$query_string))
						{
						if ($DB) {echo "gender set to $gender\n";}
						$fieldsSQL .= "gender='$gender',";
						$fieldsLIST .= "gender,";
						$field_set++;
						}
					if (ereg('gmt_offset_now',$query_string))
						{
						if ($DB) {echo "gmt_offset_now set to $gmt_offset_now\n";}
						$fieldsSQL .= "gmt_offset_now='$gmt_offset_now',";
						$fieldsLIST .= "gmt_offset_now,";
						$field_set++;
						}
					if (ereg('last_name',$query_string))
						{
						if ($DB) {echo "last_name set to $last_name\n";}
						$fieldsSQL .= "last_name='$last_name',";
						$fieldsLIST .= "last_name,";
						$field_set++;
						}
					if (ereg('middle_initial',$query_string))
						{
						if ($DB) {echo "middle_initial set to $middle_initial\n";}
						$fieldsSQL .= "middle_initial='$middle_initial',";
						$fieldsLIST .= "middle_initial,";
						$field_set++;
						}
					if (ereg('phone_number',$query_string))
						{
						if ($DB) {echo "phone_number set to $phone_number\n";}
						$fieldsSQL .= "phone_number='$phone_number',";
						$fieldsLIST .= "phone_number,";
						$field_set++;
						}
					if (ereg('postal_code',$query_string))
						{
						if ($DB) {echo "postal_code set to $postal_code\n";}
						$fieldsSQL .= "postal_code='$postal_code',";
						$fieldsLIST .= "postal_code,";
						$field_set++;
						}
					if (ereg('province',$query_string))
						{
						if ($DB) {echo "province set to $province\n";}
						$fieldsSQL .= "province='$province',";
						$fieldsLIST .= "province,";
						$field_set++;
						}
					if (ereg('security_phrase',$query_string))
						{
						if ($DB) {echo "security_phrase set to $security_phrase\n";}
						$fieldsSQL .= "security_phrase='$security_phrase',";
						$fieldsLIST .= "security_phrase,";
						$field_set++;
						}
					if (ereg('source_id',$query_string))
						{
						if ($DB) {echo "source_id set to $source_id\n";}
						$fieldsSQL .= "source_id='$source_id',";
						$fieldsLIST .= "source_id,";
						$field_set++;
						}
					if (ereg('state',$query_string))
						{
						if ($DB) {echo "state set to $state\n";}
						$fieldsSQL .= "state='$state',";
						$fieldsLIST .= "state,";
						$field_set++;
						}
					if (ereg('title',$query_string))
						{
						if ($DB) {echo "title set to $title\n";}
						$fieldsSQL .= "title='$title',";
						$fieldsLIST .= "title,";
						$field_set++;
						}
					if (ereg('vendor_lead_code',$query_string))
						{
						if ($DB) {echo "vendor_lead_code set to $vendor_lead_code\n";}
						$fieldsSQL .= "vendor_lead_code='$vendor_lead_code',";
						$fieldsLIST .= "vendor_lead_code,";
						$field_set++;
						}
					if (ereg('rank',$query_string))
						{
						if ($DB) {echo "rank set to $rank\n";}
						$fieldsSQL .= "rank='$rank',";
						$fieldsLIST .= "rank,";
						$field_set++;
						}
					if (ereg('owner',$query_string))
						{
						if ($DB) {echo "owner set to $owner\n";}
						$fieldsSQL .= "owner='$owner',";
						$fieldsLIST .= "owner,";
						$field_set++;
						}
					if ($field_set > 0)
						{
						$fieldsSQL = preg_replace("/,$/","",$fieldsSQL);
						$fieldsLIST = preg_replace("/,$/","",$fieldsLIST);

						$stmt="UPDATE vicidial_list set $fieldsSQL where lead_id='$lead_id';";
							if ($format=='debug') {echo "\n<!-- $stmt -->";}
						$rslt=mysql_query($stmt, $link);

						$stmt="UPDATE vicidial_live_agents set external_update_fields='1',external_update_fields_data='$fieldsLIST' where user='$agent_user';";
							if ($format=='debug') {echo "\n<!-- $stmt -->";}
						$rslt=mysql_query($stmt, $link);

						$result = 'SUCCESS';
						$result_reason = "update_fields lead updated";
						$data = "$user|$agent_user|$lead_id|$fieldsSQL";
						echo "$result: $result_reason - $data\n";
						api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
						}
					else
						{
						$result = 'ERROR';
						$result_reason = "no fields have been defined";
						echo "$result: $result_reason - $agent_user\n";
						api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
						exit;
						}
					}
				else
					{
					$result = 'ERROR';
					$result_reason = "agent_user does not have a lead on their screen";
					echo "$result: $result_reason - $agent_user\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					exit;
					}
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "user is not allowed to modify lead information";
				echo "$result: $result_reason - $agent_user|$user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "agent_user is not logged in";
			echo "$result: $result_reason - $agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - update_fields
################################################################################





################################################################################
### BEGIN - set_timer_action
################################################################################
if ($function == 'set_timer_action')
	{
	if ( (strlen($agent_user)<1) or (strlen($value)<2) )
		{
		$result = 'ERROR';
		$result_reason = "set_timer_action not valid";
		$data = "$agent_user|$value";
		echo "$result: $result_reason - $data\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		$stmt = "select count(*) from vicidial_live_agents where user='$agent_user';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt = "select count(*) from vicidial_users where user='$user' and modify_campaigns='1';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt="UPDATE vicidial_live_agents set external_timer_action='$value',external_timer_action_message='$notes',external_timer_action_seconds='$rank' where user='$agent_user';";
					if ($format=='debug') {echo "\n<!-- $stmt -->";}
				$rslt=mysql_query($stmt, $link);

				$result = 'SUCCESS';
				$result_reason = "set_timer_action lead updated";
				$data = "$user|$agent_user|$value|$notes|$rank";
				echo "$result: $result_reason - $data\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "user is not allowed to modify campaign settings";
				echo "$result: $result_reason - $agent_user|$user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "agent_user is not logged in";
			echo "$result: $result_reason - $agent_user\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - set_timer_action
################################################################################





################################################################################
### BEGIN - st_login_log - looks up vicidial_users.custom_three from a CRM
################################################################################
if ($function == 'st_login_log')
	{
	if ( (strlen($value)<1) or (strlen($vendor_id)<1) )
		{
		$result = 'ERROR';
		$result_reason = "st_login_log not valid";
		$data = "$value|$vendor_id";
		echo "$result: $result_reason - $data\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		$stmt = "select count(*) from vicidial_users where custom_three='$value';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt = "select user from vicidial_users where custom_three='$value' order by user;";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);

			$stmt="UPDATE vicidial_users set custom_four='$vendor_id' where user='$row[0]';";
				if ($format=='debug') {echo "\n<!-- $stmt -->";}
			$rslt=mysql_query($stmt, $link);

			$result = 'SUCCESS';
			$result_reason = "st_login_log user found";
			$data = "$row[0]";
			echo "$result: $result_reason - $row[0]\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);

			}
		else
			{
			$result = 'ERROR';
			$result_reason = "no user found";
			echo "$result: $result_reason - $value\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - st_login_log
################################################################################




################################################################################
### BEGIN - st_get_agent_active_lead - looks up vicidial_users.custom_three and output active lead info
################################################################################
if ($function == 'st_get_agent_active_lead')
	{
	if ( (strlen($value)<1) or (strlen($vendor_id)<1) )
		{
		$result = 'ERROR';
		$result_reason = "st_get_agent_active_lead not valid";
		$data = "$value|$vendor_id";
		echo "$result: $result_reason - $data\n";
		api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
		exit;
		}
	else
		{
		$stmt = "select count(*) from vicidial_users where custom_three='$value';";
		if ($DB) {echo "$stmt\n";}
		$rslt=mysql_query($stmt, $link);
		$row=mysql_fetch_row($rslt);
		if ($row[0] > 0)
			{
			$stmt = "select user from vicidial_users where custom_three='$value' order by user;";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$VC_user = $row[0];

			$stmt = "select count(*) from vicidial_live_agents where user='$VC_user';";
			if ($DB) {echo "$stmt\n";}
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			if ($row[0] > 0)
				{
				$stmt = "select lead_id from vicidial_live_agents where user='$VC_user';";
				if ($DB) {echo "$stmt\n";}
				$rslt=mysql_query($stmt, $link);
				$row=mysql_fetch_row($rslt);
				$lead_id = $row[0];

				if ($lead_id > 0)
					{
					$stmt = "select phone_number,vendor_lead_code,province,security_phrase,source_id from vicidial_list where lead_id='$lead_id';";
					if ($DB) {echo "$stmt\n";}
					$rslt=mysql_query($stmt, $link);
					$row=mysql_fetch_row($rslt);
					$phone_number =		$row[0];
					$vendor_lead_code = $row[1];
					$province =			$row[2];
					$security_phrase =	$row[3];
					$source_id =		$row[4];

					$result = 'SUCCESS';
					$result_reason = "st_get_agent_active_lead lead found";
					$data = "$VC_user|$phone_number|$lead_id|$vendor_lead_code|$province|$security_phrase|$source_id";
					echo "$result: $result_reason - $data\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					}
				else
					{
					$result = 'ERROR';
					$result_reason = "no active lead found";
					echo "$result: $result_reason - $VC_user\n";
					api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
					}
				}
			else
				{
				$result = 'ERROR';
				$result_reason = "user not logged in";
				echo "$result: $result_reason - $VC_user\n";
				api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
				}
			}
		else
			{
			$result = 'ERROR';
			$result_reason = "no user found";
			echo "$result: $result_reason - $value\n";
			api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data);
			}
		}
	}
################################################################################
### END - st_get_agent_active_lead
################################################################################





if ($format=='debug') 
	{
	$ENDtime = date("U");
	$RUNtime = ($ENDtime - $StarTtime);
	echo "\n<!-- script runtime: $RUNtime seconds -->";
	echo "\n</body>\n</html>\n";
	}
	
exit; 



##### FUNCTIONS #####

##### Logging #####
function api_log($link,$api_logging,$api_script,$user,$agent_user,$function,$value,$result,$result_reason,$source,$data)
	{
	if ($api_logging > 0)
		{
		$NOW_TIME = date("Y-m-d H:i:s");
		$stmt="INSERT INTO vicidial_api_log set user='$user',agent_user='$agent_user',function='$function',value='$value',result='$result',result_reason='$result_reason',source='$source',data='$data',api_date='$NOW_TIME',api_script='$api_script';";
		$rslt=mysql_query($stmt, $link);
		}
	return 1;
	}

?>
