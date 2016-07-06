#!/usr/bin/perl
#
# ADMIN_keepalive_AST_send_listen.pl
#
# designed to keep the AST_manager_listen and manager_send processes alive and check every minute
#
# if you are on an older system you may need to change the @psoutput lines to fit your ps version
#

	sleep(2);

$MT[0]='';   $MT[1]='';

@psline=@MT;

#@psoutput = `ps -f -C AST_manager --no-headers`;
#@psoutput = `ps -f --no-headers -C AST_manager_s*; ps -f --no-headers -C AST_manager_l*`;
#@psoutput = `/bin/ps -f --no-headers -A`;
@psoutput = `/bin/ps -o "%p %a" --no-headers -A`;

$running_listen = 0;
$running_send = 0;

$i=0;
foreach (@psoutput)
{
	chomp($psoutput[$i]);
#   print "$i|$psoutput[$i]|     ";
@psline = split(/\/usr\/bin\/perl /,$psoutput[$i]);
#   print "|$psline[1]|\n";

if ($psline[1] =~ /AST_manager_li/) {$running_listen++;}
if ($psline[1] =~ /AST_manager_se/) {$running_send++;}

$i++;
}



if (!$running_listen)
{
	#   print "double check that update_11 is not running\n";

	sleep(1);

#@psoutput = `ps -f -C AST_manager --no-headers`;
#@psoutput = `ps -f --no-headers -C AST_manager_s*; ps -f --no-headers -C AST_manager_l*`;
#@psoutput = `/bin/ps -f --no-headers -A`;
@psoutput = `/bin/ps -o "%p %a" --no-headers -A`;

$i=0;
foreach (@psoutput2)
	{
		chomp($psoutput2[$i]);
	#   print "$i|$psoutput2[$i]|     ";
	@psline = split(/\/usr\/bin\/perl /,$psoutput2[$i]);
	#   print "|$psline[1]|\n";

	if ($psline[1] =~ /AST_manager_li/) {$running_listen++;}

	$i++;
	}

if (!$running_listen)
	{
#	   print "starting AST_manager_listen...\n";
	`/usr/bin/screen -d -L -m /home/cron/AST_manager_listen.pl`;
	}
}




if (!$running_send)
{
	#   print "double check that update_12 is not running\n";

	sleep(1);

#@psoutput = `ps -f -C AST_manager --no-headers`;
#@psoutput = `ps -f --no-headers -C AST_manager_s*; ps -f --no-headers -C AST_manager_l*`;
#@psoutput = `/bin/ps -f --no-headers -A`;
@psoutput = `/bin/ps -o "%p %a" --no-headers -A`;
$i=0;
foreach (@psoutput)
	{
		chomp($psoutput[$i]);
	#   print "$i|$psoutput[$i]|     ";
	@psline = split(/\/usr\/bin\/perl /,$psoutput[$i]);
	#   print "|$psline[1]|\n";

	if ($psline[1] =~ /AST_manager_se/) {$running_send++;}

	$i++;
	}

if (!$running_send)
	{
#	   print "starting AST_manager_send...\n";
	`/usr/bin/screen -d -L -m /home/cron/AST_manager_send.pl`;
	}
}




	#   print "DONE\n";

exit;
