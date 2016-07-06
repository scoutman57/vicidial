<? header("Pragma: no-cache"); ?>
<html>
<head>
<title>Memberworks recent sales lookup</title>
</head>
<?
include("/home/www/phpsubs/stylesheet.inc");
?>
<body>
<form action="<?=$PHP_SELF ?>" method=get>
<table border=0 cellpadding=5 cellspacing=0 align=center width=600>
<tr>
	<th colspan=3><font class="standard_bold">Memberworks recent sales report<BR><font color='red'>Current report file: <?=date("m/d/Y") ?>
	<?
	if (date("H")<16) {print "am";} else {print "pm";}
	?>
	shift</font></font></th>
</tr>
<tr bgcolor='#CCCCCC'>
	<th align=left width=350><font class='standard_bold'>View sales made within the last <select name="sales_time_frame">
	<option value=''>----------</option>
	<option value='15'>15 minutes</option>
	<option value='30'>30 minutes</option>
	<option value='45'>45 minutes</option>
	<option value='60'>1 hour</option>
	</select></th>
	<th width=50>OR...</th>
	<th align=right width=200><font class='standard_bold'>View the last <input type=text size=3 maxlength=3 name="sales_number"> sales</font></th>
</tr>
<tr><th colspan=3><font class="small_standard">(If you enter values in both fields, the time report will be ignored)</font></th></tr>
<tr><th colspan=3><input type=submit name="submit" value="SUBMIT"></th></tr>
<tr>
</tr>
</table>
</form>
<?
if (date("H")<16) {$sfx="am";} else {$sfx="pm";}
$filename="MWKS_COF_SALES_".date("Ymd").$sfx.".txt";
if ($submit) {
	$sales_number=eregi_replace("[^0-9]", "", $sales_number);
	print "<HR>";
	print "<table border=0 cellpadding=5 cellspacing=0 align=center>";
	$fp=fopen("/home/www/htdocs/vicidial/MWKS_sales/$filename", "r");
	$i=0;
	# $fronter0|$closer1|$first_name2|$last_name3|$phone4|$ivr_id5|$upsell16|$upsell27|$upsell38|$gender9|10|11|12|$magazine113|$magazine214|$magazine315|$magazine416|$doby-$dobm-$dobd17|$timestamp18|$group19
	while(!feof($fp)) {
		$buffer=fgets($fp, 4096);
		if (strlen(trim($buffer))>0) {
			$ary[$i]=$buffer;
			$i++;
		}
	}
	if ($sales_number && $sales_number>0) {
		if ($sales_number>count($ary)) {
			$sales_number=count($ary);
		}
		$q=0;
		print "<tr bgcolor='#000000'><th colspan=8><font class='standard_bold' color='white'>Last $sales_number sales made</font></th></tr>\n";
		print "<tr bgcolor='#000000'>\n";
		print "\t<th><font class='standard_bold' color='white'>Fronter</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Closer</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Name</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Phone</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>IVR #</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Sales/Upsells</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>DOB</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Timestamp</font></th>\n";
		print "</tr>\n";
		for ($i=count($ary)-1; $i>=0; $i--) {
			while ($q<$sales_number) {
				$buffer=$ary[$i];
				if (strlen($buffer)>0) {
					$row=explode("|", $buffer);
					if (trim($row[19])=="CL_GALLERIA") {
						if ($i%2==0) {$bgcolor="#999999";} else {$bgcolor="#CCCCCC";}
						print "<tr bgcolor='$bgcolor'>\n";
						print "\t<th><font class='standard_bold'>$row[0]</font></th>\n";
						print "\t<th><font class='standard_bold'>$row[1]</font></th>\n";
						print "\t<th><font class='standard_bold'>$row[2] $row[3]</font></th>\n";
						print "\t<th><font class='standard_bold'>$row[4]</font></th>\n";
						print "\t<th><font class='standard_bold'>$row[5]</font></th>\n";
						print "\t<th><font class='standard_bold'>$row[6], $row[7], $row[8]</font></th>\n";
						print "\t<th><font class='standard_bold'>$row[17]</font></th>\n";
						print "\t<th><font class='standard_bold'>$row[18]</font></th>\n";
						print "</tr>\n";
						flush();
					}
				}
				$q++;
				$i--;
			}
			$q=$sales_number;
		}
	} else if ($sales_time_frame && $sales_time_frame>0) {
		$timestamp=date("YmdHis", mktime(date("H"),(date("i")-$sales_time_frame),date("s"),date("m"),date("d"),date("Y")));
		print "<tr bgcolor='#000000'><th colspan=8><font class='standard_bold' color='white'>Sales made in the last $sales_time_frame minutes</font></th></tr>\n";
		print "<tr bgcolor='#000000'>\n";
		print "\t<th><font class='standard_bold' color='white'>Fronter</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Closer</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Name</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Phone</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>IVR #</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Sales/Upsells</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>DOB</font></th>\n";
		print "\t<th><font class='standard_bold' color='white'>Timestamp</font></th>\n";
		print "</tr>\n";
		for ($i=count($ary)-1; $i>=0; $i--) {
			$buffer=$ary[$i];
			$row=explode("|", $buffer);
			$q++;
			$sale_time=eregi_replace("[^0-9]", "", $row[18]);

			# print "$row[18] - $sale_time<BR>";
			if ($sale_time>$timestamp && trim($row[19])=="CL_GALLERIA") {
				if ($i%2==0) {$bgcolor="#999999";} else {$bgcolor="#CCCCCC";}
				print "<tr bgcolor='$bgcolor'>\n";
				print "\t<th><font class='standard_bold'>$row[0]</font></th>\n";
				print "\t<th><font class='standard_bold'>$row[1]</font></th>\n";
				print "\t<th><font class='standard_bold'>$row[2] $row[3]</font></th>\n";
				print "\t<th><font class='standard_bold'>$row[4]</font></th>\n";
				print "\t<th><font class='standard_bold'>$row[5]</font></th>\n";
				print "\t<th><font class='standard_bold'>$row[6], $row[7], $row[8]</font></th>\n";
				print "\t<th><font class='standard_bold'>$row[17]</font></th>\n";
				print "\t<th><font class='standard_bold'>$row[18]</font></th>\n";
				print "</tr>\n";
			}
		}
		flush();
	}
	print "</table>";
}
passthru("/home/www/htdocs/vicidial/mwks_sales_viewer.pl $filename");
# print "/home/www/htdocs/vicidial/mwks_sales_viewer.pl $filename";
print "<table align=center border=0 cellpadding=3 cellspacing=5 width='80%'><tr bgcolor='#CCCCCC'><th width='50%'><font class='standard_bold'><a href='mwks_fronter_report.xls'>View complete Excel fronter report for this shift</a></font></th><th width='50%'><font class='standard_bold'><a href='mwks_sales_report.xls'>View complete Excel closer report for this shift</a></font></th></tr></table>";
?>
</body>
</html>
