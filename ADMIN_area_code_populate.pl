#!/usr/bin/perl
# ADMIN_area_code_populate.pl version 1.1.12      for Perl
#
# Copyright (C) 2006  Joe Johnson,Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#
# Description:
# server application that allows load areacodes into to asterisk list database
#
#
# CHANGES
# 60615-1514 - Changed to ignore the header row
#

use lib ".\\",".\\libs", './', './libs', '../libs', '/usr/local/perl_TK/libs', 'C:\\AST_VICI\\libs';
use Time::HiRes ('gettimeofday','usleep','sleep');  # needed to have perl sleep in increments of less than one second
use Net::MySQL;

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

$dbh = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";


$slash_star = '\*';

	open(codefile, "/home/cron/phone_codes_GMT.txt") || die "can't open /home/cron/phone_codes_GMT.txt: $!\n";
	@codefile = <codefile>;
	close(codefile);
	$pc=0;
	$ins_stmt="insert into vicidial_phone_codes VALUES ";
	foreach (@codefile) 
	{
		@row=split(/\t/, $codefile[$pc]);
		if ($codefile[$pc] !~ /GEOGRAPHIC DESCRIPTION/)
		{
			$pc++;
			$row[7] =~ s/\r|\n|\t| $//gi;
			$row[6] =~ s/\r|\n|\t| $//gi;
			$row[5] =~ s/\r|\n|\t| $//gi;
			$row[4] =~ s/\r|\n|\t| $//gi;
			$row[3] =~ s/\r|\n|\t| $//gi;
			$row[2] =~ s/\r|\n|\t| $//gi;
			$row[1] =~ s/\r|\n|\t| $//gi;
			$row[0] =~ s/\r|\n|\t| $//gi;
			$ins_stmt.="('$row[0]', '$row[1]', '$row[2]', '$row[3]', '$row[4]', '$row[5]', '$row[6]', '$row[7]'), ";
			if ($pc =~ /00$/) 
			{
				chop($ins_stmt);
				chop($ins_stmt);
				$dbh->query($ins_stmt) || die "can't execute query: |$ins_stmt| $!\n";
				$ins_stmt="insert into vicidial_phone_codes VALUES ";
				print STDERR "$pc\n";
			}
		}
		else {$pc++;}
	}

	chop($ins_stmt);
	chop($ins_stmt);
	$dbh->query($ins_stmt);
	$ins_stmt="insert into vicidial_phone_codes VALUES ";
	print STDERR "$pc\n";

exit;