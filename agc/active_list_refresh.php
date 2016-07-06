<?
### active_list_refresh.php

### This script is designed purely to serve updates of the live data to the display scripts
### This script depends on the server_ip being sent and also needs to have a valid user/pass from the vicidial_users table
### 
### required variables:
###  - $server_ip
###  - $session_name
###  - $PHP_AUTH_USER
###  - $PHP_AUTH_PW
### optional variables:
###  - $ADD - ('1','2','3','4','5')
###  - $order - ('asc','desc')
###  - $format - ('text','table','menu','selectlist','textarea')
###  - $bgcolor - ('#123456','white','black','etc...')
###  - $txtcolor - ('#654321','black','white','etc...')
###  - $txtsize - ('1','2','3','etc...')
###  - $selectsize - ('2','3','4','etc...')
###  - $selectfontsize - ('8','10','12','etc...')
###  - $selectedext - ('cc100')
###  - $selectedtrunk - ('Zap/25-1')
###  - $selectedlocal - ('SIP/cc100')
###  - $textareaheight - ('8','10','12','etc...')
###  - $textareawidth - ('8','10','12','etc...')
###  - $field_name - ('extension','busyext','extension_xfer','etc...')
### 

# changes
# 50323-1147 First build of script
# 50401-1132 small formatting changes
# 50502-1402 added field_name as modifiable variable
# 50503-1213 added session_name checking for extra security
# 50503-1311 added conferences list
# 50610-1155 Added NULL check on MySQL results to reduced errors
#


require("dbconnect.php");

require_once("htglobalize.php");

### If you have globals turned off uncomment these lines
$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$server_ip=$_GET["server_ip"];			if (!$server_ip) {$server_ip=$_POST["server_ip"];}
$session_name=$_GET["session_name"];	if (!$session_name) {$session_name=$_POST["session_name"];}
$ADD=$_GET["ADD"];						if (!$ADD) {$ADD=$_POST["ADD"];}
$order=$_GET["order"];					if (!$order) {$order=$_POST["order"];}
$format=$_GET["format"];				if (!$format) {$format=$_POST["format"];}
$bgcolor=$_GET["bgcolor"];				if (!$bgcolor) {$bgcolor=$_POST["bgcolor"];}
$txtcolor=$_GET["txtcolor"];			if (!$txtcolor) {$txtcolor=$_POST["txtcolor"];}
$txtsize=$_GET["txtsize"];				if (!$txtsize) {$txtsize=$_POST["txtsize"];}
$selectsize=$_GET["selectsize"];		if (!$selectsize) {$selectsize=$_POST["selectsize"];}
$selectfontsize=$_GET["selectfontsize"];		if (!$selectfontsize) {$selectfontsize=$_POST["selectfontsize"];}
$selectedext=$_GET["selectedext"];		if (!$selectedext) {$selectedext=$_POST["selectedext"];}
$selectedtrunk=$_GET["selectedtrunk"];	if (!$selectedtrunk) {$selectedtrunk=$_POST["selectedtrunk"];}
$selectedlocal=$_GET["selectedlocal"];	if (!$selectedlocal) {$selectedlocal=$_POST["selectedlocal"];}
$textareaheight=$_GET["textareaheight"];		if (!$textareaheight) {$textareaheight=$_POST["textareaheight"];}
$textareawidth=$_GET["textareawidth"];		if (!$textareawidth) {$textareawidth=$_POST["textareawidth"];}
$field_name=$_GET["field_name"];		if (!$field_name) {$field_name=$_POST["field_name"];}

# default optional vars if not set
if (!$ADD)	{$ADD="1";}
if (!$order) {$order='desc';}
if (!$format) {$format='table';}
if (!$bgcolor) {$bgcolor='white';}
if (!$txtcolor) {$txtcolor='black';}
if (!$txtsize) {$txtsize='2';}
if (!$selectsize) {$selectsize='4';}
if (!$selectfontsize) {$selectfontsize='10';}
if (!$textareaheight) {$textareaheight='10';}
if (!$textareawidth) {$textareawidth='20';}


$version = '0.0.5';
$build = '50610-1155';
$STARTtime = date("U");
$NOW_DATE = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
if (!$query_date) {$query_date = $NOW_DATE;}

	$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 0;";
	if ($DB) {echo "|$stmt|\n";}
	$rslt=mysql_query($stmt, $link);
	$row=mysql_fetch_row($rslt);
	$auth=$row[0];

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
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
			Header("WWW-Authenticate: Basic realm=\"VICI-PROJECTS\"");
			Header("HTTP/1.0 401 Unauthorized");
			echo "Invalid session_name: |$session_name|$server_ip|\n";
			exit;
			}
		  else
			{
			# do nothing for now
			}
		}
	}

if ($format=='table')
{
echo "<html>\n";
echo "<head>\n";
echo "<!-- VERSION: $version     BUILD: $build    ADD: $ADD   server_ip: $server_ip-->\n";
echo "<title>List Display: ";
if ($ADD==1)		{echo "Live Extensions";}
if ($ADD==2)		{echo "Busy Extensions";}
if ($ADD==3)		{echo "Outside Lines";}
if ($ADD==4)		{echo "Local Extensions";}
if ($ADD==5)		{echo "Conferences";}
if ($ADD==99999)	{echo "HELP";}
echo "</title>\n";
echo "</head>\n";
echo "<BODY BGCOLOR=white marginheight=0 marginwidth=0 leftmargin=0 topmargin=0>\n";
}





######################
# ADD=1 display all live extensions on a server
######################
if ($ADD==1)
{
	$pt='pt';
	if (!$field_name) {$field_name = 'extension';}
	if ($format=='table') {echo "<TABLE WIDTH=120 BGCOLOR=$bgcolor cellpadding=0 cellspacing=0>\n";}
	if ($format=='menu') {echo "<SELECT SIZE=1 name=\"$field_name\">\n";}
	if ($format=='selectlist') 
		{
		echo "<SELECT SIZE=$selectsize name=\"$field_name\" STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">\n";
		}
	if ($format=='textarea') 
		{
		echo "<TEXTAREA ROWS=$textareaheight COLS=$textareawidth NAME=extension WRAP=off STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">";
		}

	$stmt="SELECT extension,fullname FROM phones where server_ip = '$server_ip' order by extension $order";
		if ($format=='table') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$phones_to_print = mysql_num_rows($rslt);}
	$o=0;
	while ($phones_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if ($format=='table')
			{
			echo "<TR><TD ALIGN=LEFT NOWRAP><FONT FACE=\"ARIAL,HELVETICA\" COLOR=$txtcolor SIZE=$txtsize>";
			echo "$row[0] - $row[1]";
			echo "</TD></TR>\n";
			}
		if ( ($format=='text') or ($format=='textarea') )
			{
			echo "$row[0] - $row[1]\n";
			}
		if ( ($format=='menu') or ($format=='selectlist') )
			{
			echo "<OPTION ";
			if ($row[0]=="$selectedext") {echo "SELECTED ";}
			echo "VALUE=\"$row[0]\">";
			echo "$row[0] - $row[1]";
			echo "</OPTION>\n";
			}
		$o++;
	}

	if ($format=='table') {echo "</TABLE>\n";}
	if ($format=='menu') {echo "</SELECT>\n";}
	if ($format=='selectlist') {echo "</SELECT>\n";}
	if ($format=='textarea') {echo "</TEXTAREA>\n";}
}







######################
# ADD=2 display all busy extensions on a server
######################
if ($ADD==2)
{
	if (!$field_name) {$field_name = 'busyext';}
	if ($format=='table') {echo "<TABLE WIDTH=120 BGCOLOR=$bgcolor cellpadding=0 cellspacing=0>\n";}
	if ($format=='menu') {echo "<SELECT SIZE=1 name=\"$field_name\">\n";}
	if ($format=='selectlist') 
		{
		echo "<SELECT SIZE=$selectsize name=\"$field_name\" STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">\n";
		}
	if ($format=='textarea') 
		{
		echo "<TEXTAREA ROWS=$textareaheight COLS=$textareawidth NAME=extension WRAP=off STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">";
		}

	$stmt="SELECT extension FROM live_channels where server_ip = '$server_ip' order by extension $order";
		if ($format=='table') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$busys_to_print = mysql_num_rows($rslt);}
	$o=0;
	while ($busys_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if ($format=='table')
			{
			echo "<TR><TD ALIGN=LEFT NOWRAP><FONT FACE=\"ARIAL,HELVETICA\" COLOR=$txtcolor SIZE=$txtsize>";
			echo "$row[0]";
			echo "</TD></TR>\n";
			}
		if ( ($format=='text') or ($format=='textarea') )
			{
			echo "$row[0]\n";
			}
		if ( ($format=='menu') or ($format=='selectlist') )
			{
			echo "<OPTION ";
			if ($row[0]=="$selectedext") {echo "SELECTED ";}
			echo "VALUE=\"$row[0]\">";
			echo "$row[0]";
			echo "</OPTION>\n";
			}
		$o++;
	}

	if ($format=='table') {echo "</TABLE>\n";}
	if ($format=='menu') {echo "</SELECT>\n";}
	if ($format=='selectlist') {echo "</SELECT>\n";}
	if ($format=='textarea') {echo "</TEXTAREA>\n";}
}






######################
# ADD=3 display all busy outside lines(trunks) on a server
######################
if ($ADD==3)
{
	if (!$field_name) {$field_name = 'trunk';}
	if ($format=='table') {echo "<TABLE WIDTH=120 BGCOLOR=$bgcolor cellpadding=0 cellspacing=0>\n";}
	if ($format=='menu') {echo "<SELECT SIZE=1 name=\"$field_name\">\n";}
	if ($format=='selectlist') 
		{
		echo "<SELECT SIZE=$selectsize name=\"$field_name\" STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">\n";
		}
	if ($format=='textarea') 
		{
		echo "<TEXTAREA ROWS=$textareaheight COLS=$textareawidth NAME=extension WRAP=off STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">";
		}

	$stmt="SELECT channel, extension FROM live_channels where server_ip = '$server_ip' order by channel $order";
		if ($format=='table') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$busys_to_print = mysql_num_rows($rslt);}
	$o=0;
	while ($busys_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if ($format=='table')
			{
			echo "<TR><TD ALIGN=LEFT NOWRAP><FONT FACE=\"ARIAL,HELVETICA\" COLOR=$txtcolor SIZE=$txtsize>";
			echo "$row[0] - $row[1]";
			echo "</TD></TR>\n";
			}
		if ( ($format=='text') or ($format=='textarea') )
			{
			echo "$row[0] - $row[1]\n";
			}
		if ( ($format=='menu') or ($format=='selectlist') )
			{
			echo "<OPTION ";
			if ($row[0]=="$selectedtrunk") {echo "SELECTED ";}
			echo "VALUE=\"$row[0]\">";
			echo "$row[0] - $row[1]";
			echo "</OPTION>\n";
			}
		$o++;
	}

	if ($format=='table') {echo "</TABLE>\n";}
	if ($format=='menu') {echo "</SELECT>\n";}
	if ($format=='selectlist') {echo "</SELECT>\n";}
	if ($format=='textarea') {echo "</TEXTAREA>\n";}
}






######################
# ADD=4 display all busy Local lines on a server
######################
if ($ADD==4)
{
	if (!$field_name) {$field_name = 'local';}
	if ($format=='table') {echo "<TABLE WIDTH=120 BGCOLOR=$bgcolor cellpadding=0 cellspacing=0>\n";}
	if ($format=='menu') {echo "<SELECT SIZE=1 name=\"$field_name\">\n";}
	if ($format=='selectlist') 
		{
		echo "<SELECT SIZE=$selectsize name=\"$field_name\" STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">\n";
		}
	if ($format=='textarea') 
		{
		echo "<TEXTAREA ROWS=$textareaheight COLS=$textareawidth NAME=extension WRAP=off STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">";
		}

	$stmt="SELECT channel, extension FROM live_sip_channels where server_ip = '$server_ip' order by channel $order";
		if ($format=='table') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$busys_to_print = mysql_num_rows($rslt);}
	$o=0;
	while ($busys_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if ($format=='table')
			{
			echo "<TR><TD ALIGN=LEFT NOWRAP><FONT FACE=\"ARIAL,HELVETICA\" COLOR=$txtcolor SIZE=$txtsize>";
			echo "$row[0] - $row[1]";
			echo "</TD></TR>\n";
			}
		if ( ($format=='text') or ($format=='textarea') )
			{
			echo "$row[0] - $row[1]\n";
			}
		if ( ($format=='menu') or ($format=='selectlist') )
			{
			echo "<OPTION ";
			if ($row[0]=="$selectedlocal") {echo "SELECTED ";}
			echo "VALUE=\"$row[0]\">";
			echo "$row[0] - $row[1]";
			echo "</OPTION>\n";
			}
		$o++;
	}

	if ($format=='table') {echo "</TABLE>\n";}
	if ($format=='menu') {echo "</SELECT>\n";}
	if ($format=='selectlist') {echo "</SELECT>\n";}
	if ($format=='textarea') {echo "</TEXTAREA>\n";}
}






######################
# ADD=5 display all agc-usable conferences on a server
######################
if ($ADD==5)
{
	$pt='pt';
	if (!$field_name) {$field_name = 'conferences';}
	if ($format=='table') {echo "<TABLE WIDTH=120 BGCOLOR=$bgcolor cellpadding=0 cellspacing=0>\n";}
	if ($format=='menu') {echo "<SELECT SIZE=1 name=\"$field_name\">\n";}
	if ($format=='selectlist') 
		{
		echo "<SELECT SIZE=$selectsize name=\"$field_name\" STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">\n";
		}
	if ($format=='textarea') 
		{
		echo "<TEXTAREA ROWS=$textareaheight COLS=$textareawidth NAME=extension WRAP=off STYLE=\"font-family : sans-serif; font-size : $selectfontsize$pt\">";
		}

	$stmt="SELECT conf_exten,extension FROM conferences where server_ip = '$server_ip' order by conf_exten $order";
		if ($format=='table') {echo "\n<!-- $stmt -->";}
	$rslt=mysql_query($stmt, $link);
	if ($rslt) {$phones_to_print = mysql_num_rows($rslt);}
	$o=0;
	while ($phones_to_print > $o) {
		$row=mysql_fetch_row($rslt);
		if ($format=='table')
			{
			echo "<TR><TD ALIGN=LEFT NOWRAP><FONT FACE=\"ARIAL,HELVETICA\" COLOR=$txtcolor SIZE=$txtsize>";
			echo "$row[0] - $row[1]";
			echo "</TD></TR>\n";
			}
		if ( ($format=='text') or ($format=='textarea') )
			{
			echo "$row[0] - $row[1]\n";
			}
		if ( ($format=='menu') or ($format=='selectlist') )
			{
			echo "<OPTION ";
			if ($row[0]=="$selectedext") {echo "SELECTED ";}
			echo "VALUE=\"$row[0]\">";
			echo "$row[0] - $row[1]";
			echo "</OPTION>\n";
			}
		$o++;
	}

	if ($format=='table') {echo "</TABLE>\n";}
	if ($format=='menu') {echo "</SELECT>\n";}
	if ($format=='selectlist') {echo "</SELECT>\n";}
	if ($format=='textarea') {echo "</TEXTAREA>\n";}
}














$ENDtime = date("U");
$RUNtime = ($ENDtime - $STARTtime);
if ($format=='table') {echo "\n<!-- script runtime: $RUNtime seconds -->";}
if ($format=='table') {echo "\n</body>\n</html>\n";}
	
exit; 

?>





