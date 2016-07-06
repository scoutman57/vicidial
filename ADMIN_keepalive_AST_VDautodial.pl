#!/usr/bin/perl
#
# ADMIN_keepalive_AST_VDauto_dial.pl
#
# designed to keep the AST_update processes aline and check every minute
$MT[0]='';   $MT[1]='';

@psline=@MT;

#@psoutput = `ps -f -C AST_update --no-headers`;
#@psoutput = `ps -f -C AST_updat* --no-headers`;
@psoutput = `/bin/ps -f --no-headers -A`;

$running_12 = 0;

$i=0;
foreach (@psoutput)
{
	chomp($psoutput[$i]);
 #  print "$i|$psoutput[$i]|     ";
@psline = split(/\/usr\/bin\/perl /,$psoutput[$i]);
 #  print "|$psline[1]|\n";

if ($psline[1] =~ /\/home\/cron\/AST_VDauto_dial\.pl/) {$running_12++;}

$i++;
}


if (!$running_12)
{
#	   print "double check that update is not running\n";

	sleep(5);

#@psoutput = `ps -f -C AST_update --no-headers`;
#@psoutput = `ps -f -C AST_updat* --no-headers`;
@psoutput = `/bin/ps -f --no-headers -A`;
$i=0;
foreach (@psoutput2)
	{
		chomp($psoutput2[$i]);
	#   print "$i|$psoutput2[$i]|     ";
	@psline = split(/\/usr\/bin\/perl /,$psoutput2[$i]);
	#   print "|$psline[1]|\n";

	if ($psline[1] =~ /\/home\/cron\/AST_VDauto_dial\.pl/) {$running_12++;}

	$i++;
	}

if (!$running_12)
	{
	`/usr/bin/screen -d -L -m /home/cron/AST_VDauto_dial.pl`;
	#   print "starting update_12...\n";
	}
}




	#   print "DONE\n";

exit;
