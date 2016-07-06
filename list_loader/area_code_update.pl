#!/usr/bin/perl
use DBI;
use IO::Socket;
use Net::MySQL;
use Time::Local;
use Term::ReadKey;
use LWP::Simple;
use MIME::QuotedPrint;
use MIME::Base64;
use HTML::Entities;
use Mail::Sendmail 0.78;
use Net::FTP;
use Net::MySQL;
use HTML::TreeBuilder;


$pattern="e ";
$i=0;

$|=1;

require "/home/cron/vici/subs/vici_insert_subs.pl";

&db_connect;

$states{"AL"}="Alabama";
$states{"AK"}="Alaska";
$states{"AZ"}="Arizona";
$states{"AR"}="Arkansas";
$states{"CA"}="California";
$states{"CO"}="Colorado";
$states{"CT"}="Connecticut";
$states{"DE"}="Delaware";
$states{"DC"}="District of Columbia";
$states{"FL"}="Florida";
$states{"GA"}="Georgia";
$states{"HI"}="Hawaii";
$states{"ID"}="Idaho";
$states{"IL"}="Illinois";
$states{"IN"}="Indiana";
$states{"IA"}="Iowa";
$states{"KS"}="Kansas";
$states{"KY"}="Kentucky";
$states{"LA"}="Louisiana";
$states{"ME"}="Maine";
$states{"MD"}="Maryland";
$states{"MA"}="Massachusetts";
$states{"MI"}="Michigan";
$states{"MN"}="Minnesota";
$states{"MS"}="Mississippi";
$states{"MO"}="Missouri";
$states{"MT"}="Montana";
$states{"NE"}="Nebraska";
$states{"NV"}="Nevada";
$states{"NH"}="New Hampshire";
$states{"NJ"}="New Jersey";
$states{"NM"}="New Mexico";
$states{"NY"}="New York";
$states{"NC"}="North Carolina";
$states{"ND"}="North Dakota";
$states{"OH"}="Ohio";
$states{"OK"}="Oklahoma";
$states{"OR"}="Oregon";
$states{"PA"}="Pennsylvania";
$states{"RI"}="Rhode Island";
$states{"SC"}="South Carolina";
$states{"SD"}="South Dakota";
$states{"TN"}="Tennessee";
$states{"TX"}="Texas";
$states{"US"}="US";
$states{"UT"}="Utah";
$states{"VT"}="Vermont";
$states{"VA"}="Virginia";
$states{"WA"}="Washington";
$states{"WV"}="West Virginia";
$states{"WI"}="Wisconsin";
$states{"WY"}="Wyoming";
$states{"PR"}="Puerto Rico";
$states{"VI"}="US Virgin Islands";
$states{"GU"}="Guam";

##############################################################
# The following section contains information that MUST       #
# be altered to fit the format of the received file.         #
##############################################################


# print "FETCHING AREA CODE FILE...\n";
# $file=get("http://docs.nanpa.com/cgi-bin/npa_reports/nanpa?function=list_npa_geo_number") or die "Couldn't fetch area codes";
$url='http://www.nanpa.com/nas/public/npasInServiceByNumberReport.do?method=displayNpasInServiceByNumberReport';
$page=get($url) or die "$!\n";

$text="";
# print "FILE GRABBED.  PARSING...\n";

$dbhA = Net::MySQL->new(hostname => "10.10.11.10", database => "asterisk", user => "astcron", password => "astcron"); 
$dbhA->query("delete from vicidial_areacodes");


$stmt="delete from valid_area_codes";
$sth=$dbhX->prepare($stmt);
$sth->execute();

$sth=$dbhOOE->prepare($stmt);
$sth->execute();


$p=HTML::TreeBuilder->new_from_content($page);

@links=$p->look_down(
	_tag => 'td',
	width => qr{^35}x
);

@rows=map{$_->parent} @links;

@pages;
for $row (@rows) {
	@cells=$row->look_down(_tag => 'td');
	$area_code=$cells[0]->as_trimmed_text;
	$fullstate=$cells[1]->as_trimmed_text;
	$state="";
	foreach $abbr (keys %states) {
		if ($states{$abbr} eq "$fullstate" || $abbr eq "$fullstate") {
			$state=$abbr;
		}
	}
	if ($state eq "") {
		$text.="NOT A MARKETABLE AREA CODE: $fullstate - ($area_code)\n";
		$state="XX";
		$bad_ac++;
	} else {
			$stmt="insert into valid_area_codes VALUES($area_code, '".uc($state)."')";

			$sth=$dbhX->prepare($stmt);
			$sth->execute();

			$sth=$dbhOOE->prepare($stmt);
			$sth->execute();

			$ast_stmt="insert into vicidial_areacodes VALUES($area_code, '".uc($state)."')";
			$dbhA->query($ast_stmt);

			print AREA_CODES "$area_code|".uc($state)."\n";
			if ($state!~/XX/i) {$good_ac++;}
			$area_code="";
			$state="";
	}
}
# close(AREA_CODES);
# $ftp->put("/home/cron/vici/nanpa_area_codes.txt");
# `rm /home/cron/vici/nanpa_area_codes.txt`;

$stmt="delete from valid_area_codes where state='XX'";

$sth=$dbhX->prepare($stmt);
$sth->execute();

$sth=$dbhOOE->prepare($stmt);
$sth->execute();

$ast_stmt="delete from vicidial_areacodes where state='XX'";
$dbhA->query($ast_stmt);

$rslts= "---------- RESULTS ----------\n";
$rslts.="   GOOD AREA CODES: $good_ac\n";
$rslts.="    BAD AREA CODES: $bad_ac\n\n";

$boundary = "====" . time() . "====";

%mail = (
#         SMTP => 'smtp.vicimarketing.com',
         from => 'joej@vicimarketing.com',
         to => 'joej@vicimarketing.com, mattf@vicimarketing.com',
         subject => 'Area code processing results',
         'content-type' => "text/plain; boundary=\"$boundary\""
        );

$plain = encode_qp $text;

$boundary = '--'.$boundary;

$mail{body} = <<END_OF_BODY;
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

$rslts
$plain

$mail{body}
END_OF_BODY


sendmail(%mail) || print "Error: $Mail::Sendmail::error\\n";


