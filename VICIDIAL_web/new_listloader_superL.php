<?
# new_listloader_superL.php
# 
# Copyright (C) 2006  Matt Florell,Joe Johnson <vicidial@gmail.com>    LICENSE: GPLv2
#
# AST GUI lead loader from formatted file
# 
# CHANGES
# 50602-1640 - First version created by Joe Johnson
# 51128-1108 - Removed PHP global vars requirement
# 60113-1603 - Fixed a few bugs in Excel import
# 60421-1624 - check GET/POST vars lines with isset to not trigger PHP NOTICES
#
# make sure vicidial_list exists and that your file follows the formatting correctly. This page does not dedupe or do any other lead filtering actions yet at this time.


require("dbconnect.php");

### links used for testing
#$link=mysql_connect("10.10.10.15", "cron", "1234");
#mysql_select_db("asterisk");
#$WeBServeRRooT = '/home/www/htdocs';

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
$leadfile=$_FILES["leadfile"];
	$LF_orig = $_FILES['leadfile']['name'];
	$LF_path = $_FILES['leadfile']['tmp_name'];
if (isset($_GET["submit_file"]))				{$submit_file=$_GET["submit_file"];}
	elseif (isset($_POST["submit_file"]))		{$submit_file=$_POST["submit_file"];}
if (isset($_GET["submit"]))				{$submit=$_GET["submit"];}
	elseif (isset($_POST["submit"]))		{$submit=$_POST["submit"];}
if (isset($_GET["SUBMIT"]))				{$SUBMIT=$_GET["SUBMIT"];}
	elseif (isset($_POST["SUBMIT"]))		{$SUBMIT=$_POST["SUBMIT"];}
if (isset($_GET["leadfile_name"]))				{$leadfile_name=$_GET["leadfile_name"];}
	elseif (isset($_POST["leadfile_name"]))		{$leadfile_name=$_POST["leadfile_name"];}
if (isset($_GET["file_layout"]))				{$file_layout=$_GET["file_layout"];}
	elseif (isset($_POST["file_layout"]))		{$file_layout=$_POST["file_layout"];}
if (isset($_GET["OK_to_process"]))				{$OK_to_process=$_GET["OK_to_process"];}
	elseif (isset($_POST["OK_to_process"]))		{$OK_to_process=$_POST["OK_to_process"];}
if (isset($_GET["vendor_lead_code_field"]))				{$vendor_lead_code_field=$_GET["vendor_lead_code_field"];}
	elseif (isset($_POST["vendor_lead_code_field"]))		{$vendor_lead_code_field=$_POST["vendor_lead_code_field"];}
if (isset($_GET["source_id_field"]))				{$source_id_field=$_GET["source_id_field"];}
	elseif (isset($_POST["source_id_field"]))		{$source_id_field=$_POST["source_id_field"];}
if (isset($_GET["list_id_field"]))				{$list_id_field=$_GET["list_id_field"];}
	elseif (isset($_POST["list_id_field"]))		{$list_id_field=$_POST["list_id_field"];}
if (isset($_GET["phone_code_field"]))				{$phone_code_field=$_GET["phone_code_field"];}
	elseif (isset($_POST["phone_code_field"]))		{$phone_code_field=$_POST["phone_code_field"];}
if (isset($_GET["phone_number_field"]))				{$phone_number_field=$_GET["phone_number_field"];}
	elseif (isset($_POST["phone_number_field"]))		{$phone_number_field=$_POST["phone_number_field"];}
if (isset($_GET["title_field"]))				{$title_field=$_GET["title_field"];}
	elseif (isset($_POST["title_field"]))		{$title_field=$_POST["title_field"];}
if (isset($_GET["first_name_field"]))				{$first_name_field=$_GET["first_name_field"];}
	elseif (isset($_POST["first_name_field"]))		{$first_name_field=$_POST["first_name_field"];}
if (isset($_GET["middle_initial_field"]))				{$middle_initial_field=$_GET["middle_initial_field"];}
	elseif (isset($_POST["middle_initial_field"]))		{$middle_initial_field=$_POST["middle_initial_field"];}
if (isset($_GET["last_name_field"]))				{$last_name_field=$_GET["last_name_field"];}
	elseif (isset($_POST["last_name_field"]))		{$last_name_field=$_POST["last_name_field"];}
if (isset($_GET["address1_field"]))				{$address1_field=$_GET["address1_field"];}
	elseif (isset($_POST["address1_field"]))		{$address1_field=$_POST["address1_field"];}
if (isset($_GET["address2_field"]))				{$address2_field=$_GET["address2_field"];}
	elseif (isset($_POST["address2_field"]))		{$address2_field=$_POST["address2_field"];}
if (isset($_GET["address3_field"]))				{$address3_field=$_GET["address3_field"];}
	elseif (isset($_POST["address3_field"]))		{$address3_field=$_POST["address3_field"];}
if (isset($_GET["city_field"]))				{$city_field=$_GET["city_field"];}
	elseif (isset($_POST["city_field"]))		{$city_field=$_POST["city_field"];}
if (isset($_GET["state_field"]))				{$state_field=$_GET["state_field"];}
	elseif (isset($_POST["state_field"]))		{$state_field=$_POST["state_field"];}
if (isset($_GET["province_field"]))				{$province_field=$_GET["province_field"];}
	elseif (isset($_POST["province_field"]))		{$province_field=$_POST["province_field"];}
if (isset($_GET["postal_code_field"]))				{$postal_code_field=$_GET["postal_code_field"];}
	elseif (isset($_POST["postal_code_field"]))		{$postal_code_field=$_POST["postal_code_field"];}
if (isset($_GET["country_code_field"]))				{$country_code_field=$_GET["country_code_field"];}
	elseif (isset($_POST["country_code_field"]))		{$country_code_field=$_POST["country_code_field"];}
if (isset($_GET["gender_field"]))				{$gender_field=$_GET["gender_field"];}
	elseif (isset($_POST["gender_field"]))		{$gender_field=$_POST["gender_field"];}
if (isset($_GET["date_of_birth_field"]))				{$date_of_birth_field=$_GET["date_of_birth_field"];}
	elseif (isset($_POST["date_of_birth_field"]))		{$date_of_birth_field=$_POST["date_of_birth_field"];}
if (isset($_GET["alt_phone_field"]))				{$alt_phone_field=$_GET["alt_phone_field"];}
	elseif (isset($_POST["alt_phone_field"]))		{$alt_phone_field=$_POST["alt_phone_field"];}
if (isset($_GET["email_field"]))				{$email_field=$_GET["email_field"];}
	elseif (isset($_POST["email_field"]))		{$email_field=$_POST["email_field"];}
if (isset($_GET["security_phrase_field"]))				{$security_phrase_field=$_GET["security_phrase_field"];}
	elseif (isset($_POST["security_phrase_field"]))		{$security_phrase_field=$_POST["security_phrase_field"];}
if (isset($_GET["comments_field"]))				{$comments_field=$_GET["comments_field"];}
	elseif (isset($_POST["comments_field"]))		{$comments_field=$_POST["comments_field"];}

# $country_field=$_GET["country_field"];					if (!$country_field) {$country_field=$_POST["country_field"];}
$version = '1.1.11';
$build = '60421-1624';


$STARTtime = date("U");
$TODAY = date("Y-m-d");
$NOW_TIME = date("Y-m-d H:i:s");
$FILE_datetime = $STARTtime;

$stmt="SELECT count(*) from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW' and user_level > 7;";
if ($DB) {echo "|$stmt|\n";}
$rslt=mysql_query($stmt, $link);
$row=mysql_fetch_row($rslt);
$auth=$row[0];

$fp = fopen ("./project_auth_entries.txt", "a");
$date = date("r");
$ip = getenv("REMOTE_ADDR");
$browser = getenv("HTTP_USER_AGENT");

  if( (strlen($PHP_AUTH_USER)<2) or (strlen($PHP_AUTH_PW)<2) or (!$auth))
	{
    Header("WWW-Authenticate: Basic realm=\"VICIDIAL-LEAD-LOADER\"");
    Header("HTTP/1.0 401 Unauthorized");
    echo "Invalid Username/Password: |$PHP_AUTH_USER|$PHP_AUTH_PW|\n";
    exit;
	}
  else
	{
	header ("Content-type: text/html; charset=utf-8");
	if($auth>0)
		{
		$office_no=strtoupper($PHP_AUTH_USER);
		$password=strtoupper($PHP_AUTH_PW);
			$stmt="SELECT load_leads from vicidial_users where user='$PHP_AUTH_USER' and pass='$PHP_AUTH_PW'";
			$rslt=mysql_query($stmt, $link);
			$row=mysql_fetch_row($rslt);
			$LOGload_leads				=$row[0];

		if ($LOGload_leads < 1)
			{
			echo "You do not have permissions to load leads\n";
			exit;
			}
		fwrite ($fp, "LIST_LOAD|GOOD|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|$LOGfullname|\n");
		fclose($fp);
		}
	else
		{
		fwrite ($fp, "LIST_LOAD|FAIL|$date|$PHP_AUTH_USER|$PHP_AUTH_PW|$ip|$browser|\n");
		fclose($fp);
		}
	}


$script_name = getenv("SCRIPT_NAME");
$server_name = getenv("SERVER_NAME");
$server_port = getenv("SERVER_PORT");
if (eregi("443",$server_port)) {$HTTPprotocol = 'https://';}
  else {$HTTPprotocol = 'http://';}
$admDIR = "$HTTPprotocol$server_name$script_name";
$admDIR = eregi_replace('new_listloader_superL.php','',$admDIR);
$admSCR = 'admin.php';
$NWB = " &nbsp; <a href=\"javascript:openNewWindow('$admDIR$admSCR?ADD=99999";
$NWE = "')\"><IMG SRC=\"help.gif\" WIDTH=20 HEIGHT=20 BORDER=0 ALT=\"HELP\" ALIGN=TOP></A>";

echo "<html>\n";
echo "<head>\n";
echo "<!-- VERSION: $version     BUILD: $build -->\n";

function macfontfix($fontsize) {

  $browser = getenv("HTTP_USER_AGENT");
  $pctype = explode("(", $browser);
  if (ereg("Mac",$pctype[1])) {
   /* Browser is a Mac.  If not Netscape 6, raise fonts */

    $blownbrowser = explode('/', $browser);
    $ver = explode(' ', $blownbrowser[1]);
    $ver = $ver[0];
    if ($ver >= 5.0) return $fontsize; else return ($fontsize+2);

  } else return $fontsize;	/* Browser is not a Mac - don't touch fonts */
}

echo "<style type=\"text/css\">\n
<!--\n
.title {  font-family: Arial, Helvetica, sans-serif; font-size: ".macfontfix(18)."pt}\n
.standard {  font-family: Arial, Helvetica, sans-serif; font-size: ".macfontfix(10)."pt}\n
.small_standard {  font-family: Arial, Helvetica, sans-serif; font-size: ".macfontfix(8)."pt}\n
.tiny_standard {  font-family: Arial, Helvetica, sans-serif; font-size: ".macfontfix(6)."pt}\n
.standard_bold {  font-family: Arial, Helvetica, sans-serif; font-size: ".macfontfix(10)."pt; font-weight: bold}\n
.standard_header {  font-family: Arial, Helvetica, sans-serif; font-size: ".macfontfix(14)."pt; font-weight: bold}\n
.standard_bold_highlight {  font-family: Arial, Helvetica, sans-serif; font-size: ".macfontfix(10)."pt; font-weight: bold; color: white; BACKGROUND-COLOR: black}\n
.standard_bold_blue_highlight {  font-family: Arial, Helvetica, sans-serif; font-size: 10pt; font-weight: bold; BACKGROUND-COLOR: blue}\n
A.employee_standard {  font-family: garamond, sans-serif; font-size: ".macfontfix(10)."pt; font-style: normal; font-variant: normal; font-weight: bold; text-decoration: none}\n
.employee_standard {  font-family: garamond, sans-serif; font-size: ".macfontfix(10)."pt; font-weight: bold}\n
.employee_title {  font-family: Garamond, sans-serif; font-size: ".macfontfix(14)."pt; font-weight: bold}\n
\\\\-->\n
</style>\n";

?>


<script language="JavaScript1.2">
function openNewWindow(url) {
  window.open (url,"",'width=500,height=300,scrollbars=yes,menubar=yes,address=yes');
}
function ShowProgress(good, bad, total) {
	parent.lead_count.document.open();
	parent.lead_count.document.write('<html><body><table border=0 width=200 cellpadding=10 cellspacing=0 align=center valign=top><tr bgcolor="#000000"><th colspan=2><font face="arial, helvetica" size=3 color=white>Current file status:</font></th></tr><tr bgcolor="#009900"><td align=right><font face="arial, helvetica" size=2 color=white><B>Good:</B></font></td><td align=left><font face="arial, helvetica" size=2 color=white><B>'+good+'</B></font></td></tr><tr bgcolor="#990000"><td align=right><font face="arial, helvetica" size=2 color=white><B>Bad:</B></font></td><td align=left><font face="arial, helvetica" size=2 color=white><B>'+bad+'</B></font></td></tr><tr bgcolor="#000099"><td align=right><font face="arial, helvetica" size=2 color=white><B>Total:</B></font></td><td align=left><font face="arial, helvetica" size=2 color=white><B>'+total+'</B></font></td></tr></table><body></html>');
	parent.lead_count.document.close();
}
function ParseFileName() {
	if (!document.forms[0].OK_to_process) {	
		var endstr=document.forms[0].leadfile.value.lastIndexOf('\\');
		if (endstr>-1) {
			endstr++;
			var filename=document.forms[0].leadfile.value.substring(endstr);
			document.forms[0].leadfile_name.value=filename;
		}
	}
}
</script>
<title>VICIDIAL ADMIN: Super Lead Loader</title>
</head>
<body>
<form action=<?=$PHP_SELF ?> method=post onSubmit="ParseFileName()" enctype="multipart/form-data">
<input type=hidden name='leadfile_name' value="<?=$leadfile_name ?>">
<? if ($file_layout!="custom") { ?>
<table align=center width="500" border=0 cellpadding=5 cellspacing=0 bgcolor=#D9E6FE>
  <tr>
	<td align=right width="35%"><B><font face="arial, helvetica" size=2>Load leads from this file:</font></B></td>
	<td align=left width="65%"><input type=file name="leadfile" value="<?=$leadfile ?>"> <? echo "$NWB#vicidial_list_loader$NWE"; ?></td>
  </tr>
  <tr>
	<td align=right><B><font face="arial, helvetica" size=2>File layout to use:</font></B></td>
	<td align=left><font face="arial, helvetica" size=2><input type=radio name="file_layout" value="standard" checked>Standard VICIDIAL&nbsp;&nbsp;&nbsp;&nbsp;<input type=radio name="file_layout" value="custom">Custom layout</td>
  </tr>
  <tr>
	<td align=center colspan=2><input type=submit value="SUBMIT" name='submit_file'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type=button onClick="javascript:document.location='new_listloader_superL.php'" value="START OVER" name='reload_page'></td>
  </tr>
  <tr><td colspan=2><font size=1><a href="listloaderMAIN.php" target="_parent">CLICK HERE TO GO TO THE BASIC LEAD LOADER </a> &nbsp; &nbsp; &nbsp; &nbsp; <a href="admin.php" target="_parent">BACK TO ADMIN</a></font></td></tr>
  <tr><td colspan=2><font size=1>SUPER LIST LOADER- &nbsp; &nbsp; VERSION: <?=$version ?> &nbsp; &nbsp; BUILD: <?=$build ?></td></tr>
</table>
<? } ?>

<?

	if ($OK_to_process) {
		print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=true; document.forms[0].submit_file.disabled=true; document.forms[0].reload_page.disabled=true;</script>";
		flush();
		$total=0; $good=0; $bad=0;

		if (!eregi(".csv", $leadfile_name) && !eregi(".xls", $leadfile_name)) {
			# copy($leadfile, "./vicidial_temp_file.txt");
			$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.txt", "r");
			$stmt_file=fopen("listloader_stmts.txt", "w");

			$buffer=fgets($file, 4096);
			$tab_count=substr_count($buffer, "\t");
			$pipe_count=substr_count($buffer, "|");

			if ($tab_count>$pipe_count) {$delimiter="\t";  $delim_name="tab";} else {$delimiter="|";  $delim_name="pipe";}
			$field_check=explode($delimiter, $buffer);

			if (count($field_check)>=5) {
				flush();
				$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.txt", "r");
				print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing $delim_name-delimited file...\n";
				while (!feof($file)) {
					$record++;
					$buffer=rtrim(fgets($file, 4096));
					$buffer=stripslashes($buffer);

					if (strlen($buffer)>0) {
						$row=explode($delimiter, eregi_replace("[\'\"]", "", $buffer));

						$pulldate=date("Y-m-d H:i:s");
						$entry_date =			"$pulldate";
						$modify_date =			"";
						$status =				"NEW";
						$user ="";
						$vendor_lead_code =		$row[$vendor_lead_code_field];
						$source_code =			$row[$source_id_field];
						$source_id=$source_code;
						$list_id =				$row[$list_id_field];
						$campaign_id =			'';
						$called_since_last_reset='N';
						$phone_code =			eregi_replace("[^0-9]", "", $row[$phone_code_field]);
						$phone_number =			eregi_replace("[^0-9]", "", $row[$phone_number_field]);
						$title =				$row[$title_field];
						$first_name =			$row[$first_name_field];
						$middle_initial =		$row[$middle_initial_field];
						$last_name =			$row[$last_name_field];
						$address1 =				$row[$address1_field];
						$address2 =				$row[$address2_field];
						$address3 =				$row[$address3_field];
						$city =$row[$city_field];
						$state =				$row[$state_field];
						$province =				$row[$province_field];
						$postal_code =			$row[$postal_code_field];
						$country_code =				$row[$country_code_field];
						$gender =				$row[$gender_field];
						$date_of_birth =		$row[$date_of_birth_field];
						$alt_phone =			$row[$alt_phone_field];
						$email =				$row[$email_field];
						$security_phrase =		$row[$security_phrase_field];
						$comments =				trim($row[$comments_field]);

						if (strlen($phone_number)>8) {

							if ($multi_insert_counter > 8) {
								### insert good deal into pending_transactions table ###
								$stmtZ = "INSERT INTO vicidial_list values$multistmt('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0);";
								$rslt=mysql_query($stmtZ, $link);
								if ($WeBRooTWritablE > 0) 
									{fwrite($stmt_file, $stmtZ."\r\n");}
								$multistmt='';
								$multi_insert_counter=0;

							} else {
								$multistmt .= "('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0),";
								$multi_insert_counter++;
							}

							$good++;
						} else {
							if ($bad < 10) {print "<BR></b><font size=1 color=red>record $total BAD- PHONE: $phone_number ROW: |$row[0]|</font><b>\n";}
							$bad++;
						}
						$total++;
						if ($total%100==0) {
							print "<script language='JavaScript1.2'>ShowProgress($good, $bad, $total)</script>";
							usleep(1000);
							flush();
						}
					}
				}
				if ($multi_insert_counter!=0) {
					$stmtZ = "INSERT INTO vicidial_list values".substr($multistmt, 0, -1).";";
					mysql_query($stmtZ, $link);
					if ($WeBRooTWritablE > 0) 
						{fwrite($stmt_file, $stmtZ."\r\n");}
				}

				print "<BR><BR>Done</B> GOOD: $good &nbsp; &nbsp; &nbsp; BAD: $bad &nbsp; &nbsp; &nbsp; TOTAL: $total</font></center>";

			} else {
				print "<center><font face='arial, helvetica' size=3 color='#990000'><B>ERROR: The file does not have the required number of fields to process it.</B></font></center>";
			}
		} else if (!eregi(".csv", $leadfile_name)) {
			# copy($leadfile, "./vicidial_temp_file.xls");
			$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.xls", "r");

			print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing Excel file... \n";
			# print "$WeBServeRRooT/vicidial/listloader_super.pl $vendor_lead_code_field,$source_id_field,$list_id_field,$phone_code_field,$phone_number_field,$title_field,$first_name_field,$middle_initial_field,$last_name_field,$address1_field,$address2_field,$address3_field,$city_field,$state_field,$province_field,$postal_code_field,$country_code_field,$gender_field,$date_of_birth_field,$alt_phone_field,$email_field,$security_phrase_field,$comments_field";
			passthru("$WeBServeRRooT/vicidial/listloader_super.pl $vendor_lead_code_field,$source_id_field,$list_id_field,$phone_code_field,$phone_number_field,$title_field,$first_name_field,$middle_initial_field,$last_name_field,$address1_field,$address2_field,$address3_field,$city_field,$state_field,$province_field,$postal_code_field,$country_code_field,$gender_field,$date_of_birth_field,$alt_phone_field,$email_field,$security_phrase_field,$comments_field");
		} else {
			# copy($leadfile, "./vicidial_temp_file.csv");
			$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.csv", "r");
			$stmt_file=fopen("listloader_stmts.txt", "w");
			
			print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing CSV file... \n";

			while($row=fgetcsv($file, 1000, ",")) {

				$pulldate=date("Y-m-d H:i:s");
				$entry_date =			"$pulldate";
				$modify_date =			"";
				$status =				"NEW";
				$user ="";
				$vendor_lead_code =		$row[$vendor_lead_code_field];
				$source_code =			$row[$source_id_field];
				$source_id=$source_code;
				$list_id =				$row[$list_id_field];
				$campaign_id =			'';
				$called_since_last_reset='N';
				$phone_code =			eregi_replace("[^0-9]", "", $row[$phone_code_field]);
				$phone_number =			eregi_replace("[^0-9]", "", $row[$phone_number_field]);
				$title =				$row[$title_field];
				$first_name =			$row[$first_name_field];
				$middle_initial =		$row[$middle_initial_field];
				$last_name =			$row[$last_name_field];
				$address1 =				$row[$address1_field];
				$address2 =				$row[$address2_field];
				$address3 =				$row[$address3_field];
				$city =$row[$city_field];
				$state =				$row[$state_field];
				$province =				$row[$province_field];
				$postal_code =			$row[$postal_code_field];
				$country_code =				$row[$country_code_field];
				$gender =				$row[$gender_field];
				$date_of_birth =		$row[$date_of_birth_field];
				$alt_phone =			$row[$alt_phone_field];
				$email =				$row[$email_field];
				$security_phrase =		$row[$security_phrase_field];
				$comments =				trim($row[$comments_field]);

				if (strlen($phone_number)>8) {
					if ($multi_insert_counter > 8) {
						### insert good deal into pending_transactions table ###
						$stmtZ = "INSERT INTO vicidial_list values$multistmt('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0);";
						$rslt=mysql_query($stmtZ, $link);
						if ($WeBRooTWritablE > 0) 
							{fwrite($stmt_file, $stmtZ."\r\n");}
						$multistmt='';
						$multi_insert_counter=0;

					} else {
						$multistmt .= "('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0),";
						$multi_insert_counter++;
					}

					$good++;
				} else {
					if ($bad < 10) {print "<BR></b><font size=1 color=red>record $total BAD- PHONE: $phone_number ROW: |$row[0]|</font><b>\n";}
					$bad++;
				}
				$total++;
				if ($total%100==0) {
					print "<script language='JavaScript1.2'>ShowProgress($good, $bad, $total)</script>";
					usleep(1000);
					flush();
				}
			}
			if ($multi_insert_counter!=0) {
				$stmtZ = "INSERT INTO vicidial_list values".substr($multistmt, 0, -1).";";
				mysql_query($stmtZ, $link);
				if ($WeBRooTWritablE > 0) 
					{fwrite($stmt_file, $stmtZ."\r\n");}
			}
			print "<BR><BR>Done</B> GOOD: $good &nbsp; &nbsp; &nbsp; BAD: $bad &nbsp; &nbsp; &nbsp; TOTAL: $total</font></center>";
		}
		print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=false; document.forms[0].submit_file.disabled=false; document.forms[0].reload_page.disabled=false;</script>";
	} 

if ($leadfile && filesize($LF_path)<=8388608) {
		$total=0; $good=0; $bad=0;
		if ($file_layout=="standard") {

	print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=true; document.forms[0].submit_file.disabled=true; document.forms[0].reload_page.disabled=true;</script>";
	flush();

	if (!eregi(".csv", $leadfile_name) && !eregi(".xls", $leadfile_name)) {

		copy($LF_path, "$WeBServeRRooT/vicidial/vicidial_temp_file.txt");
		$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.txt", "r");
		if ($WeBRooTWritablE > 0) 
			{$stmt_file=fopen("$WeBServeRRooT/vicidial/listloader_stmts.txt", "w");}

		$buffer=fgets($file, 4096);
		$tab_count=substr_count($buffer, "\t");
		$pipe_count=substr_count($buffer, "|");

		if ($tab_count>$pipe_count) {$delimiter="\t";  $delim_name="tab";} else {$delimiter="|";  $delim_name="pipe";}
		$field_check=explode($delimiter, $buffer);

		if (count($field_check)>=5) {
			flush();
			$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.txt", "r");
			$total=0; $good=0; $bad=0;
			print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing $delim_name-delimited file... ($tab_count|$pipe_count)\n";
			while (!feof($file)) {
				$record++;
				$buffer=rtrim(fgets($file, 4096));
				$buffer=stripslashes($buffer);

				if (strlen($buffer)>0) {
					$row=explode($delimiter, eregi_replace("[\'\"]", "", $buffer));

					$pulldate=date("Y-m-d H:i:s");
					$entry_date =			"$pulldate";
					$modify_date =			"";
					$status =				"NEW";
					$user ="";
					$vendor_lead_code =		$row[0];
					$source_code =			$row[1];
					$source_id=$source_code;
					$list_id =				$row[2];
					$campaign_id =			'';
					$called_since_last_reset='N';
					$phone_code =			eregi_replace("[^0-9]", "", $row[3]);
					$phone_number =			eregi_replace("[^0-9]", "", $row[4]);
					$title =				$row[5];
					$first_name =			$row[6];
					$middle_initial =		$row[7];
					$last_name =			$row[8];
					$address1 =				$row[9];
					$address2 =				$row[10];
					$address3 =				$row[11];
					$city =$row[12];
					$state =				$row[13];
					$province =				$row[14];
					$postal_code =			$row[15];
					$country_code =				$row[16];
					$gender =				$row[17];
					$date_of_birth =		$row[18];
					$alt_phone =			$row[19];
					$email =				$row[20];
					$security_phrase =		$row[21];
					$comments =				trim($row[22]);

					if (strlen($phone_number)>8) {

						if ($multi_insert_counter > 8) {
							### insert good deal into pending_transactions table ###
							$stmtZ = "INSERT INTO vicidial_list values$multistmt('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0);";
							$rslt=mysql_query($stmtZ, $link);
							if ($WeBRooTWritablE > 0) 
								{fwrite($stmt_file, $stmtZ."\r\n");}
							$multistmt='';
							$multi_insert_counter=0;

						} else {
							$multistmt .= "('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0),";
							$multi_insert_counter++;
						}

						$good++;
					} else {
						if ($bad < 10) {print "<BR></b><font size=1 color=red>record $total BAD- PHONE: $phone_number ROW: |$row[0]|</font><b>\n";}
						$bad++;
					}
					$total++;
					if ($total%100==0) {
						print "<script language='JavaScript1.2'>ShowProgress($good, $bad, $total)</script>";
						usleep(1000);
						flush();
					}
				}
			}
			if ($multi_insert_counter!=0) {
				$stmtZ = "INSERT INTO vicidial_list values".substr($multistmt, 0, -1).";";
				mysql_query($stmtZ, $link);
				if ($WeBRooTWritablE > 0) 
					{fwrite($stmt_file, $stmtZ."\r\n");}
			}

			print "<BR><BR>Done</B> GOOD: $good &nbsp; &nbsp; &nbsp; BAD: $bad &nbsp; &nbsp; &nbsp; TOTAL: $total</font></center>";

		} else {
			print "<center><font face='arial, helvetica' size=3 color='#990000'><B>ERROR: The file does not have the required number of fields to process it.</B></font></center>";
		}
	} else if (!eregi(".csv", $leadfile_name)) {
		copy($LF_path, "$WeBServeRRooT/vicidial/vicidial_temp_file.xls");
		$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.xls", "r");

		passthru("$WeBServeRRooT/vicidial/listloader.pl");
	} else {
		copy($LF_path, "$WeBServeRRooT/vicidial/vicidial_temp_file.csv");
		$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.csv", "r");
		$stmt_file=fopen("listloader_stmts.txt", "w");
		
		print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing CSV file... \n";

		while($row=fgetcsv($file, 1000, ",")) {
				$pulldate=date("Y-m-d H:i:s");
				$entry_date =			"$pulldate";
				$modify_date =			"";
				$status =				"NEW";
				$user ="";
				$vendor_lead_code =		$row[0];
				$source_code =			$row[1];
				$source_id=$source_code;
				$list_id =				$row[2];
				$campaign_id =			'';
				$called_since_last_reset='N';
				$phone_code =			eregi_replace("[^0-9]", "", $row[3]);
				$phone_number =			eregi_replace("[^0-9]", "", $row[4]);
				$title =				$row[5];
				$first_name =			$row[6];
				$middle_initial =		$row[7];
				$last_name =			$row[8];
				$address1 =				$row[9];
				$address2 =				$row[10];
				$address3 =				$row[11];
				$city =$row[12];
				$state =				$row[13];
				$province =				$row[14];
				$postal_code =			$row[15];
				$country_code =				$row[16];
				$gender =				$row[17];
				$date_of_birth =		$row[18];
				$alt_phone =			$row[19];
				$email =				$row[20];
				$security_phrase =		$row[21];
				$comments =				trim($row[22]);

				if (strlen($phone_number)>8) {
					if ($multi_insert_counter > 8) {
						### insert good deal into pending_transactions table ###
						$stmtZ = "INSERT INTO vicidial_list values$multistmt('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0);";
						$rslt=mysql_query($stmtZ, $link);
						if ($WeBRooTWritablE > 0) 
							{fwrite($stmt_file, $stmtZ."\r\n");}
						$multistmt='';
						$multi_insert_counter=0;

					} else {
						$multistmt .= "('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0),";
						$multi_insert_counter++;
					}

					$good++;
				} else {
					if ($bad < 10) {print "<BR></b><font size=1 color=red>record $total BAD- PHONE: $phone_number ROW: |$row[0]|</font><b>\n";}
					$bad++;
				}
				$total++;
				if ($total%100==0) {
					print "<script language='JavaScript1.2'>ShowProgress($good, $bad, $total)</script>";
					usleep(1000);
					flush();
				}
			}
			if ($multi_insert_counter!=0) {
				$stmtZ = "INSERT INTO vicidial_list values".substr($multistmt, 0, -1).";";
				mysql_query($stmtZ, $link);
				if ($WeBRooTWritablE > 0) 
					{fwrite($stmt_file, $stmtZ."\r\n");}
			}

			print "<BR><BR>Done</B> GOOD: $good &nbsp; &nbsp; &nbsp; BAD: $bad &nbsp; &nbsp; &nbsp; TOTAL: $total</font></center>";

		}
		print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=false; document.forms[0].submit_file.disabled=false; document.forms[0].reload_page.disabled=false;</script>";

		} else {
			print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=true; document.forms[0].submit_file.disabled=true; document.forms[0].reload_page.disabled=true;</script><HR>";
			flush();
			print "<table border=0 cellpadding=3 cellspacing=0 width=500 align=center>\r\n";
			print "  <tr bgcolor='#330099'>\r\n";
			print "    <th align=right><font class='standard' color='white'>VICIDIAL Column</font></th>\r\n";
			print "    <th><font class='standard' color='white'>File data</font></th>\r\n";
			print "  </tr>\r\n";

			$tbl_rslt=mysql_query("select vendor_lead_code, source_id, list_id, phone_code, phone_number, title, first_name, middle_initial, last_name, address1, address2, address3, city, state, province, postal_code, country_code, gender, date_of_birth, alt_phone, email, security_phrase, comments from vicidial_list limit 1", $link);
			

			if (!eregi(".csv", $leadfile_name) && !eregi(".xls", $leadfile_name)) {
				copy($LF_path, "$WeBServeRRooT/vicidial/vicidial_temp_file.txt");
				$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.txt", "r");
				$stmt_file=fopen("listloader_stmts.txt", "w");

				$buffer=fgets($file, 4096);
				$tab_count=substr_count($buffer, "\t");
				$pipe_count=substr_count($buffer, "|");

				if ($tab_count>$pipe_count) {$delimiter="\t";  $delim_name="tab";} else {$delimiter="|";  $delim_name="pipe";}
				$field_check=explode($delimiter, $buffer);
				flush();
				$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.txt", "r");
				print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing $delim_name-delimited file...\n";

				$buffer=rtrim(fgets($file, 4096));
				$buffer=stripslashes($buffer);
				$row=explode($delimiter, eregi_replace("[\'\"]", "", $buffer));
				
				for ($i=0; $i<mysql_num_fields($tbl_rslt); $i++) {

					print "  <tr bgcolor=#D9E6FE>\r\n";
					print "    <td align=right><font class=standard>".strtoupper(eregi_replace("_", " ", mysql_field_name($tbl_rslt, $i))).": </font></td>\r\n";
					print "    <td align=center><select name='".mysql_field_name($tbl_rslt, $i)."_field'>\r\n";
					print "     <option value='-1'>(none)</option>\r\n";

					for ($j=0; $j<count($row); $j++) {
						eregi_replace("\"", "", $row[$j]);
						print "     <option value='$j'>\"$row[$j]\"</option>\r\n";
					}

					print "    </select></td>\r\n";
					print "  </tr>\r\n";

					#print "  <tr bgcolor=#D9E6FE>\r\n";
					#print "    <td align=center><font class=standard>$row[$i]</font></td>\r\n";
					#print "    <td align=center><select name=datafield$i>\r\n";
					#print "     <option value=''>---------------------</option>\r\n";
					#print "     <option value='entry_date'>Entry date</option>\r\n";
					#print "     <option value='modify_date'>Modify date</option>\r\n";
					#print "     <option value='status'>Status</option>\r\n";
					#print "     <option value='user'>User</option>\r\n";
					#print "     <option value='vendor_lead_code'>Vendor lead code</option>\r\n";
					#print "     <option value='source_id'>Source ID</option>\r\n";
					#print "     <option value='list_id'>List ID</option>\r\n";
					#print "     <option value='campaign_id'>Campaign ID</option>\r\n";
					#print "     <option value='called_since_last_reset'>Called since last reset</option>\r\n";
					#print "     <option value='phone_code'>Phone code</option>\r\n";
					#print "     <option value='phone_number'>Phone number</option>\r\n";
					#print "     <option value='title'>Title</option>\r\n";
					#print "     <option value='first_name'>First name</option>\r\n";
					#print "     <option value='middle_initial'>Middle initial</option>\r\n";
					#print "     <option value='last_name'>Last name</option>\r\n";
					#print "     <option value='address1'>Address 1</option>\r\n";
					#print "     <option value='address2'>Address 2</option>\r\n";
					#print "     <option value='address3'>Address 3</option>\r\n";
					#print "     <option value='city'>City</option>\r\n";
					#print "     <option value='state'>State</option>\r\n";
					#print "     <option value='province'>Province</option>\r\n";
					#print "     <option value='postal_code'>Postal code</option>\r\n";
					#print "     <option value='country_code'>Country code</option>\r\n";
					#print "     <option value='gender'>Gender</option>\r\n";
					#print "     <option value='date_of_birth'>Date of birth</option>\r\n";
					#print "     <option value='alt_phone'>Alt. phone</option>\r\n";
					#print "     <option value='email'>E-mail</option>\r\n";
					#print "     <option value='security_phrase'>Security phrase</option>\r\n";
					#print "     <option value='comments'>Comments</option>\r\n";
					#print "    </td>\r\n";
					#print "  </tr>\r\n";
				}
			} else if (!eregi(".csv", $leadfile_name)) {
				copy($LF_path, "$WeBServeRRooT/vicidial/vicidial_temp_file.xls");
				passthru("$WeBServeRRooT/vicidial/listloader_rowdisplay.pl");
			} else {
				copy($LF_path, "$WeBServeRRooT/vicidial/vicidial_temp_file.csv");
				$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.csv", "r");
				$stmt_file=fopen("listloader_stmts.txt", "w");
				
				print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing CSV file... \n";
				
				$total=0; $good=0; $bad=0;
				$row=fgetcsv($file, 1000, ",");
				for ($i=0; $i<mysql_num_fields($tbl_rslt); $i++) {
					print "  <tr bgcolor=#D9E6FE>\r\n";
					print "    <td align=right><font class=standard>".strtoupper(eregi_replace("_", " ", mysql_field_name($tbl_rslt, $i))).": </font></td>\r\n";
					print "    <td align=center><select name='".mysql_field_name($tbl_rslt, $i)."_field'>\r\n";
					print "     <option value='-1'>(none)</option>\r\n";

					for ($j=0; $j<count($row); $j++) {
						eregi_replace("\"", "", $row[$j]);
						print "     <option value='$j'>\"$row[$j]\"</option>\r\n";
					}

					print "    </select></td>\r\n";
					print "  </tr>\r\n";

					#print "  <tr bgcolor=#D9E6FE>\r\n";
					#print "    <td align=center><font class=standard>$row[$i]</font></td>\r\n";
					#print "    <td align=center><select name=datafield$i>\r\n";
					#print "     <option value=''>---------------------</option>\r\n";
					#print "     <option value='entry_date'>Entry date</option>\r\n";
					#print "     <option value='modify_date'>Modify date</option>\r\n";
					#print "     <option value='status'>Status</option>\r\n";
					#print "     <option value='user'>User</option>\r\n";
					#print "     <option value='vendor_lead_code'>Vendor lead code</option>\r\n";
					#print "     <option value='source_id'>Source ID</option>\r\n";
					#print "     <option value='list_id'>List ID</option>\r\n";
					#print "     <option value='campaign_id'>Campaign ID</option>\r\n";
					#print "     <option value='called_since_last_reset'>Called since last reset</option>\r\n";
					#print "     <option value='phone_code'>Phone code</option>\r\n";
					#print "     <option value='phone_number'>Phone number</option>\r\n";
					#print "     <option value='title'>Title</option>\r\n";
					#print "     <option value='first_name'>First name</option>\r\n";
					#print "     <option value='middle_initial'>Middle initial</option>\r\n";
					#print "     <option value='last_name'>Last name</option>\r\n";
					#print "     <option value='address1'>Address 1</option>\r\n";
					#print "     <option value='address2'>Address 2</option>\r\n";
					#print "     <option value='address3'>Address 3</option>\r\n";
					#print "     <option value='city'>City</option>\r\n";
					#print "     <option value='state'>State</option>\r\n";
					#print "     <option value='province'>Province</option>\r\n";
					#print "     <option value='postal_code'>Postal code</option>\r\n";
					#print "     <option value='country_code'>Country code</option>\r\n";
					#print "     <option value='gender'>Gender</option>\r\n";
					#print "     <option value='date_of_birth'>Date of birth</option>\r\n";
					#print "     <option value='alt_phone'>Alt. phone</option>\r\n";
					#print "     <option value='email'>E-mail</option>\r\n";
					#print "     <option value='security_phrase'>Security phrase</option>\r\n";
					#print "     <option value='comments'>Comments</option>\r\n";
					#print "    </td>\r\n";
					#print "  </tr>\r\n";
				}
			}
			print "  <tr bgcolor='#330099'>\r\n";
			print "    <th colspan=2><input type=submit name='OK_to_process' value='OK TO PROCESS'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type=button onClick=\"javascript:document.location='new_listloader_superL.php'\" value=\"START OVER\" name='reload_page'></th>\r\n";
			print "  </tr>\r\n";
			print "</table>\r\n";
	# }
		print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=false; document.forms[0].submit_file.disabled=false; document.forms[0].reload_page.disabled=false;</script>";
	}
} else if (filesize($leadfile)>8388608) {
		print "<center><font face='arial, helvetica' size=3 color='#990000'><B>ERROR: File exceeds the 8MB limit.</B></font></center>";
}
?>
</form>
</body>
</html>
