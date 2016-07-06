#!/usr/bin/perl
#
# VICIDIAL_IN_new_leads_file.pl version 0.2
#
# DESCRIPTION:
# script lets you insert leads into the vicidial_list table from a TAB-delimited
# lead file that is in the proper format. (for format see --help)
#
# It is recommended that you run this program on the local Asterisk machine
#
# Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#

$secX = time();

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = ($year + 1900);
$mon++;
if ($min < 10) {$min = "0$min";}
if ($sec < 10) {$sec = "0$sec";}
if ($mon < 10) {$mon = "0$mon";}
if ($mday < 10) {$mday = "0$mday";}
$pulldate0 = "$year-$mon-$mday $hour:$min:$sec";
$inSD = $pulldate0;


print "\n\n\n\n\n\n\n\n\n\n\n\n-- VICIDIAL_IN_new_leads_file.pl --\n\n";
print "This program is designed to take a tab delimited file and import it into the VICIDIAL system. \n\n";

### begin parsing run-time options ###
if (length($ARGV[0])>1)
{
	$i=0;
	while ($#ARGV >= $i)
	{
	$args = "$args $ARGV[$i]";
	$i++;
	}

	if ($args =~ /--help|-h/i)
	{
	print "allowed run time options:\n  [-q] = quiet\n  [-t] = test\n [-h] = this help screen\n\n";
	print "This script takes in lead files in the following order when they are placed in the /home/cron/VICIDIAL/LEADS_IN directory to be imported into the vicidial_list table:\n\n";
	print "vendor_lead_code|source_code|list_id|phone_code|phone_number|title|first_name|middle|last_name|address1|address2|address3|city|state|province|postal_code|country|gender|date_of_birth|alt_phone|email|security_phrase|COMMENTS\n\n";
	print "3857822|31022|105|01144|1625551212|MRS|B||BURTON|249 MUNDON ROAD|MALDON|ESSEX||||CM9 6PW|UK||||||COMMENTS\n\n";
	}
	else
	{
		if ($args =~ /-q/i)
		{
		$q=1;
		}
		if ($args =~ /-t/i)
		{
		$T=1;
		$TEST=1;
		print "\n-----TESTING -----\n\n";
		}
	}
}
else
{
print "no command line options set\n";
}
### end parsing run-time options ###


$suf = '.txt';
$people_packages_id_update='';
$dir1 = '/home/cron/VICIDIAL/LEADS_IN';
$dir2 = '/home/cron/VICIDIAL/LEADS_IN/DONE';


 opendir(FILE, "$dir1/");
 @FILES = readdir(FILE);

foreach(@FILES)
   {
	$size1 = 0;
	$size2 = 0;
	$person_id_delete = '';
	$transaction_id_delete = '';

	if (length($FILES[$i]) > 4)
		{

		$size1 = (-s "$dir1/$FILES[$i]");
		if (!$q) {print "$FILES[$i] $size1\n";}
		sleep(2);
		$size2 = (-s "$dir1/$FILES[$i]");
		if (!$q) {print "$FILES[$i] $size2\n\n";}


		if ( ($FILES[$i] !~ /^TRANSFERRED/i) && ($size1 eq $size2) && (length($FILES[$i]) > 4))
			{
			$GOODfname = $FILES[$i];
			$FILES[$i] =~ s/ /_/gi;
			$FILES[$i] =~ s/\(|\)|\||\\|\/|\'|\"|//gi;
			rename("$dir1/$GOODfname","$dir1/$FILES[$i]");
			$FILEname = $FILES[$i];

			$Routfile = "ERR_$source$FILES[$i]";
			$Soutfile = "STS_$source$FILES[$i]";
			$Toutfile = "SQL_$source$FILES[$i]";
			$Doutfile = "DEL_$source$FILES[$i]";

			`cp -f $dir1/$FILES[$i] $dir2/$source$FILES[$i]`;

	### open the in file for reading ###
	open(infile, "$dir2/$source$FILES[$i]")
			|| die "Can't open $source$FILES[$i]: $!\n";

	### open the error out file for writing ###
	open(Rout, ">>$dir2/$Routfile")
			|| die "Can't open $Routfile: $!\n";

	### open the error out file for writing ###
	open(Tout, ">>$dir2/$Toutfile")
			|| die "Can't open $Toutfile: $!\n";

	### open the error out file for writing ###
	open(Dout, ">>$dir2/$Doutfile")
			|| die "Can't open $Doutfile: $!\n";


### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

use Net::MySQL;
	  
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";



	print "\n\n SQL inserts will be put in $Toutfile\n\n";

	$a=0;	### each line of input file counter ###
	$b=0;	### status of 'APPROVED' counter ###
	$c=0;	### status of 'DECLINED' counter ###
	$d=0;	### status of 'REFERRED' counter ###
	$e=0;	### status of 'ERROR' counter ###
	$f=0;	### number of modified packages ###
	$g=0;	### number of credits ###

	$multi_insert_counter=0;
	$multistmt='';

	while (<infile>)
	{

		#print "$a| $number\n";
		$number = $_;
		chomp($number);
#		$number =~ s/,/\|/gi;
		$number =~ s/\t/\|/gi;
		$number =~ s/\'|\t|\r|\n|\l//gi;
		$number =~ s/\'|\t|\r|\n|\l//gi;
		$number =~ s/\",,,,,,,\"/\|\|\|\|\|\|\|/gi;
		$number =~ s/\",,,,,,\"/\|\|\|\|\|\|/gi;
		$number =~ s/\",,,,,\"/\|\|\|\|\|/gi;
		$number =~ s/\",,,,\"/\|\|\|\|/gi;
		$number =~ s/\",,,\"/\|\|\|/gi;
		$number =~ s/\",,\"/\|\|/gi;
		$number =~ s/\",\"/\|/gi;
		$number =~ s/\"//gi;
	@m = split(/\|/, $number);

# This is the format for the lead files
#3857822|31022|105|01144|1625551212|MRS|B||BURTON|249 MUNDON ROAD|MALDON|ESSEX||||CM9 6PW|UK||||||COMMENTS


		$entry_date =			"$pulldate0";
		$modify_date =			"";
		$status =				"NEW";
		$user =					"";
		$vendor_lead_code =		$m[0];		chomp($vendor_lead_code);
		$source_code =			$m[1];		chomp($source_code); $source_id = $source_code;
		$list_id =				$m[2];		chomp($list_id);
		$campaign_id =			'';
		$called_since_last_reset='N';
		$phone_code =			$m[3];		chomp($phone_code);	$phone_code =~ s/\D//gi;
		$phone_number =			$m[4];		chomp($phone_number);	$phone_number =~ s/\D//gi;
		$title =				$m[5];		chomp($title);
		$first_name =			$m[6];		chomp($first_name);
		$middle_initial =		$m[7];		chomp($middle_initial);
		$last_name =			$m[8];		chomp($last_name);
		$address1 =				$m[9];		chomp($address1);
		$address2 =				$m[10];		chomp($address2);
		$address3 =				$m[11];		chomp($address3);
		$city =					$m[12];		chomp($city);
		$state =				$m[13];		chomp($state);
		$province =				$m[14];		chomp($province);
		$postal_code =			$m[15];		chomp($postal_code);
		$country =				$m[16];		chomp($country);
		$gender =				$m[17];
		$date_of_birth =		$m[18];
		$alt_phone =			$m[19];
		$email =				$m[20];
		$security_phrase =		$m[21];
		$comments =				$m[22];


		if (length($phone_number)>8)
			{

			if ($multi_insert_counter > 8)
				{
				### insert good deal into pending_transactions table ###
				$stmtZ = "INSERT INTO vicidial_list values$multistmt('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments','0');";
						if($DB){print STDERR "\n|$stmtZ|\n";}
						if (!$T) {$dbhA->query($stmtZ); } #  or die  "Couldn't execute query: |$stmtA|\n";

				$multistmt='';
				$multi_insert_counter=0;
				$c++;
				}
			else
				{
				$multistmt .= "('','$entry_date','$modify_date','$status','$user','$vendor_lead_code','$source_id','$list_id','$campaign_id','$called_since_last_reset','$phone_code','$phone_number','$title','$first_name','$middle_initial','$last_name','$address1','$address2','$address3','$city','$state','$province','$postal_code','$country_code','$gender','$date_of_birth','$alt_phone','$email','$security_phrase','$comments','0'),";
				$multi_insert_counter++;
				}

			$b++;
			}
		else
			{
			print "BAD Home_Phone: $phone|$vendor_id";
			$e++;
			}
		
		$a++;

		if ($a =~ /100$/i) {print STDERR "0     $a\r";}
		if ($a =~ /200$/i) {print STDERR "+     $a\r";}
		if ($a =~ /300$/i) {print STDERR "|     $a\r";}
		if ($a =~ /400$/i) {print STDERR "\\     $a\r";}
		if ($a =~ /500$/i) {print STDERR "-     $a\r";}
		if ($a =~ /600$/i) {print STDERR "/     $a\r";}
		if ($a =~ /700$/i) {print STDERR "|     $a\r";}
		if ($a =~ /800$/i) {print STDERR "+     $a\r";}
		if ($a =~ /900$/i) {print STDERR "0     $a\r";}
		if ($a =~ /000$/i) {print "$a|$b|$c|$d|$e|$phone_number|\n";}

	}

			if (length($multistmt) > 10)
				{
				chop($multistmt);
				### insert good deal into pending_transactions table ###
				$stmtZ = "INSERT INTO vicidial_list values$multistmt;";
						if($DB){print STDERR "\n|$stmtZ|\n";}
						if (!$T) {$dbhA->query($stmtZ); } #  or die  "Couldn't execute query: |$stmtA|\n";

				$multistmt='';
				$multi_insert_counter=0;
				$c++;
				}

	### open the stats out file for writing ###
	open(Sout, ">>/$dir2/$Soutfile")
			|| die "Can't open $Soutfile: $!\n";


	### close file handler and DB connections ###
	print "\n\nTOTALS FOR $FILEname:\n";
	print "Transactions sent:$a\n";
	print "INSERTED:         $b\n";
	print "INSERT STATEMENTS:$c\n";
	print "ERROR:            $e\n";
#	print "Modified PAID NS: $f\n";
#	print "Credits:          $g\n\n";

	print Sout "\nTOTALS FOR $FILEname:\n";
	print Sout "Transactions sent:$a\n";
	print Sout "INSERTED:         $b\n";
	print Sout "INSERT STATEMENTS:$c\n";
	print Sout "ERROR:            $e\n";
#	print Sout "Modified PAID NS: $f\n";
#	print Sout "Credits:          $g\n\n";

	close(infile);
	close(Rout);
	chmod 0777, "$dir2/$Routfile";
	close(Sout);
	chmod 0777, "$dir2/$Soutfile";
	close(Tout);
	chmod 0777, "$dir2/$Toutfile";
	close(Dout);
	chmod 0777, "$dir2/$Doutfile";

			if (!$T) {`mv -f $dir1/$FILEname $dir2/$FILEname`;}

			}
		}
		$i++;
}


### calculate time to run script ###
$secY = time();
$secZ = ($secY - $secX);
$secZm = ($secZ /60);

print "script execution time in seconds: $secZ     minutes: $secZm\n";

exit;
