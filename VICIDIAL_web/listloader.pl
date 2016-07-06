#!/usr/bin/perl

### listloader.pl
### 
### Copyright (C) 2006  Matt Florell,Joe Johnson <vicidial@gmail.com>    LICENSE: GPLv2
###

use Spreadsheet::ParseExcel;
use Time::Local;
use Net::MySQL;

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

$dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";


$|=0;
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = ($year + 1900);
$mon++;
if ($mon < 10) {$mon = "0$mon";}
if ($mday < 10) {$mday = "0$mday";}
$pulldate="$year-$mon-$mday $hour:$min:$sec";

$total=0; $good=0; $bad=0;
print "<center><font face='arial, helvetica' size=3 color='#009900'><B>Processing Excel file...\n";
open(STMT_FILE, "> listloader_stmts.txt");

$oBook = Spreadsheet::ParseExcel::Workbook->Parse("./vicidial_temp_file.xls");
my($iR, $iC, $oWkS, $oWkC);

foreach $oWkS (@{$oBook->{Worksheet}}) {
	for($iR = 0 ; defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ; $iR++) {

		$entry_date =			"$pulldate";
		$modify_date =			"";
		$status =				"NEW";
		$user =					"";
		$oWkC = $oWkS->{Cells}[$iR][0];
		if ($oWkC) {$vendor_lead_code=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][1];
		if ($oWkC) {$source_code=$oWkC->Value; }
		$source_id=$source_code;
		$oWkC = $oWkS->{Cells}[$iR][2];
		if ($oWkC) {$list_id=$oWkC->Value; }
		$campaign_id =			'';
		$called_since_last_reset='N';
		$oWkC = $oWkS->{Cells}[$iR][3];
		if ($oWkC) {$phone_code=$oWkC->Value; }
		$phone_code=~s/[^0-9]//g;
		$oWkC = $oWkS->{Cells}[$iR][4];
		if ($oWkC) {$phone_number=$oWkC->Value; }
		$phone_number=~s/[^0-9]//g;
		$oWkC = $oWkS->{Cells}[$iR][5];
		if ($oWkC) {$title=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][6];
		if ($oWkC) {$first_name=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][7];
		if ($oWkC) {$middle_initial=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][8];
		if ($oWkC) {$last_name=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][9];
		if ($oWkC) {$address1=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][10];
		if ($oWkC) {$address2=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][11];
		if ($oWkC) {$address3=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][12];
		if ($oWkC) {$city=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][13];
		if ($oWkC) {$state=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][14];
		if ($oWkC) {$province=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][15];
		if ($oWkC) {$postal_code=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][16];
		if ($oWkC) {$country=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][17];
		if ($oWkC) {$gender=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][18];
		if ($oWkC) {$date_of_birth=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][19];
		if ($oWkC) {$alt_phone=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][20];
		if ($oWkC) {$email=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][21];
		if ($oWkC) {$security_phrase=$oWkC->Value; }
		$oWkC = $oWkS->{Cells}[$iR][22];
		if ($oWkC) {$comments=$oWkC->Value; }
		$comments=~s/^\s*(.*?)\s*$/$1/;

		if (length($phone_number)>8) {

			if ($multi_insert_counter > 8) {
				### insert good deal into pending_transactions table ###
				$stmtZ = "INSERT INTO vicidial_list values$multistmt('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0);";
				$dbhA->query("$stmtZ");
				print STMT_FILE $stmtZ."\r\n";
				$multistmt='';
				$multi_insert_counter=0;

			} else {
				$multistmt .= "('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments',0),";
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
			sleep(1);
#			flush();
		}
	}
}

if ($multi_insert_counter > 0) {
	$stmtZ = "INSERT INTO vicidial_list values ".substr($multistmt, 0, -1).";";
	$dbhA->query("$stmtZ");
	print STMT_FILE $stmtZ."\r\n";
}

print "<BR><BR>Done</B> GOOD: $good &nbsp; &nbsp; &nbsp; BAD: $bad &nbsp; &nbsp; &nbsp; TOTAL: $total</font></center>";

