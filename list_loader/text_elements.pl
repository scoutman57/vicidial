#!/usr/local/ActivePerl-5.8/bin/perl -w
# perlTK_module.pl version 1.0      for Perl/Tk
# by Joe Johnson - joej@vicimarketing.com  10/13/2003
#
# Description:
# Desktop application that allows telemarketers to interact with evoDialer and pass sales data to VICI's databases
#
# Distributed with no waranty under the GNU Public License

use lib ".\\",".\\libs", './', './libs', '../libs', '/usr/local/perl_TK/libs', 'C:\\AST_VICI\\libs';
use English;
use Tk;
use POSIX;
use Tk::BrowseEntry;

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "File Name:"
)->place(
	-x => '90',
	-y => '20',
	-anchor => 'e'
);

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "Delimiter:"
)->place(
	-x => '90',
	-y => '50',
	-anchor => 'e'
);

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "List ID:"
)->place(
	-x => '90',
	-y => '80',
	-anchor => 'e'
);

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "Country:"
)->place(
	-x => '250',
	-y => '80',
	-anchor => 'e'
);

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "Errata:"
)->place(
	-x => '95',
	-y => '125',
	-anchor => 'e'
);

$errata=$MW->Scrolled("Text",
	-font => "{Arial} 9 {bold}",
	-wrap => "word",
	-height => 10,
	-width => 65,
	-scrollbars => 'e',
	-spacing1 => 0
)->place(
	-x => '95',
	-y => '270',
	-anchor => 'sw'
);

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "Good records: "
)->place(
	-x => '475',
	-y => '300',
	-anchor => 'e'
);

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "Bad records: "
)->place(
	-x => '475',
	-y => '340',
	-anchor => 'e'
);

$MW->Label(
	-font => "{Arial} 9 {bold}",
	-background => '#CCCCCC',
	-text => "Total records: "
)->place(
	-x => '475',
	-y => '380',
	-anchor => 'e'
);

$MW->Label(
	-background => '#CCCCCC',
	-text => "Version 1.yo-mama - Written by Joseph Johnson\n<joej\@vicimarketing.com>"
 )->place(
	-x => '300',
	-y => '480',
	-anchor => 'center'
 );

