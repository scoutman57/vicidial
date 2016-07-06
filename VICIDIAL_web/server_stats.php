<? 
### server_stats.php
### 
### Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
###
require("dbconnect.php");

$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$STARTtime = date("U");
if (!isset($query_date)) {$query_date = $NOW_DATE;}

$stmt="select * from servers;";
$rslt=mysql_query($stmt, $link);
if ($DB) {echo "$stmt\n";}
$servers_to_print = mysql_num_rows($rslt);
$i=0;
while ($i < $servers_to_print)
	{
	$row=mysql_fetch_row($rslt);
	$server_id[$i] =			$row[0];
	$server_description[$i] =	$row[1];
	$server_ip[$i] =			$row[2];
	$active[$i] =				$row[3];
	$i++;
	}
?>

<HTML>
<HEAD>

<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
<TITLE>VICIDIAL: Server Stats and Reports</TITLE></HEAD><BODY BGCOLOR=WHITE>
<FONT SIZE=2>
<H1>VICIDIAL: Server Stats and Reports</H1>
<UL>
<LI><a href="AST_timeonVDADall.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=2>TIME ON VDAD (per campaign)</a></FONT>
<LI><a href="AST_parkstats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=2>PARK REPORT</a></FONT>
<LI><a href="AST_VDADstats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=2>VDAD REPORT</a></FONT>
<LI><a href="AST_CLOSERstats.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=2>CLOSER REPORT</a></FONT>
<LI><a href="AST_agent_performance.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=2>AGENT PERFORMANCE</a></FONT>
<LI><a href="AST_agent_performance_detail.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=2>AGENT PERFORMANCE DETAIL</a></FONT>
<LI><a href="AST_server_performance.php"><FONT FACE="ARIAL,HELVETICA" COLOR=BLACK SIZE=2>SERVER PERFORMANCE</a></FONT>
</UL>

<PRE><TABLE BORDER=1>
<TR><TD>SERVER</TD><TD>DESCRIPTION</TD><TD>IP ADDRESS</TD><TD>ACTIVE</TD><TD>VDAD time</TD><TD>VDcall time</TD><TD>PARK time</TD><TD>CLOSER/INBOUND time</TD></TR>
<? 

	$o=0;
	while ($servers_to_print > $o)
	{
	echo "<TR>\n";
	echo "<TD>$server_id[$o]</TD>\n";
	echo "<TD>$server_description[$o]</TD>\n";
	echo "<TD>$server_ip[$o]</TD>\n";
	echo "<TD>$active[$o]</TD>\n";
	echo "<TD><a href=\"AST_timeonVDAD.php?server_ip=$server_ip[$o]\">LINK</a></TD>\n";
	echo "<TD><a href=\"AST_timeoncall.php?server_ip=$server_ip[$o]\">LINK</a></TD>\n";
	echo "<TD><a href=\"AST_timeonpark.php?server_ip=$server_ip[$o]\">LINK</a></TD>\n";
	echo "<TD><a href=\"AST_timeonVDAD_closer.php?server_ip=$server_ip[$o]\">LINK</a></TD>\n";
	echo "</TR>\n";
	$o++;
	}

?>
</TABLE>

</BODY></HTML>