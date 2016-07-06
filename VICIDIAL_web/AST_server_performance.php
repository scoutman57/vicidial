<? 
require("dbconnect.php");

require_once("htglobalize.php");

# path from root to where ploticus files will be stored
$DOCroot = '/usr/local/apache2/htdocs/vicidial/ploticus/';

# AST_server_performance.php

$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$STARTtime = date("U");
if (!$query_date) {$query_date = $NOW_DATE;}

$stmt="select server_ip from servers;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$servers_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $servers_to_print)
	{
	$row=mysql_fetch_row($rslt);
	$groups[$i] =$row[0];
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
# query_date - 2005-05-10
echo "<TITLE>VICIDIAL: Server Performance</TITLE></HEAD><BODY BGCOLOR=WHITE>\n";
echo "<FORM ACTION=\"$PHP_SELF\" METHOD=GET>\n";
echo "<INPUT TYPE=TEXT NAME=query_date SIZE=19 MAXLENGTH=19 VALUE=\"$query_date\">\n";
echo "<SELECT SIZE=1 NAME=group>\n";
	$o=0;
	while ($servers_to_print > $o)
	{
		if ($groups[$o] == $group) {echo "<option selected value=\"$groups[$o]\">$groups[$o]</option>\n";}
		  else {echo "<option value=\"$groups[$o]\">$groups[$o]</option>\n";}
		$o++;
	}
echo "</SELECT>\n";
echo "<SELECT SIZE=1 NAME=shift>\n";
echo "<option selected value=\"AM\">AM</option>\n";
echo "<option value=\"PM\">PM</option>\n";
echo "</SELECT>\n";
echo "<INPUT TYPE=SUBMIT NAME=SUBMIT VALUE=SUBMIT>\n";
echo "</FORM>\n\n";

echo "<PRE><FONT SIZE=2>\n";


if (!$group)
{
echo "\n";
echo "PLEASE SELECT A SERVER AND DATE-TIME ABOVE AND CLICK SUBMIT\n";
echo " NOTE: stats taken from 6 hour shift specified\n";
}

else
{
if ($shift == 'AM') 
	{
	$query_date_BEGIN = "$query_date 08:45:00";   
	$query_date_END = "$query_date 15:32:00";
	$time_BEGIN = "08:45:00";   
	$time_END = "15:32:00";
	}
if ($shift == 'PM') 
	{
	$query_date_BEGIN = "$query_date 15:32:00";   
	$query_date_END = "$query_date 23:15:00";
	$time_BEGIN = "15:32:00";   
	$time_END = "23:15:00";
	}

echo "VICIDIAL: Server Performance                             $NOW_TIME\n";

echo "Time range: $query_date_BEGIN to $query_date_END\n\n";
echo "---------- TOTALS, PEAKS and AVERAGES\n";

$stmt="select sysload from server_performance where start_time <= '$query_date_END' and start_time >= '$query_date_BEGIN' and server_ip='$group' order by sysload desc limit 1;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$HIGHload =	sprintf("%10s", $row[0]);

$stmt="select AVG(sysload),AVG(channels_total) from server_performance where start_time <= '$query_date_END' and start_time >= '$query_date_BEGIN' and server_ip='$group';";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$AVGload =	sprintf("%10s", $row[0]);
$AVGchannels =	sprintf("%10s", $row[1]);

$stmt="select usedram from server_performance where start_time <= '$query_date_END' and start_time >= '$query_date_BEGIN' and server_ip='$group' order by usedram desc limit 1;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$USEDram =	sprintf("%10s", $row[0]);

$stmt="select count(*),SUM(length_in_min) from call_log where extension NOT IN('8365') and  start_time <= '$query_date_END' and start_time >= '$query_date_BEGIN' and server_ip='$group';";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$row=mysql_fetch_row($rslt);
$TOTALcalls =	sprintf("%10s", $row[0]);
$OFFHOOKtime =	sprintf("%10s", $row[1]);


echo "Total Calls in/out on this server:        $TOTALcalls\n";
echo "Total Off-Hook time on this server (min): $OFFHOOKtime\n";
echo "Average load for server:                  $AVGload\n";
echo "Peak load for server:                     $HIGHload\n";
#echo "Peak used memory for server (in MB):      $USEDram\n";
echo "Average channels in use for server:       $AVGchannels\n";

echo "\n";
echo "---------- LINE GRAPH:\n";



##############################
#########  Graph stats

$DAT = '.dat';
$HTM = '.htm';
$PNG = '.png';
$filedate = date("Y-m-d_His");
$DATfile = "$group$query_date$shift$filedate$DAT";
$HTMfile = "$group$query_date$shift$filedate$HTM";
$PNGfile = "$group$query_date$shift$filedate$PNG";

$HTMfp = fopen ("$DOCroot/$HTMfile", "a");
$DATfp = fopen ("$DOCroot/$DATfile", "a");

$stmt="select DATE_FORMAT(start_time,'%H:%i:%s') as timex,sysload,processes,channels_total,live_recordings from server_performance where server_ip='$group' and start_time <= '$query_date_END' and start_time >= '$query_date_BEGIN' order by timex;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$rows_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $rows_to_print)
	{
	$row=mysql_fetch_row($rslt);
	fwrite ($DATfp, "$row[0]\t$row[1]\t$row[2]\t$row[3]\t$row[4]\n");
	$i++;
	}
fclose($DATfp);

$rows_to_max = ($rows_to_print + 100);

$HTMcontent  = '';
$HTMcontent .= "#proc page\n";
$HTMcontent .= "#if @DEVICE in png,gif\n";
$HTMcontent .= "   scale: 0.6\n";
$HTMcontent .= "\n";
$HTMcontent .= "#endif\n";
$HTMcontent .= "#proc getdata\n";
$HTMcontent .= "file: $DOCroot/$DATfile\n";
$HTMcontent .= "fieldnames: time load processes channels recordings\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc areadef\n";
$HTMcontent .= "title: Server $group   $query_date_BEGIN to $query_date_END\n";
$HTMcontent .= "titledetails: size=14  align=C\n";
$HTMcontent .= "rectangle: 1 1 14 7\n";
$HTMcontent .= "xscaletype: time hh:mm:ss\n";
$HTMcontent .= "xrange: $time_BEGIN $time_END\n";
$HTMcontent .= "yrange: 0 $HIGHload\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc xaxis\n";
$HTMcontent .= "stubs: inc 30 minutes\n";
$HTMcontent .= "minorticinc: 5 minutes\n";
$HTMcontent .= "stubformat: hh:mm:ssa\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc yaxis\n";
$HTMcontent .= "stubs: inc 50\n";
$HTMcontent .= "grid: color=yellow\n";
$HTMcontent .= "gridskip: min\n";
$HTMcontent .= "ticincrement: 100 1000\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc curvefit\n";
$HTMcontent .= "xfield: time\n";
$HTMcontent .= "yfield: load\n";
$HTMcontent .= "linedetails: color=blue width=.5\n";
$HTMcontent .= "legendlabel: load\n";
$HTMcontent .= "maxinpoints: $rows_to_max\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc curvefit\n";
$HTMcontent .= "xfield: time\n";
$HTMcontent .= "yfield: processes\n";
$HTMcontent .= "linedetails: color=red width=.5\n";
$HTMcontent .= "legendlabel: processes\n";
$HTMcontent .= "maxinpoints: $rows_to_max\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc curvefit\n";
$HTMcontent .= "xfield: time\n";
$HTMcontent .= "yfield: channels\n";
$HTMcontent .= "linedetails: color=green width=.5\n";
$HTMcontent .= "legendlabel: channels\n";
$HTMcontent .= "maxinpoints: $rows_to_max\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc curvefit\n";
$HTMcontent .= "xfield: time\n";
$HTMcontent .= "yfield: recordings\n";
$HTMcontent .= "linedetails: color=purple width=.5\n";
$HTMcontent .= "legendlabel: recordings\n";
$HTMcontent .= "maxinpoints: $rows_to_max\n";
$HTMcontent .= "\n";
$HTMcontent .= "#proc legend\n";
$HTMcontent .= "location: max-2 max\n";
$HTMcontent .= "seglen: 0.2\n";
$HTMcontent .= "\n";

fwrite ($HTMfp, "$HTMcontent");
fclose($HTMfp);


passthru("/usr/local/bin/pl -png $DOCroot/$HTMfile -o $DOCroot/$PNGfile");

sleep(1);

echo "</PRE>\n";
echo "\n";
echo "<IMG SRC=\"./ploticus/$PNGfile\">\n";


}



?>

</BODY></HTML>