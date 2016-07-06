#!/usr/bin/perl
use Spreadsheet::WriteExcel;

%tsrs=();
$filename=$ARGV[0];
$shift=substr($filename, 15, 10);

open(SALES, "< /home/www/htdocs/vicidial/MWKS_sales/$filename");
while($buffer=<SALES>) {
	@row=split(/\|/, $buffer);
	if ($row[19]=~/CL_GALLERIA/i) {
		if ($row[6]!~/N/i) {
			$tsrs{$row[1]}[0]++;
		}
		if ($row[7]!~/N/i) {
			$tsrs{$row[1]}[1]++;
		}
		if ($row[8]!~/N/i) {
			$tsrs{$row[1]}[2]++;
		}
	}
}
close(SALES);


$xl = Spreadsheet::WriteExcel->new("/home/www/htdocs/vicidial/mwks_sales_report.xls");
$xlsheet = $xl->add_worksheet();
$xlsheet->set_landscape();
$rptheader = $xl->add_format(); # Add a format
$rptheader->set_bold();
$rptheader->set_size('8');
$rptheader->set_color('10');
$rptheader->set_align('center');

$normcell = $xl->add_format(); # Add a format
$normcell->set_size('8');
$normcell->set_align('center');
$normcell->set_bg_color('22');

$boldcell = $xl->add_format(); # Add a format
$boldcell->set_bold();
$boldcell->set_size('8');
$boldcell->set_align('center');
$boldcell->set_bg_color('22');

$dollarformat = $xl->add_format(); # Add a format
$dollarformat->set_size('8');
$dollarformat->set_num_format('$0.00');

$intformat = $xl->add_format(); # Add a format
$intformat->set_size('8');
$intformat->set_num_format('0');

$numberformat = $xl->add_format(); # Add a format
$numberformat->set_size('8');
$numberformat->set_num_format('0.00');

$pformat = $xl->add_format(); # Add a format
$pformat->set_size('8');
$pformat->set_num_format('0.00%');

$statcell = $xl->add_format(num_format => '@'); # Add a format
$statcell->set_size('8');

$countcell = $xl->add_format(); # Add a format
$countcell->set_size('8');
$countcell->set_bg_color('35');

$terminateheader = $xl->add_format(); # Add a format
$terminateheader->set_bold();
$terminateheader->set_size('8');
$terminateheader->set_color('10');
$terminateheader->set_num_format('0.00');

$xlsheet->merge_range("A1:H1", "Verification stats", $rptheader);
$xlsheet->write("A2", "Verifier Name", $rptheader);
$xlsheet->write("B2", "Main sale", $rptheader);
$xlsheet->write("C2", "Upsell 1", $rptheader);
$xlsheet->write("D2", "Upsell 1 %", $rptheader);
$xlsheet->write("E2", "Upsell 2", $rptheader);
$xlsheet->write("F2", "Upsell 2 %", $rptheader);
$xlsheet->write("G2", "Commission", $rptheader);
$xlsheet->write("H2", "Total Gross", $rptheader);

$x=3;
foreach $tsrname (sort(keys(%tsrs))) {
#   print "$tsrname:\t";
#   print $tsrs{$tsrname}[0]."\t";
#   print $tsrs{$tsrname}[1]."\t";
#   print $tsrs{$tsrname}[2]."\t";
#   print "\n";
    $xlsheet->write("A$x", "$tsrname", $normcell);
    $xlsheet->write("B$x", "=$tsrs{$tsrname}[0]+0", $intformat);
    $xlsheet->write("C$x", "=$tsrs{$tsrname}[1]+0", $intformat);
    $xlsheet->write("D$x", "=C$x/B$x", $pformat);
    $xlsheet->write("E$x", "=$tsrs{$tsrname}[2]+0", $intformat);
    $xlsheet->write("F$x", "=E$x/B$x", $pformat);
    $xlsheet->write("G$x", "=SUM(C$x,E$x)", $intformat);
    $xlsheet->write("H$x", "=SUM(B$x,C$x,E$x)", $intformat);
    $x++;
}

$y=($x+1);
$xlsheet->write("A$y", "Total", $boldcell);
$xlsheet->write("B$y", "=SUM(B3:B$x)", $intformat);
$xlsheet->write("C$y", "=SUM(C3:C$x)", $intformat);
$xlsheet->write("D$y", "=C$y/B$y", $pformat);
$xlsheet->write("E$y", "=SUM(E3:E$x)", $intformat);
$xlsheet->write("F$y", "=E$y/B$y", $pformat);
$xlsheet->write("G$y", "=SUM(C$y,E$y)", $intformat);
$xlsheet->write("H$y", "=SUM(B$y,C$y,E$y)", $intformat);

$xl->close();


%fronters=();
open(SALES, "< /home/www/htdocs/vicidial/MWKS_sales/$filename");
while($buffer=<SALES>) {
	@row=split(/\|/, $buffer);
	if ($row[19]=~/CL_GALLERIA/i) {
		if ($row[6]!~/N/i) {
			$fronters{$row[0]}[0]++;
		}
		if ($row[7]!~/N/i) {
			$fronters{$row[0]}[1]++;
		}
		if ($row[8]!~/N/i) {
			$fronters{$row[0]}[2]++;
		}
	}
}
close(SALES);

$xl = Spreadsheet::WriteExcel->new("/home/www/htdocs/vicidial/mwks_fronter_report.xls");
$xlsheet = $xl->add_worksheet();
$xlsheet->set_landscape();
$rptheader = $xl->add_format(); # Add a format
$rptheader->set_bold();
$rptheader->set_size('8');
$rptheader->set_color('10');
$rptheader->set_align('center');

$normcell = $xl->add_format(); # Add a format
$normcell->set_size('8');
$normcell->set_align('center');
$normcell->set_bg_color('22');

$boldcell = $xl->add_format(); # Add a format
$boldcell->set_bold();
$boldcell->set_size('8');
$boldcell->set_align('center');
$boldcell->set_bg_color('22');

$dollarformat = $xl->add_format(); # Add a format
$dollarformat->set_size('8');
$dollarformat->set_num_format('$0.00');

$intformat = $xl->add_format(); # Add a format
$intformat->set_size('8');
$intformat->set_num_format('0');

$numberformat = $xl->add_format(); # Add a format
$numberformat->set_size('8');
$numberformat->set_num_format('0.00');

$pformat = $xl->add_format(); # Add a format
$pformat->set_size('8');
$pformat->set_num_format('0.00%');

$statcell = $xl->add_format(num_format => '@'); # Add a format
$statcell->set_size('8');

$countcell = $xl->add_format(); # Add a format
$countcell->set_size('8');
$countcell->set_bg_color('35');

$terminateheader = $xl->add_format(); # Add a format
$terminateheader->set_bold();
$terminateheader->set_size('8');
$terminateheader->set_color('10');
$terminateheader->set_num_format('0.00');

$xlsheet->merge_range("A1:H1", "Fronter stats", $rptheader);
$xlsheet->write("A2", "Fronter Name", $rptheader);
$xlsheet->write("B2", "Main sale", $rptheader);
$xlsheet->write("C2", "Upsell 1", $rptheader);
$xlsheet->write("D2", "Upsell 1 %", $rptheader);
$xlsheet->write("E2", "Upsell 2", $rptheader);
$xlsheet->write("F2", "Upsell 2 %", $rptheader);
$xlsheet->write("G2", "Commission", $rptheader);
$xlsheet->write("H2", "Total Gross", $rptheader);

$x=3;
foreach $tsrname (sort(keys(%fronters))) {
#   print "$tsrname:\t";
#   print $tsrs{$tsrname}[0]."\t";
#   print $tsrs{$tsrname}[1]."\t";
#   print $tsrs{$tsrname}[2]."\t";
#   print "\n";
    $xlsheet->write("A$x", "$tsrname", $normcell);
    $xlsheet->write("B$x", "=$fronters{$tsrname}[0]+0", $intformat);
    $xlsheet->write("C$x", "=$fronters{$tsrname}[1]+0", $intformat);
    $xlsheet->write("D$x", "=C$x/B$x", $pformat);
    $xlsheet->write("E$x", "=$fronters{$tsrname}[2]+0", $intformat);
    $xlsheet->write("F$x", "=E$x/B$x", $pformat);
    $xlsheet->write("G$x", "=SUM(C$x,E$x)", $intformat);
    $xlsheet->write("H$x", "=SUM(B$x,C$x,E$x)", $intformat);
    $x++;
}

$y=($x+1);
$xlsheet->write("A$y", "Total", $boldcell);
$xlsheet->write("B$y", "=SUM(B3:B$x)", $intformat);
$xlsheet->write("C$y", "=SUM(C3:C$x)", $intformat);
$xlsheet->write("D$y", "=C$y/B$y", $pformat);
$xlsheet->write("E$y", "=SUM(E3:E$x)", $intformat);
$xlsheet->write("F$y", "=E$y/B$y", $pformat);
$xlsheet->write("G$y", "=SUM(C$y,E$y)", $intformat);
$xlsheet->write("H$y", "=SUM(B$y,C$y,E$y)", $intformat);

$xl->close();
