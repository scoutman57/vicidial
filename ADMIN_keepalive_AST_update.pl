#!/usr/bin/perl -w
#
# ADMIN_keepalive_AST_update.pl
#
# designed to keep the AST_update processes aline and check every minute


@psoutput = `ps -f -C AST_update --no-headers`;

$running_11 = 0;
$running_12 = 0;

$i=0;
foreach (@psoutput)
{
	chomp($psoutput[$i]);
#   print "$i|$psoutput[$i]|     ";
@psline = split(/\/usr\/bin\/perl /,$psoutput[$i]);
#   print "|$psline[1]|\n";

if ($psline[1] =~ /\/home\/cron\/AST_update\.pl/) {$running_11++;}
if ($psline[1] =~ /\/home\/cron\/AST_update\.pl/) {$running_12++;}

$i++;
}


if (!$running_12)
{
	#   print "double check that update_12 is not running\n";

	sleep(5);

@psoutput2 = `ps -f -C AST_update --no-headers`;
$i=0;
foreach (@psoutput2)
	{
		chomp($psoutput2[$i]);
	#   print "$i|$psoutput2[$i]|     ";
	@psline = split(/\/usr\/bin\/perl /,$psoutput2[$i]);
	#   print "|$psline[1]|\n";

	if ($psline[1] =~ /\/home\/cron\/AST_update\.pl/) {$running_12++;}

	$i++;
	}

if (!$running_12)
	{
	`/usr/bin/screen -d -L -m /home/cron/AST_update.pl`;
	#   print "starting update_12...\n";
	}
}




	#   print "DONE\n";

exit;
