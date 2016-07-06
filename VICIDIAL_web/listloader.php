<?
### listloader.php
### 
### Copyright (C) 2006  Matt Florell,Joe Johnson <vicidial@gmail.com>    LICENSE: GPLv2
###
### AST Web GUI lead loader from formatted file
### 
### CHANGES
### 50602-1640 - First version created by Joe Johnson
### 51128-1108 - Removed PHP global vars requirement
###
### make sure vicidial_list exists and that your file follows the formatting correctly. This page does not dedupe or do any other lead filtering actions yet at this time.


header ("Content-type: text/html; charset=utf-8");

require("dbconnect.php");

$PHP_AUTH_USER=$_SERVER['PHP_AUTH_USER'];
$PHP_AUTH_PW=$_SERVER['PHP_AUTH_PW'];
$PHP_SELF=$_SERVER['PHP_SELF'];
$leadfile=$_FILES["leadfile"];
	$LF_orig = $_FILES['leadfile']['name'];
	$LF_path = $_FILES['leadfile']['tmp_name'];
$submit_file=$_GET["submit_file"];			if (!$submit_file) {$submit_file=$_POST["submit_file"];}
$submit=$_GET["submit"];					if (!$submit) {$submit=$_POST["submit"];}
$SUBMIT=$_GET["SUBMIT"];					if (!$SUBMIT) {$SUBMIT=$_POST["SUBMIT"];}


$version = '1.1';
$build = '51128-1108';

$script_name = getenv("SCRIPT_NAME");
$server_name = getenv("SERVER_NAME");
$server_port = getenv("SERVER_PORT");
if (eregi("443",$server_port)) {$HTTPprotocol = 'https://';}
  else {$HTTPprotocol = 'http://';}
$admDIR = "$HTTPprotocol$server_name$script_name";
$admDIR = eregi_replace('listloader.php','',$admDIR);
$admSCR = 'admin.php';
$NWB = " &nbsp; <a href=\"javascript:openNewWindow('$admDIR$admSCR?ADD=99999";
$NWE = "')\"><IMG SRC=\"help.gif\" WIDTH=20 HEIGHT=20 BORDER=0 ALT=\"HELP\" ALIGN=TOP></A>";

echo "<html>\n";
echo "<head>\n";
echo "<!-- VERSION: $version     BUILD: $build -->\n";


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
</script>
</head>
<body>
<form action=<?=$PHP_SELF ?> method=post enctype="multipart/form-data">
<table align=center width="500" border=0 cellpadding=5 cellspacing=0 bgcolor=#D9E6FE>
  <tr>
	<td align=right width="25%"><font face="arial, helvetica" size=2>Load leads from this file:</font></td>
	<td align=left width="75%"><input type=file name="leadfile" value="<?=$leadfile ?>"> <? echo "$NWB#vicidial_list_loader$NWE"; ?></td>
  </tr>
  <tr>
	<td align=center><input type=submit value="SUBMIT" name='submit_file'></td>
	<td align=center><input type=button onClick="javascript:document.location='listloader.php'" value="START OVER" name='reload_page'></td>
  </tr>
  <tr><td colspan=2><font size=1><a href="new_listloader_superL.php" target="_parent">CLICK HERE TO GO TO THE SUPER LEAD LOADER (BETA VERSION)</a> &nbsp; &nbsp; <a href="admin.php" target="_parent">BACK TO ADMIN</a></font></td></tr>
</table>
</form>
<?

#echo "|$LF_orig|$LF_path|\n";

if ($leadfile && filesize($LF_path)<=8388608) {
	print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=true; document.forms[0].submit_file.disabled=true; document.forms[0].reload_page.disabled=true;</script>";
	flush();
	copy($LF_path, "$WeBServeRRooT/vicidial/vicidial_temp_file.txt");
	$file=fopen("$WeBServeRRooT/vicidial/vicidial_temp_file.txt", "r");
	if ($WeBRooTWritablE > 0)
		{$stmt_file=fopen("$WeBServeRRooT/vicidial/listloader_stmts.txt", "w");}
	$pulldate=date("Y-m-d H:i:s");

	$buffer=fgets($file, 4096);
	$tab_count=substr_count($buffer, "\t");
	$pipe_count=substr_count($buffer, "|");

	if ($tab_count>$pipe_count) {$delimiter="\t";  $delim_name="tab";} else {$delimiter="|";  $delim_name="pipe";}
	$field_check=explode($delimiter, $buffer);

	if (count($field_check)>=5) {
		flush();
		$file=fopen("./vicidial_temp_file.txt", "r");
		$total=0; $good=0; $bad=0;
		print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing $delim_name-delimited file... ($tab_count|$pipe_count)\n";
		while (!feof($file)) {
			$record++;
			$buffer=rtrim(fgets($file, 4096));
			$buffer=stripslashes($buffer);

			if (strlen($buffer)>0) {
				$row=explode($delimiter, eregi_replace("[\'\"]", "", $buffer));
				$entry_date =			"$pulldate";
				$modify_date =			"";
				$status =				"NEW";
				$user =					"";
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
				$city =					$row[12];
				$state =				$row[13];
				$province =				$row[14];
				$postal_code =			$row[15];
				$country =				$row[16];
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
	print "<script language='JavaScript1.2'>document.forms[0].leadfile.disabled=false; document.forms[0].submit_file.disabled=false; document.forms[0].reload_page.disabled=false;</script>";
} else if (filesize($leadfile)>8388608) {
		print "<center><font face='arial, helvetica' size=3 color='#990000'><B>ERROR: File exceeds the 8MB limit.</B></font></center>";
}
?>
</body>
</html>