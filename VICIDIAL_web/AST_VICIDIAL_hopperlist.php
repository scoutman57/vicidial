<? 
require("dbconnect.php");

require_once("htglobalize.php");

# AST_VICIDIAL_hopperlist.php

$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$STARTtime = date("U");
if (!$query_date) {$query_date = $NOW_DATE;}
if (!$server_ip) {$server_ip = '10.10.11.11';}

$stmt="select campaign_id,campaign_name from vicidial_campaigns order by campaign_id;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$campaigns_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $campaigns_to_print)
	{
	$row=mysql_fetch_row($rslt);
	$campaign_id[$i] =$row[0];
	$campaign_name[$i] =$row[1];
	$i++;
	}
?>

<HTML>
<HEAD>
<STYLE type="text/css">
<!--
   .green {color: white; background-color: green}
   .red {color: white; background-color: red}
   .blue {color: white; background-color: blue}
   .purple {color: white; background-color: purple}
-->
 </STYLE>

<? 
echo"<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">\n";
#echo"<META HTTP-EQUIV=Refresh CONTENT=\"7; URL=$PHP_SELF?server_ip=$server_ip&DB=$DB\">\n";
echo "<TITLE>VICIDIAL: Hopper List</TITLE></HEAD><BODY BGCOLOR=WHITE>\n";
echo "<FORM ACTION=\"$PHP_SELF\" METHOD=GET>\n";
#echo "<INPUT TYPE=HIDDEN NAME=server_ip VALUE=\"$server_ip\">\n";
#echo "<INPUT TYPE=TEXT NAME=query_date SIZE=10 MAXLENGTH=10 VALUE=\"$query_date\">\n";
echo "<SELECT SIZE=1 NAME=group>\n";
	$o=0;
	while ($campaigns_to_print > $o)
	{
		if ($campaign_id[$o] == $group) {echo "<option selected value=\"$campaign_id[$o]\">$campaign_id[$o] - $campaign_name[$o]</option>\n";}
		  else {echo "<option value=\"$campaign_id[$o]\">$campaign_id[$o] - $campaign_name[$o]</option>\n";}
		$o++;
	}
echo "</SELECT>\n";
echo "<INPUT TYPE=SUBMIT NAME=SUBMIT VALUE=SUBMIT>\n";
echo "</FORM>\n\n";

echo "<PRE><FONT SIZE=2>\n\n";


if (!$group)
{
echo "\n\n";
echo "PLEASE SELECT A CAMPAIGN ABOVE AND CLICK SUBMIT\n";
}

else
{


echo "VICIDIAL: Live Current Hopper List                      $NOW_TIME\n";

echo "\n";
echo "---------- TOTALS\n";

$stmt="select count(*) from vicidial_hopper where campaign_id='$group';";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);

$TOTALcalls =	sprintf("%10s", $row[0]);

echo "Total leads in hopper right now:       $TOTALcalls\n";


##############################
#########  LEAD STATS

echo "\n";
echo "---------- LEADS IN HOPPER\n";
echo "+------+-----------+------------+-------+--------+-------+--------+\n";
echo "|      | LEAD_ID   | PHONE NUM  | STATE | STATUS | COUNT | GMT    |\n";
echo "+------+-----------+------------+-------+--------+-------+--------+\n";

$stmt="select vicidial_hopper.lead_id,phone_number,state,vicidial_list.status,called_count,gmt_offset_now from vicidial_hopper,vicidial_list where vicidial_hopper.CAMPAIGN_ID='$group' and vicidial_hopper.lead_id=vicidial_list.lead_id order by hopper_id limit 2000;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$users_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $users_to_print)
	{
	$row=mysql_fetch_row($rslt);

	$FMT_i =		sprintf("%-4s", $i);
	$lead_id =		sprintf("%-9s", $row[0]);
	$phone_number =	sprintf("%-10s", $row[1]);
	$state =		sprintf("%-5s", $row[2]);
	$status =		sprintf("%-6s", $row[3]);
	$count =		sprintf("%-5s", $row[4]);
	$gmt =			sprintf("%-6s", $row[5]);

	echo "| $FMT_i | $lead_id | $phone_number | $state | $status | $count | $gmt |\n";

	$i++;
	}

echo "+------+-----------+------------+-------+--------+-------+--------+\n";


}



?>
</PRE>

</BODY></HTML>