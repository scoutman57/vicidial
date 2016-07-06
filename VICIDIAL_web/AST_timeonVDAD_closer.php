<? 
require("dbconnect.php");

require_once("htglobalize.php");

# AST_timeonVDAD_closer.php
# live real-time stats for the VICIDIAL Auto-Dialer

$NOW_TIME = date("Y-m-d H:i:s");
$STARTtime = date("U");
$epochSIXhoursAGO = ($STARTtime - 21600);
$timeSIXhoursAGO = date("Y-m-d H:i:s",$epochSIXhoursAGO);

$reset_counter++;

if ($reset_counter > 7)
	{
	$reset_counter=0;

	$stmt="update park_log set status='HUNGUP' where hangup_time is not null;";
#	$rslt=mysql_query($stmt, $link);
	if ($DB) {echo "$stmt\n";}

	if ($DB)
		{	
		$stmt="delete from park_log where grab_time < '$timeSIXhoursAGO' and (hangup_time is null or hangup_time='');";
#		$rslt=mysql_query($stmt, $link);
		 echo "$stmt\n";
		}
	}

?>

<HTML>
<HEAD>
<?
echo "<STYLE type=\"text/css\">\n";
echo "<!--\n";
$stmt="select group_id,group_color from vicidial_inbound_groups;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$groups_to_print = mysql_num_rows($rslt);
	if ($groups_to_print > 0)
	{
	$g=0;
	while ($g < $groups_to_print)
		{
		$row=mysql_fetch_row($rslt);
		$group_id[$g] = $row[0];
		$group_color[$g] = $row[1];
		echo "   .$group_id[$g] {color: black; background-color: $group_color[$g]}\n";
		$g++;
		}
	}

?>
   .DEAD       {color: white; background-color: black}
   .green {color: white; background-color: green}
   .red {color: white; background-color: red}
   .blue {color: white; background-color: blue}
   .purple {color: white; background-color: purple}
-->
 </STYLE>

<? 
echo"<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">\n";
echo"<META HTTP-EQUIV=Refresh CONTENT=\"4; URL=$PHP_SELF?server_ip=$server_ip&DB=$DB&reset_counter=$reset_counter\">\n";
echo "<TITLE>VICIDIAL: Time On VDAD</TITLE></HEAD><BODY BGCOLOR=WHITE>\n";
echo "<PRE><FONT SIZE=3>\n\n";

###################################################################################
###### TIME ON SYSTEM
###################################################################################

echo "VICIDIAL: Agents Time On Calls                                        $NOW_TIME\n\n";
echo "+------------|--------+-----------+----------+--------+---------------------+---------+--------------+\n";
echo "| STATION    | USER   | SESSIONID | CHANNEL  | STATUS | START TIME          | MINUTES | CAMPAIGN     |\n";
echo "+------------|--------+-----------+----------+--------+---------------------+---------+--------------+\n";


$stmt="select extension,user,conf_exten,channel,status,last_call_time,UNIX_TIMESTAMP(last_call_time),UNIX_TIMESTAMP(last_call_finish),uniqueid from vicidial_live_agents where status NOT IN('PAUSED') and server_ip='$server_ip' order by extension;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$talking_to_print = mysql_num_rows($rslt);
	if ($talking_to_print > 0)
	{
	$i=0;
	while ($i < $talking_to_print)
		{
		$row=mysql_fetch_row($rslt);
			if (eregi("READY|PAUSED|CLOSER",$row[4]))
			{
			$row[3]='';
			$row[5]=' - WAITING - ';
			$row[6]=$row[7];
			}
		$extension[$i] =		sprintf("%-10s", $row[0]);
		$user[$i] =				sprintf("%-6s", $row[1]);
		$sessionid[$i] =		sprintf("%-9s", $row[2]);
		$channel[$i] =			sprintf("%-8s", $row[3]);
			$cc[$i]=0;
		while ( (strlen($channel[$i]) > 8) and ($cc[$i] < 100) )
			{
			$channel[$i] = eregi_replace(".$","",$channel[$i]);   
			$cc[$i]++;
			if (strlen($channel[$i]) <= 8) {$cc[$i]=101;}
			}
		$status[$i] =			sprintf("%-6s", $row[4]);
		$start_time[$i] =		sprintf("%-19s", $row[5]);
		$uniqueid[$i] =			$row[8];
		$call_time_S[$i] = ($STARTtime - $row[6]);

		$call_time_M[$i] = ($call_time_S[$i] / 60);
		$call_time_M[$i] = round($call_time_M[$i], 2);
		$call_time_M_int[$i] = intval("$call_time_M[$i]");
		$call_time_SEC[$i] = ($call_time_M[$i] - $call_time_M_int[$i]);
		$call_time_SEC[$i] = ($call_time_SEC[$i] * 60);
		$call_time_SEC[$i] = round($call_time_SEC[$i], 0);
		if ($call_time_SEC[$i] < 10) {$call_time_SEC[$i] = "0$call_time_SEC[$i]";}
		$call_time_MS[$i] = "$call_time_M_int[$i]:$call_time_SEC[$i]";
		$call_time_MS[$i] =		sprintf("%7s", $call_time_MS[$i]);
		$i++;
		}
		$ext_count = $i;
		$i=0;
	while ($i < $ext_count)
		{

		$stmt="select campaign_id from vicidial_auto_calls where uniqueid='$uniqueid[$i]' and server_ip='$server_ip';";
		$rslt=mysql_query($stmt, $link);
		if ($DB) {echo "$stmt\n";}
		$camp_to_print = mysql_num_rows($rslt);
		if ($camp_to_print > 0)
			{
			$row=mysql_fetch_row($rslt);
			$campaign = sprintf("%-12s", $row[0]);
			$camp_color = $row[0];
			}
		else
			{$campaign = 'DEAD        ';   	$camp_color = 'DEAD';}
		if (eregi("READY|PAUSED|CLOSER",$status[$i]))
			{$campaign = '            ';   	$camp_color = '';}

		$G = '';		$EG = '';
		$G="<SPAN class=\"$camp_color\"><B>"; $EG='</B></SPAN>';
	#	if ($call_time_M_int[$i] >= 5) {$G='<SPAN class="blue"><B>'; $EG='</B></SPAN>';}
	#	if ($call_time_M_int[$i] >= 10) {$G='<SPAN class="purple"><B>'; $EG='</B></SPAN>';}

		echo "| $G$extension[$i]$EG | $G$user[$i]$EG | $G$sessionid[$i]$EG | $G$channel[$i]$EG | $G$status[$i]$EG | $G$start_time[$i]$EG | $G$call_time_MS[$i]$EG | $G$campaign$EG |\n";

		$i++;
		}

		echo "+------------|--------+-----------+----------+--------+---------------------+---------+--------------+\n";
		echo "  $i agents logged in on server $server_ip\n\n";

	#	echo "  <SPAN class=\"blue\"><B>          </SPAN> - 5 minutes or more on call</B>\n";
	#	echo "  <SPAN class=\"purple\"><B>          </SPAN> - Over 10 minutes on call</B>\n";

	}
	else
	{
	echo "**************************************************************************************\n";
	echo "**************************************************************************************\n";
	echo "********************************* NO AGENTS ON CALLS *********************************\n";
	echo "**************************************************************************************\n";
	echo "**************************************************************************************\n";
	}


###################################################################################
###### OUTBOUND CALLS
###################################################################################
#echo "\n\n";
echo "----------------------------------------------------------------------------------------";
echo "\n\n";
echo "VICIDIAL: Time On VDAD                                              $NOW_TIME\n\n";
echo "+----------+--------+--------------+--------------------+---------------------+---------+\n";
echo "| CHANNEL  | STATUS | CAMPAIGN     | PHONE NUMBER       | START TIME          | MINUTES |\n";
echo "+----------+--------+--------------+--------------------+---------------------+---------+\n";

#$link=mysql_connect("localhost", "cron", "1234");
# $linkX=mysql_connect("localhost", "cron", "1234");
#mysql_select_db("asterisk");

$stmt="select channel,status,campaign_id,phone_code,phone_number,call_time,UNIX_TIMESTAMP(call_time) from vicidial_auto_calls where status NOT IN('XFER') and server_ip='$server_ip' order by auto_call_id desc;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$parked_to_print = mysql_num_rows($rslt);
	if ($parked_to_print > 0)
	{
	$i=0;
	while ($i < $parked_to_print)
		{
		$row=mysql_fetch_row($rslt);

		$channel =			sprintf("%-8s", $row[0]);
			$cc=0;
		while ( (strlen($channel) > 8) and ($cc < 100) )
			{
			$channel = eregi_replace(".$","",$channel);   
			$cc++;
			if (strlen($channel) <= 8) {$cc=101;}
			}
		$status =			sprintf("%-6s", $row[1]);
		$campaign =			sprintf("%-12s", $row[2]);
			$all_phone = "$row[3]$row[4]";
		$number_dialed =	sprintf("%-18s", $all_phone);
		$start_time =		sprintf("%-19s", $row[5]);
		$call_time_S = ($STARTtime - $row[6]);

		$call_time_M = ($call_time_S / 60);
		$call_time_M = round($call_time_M, 2);
		$call_time_M_int = intval("$call_time_M");
		$call_time_SEC = ($call_time_M - $call_time_M_int);
		$call_time_SEC = ($call_time_SEC * 60);
		$call_time_SEC = round($call_time_SEC, 0);
		if ($call_time_SEC < 10) {$call_time_SEC = "0$call_time_SEC";}
		$call_time_MS = "$call_time_M_int:$call_time_SEC";
		$call_time_MS =		sprintf("%7s", $call_time_MS);
		$G = '';		$EG = '';
		if (eregi("LIVE",$status)) {$G='<SPAN class="green"><B>'; $EG='</B></SPAN>';}
	#	if ($call_time_M_int >= 6) {$G='<SPAN class="red"><B>'; $EG='</B></SPAN>';}

		echo "| $G$channel$EG | $G$status$EG | $G$campaign$EG | $G$number_dialed$EG | $G$start_time$EG | $G$call_time_MS$EG |\n";

		$i++;
		}

		echo "+----------+--------+--------------+--------------------+---------------------+---------+\n";
		echo "  $i calls being placed on server $server_ip\n\n";

		echo "  <SPAN class=\"green\"><B>          </SPAN> - LIVE CALL WAITING</B>\n";
	#	echo "  <SPAN class=\"red\"><B>          </SPAN> - Over 5 minutes on hold</B>\n";

		}
	else
	{
	echo "***************************************************************************************\n";
	echo "***************************************************************************************\n";
	echo "******************************* NO LIVE CALLS WAITING *********************************\n";
	echo "***************************************************************************************\n";
	echo "***************************************************************************************\n";
	}


?>
</PRE>

</BODY></HTML>