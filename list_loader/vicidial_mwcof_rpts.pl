#!/usr/bin/perl
use DBI;
use POSIX;
use IO::Socket;
use Net::MySQL;
use Time::Local;
use MIME::QuotedPrint;
use MIME::Base64;
use HTML::Entities;
use Mail::Sendmail 0.78;
use Spreadsheet::WriteExcel;
$|=1;

$dbh=DBI->connect('DBI:mysql:dbname=asterisk;host=10.10.11.10', 'astcron', 'astcron') or die "Couldn't connect to database: $!\n";


($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time()-86400);
$year = ($year + 1900);
$mon++;
if ($mon < 10) {$mon = "0$mon";}
if ($mday < 10) {$mday = "0$mday";}
$cdate="$year$mon$mday";

$ssname="/home/cron/vicidial/REPORTS/MWCOF_".$cdate."/VICIDIAL_MWCOF_LIST_rpt_".$cdate.".xls";
`mkdir /home/cron/vicidial/REPORTS/MWCOF_$cdate `;

$call_date="$year-$mon-$mday $hour:$min:$sec";
# $call_date="2004-04-19 05:50:00";
# $call_date2="2004-03-08 05:50:00";

$xl = Spreadsheet::WriteExcel->new($ssname);
$xlsheet = $xl->add_worksheet();
$rptheader = $xl->add_format(); # Add a format
$rptheader->set_bold();
$rptheader->set_color('10');
$rptheader->set_align('center');

$boldcell = $xl->add_format(); # Add a format
$boldcell->set_bold();
$boldcell->set_align('center');
$boldcell->set_bg_color('22');

$percentcell = $xl->add_format(); # Add a format
$percentcell->set_bold();
$percentcell->set_align('center');
$percentcell->set_num_format('0.0%');

$statcell = $xl->add_format(); # Add a format
$statcell->set_bg_color('40');
$statcell->set_align('left');

$countcell = $xl->add_format(); # Add a format
$countcell->set_bg_color('35');

$stmt="select list_id, count(*) from vicidial_list where list_id like '88%' group by list_id order by list_id asc";

$rslt=$dbh->prepare($stmt);
$rslt->execute();

###################### LIST COUNT REPORT ######################
$xlsheet->merge_range('D1:G1', 'COMPLETE LIST REPORT', $rptheader);
$xlsheet->write('E2', 'List ID', $boldcell); 
$xlsheet->write('F2', 'Count', $boldcell); 
$i=3;
$totcount=0;
while(@row=$rslt->fetchrow_array) {
	$statcoord="E$i";
	$ctcoord="F$i";
	$pctcoord="G$i";
	$xlsheet->write($statcoord, "$row[0]", $statcell); 
	$xlsheet->write($ctcoord, "$row[1]", $countcell); 
	$i++;
	$totcount+=$row[1];
}
$statcoord="E$i";
$ctcoord="F$i";
$pctcoord="G$i";
$xlsheet->write($statcoord, "TOTAL", $boldcell); 
$xlsheet->write($ctcoord, "$totcount", $boldcell); 
###############################################################

$nrow=$i+2;
$rslt=$dbh->prepare($stmt);
$rslt->execute();
$ca=0;
$maxrow=0;
@col_ary=();
$col_ary[0]='A|B|C';
$col_ary[1]='E|F|G';
$col_ary[2]='I|J|K';

while(@row=$rslt->fetchrow_array) {
	$i=$nrow;
	@col=split(/\|/, $col_ary[($ca%3)]);
	$titlecoords=$col[0].$i.':'.$col[1].$i;
	$xlsheet->merge_range($titlecoords, "LIST $row[0] REPORT", $rptheader);

	$i++;
	$statcoord=$col[0].$i;
	$ctcoord=$col[1].$i;
	$pctcoord=$col[2].$i;
	$xlsheet->write($statcoord, "Status", $boldcell); 
	$xlsheet->write($ctcoord, "Count", $boldcell);
#	$xlsheet->write($ctcoord, "%", $boldcell);
	
	$stat_stmt="select status, count(*) from vicidial_list where list_id='$row[0]' group by status";
	$stat_rslt=$dbh->prepare($stat_stmt);
	$stat_rslt->execute();
	while(@srow=$stat_rslt->fetchrow_array) {
		$i++;
		$statcoord=$col[0].$i;
		$ctcoord=$col[1].$i;
		$pctcoord=$col[2].$i;
		$xlsheet->write($statcoord, "$srow[0]", $statcell); 
		$xlsheet->write($ctcoord, "$srow[1]", $countcell); 
		$formula="=$ctcoord/$row[1]";
		$xlsheet->write($pctcoord, "$formula", $percentcell); 
	}
	$i++;
	$statcoord=$col[0].$i;
	$ctcoord=$col[1].$i;
	$xlsheet->write($statcoord, "TOTAL", $boldcell); 
	$xlsheet->write($ctcoord, "$row[1]", $boldcell); 
	if ($i>$maxrow) {
		$maxrow=$i;
	}

	$ca++;
	if ($ca%3==0) {
		$nrow=$maxrow+2;
	}

}

$xl->close();


##########################################
##########################################
$camp_stmt="select distinct upper(v.campaign_id), c.campaign_name from vicidial_log v, vicidial_campaigns c where v.list_id like '88%' and call_date>='".$call_date."' and upper(v.campaign_id)=upper(c.campaign_id)"; 
$camp_rslt=$dbh->prepare($camp_stmt);
$camp_rslt->execute();

while (@camp_row=$camp_rslt->fetchrow_array) {
	$campaign_id=uc($camp_row[0]);
	$campaign=$camp_row[1];
	$ssname="/home/cron/vicidial/REPORTS/MWCOF_".$cdate."/VICIDIAL_".$campaign_id."_".$cdate.".xls";

	$xl = Spreadsheet::WriteExcel->new($ssname);
	$xlsheet = $xl->add_worksheet();
	$rptheader = $xl->add_format(); # Add a format
	$rptheader->set_bold();
	$rptheader->set_color('10');
	$rptheader->set_align('center');

	$boldcell = $xl->add_format(); # Add a format
	$boldcell->set_bold();
	$boldcell->set_align('center');
	$boldcell->set_bg_color('22');

	$statcell = $xl->add_format(); # Add a format
	$statcell->set_bg_color('40');
	$statcell->set_align('left');

	$timecell = $xl->add_format(); # Add a format
	$timecell->set_bg_color('44');

	$countcell = $xl->add_format(); # Add a format
	$countcell->set_bg_color('35');

	###################### NAME COUNT REPORT ######################
	$stmt="select full_name, sec_to_time(sum(length_in_sec)), sum(length_in_sec), count(*) from vicidial_log v, vicidial_users u where v.list_id like '88%' and call_date>='".$call_date."' and upper(campaign_id)='$campaign_id' and v.user=u.user group by full_name order by full_name asc";
	$rslt=$dbh->prepare($stmt);
	$rslt->execute();

	$xlsheet->merge_range('A1:E1', "$campaign NAME REPORT", $rptheader);
	$xlsheet->write('B2', 'Name', $boldcell); 
	$xlsheet->write('C2', 'Calls', $boldcell); 
	$xlsheet->write('D2', 'Time Logged', $boldcell); 
	$i=3;
	$totalcount=0;
	$totaltime=0;
	while(@row=$rslt->fetchrow_array) {
		$namecoord="B$i";
		$ctcoord="C$i";
		$timecoord="D$i";
		$xlsheet->write($namecoord, "$row[0]", $statcell); 
		$xlsheet->write($ctcoord, "$row[3]", $countcell); 
		$xlsheet->write($timecoord, "$row[1]", $timecell); 
		$i++;
		$totaltime+=$row[2];
		$totalcount+=$row[3];
	}
	$ncrows=$i;
	$hours=floor($totaltime/3600);
	($sec, $min)=localtime($totaltime);
	if ($hours < 10) {$hours = "0$hours";}
	if ($sec < 10) {$sec = "0$sec";}
	if ($min < 10) {$min = "0$min";}
	$namecoord="B$i";
	$ctcoord="C$i";
	$timecoord="D$i";
	$xlsheet->write($namecoord, "TOTAL", $boldcell); 
	$xlsheet->write($ctcoord, "$totalcount", $boldcell); 
	$xlsheet->write($timecoord, "$hours:$min:$sec", $boldcell); 
	###############################################################

	##################### STATUS COUNT REPORT #####################
	$stmt="select status, sec_to_time(sum(length_in_sec)), sum(length_in_sec), count(*) from vicidial_log v, vicidial_users u where v.list_id like '88%' and call_date>='".$call_date."' and upper(campaign_id)='$campaign_id' and v.user=u.user group by status order by status asc";
	$rslt=$dbh->prepare($stmt);
	$rslt->execute();

	$xlsheet->merge_range('G1:K1', "$campaign STATUS REPORT", $rptheader);
	$xlsheet->write('H2', 'Name', $boldcell); 
	$xlsheet->write('I2', 'Calls', $boldcell); 
	$xlsheet->write('J2', 'Time Logged', $boldcell); 
	$i=3;
	$totalcount=0;
	$totaltime=0;
	while(@row=$rslt->fetchrow_array) {
		$namecoord="H$i";
		$ctcoord="I$i";
		$timecoord="J$i";
		$xlsheet->write($namecoord, "$row[0]", $statcell); 
		$xlsheet->write($ctcoord, "$row[3]", $countcell); 
		$xlsheet->write($timecoord, "$row[1]", $timecell); 
		$i++;
		$totaltime+=$row[2];
		$totalcount+=$row[3];
	}
	$scrows=$i;
	$hours=floor($totaltime/3600);
	($sec, $min)=localtime($totaltime);
	if ($hours < 10) {$hours = "0$hours";}
	if ($sec < 10) {$sec = "0$sec";}
	if ($min < 10) {$min = "0$min";}
	$namecoord="H$i";
	$ctcoord="I$i";
	$timecoord="J$i";
	$xlsheet->write($namecoord, "TOTAL", $boldcell); 
	$xlsheet->write($ctcoord, "$totalcount", $boldcell); 
	$xlsheet->write($timecoord, "$hours:$min:$sec", $boldcell); 
	###############################################################

	$stmt="select full_name, sec_to_time(sum(length_in_sec)), sum(length_in_sec), status, count(*), u.user from vicidial_log v, vicidial_users u where call_date>='".$call_date."' and v.list_id like '88%' and upper(campaign_id)='$campaign_id' and v.user=u.user group by full_name, status order by full_name, status asc";
	if ($scrows>=$ncrows) {$i=$scrows;} else {$i=$ncrows;}
	$nrow=$i+3;
	$rslt=$dbh->prepare($stmt);
	$rslt->execute();
	$ca=-1;
	$maxrow=0;
	@col_ary=();
	$col_ary[0]='A|B|C';
	$col_ary[1]='E|F|G';
	$col_ary[2]='I|J|K';

	$prev_name="";
	while(@row=$rslt->fetchrow_array) {
		$cur_name=$row[0];
		if ($cur_name eq $prev_name) {
			$i++;
			$statcoord=$col[0].$i;
			$ctcoord=$col[1].$i;
			$timecoord=$col[2].$i;
			$xlsheet->write($statcoord, "$row[3]", $statcell); 
			$xlsheet->write($ctcoord, "$row[4]", $countcell); 
			$xlsheet->write($timecoord, "$row[1]", $timecell);
			$totalcount+=$row[4];
			$totaltime+=$row[2];
		} else {
			if (length($prev_name)>0) {
				$hours=floor($totaltime/3600);
				($sec, $min)=localtime($totaltime);
				if ($hours < 10) {$hours = "0$hours";}
				if ($sec < 10) {$sec = "0$sec";}
				if ($min < 10) {$min = "0$min";}

				$i++;
				$statcoord=$col[0].$i;
				$ctcoord=$col[1].$i;
				$timecoord=$col[2].$i;
				$xlsheet->write($statcoord, "TOTALS", $boldcell); 
				$xlsheet->write($ctcoord, "$totalcount", $boldcell); 
				$xlsheet->write($timecoord, "$hours:$min:$sec", $boldcell); 
				$i++;

				############## GET TOTAL LOGIN/LOGOUT TIME #################
				$time_stmt="SELECT event,event_epoch,event_date,campaign_id from vicidial_user_log where user='$user_id' and event_date>='".$call_date."'";
#				print "\n".$time_stmt."\n";
				$time_rslt=$dbh->prepare($time_stmt);
				$time_rslt->execute();
				$event_start_seconds='';
				$event_stop_seconds='';
				$total_login_time=0;
				while(@time_row=$time_rslt->fetchrow_array) {
					if ($time_row[0]=~/LOGIN/) {
						$event_start_seconds = $time_row[1];
					}
					if ($time_row[0]=~/LOGOUT/ && $event_start_seconds) {
						$event_stop_seconds = $time_row[1];
						$event_seconds = ($event_stop_seconds - $event_start_seconds);
#						print "$event_seconds = ($event_stop_seconds - $event_start_seconds)\n";
						$total_login_time+=$event_seconds;
						$event_start_seconds='';
						$event_stop_seconds='';
					}
				}
				$statcoord=$col[0].$i;
				$ctcoord=$col[1].$i;
				$timecoord=$col[2].$i;
				$time_stmt="select sec_to_time($total_login_time)";
				$time_rslt=$dbh->prepare($time_stmt);
				$time_rslt->execute();
				@time_row=$time_rslt->fetchrow_array;
				$xlsheet->merge_range("$statcoord:$ctcoord", "TOTAL LOGIN TIME:", $boldcell); 
				$xlsheet->write($timecoord, "$time_row[0]", $boldcell); 
				############################################################

			}

			$totalcount=0;
			$totaltime=0;
			
			if ($i>$maxrow) {
				$maxrow=$i;
			}
			$ca++;
			if ($ca%3==0) {
				$nrow=$maxrow+2;
			}

			@col=split(/\|/, $col_ary[($ca%3)]);

			$i=$nrow;
			############### INDIVIDUAL REPORT HEADER ###################
			$titlecoords=$col[0].$i.':'.$col[2].$i;
			$xlsheet->merge_range($titlecoords, "$row[0]", $rptheader);
			$i++;
			$statcoord=$col[0].$i;
			$ctcoord=$col[1].$i;
			$timecoord=$col[2].$i;
			$xlsheet->write($statcoord, "Status", $boldcell); 
			$xlsheet->write($ctcoord, "Count", $boldcell);
			$xlsheet->write($timecoord, "Time", $boldcell);
			############################################################
			$i++;
			$statcoord=$col[0].$i;
			$ctcoord=$col[1].$i;
			$timecoord=$col[2].$i;
			$xlsheet->write($statcoord, "$row[3]", $statcell); 
			$xlsheet->write($ctcoord, "$row[4]", $countcell); 
			$xlsheet->write($timecoord, "$row[1]", $timecell);
			$totalcount+=$row[4];
			$totaltime+=$row[2];
		}
		$prev_name=$cur_name;
		$user_id=$row[5];
		$user_id=$row[5];
	}
	$i++;
	$statcoord=$col[0].$i;
	$ctcoord=$col[1].$i;
	$timecoord=$col[2].$i;
	$hours=floor($totaltime/3600);
	($sec, $min)=localtime($totaltime);
	if ($hours < 10) {$hours = "0$hours";}
	if ($sec < 10) {$sec = "0$sec";}
	if ($min < 10) {$min = "0$min";}
	$xlsheet->write($statcoord, "TOTALS", $boldcell); 
	$xlsheet->write($ctcoord, "$totalcount", $boldcell); 
	$xlsheet->write($timecoord, "$hours:$min:$sec", $boldcell); 

	############## GET TOTAL LOGIN/LOGOUT TIME #################
	$i++;
	$time_stmt="SELECT event,event_epoch,event_date,campaign_id from vicidial_user_log where user='$user_id' and event_date>='".$call_date."'";
	$time_rslt=$dbh->prepare($time_stmt);
	$time_rslt->execute();
	$event_start_seconds='';
	$event_stop_seconds='';
	$total_login_time=0;
	while(@time_row=$time_rslt->fetchrow_array) {
		if ($time_row[0]=~/LOGIN/) {
			$event_start_seconds = $time_row[1];
		}
		if ($time_row[0]=~/LOGOUT/) {
			$event_stop_seconds = $time_row[1];
			$event_seconds = ($event_stop_seconds - $event_start_seconds);
			$total_login_time+=$event_seconds;
#			print "$event_seconds = ($event_stop_seconds - $event_start_seconds)\n";
			$event_start_seconds='';
			$event_stop_seconds='';
		}
	}
	$statcoord=$col[0].$i;
	$ctcoord=$col[1].$i;
	$timecoord=$col[2].$i;
	$time_stmt="select sec_to_time($total_login_time)";
	$time_rslt=$dbh->prepare($time_stmt);
	$time_rslt->execute();
	@time_row=$time_rslt->fetchrow_array;
	$xlsheet->merge_range("$statcoord:$ctcoord", "TOTAL LOGIN TIME:", $boldcell); 
	$xlsheet->write($timecoord, "$time_row[0]", $boldcell); 
	############################################################

	$xl->close();
}
##########################################
##########################################

`zip /home/cron/vicidial/REPORTS/MWCOF_$cdate/VICIDIAL_MWCOF_rpts_$cdate.zip -j /home/cron/vicidial/REPORTS/MWCOF_$cdate/*`;

$boundary = "====" . time() . "====";

%mail = (
         # SMTP => 'smtp.vicimarketing.com',
         from => 'joej@vicimarketing.com',
         to => 'snihat@vicimarketing.com; vdelcorso@vicimarketing.com; blime@vicimarketing.com; cnihat@vicimarketing.com; joej@vicimarketing.com; mattf@vicimarketing.com; pryley@vicimarketing.com; bfisher@vicimarketing.com; jsnee@vicimarketing.com',
         # to => 'joej@vicimarketing.com',
		 subject => "VICIDIAL reports for MWCOF ".substr($call_date, 0, 10)." shift",
         'content-type' => "multipart/mixed; boundary=\"$boundary\""
        );

open(STORAGE, " < /home/cron/vicidial/REPORTS/MWCOF_$cdate/VICIDIAL_MWCOF_rpts_$cdate.zip") or die "File /home/cron/vicidial/REPORTS/MWCOF_$cdate/VICIDIAL_MWCOF_rpts_$cdate.zip cannot be found/opened";
binmode STORAGE; undef $/;
$mail{body}.=encode_base64(<STORAGE>);
close STORAGE;

$boundary = '--'.$boundary;

$mail{body} = <<END_OF_BODY;
$boundary
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

$plain

$boundary
Content-Type: application/octet-stream; name="VICIDIAL_MWCOF_rpts_$cdate.zip"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="VICIDIAL_MWCOF_rpts_$cdate.zip"

$mail{body}
END_OF_BODY


sendmail(%mail) || die "Error: $Mail::Sendmail::error\\r\n";

