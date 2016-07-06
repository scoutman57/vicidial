#!/usr/bin/perl

# install.pl
#
# Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#

############################################
# install.pl - puts server files in the right places and creates conf file
#
# default paths.
#
# default path to astguiclient configuration file:
$PATHconf =		'/etc/astguiclient.conf';
# default path to home directory:
$PATHhome =		'/usr/share/astguiclient';
# default path to astguiclient logs directory: 
$PATHlogs =		'/var/log/astguiclient';
# default path to asterisk agi-bin directory: 
$PATHagi =		'/var/lib/asterisk/agi-bin';
# default path to web root directory: 
#$PATHweb =		'/var/www/html';
#$PATHweb =		'/home/www/htdocs';
$PATHweb =		'/usr/local/apache2/htdocs';
# default path to asterisk sounds directory: 
$PATHsounds =	'/var/lib/asterisk/sounds';
# default path to asterisk recordings directory: 
$PATHmonitor =	'/var/spool/asterisk/monitor';
# default database server variables: 
$VARDB_server =	'localhost';
$VARDB_database =	'asterisk';
$VARDB_user =	'cron';
$VARDB_pass =	'1234';
$VARDB_port =	'3306';
# default keepalive processes: 
$VARactive_keepalives =		'123456';
# defaults for FastAGI Server PreFork
$VARfastagi_log_min_servers =	'3';
$VARfastagi_log_max_servers =	'16';
$VARfastagi_log_min_spare_servers = '2';
$VARfastagi_log_max_spare_servers = '8';
$VARfastagi_log_max_requests =	'1000';
$VARfastagi_log_checkfordead =	'30';
$VARfastagi_log_checkforwait =	'60';

############################################

$CLIhome=0;
$CLIlogs=0;
$CLIagi=0;
$CLIweb=0;
$CLIsounds=0;
$CLImonitor=0;
$CLIserver_ip=0;
$CLIDB_server=0;
$CLIDB_database=0;
$CLIDB_user=0;
$CLIDB_pass=0;
$CLIDB_port=0;
$CLIVARactive_keepalives=0;
$CLIVARfastagi_log_min_servers=0;
$CLIVARfastagi_log_max_servers=0;
$CLIVARfastagi_log_min_spare_servers=0;
$CLIVARfastagi_log_max_spare_servers=0;
$CLIVARfastagi_log_max_requests=0;
$CLIVARfastagi_log_checkfordead=0;
$CLIVARfastagi_log_checkforwait=0;

$COPYhome=0;
$COPYlogs=0;
$COPYagi=0;
$COPYweb=0;
$COPYsounds=0;
$COPYmonitor=0;

$secX = time();

# constants
$DB=1;  # Debug flag, set to 0 for no debug messages, lots of output
$US='_';
$MT[0]='';

### begin parsing run-time options ###
if (length($ARGV[0])>1)
{
	$i=0;
	while ($#ARGV >= $i)
	{
	$args = "$args $ARGV[$i]";
	$i++;
	}

	if ($args =~ /--help/i)
	{
	print "install.pl - installs astGUIclient server files in the proper places, this\n";
	print "script will look for an /etc/astguiclient.conf file for existing settings, and\n";
	print "if not present will prompt for proper information then copy files.\n";
	print "\n";
	print "installation options:\n";
	print "  [--help] = this help screen\n";
	print "  [--test] = test (will not copy files)\n";
	print "  [--debug] = verbose debug messages\n";
	print "  [--web-only] = only copy files/directories for web server install\n";
	print "  [--without-web] = do not copy web files/directories\n\n";
	print "configuration options:\n";
	print "  [--home=/path/from/root] = define home path from root at runtime\n";
	print "  [--logs=/path/from/root] = define logs path from root at runtime\n";
	print "  [--agi=/path/from/root] = define agi-bin path from root at runtime\n";
	print "  [--web=/path/from/root] = define webroot path from root at runtime\n";
	print "  [--sounds=/path/from/root] = define sounds path from root at runtime\n";
	print "  [--monitor=/path/from/root] = define monitor path from root at runtime\n";
	print "  [--server_ip=192.168.0.1] = define server IP address at runtime\n";
	print "  [--DB_server=localhost] = define database server IP address at runtime\n";
	print "  [--DB_database=localhost] = define database name at runtime\n";
	print "  [--DB_user=cron] = define database user login at runtime\n";
	print "  [--DB_pass=1234] = define database user password at runtime\n";
	print "  [--DB_port=3306] = define database connection port at runtime\n";
	print "  [--active_keepalives=123456] = define processes to keepalive\n";
	print "     X - NO KEEPALIVE PROCESSES (use only if you want none to be keepalive)\n";
	print "     1 - AST_update\n";
	print "     2 - AST_send_listen\n";
	print "     3 - AST_VDauto_dial\n";
	print "     4 - AST_VDremote_agents\n";
	print "     5 - AST_VDadapt (If multi-server system, this must only be on one server)\n";
	print "     6 - FastAGI_log\n";
	print "     7 - AST_VDauto_dial_FILL (only for multi-server, this must only be on one server)\n";
	print "  [--fastagi_log_min_servers=3] = define FastAGI log min servers\n";
	print "  [--fastagi_log_max_servers=16] = define FastAGI log max servers\n";
	print "  [--fastagi_log_min_spare_servers=2] = define FastAGI log min spare servers\n";
	print "  [--fastagi_log_max_spare_servers=8] = define FastAGI log max spare servers\n";
	print "  [--fastagi_log_max_requests=1000] = define FastAGI log max requests\n";
	print "  [--fastagi_log_checkfordead=30] = define FastAGI log check-for-dead seconds\n";
	print "  [--fastagi_log_checkforwait=60] = define FastAGI log check-for-wait seconds\n";
	print "\n";

	exit;
	}
	else
	{
		if ($args =~ /--debug/i) # Debug flag
		{
		$DB=1;
		}
		if ($args =~ /--test/i) # test flag
		{
		$TEST=1;   $T=1;
		}
		if ($args =~ /--web-only/i) # web-only flag
		{
		$WEBONLY=1;
		}
		if ($args =~ /--without-web/i) # without web flag
		{
		$NOWEB=1;
		}
		else
		{
		$NOWEB=0;
		}
		if ($args =~ /--home=/i) # CLI defined home path
		{
		@CLIhomeARY = split(/--home=/,$args);
		@CLIhomeARX = split(/ /,$CLIhomeARY[1]);
		if (length($CLIhomeARX[0])>2)
			{
			$PATHhome = $CLIhomeARX[0];
			$PATHhome =~ s/\/$| |\r|\n|\t//gi;
			$CLIhome=1;
			print "  CLI defined home path:      $PATHhome\n";
			}
		}
		if ($args =~ /--logs=/i) # CLI defined logs path
		{
		@CLIlogsARY = split(/--logs=/,$args);
		@CLIlogsARX = split(/ /,$CLIlogsARY[1]);
		if (length($CLIlogsARX[0])>2)
			{
			$PATHlogs = $CLIlogsARX[0];
			$PATHlogs =~ s/\/$| |\r|\n|\t//gi;
			$CLIlogs=1;
			print "  CLI defined logs path:      $PATHlogs\n";
			}
		}
		if ($args =~ /--agi=/i) # CLI defined agi-bin path
		{
		@CLIagiARY = split(/--agi=/,$args);
		@CLIagiARX = split(/ /,$CLIagiARY[1]);
		if (length($CLIagiARX[0])>2)
			{
			$PATHagi = $CLIagiARX[0];
			$PATHagi =~ s/\/$| |\r|\n|\t//gi;
			$CLIagi=1;
			print "  CLI defined agi-bin path:   $PATHagi\n";
			}
		}
		if ($args =~ /--web=/i) # CLI defined webroot path
		{
		@CLIwebARY = split(/--web=/,$args);
		@CLIwebARX = split(/ /,$CLIwebARY[1]);
		if (length($CLIwebARX[0])>2)
			{
			$PATHweb = $CLIwebARX[0];
			$PATHweb =~ s/\/$| |\r|\n|\t//gi;
			$CLIweb=1;
			print "  CLI defined webroot path:   $PATHweb\n";
			}
		}
		if ($args =~ /--sounds=/i) # CLI defined sounds path
		{
		@CLIsoundsARY = split(/--sounds=/,$args);
		@CLIsoundsARX = split(/ /,$CLIsoundsARY[1]);
		if (length($CLIsoundsARX[0])>2)
			{
			$PATHsounds = $CLIsoundsARX[0];
			$PATHsounds =~ s/\/$| |\r|\n|\t//gi;
			$CLIsounds=1;
			print "  CLI defined sounds path:    $PATHsounds\n";
			}
		}
		if ($args =~ /--monitor=/i) # CLI defined monitor path
		{
		@CLImonitorARY = split(/--monitor=/,$args);
		@CLImonitorARX = split(/ /,$CLImonitorARY[1]);
		if (length($CLImonitorARX[0])>2)
			{
			$PATHmonitor = $CLImonitorARX[0];
			$PATHmonitor =~ s/\/$| |\r|\n|\t//gi;
			$CLImonitor=1;
			print "  CLI defined monitor path:   $PATHmonitor\n";
			}
		}
		if ($args =~ /--server_ip=/i) # CLI defined server IP address
		{
		@CLIserver_ipARY = split(/--server_ip=/,$args);
		@CLIserver_ipARX = split(/ /,$CLIserver_ipARY[1]);
		if (length($CLIserver_ipARX[0])>2)
			{
			$VARserver_ip = $CLIserver_ipARX[0];
			$VARserver_ip =~ s/\/$| |\r|\n|\t//gi;
			$CLIserver_ip=1;
			print "  CLI defined server IP:      $VARserver_ip\n";
			}
		}
		if ($args =~ /--DB_server=/i) # CLI defined Database server address
		{
		@CLIDB_serverARY = split(/--DB_server=/,$args);
		@CLIDB_serverARX = split(/ /,$CLIDB_serverARY[1]);
		if (length($CLIDB_serverARX[0])>2)
			{
			$VARDB_server = $CLIDB_serverARX[0];
			$VARDB_server =~ s/\/$| |\r|\n|\t//gi;
			$CLIDB_server=1;
			print "  CLI defined DB server:      $VARDB_server\n";
			}
		}
		if ($args =~ /--DB_database=/i) # CLI defined Database name
		{
		@CLIDB_databaseARY = split(/--DB_database=/,$args);
		@CLIDB_databaseARX = split(/ /,$CLIDB_databaseARY[1]);
		if (length($CLIDB_databaseARX[0])>1)
			{
			$VARDB_database = $CLIDB_databaseARX[0];
			$VARDB_database =~ s/ |\r|\n|\t//gi;
			$CLIDB_database=1;
			print "  CLI defined DB database:    $VARDB_database\n";
			}
		}
		if ($args =~ /--DB_user=/i) # CLI defined Database user login
		{
		@CLIDB_userARY = split(/--DB_user=/,$args);
		@CLIDB_userARX = split(/ /,$CLIDB_userARY[1]);
		if (length($CLIDB_userARX[0])>1)
			{
			$VARDB_user = $CLIDB_userARX[0];
			$VARDB_user =~ s/ |\r|\n|\t//gi;
			$CLIDB_user=1;
			print "  CLI defined DB user:        $VARDB_user\n";
			}
		}
		if ($args =~ /--DB_pass=/i) # CLI defined Database user password
		{
		@CLIDB_passARY = split(/--DB_pass=/,$args);
		@CLIDB_passARX = split(/ /,$CLIDB_passARY[1]);
		if (length($CLIDB_passARX[0])>1)
			{
			$VARDB_pass = $CLIDB_passARX[0];
			$VARDB_pass =~ s/ |\r|\n|\t//gi;
			$CLIDB_pass=1;
			print "  CLI defined DB password:    $VARDB_pass\n";
			}
		}
		if ($args =~ /--DB_port=/i) # CLI defined Database connection port
		{
		@CLIDB_portARY = split(/--DB_port=/,$args);
		@CLIDB_portARX = split(/ /,$CLIDB_portARY[1]);
		if (length($CLIDB_portARX[0])>1)
			{
			$VARDB_port = $CLIDB_portARX[0];
			$VARDB_port =~ s/ |\r|\n|\t//gi;
			$CLIDB_port=1;
			print "  CLI defined DB port:        $VARDB_port\n";
			}
		}
		if ($args =~ /--active_keepalives=/i) # CLI defined keepalive processes
		{
		@CLIkeepaliveARY = split(/--active_keepalives=/,$args);
		@CLIkeepaliveARX = split(/ /,$CLIkeepaliveARY[1]);
		if (length($CLIkeepaliveARX[0])>1)
			{
			$VARactive_keepalives = $CLIkeepaliveARX[0];
			$VARactive_keepalives =~ s/ |\r|\n|\t//gi;
			$CLIactive_keepalives=1;
			print "  CLI active keepalive procs: $VARactive_keepalives\n";
			}
		}
		if ($args =~ /--fastagi_log_min_servers=/i) # CLI defined fastagi min servers
		{
		@CLIDB_minserARY = split(/--fastagi_log_min_servers=/,$args);
		@CLIDB_minserARX = split(/ /,$CLIDB_minserARY[1]);
		if (length($CLIDB_minserARX[0])>1)
			{
			$VARfastagi_log_min_servers = $CLIDB_minserARX[0];
			$VARfastagi_log_min_servers =~ s/ |\r|\n|\t//gi;
			$CLIfastagi_log_min_servers=1;
			print "  CLI defined log min server: $VARfastagi_log_min_servers\n";
			}
		}
		if ($args =~ /--fastagi_log_max_servers=/i) # CLI defined fastagi max servers
		{
		@CLIDB_maxserARY = split(/--fastagi_log_max_servers=/,$args);
		@CLIDB_maxserARX = split(/ /,$CLIDB_maxserARY[1]);
		if (length($CLIDB_maxserARX[0])>1)
			{
			$VARfastagi_log_max_servers = $CLIDB_maxserARX[0];
			$VARfastagi_log_max_servers =~ s/ |\r|\n|\t//gi;
			$CLIfastagi_log_max_servers=1;
			print "  CLI defined log max server: $VARfastagi_log_max_servers\n";
			}
		}
		if ($args =~ /--fastagi_log_min_spare_servers=/i) # CLI defined fastagi min spare servers
		{
		@CLIDB_minspaARY = split(/--fastagi_log_min_spare_servers=/,$args);
		@CLIDB_minspaARX = split(/ /,$CLIDB_minspaARY[1]);
		if (length($CLIDB_minspaARX[0])>1)
			{
			$VARfastagi_log_min_spare_servers = $CLIDB_minspaARX[0];
			$VARfastagi_log_min_spare_servers =~ s/ |\r|\n|\t//gi;
			$CLIfastagi_log_min_spare_servers=1;
			print "  CLI defined log min spare:  $VARfastagi_log_min_spare_servers\n";
			}
		}
		if ($args =~ /--fastagi_log_max_spare_servers=/i) # CLI defined fastagi max spare servers
		{
		@CLIDB_maxspaARY = split(/--fastagi_log_max_spare_servers=/,$args);
		@CLIDB_maxspaARX = split(/ /,$CLIDB_maxspaARY[1]);
		if (length($CLIDB_maxspaARX[0])>1)
			{
			$VARfastagi_log_max_spare_servers = $CLIDB_maxspaARX[0];
			$VARfastagi_log_max_spare_servers =~ s/ |\r|\n|\t//gi;
			$CLIfastagi_log_max_spare_servers=1;
			print "  CLI defined log max spare:  $VARfastagi_log_max_spare_servers\n";
			}
		}
		if ($args =~ /--fastagi_log_max_requests=/i) # CLI defined fastagi max requests
		{
		@CLIDB_maxreqARY = split(/--fastagi_log_max_requests=/,$args);
		@CLIDB_maxreqARX = split(/ /,$CLIDB_maxreqARY[1]);
		if (length($CLIDB_maxreqARX[0])>1)
			{
			$VARfastagi_log_max_requests = $CLIDB_maxreqARX[0];
			$VARfastagi_log_max_requests =~ s/ |\r|\n|\t//gi;
			$CLIfastagi_log_max_requests=1;
			print "  CLI defined log max request:$VARfastagi_log_max_requests\n";
			}
		}
		if ($args =~ /--fastagi_log_checkfordead=/i) # CLI defined fastagi check-for-dead seconds
		{
		@CLIDB_ckdeadARY = split(/--fastagi_log_checkfordead=/,$args);
		@CLIDB_ckdeadARX = split(/ /,$CLIDB_ckdeadARY[1]);
		if (length($CLIDB_ckdeadARX[0])>1)
			{
			$VARfastagi_log_checkfordead = $CLIDB_ckdeadARX[0];
			$VARfastagi_log_checkfordead =~ s/ |\r|\n|\t//gi;
			$CLIfastagi_log_checkfordead=1;
			print "  CLI defined log ckdead sec: $VARfastagi_log_checkfordead\n";
			}
		}
		if ($args =~ /--fastagi_log_checkforwait=/i) # CLI defined fastagi check-for-wait seconds
		{
		@CLIDB_ckwaitARY = split(/--fastagi_log_checkforwait=/,$args);
		@CLIDB_ckwaitARX = split(/ /,$CLIDB_ckwaitARY[1]);
		if (length($CLIDB_ckwaitARX[0])>1)
			{
			$VARfastagi_log_checkforwait = $CLIDB_ckwaitARX[0];
			$VARfastagi_log_checkforwait =~ s/ |\r|\n|\t//gi;
			$CLIfastagi_log_checkforwait=1;
			print "  CLI defined log ckwait sec: $VARfastagi_log_checkforwait\n";
			}
		}
	}
}
else
{
#	print "no command line options set\n";
}
### end parsing run-time options ###

if (-e "$PATHconf") 
	{
	print "Previous astGUIclient configuration file found at: $PATHconf\n";
	open(conf, "$PATHconf") || die "can't open $PATHconf: $!\n";
	@conf = <conf>;
	close(conf);
	$i=0;
	foreach(@conf)
		{
		$line = $conf[$i];
		$line =~ s/ |>|\n|\r|\t|\#.*|;.*//gi;
		if ( ($line =~ /^PATHhome/) && ($CLIhome < 1) )
			{$PATHhome = $line;   $PATHhome =~ s/.*=//gi;}
		if ( ($line =~ /^PATHlogs/) && ($CLIlogs < 1) )
			{$PATHlogs = $line;   $PATHlogs =~ s/.*=//gi;}
		if ( ($line =~ /^PATHagi/) && ($CLIagi < 1) )
			{$PATHagi = $line;   $PATHagi =~ s/.*=//gi;}
		if ( ($line =~ /^PATHweb/) && ($CLIweb < 1) )
			{$PATHweb = $line;   $PATHweb =~ s/.*=//gi;}
		if ( ($line =~ /^PATHsounds/) && ($CLIsounds < 1) )
			{$PATHsounds = $line;   $PATHsounds =~ s/.*=//gi;}
		if ( ($line =~ /^PATHmonitor/) && ($CLImonitor < 1) )
			{$PATHmonitor = $line;   $PATHmonitor =~ s/.*=//gi;}
		if ( ($line =~ /^VARserver_ip/) && ($CLIserver_ip < 1) )
			{$VARserver_ip = $line;   $VARserver_ip =~ s/.*=//gi;}
		if ( ($line =~ /^VARDB_server/) && ($CLIDB_server < 1) )
			{$VARDB_server = $line;   $VARDB_server =~ s/.*=//gi;}
		if ( ($line =~ /^VARDB_database/) && ($CLIDB_database < 1) )
			{$VARDB_database = $line;   $VARDB_database =~ s/.*=//gi;}
		if ( ($line =~ /^VARDB_user/) && ($CLIDB_user < 1) )
			{$VARDB_user = $line;   $VARDB_user =~ s/.*=//gi;}
		if ( ($line =~ /^VARDB_pass/) && ($CLIDB_pass < 1) )
			{$VARDB_pass = $line;   $VARDB_pass =~ s/.*=//gi;}
		if ( ($line =~ /^VARDB_port/) && ($CLIDB_port < 1) )
			{$VARDB_port = $line;   $VARDB_port =~ s/.*=//gi;}
		if ( ($line =~ /^VARactive_keepalives/) && ($CLIactive_keepalives < 1) )
			{$VARactive_keepalives = $line;   $VARactive_keepalives =~ s/.*=//gi;}
		if ( ($line =~ /^VARfastagi_log_min_servers/) && ($CLIVARfastagi_log_min_servers < 1) )
			{$VARfastagi_log_min_servers = $line;   $VARfastagi_log_min_servers =~ s/.*=//gi;}
		if ( ($line =~ /^VARfastagi_log_max_servers/) && ($CLIVARfastagi_log_max_servers < 1) )
			{$VARfastagi_log_max_servers = $line;   $VARfastagi_log_max_servers =~ s/.*=//gi;}
		if ( ($line =~ /^VARfastagi_log_min_spare_servers/) && ($CLIVARfastagi_log_min_spare_servers < 1) )
			{$VARfastagi_log_min_spare_servers = $line;   $VARfastagi_log_min_spare_servers =~ s/.*=//gi;}
		if ( ($line =~ /^VARfastagi_log_max_spare_servers/) && ($CLIVARfastagi_log_max_spare_servers < 1) )
			{$VARfastagi_log_max_spare_servers = $line;   $VARfastagi_log_max_spare_servers =~ s/.*=//gi;}
		if ( ($line =~ /^VARfastagi_log_max_requests/) && ($CLIVARfastagi_log_max_requests < 1) )
			{$VARfastagi_log_max_requests = $line;   $VARfastagi_log_max_requests =~ s/.*=//gi;}
		if ( ($line =~ /^VARfastagi_log_checkfordead/) && ($CLIVARfastagi_log_checkfordead < 1) )
			{$VARfastagi_log_checkfordead = $line;   $VARfastagi_log_checkfordead =~ s/.*=//gi;}
		if ( ($line =~ /^VARfastagi_log_checkforwait/) && ($CLIVARfastagi_log_checkforwait < 1) )
			{$VARfastagi_log_checkforwait = $line;   $VARfastagi_log_checkforwait =~ s/.*=//gi;}
		$i++;
		}
	}

print("\nWould you like to use manual configuration and installation(y/n): [y] ");
$manual = <STDIN>;
chomp($manual);
if ($manual =~ /n/i)
	{
	$manual=0;
	}
else
	{
	$config_finished='NO';
	while ($config_finished =~/NO/)
		{
		print "\nSTARTING ASTGUICLIENT MANUAL CONFIGURATION PHASE...\n";
		##### BEGIN astguiclient home directory prompting and existence check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nastguiclient home path or press enter for default: [$PATHhome] ");
			$PROMPThome = <STDIN>;
			chomp($PROMPThome);
			if (length($PROMPThome)>2)
				{
				$PROMPThome =~ s/ |\n|\r|\t|\/$//gi;
				if (!-e "$PROMPThome")
					{
					print("$PROMPThome does not exist, would you like me to create it?(y/n) [y] ");
					$createPROMPThome = <STDIN>;
					chomp($createPROMPThome);
					if ($createPROMPThome =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PROMPThome`;
							print "     $PROMPThome directory created\n";
						$PATHhome=$PROMPThome;
						$continue='YES';
						}
					}
				else
					{
					$PATHhome=$PROMPThome;
					$continue='YES';
					}
				}
			else
				{
				if (!-e "$PATHhome")
					{
					print("$PATHhome does not exist, would you like me to create it?(y/n) [y] ");
					$createPATHhome = <STDIN>;
					chomp($createPATHhome);
					if ($createPATHhome =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PATHhome`;
							print "     $PATHhome directory created\n";
						$continue='YES';
						}
					}
				else
					{
					$continue='YES';
					}
				}
			}
		##### END astguiclient home directory prompting and existence check #####

		##### BEGIN astguiclient logs directory prompting and existence check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nastguiclient logs path or press enter for default: [$PATHlogs] ");
			$PROMPTlogs = <STDIN>;
			chomp($PROMPTlogs);
			if (length($PROMPTlogs)>2)
				{
				$PROMPTlogs =~ s/ |\n|\r|\t|\/$//gi;
				if (!-e "$PROMPTlogs")
					{
					print("$PROMPTlogs does not exist, would you like me to create it?(y/n) [y] ");
					$createPROMPTlogs = <STDIN>;
					chomp($createPROMPTlogs);
					if ($createPROMPTlogs =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PROMPTlogs`;
							print "     $PROMPTlogs directory created\n";
						$PATHlogs=$PROMPTlogs;
						$continue='YES';
						}
					}
				else
					{
					$PATHlogs=$PROMPTlogs;
					$continue='YES';
					}
				}
			else
				{
				if (!-e "$PATHlogs")
					{
					print("$PATHlogs does not exist, would you like me to create it?(y/n) [y] ");
					$createPATHlogs = <STDIN>;
					chomp($createPATHlogs);
					if ($createPATHlogs =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p --mode=0666 $PATHlogs`;
						print "     $PATHlogs directory created\n";
						$continue='YES';
						}
					}
				else
					{
					$continue='YES';
					}
				}
			}
		##### END astguiclient logs directory prompting and existence check #####

		##### BEGIN asterisk agi-bin directory prompting and existence check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nasterisk agi-bin path or press enter for default: [$PATHagi] ");
			$PROMPTagi = <STDIN>;
			chomp($PROMPTagi);
			if (length($PROMPTagi)>2)
				{
				$PROMPTagi =~ s/ |\n|\r|\t|\/$//gi;
				if (!-e "$PROMPTagi")
					{
					print("$PROMPTagi does not exist, would you like me to create it?(y/n) [y] ");
					$createPROMPTagi = <STDIN>;
					chomp($createPROMPTagi);
					if ($createPROMPTagi =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PROMPTagi`;
							print "     $PROMPTagi directory created\n";
						$PATHagi=$PROMPTagi;
						$continue='YES';
						}
					}
				else
					{
					$PATHagi=$PROMPTagi;
					$continue='YES';
					}
				}
			else
				{
				if (!-e "$PATHagi")
					{
					print("$PATHagi does not exist, would you like me to create it?(y/n) [y] ");
					$createPATHagi = <STDIN>;
					chomp($createPATHagi);
					if ($createPATHagi =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PATHagi`;
						print "     $PATHagi directory created\n";
						$continue='YES';
						}
					}
				else
					{
					$continue='YES';
					}
				}
			}
		##### END asterisk agi-bin directory prompting and existence check #####

		##### BEGIN server webroot directory prompting and existence check #####
		$continue='NO';
		while ( ($continue =~/NO/) && ($NOWEB < 1) )
			{
			print("\nserver webroot path or press enter for default: [$PATHweb] ");
			$PROMPTweb = <STDIN>;
			chomp($PROMPTweb);
			if (length($PROMPTweb)>2)
				{
				$PROMPTweb =~ s/ |\n|\r|\t|\/$//gi;
				if (!-e "$PROMPTweb")
					{
					print("$PROMPTweb does not exist, would you like me to create it?(y/n) [y] ");
					$createPROMPTweb = <STDIN>;
					chomp($createPROMPTweb);
					if ($createPROMPTweb =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PROMPTweb`;
							print "     $PROMPTweb directory created\n";
						$PATHweb=$PROMPTweb;
						$continue='YES';
						}
					}
				else
					{
					$PATHweb=$PROMPTweb;
					$continue='YES';
					}
				}
			else
				{
				if (!-e "$PATHweb")
					{
					print("$PATHweb does not exist, would you like me to create it?(y/n) [y] ");
					$createPATHweb = <STDIN>;
					chomp($createPATHweb);
					if ($createPATHweb =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PATHweb`;
						print "     $PATHweb directory created\n";
						$continue='YES';
						}
					}
				else
					{
					$continue='YES';
					}
				}
			}
		##### END server webroot directory prompting and existence check #####

		##### BEGIN asterisk sounds directory prompting and existence check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nasterisk sounds path or press enter for default: [$PATHsounds] ");
			$PROMPTsounds = <STDIN>;
			chomp($PROMPTsounds);
			if (length($PROMPTsounds)>2)
				{
				$PROMPTsounds =~ s/ |\n|\r|\t|\/$//gi;
				if (!-e "$PROMPTsounds")
					{
					print("$PROMPTsounds does not exist, would you like me to create it?(y/n) [y] ");
					$createPROMPTsounds = <STDIN>;
					chomp($createPROMPTsounds);
					if ($createPROMPTsounds =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PROMPTsounds`;
							print "     $PROMPTsounds directory created\n";
						$PATHsounds=$PROMPTsounds;
						$continue='YES';
						}
					}
				else
					{
					$PATHsounds=$PROMPTsounds;
					$continue='YES';
					}
				}
			else
				{
				if (!-e "$PATHsounds")
					{
					print("$PATHsounds does not exist, would you like me to create it?(y/n) [y] ");
					$createPATHsounds = <STDIN>;
					chomp($createPATHsounds);
					if ($createPATHsounds =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PATHsounds`;
						print "     $PATHsounds directory created\n";
						$continue='YES';
						}
					}
				else
					{
					$continue='YES';
					}
				}
			}
		##### END asterisk sounds directory prompting and existence check #####

		##### BEGIN asterisk monitor directory prompting and existence check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nasterisk monitor path or press enter for default: [$PATHmonitor] ");
			$PROMPTmonitor = <STDIN>;
			chomp($PROMPTmonitor);
			if (length($PROMPTmonitor)>2)
				{
				$PROMPTmonitor =~ s/ |\n|\r|\t|\/$//gi;
				if (!-e "$PROMPTmonitor")
					{
					print("$PROMPTmonitor does not exist, would you like me to create it?(y/n) [y] ");
					$createPROMPTmonitor = <STDIN>;
					chomp($createPROMPTmonitor);
					if ($createPROMPTmonitor =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PROMPTmonitor`;
							print "     $PROMPTmonitor directory created\n";
						$PATHmonitor=$PROMPTmonitor;
						$continue='YES';
						}
					}
				else
					{
					$PATHmonitor=$PROMPTmonitor;
					$continue='YES';
					}
				}
			else
				{
				if (!-e "$PATHmonitor")
					{
					print("$PATHmonitor does not exist, would you like me to create it?(y/n) [y] ");
					$createPATHmonitor = <STDIN>;
					chomp($createPATHmonitor);
					if ($createPATHmonitor =~ /n/i)
						{
						$continue='NO';
						}
					else
						{
						`mkdir -p $PATHmonitor`;
						print "     $PATHmonitor directory created\n";
						$continue='YES';
						}
					}
				else
					{
					$continue='YES';
					}
				}
			}
		##### END asterisk monitor directory prompting and existence check #####

		##### BEGIN server_ip prompting and check #####
		if (length($VARserver_ip)<7)
			{	
			### get best guess of IP address from ifconfig output ###
			# inet addr:10.10.11.17  Bcast:10.10.255.255  Mask:255.255.0.0
			@ip = `/sbin/ifconfig`;
			$j=0;
			while($#ip>=$j)
				{
				if ($ip[$j] =~ /inet addr/) {$VARserver_ip = $ip[$j]; $j=1000;}
				$j++;
				}
			$VARserver_ip =~ s/.*addr:| Bcast.*|\r|\n|\t| //gi;
			}

		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nserver IP address or press enter for default: [$VARserver_ip] ");
			$PROMPTserver_ip = <STDIN>;
			chomp($PROMPTserver_ip);
			if (length($PROMPTserver_ip)>6)
				{
				$PROMPTserver_ip =~ s/ |\n|\r|\t|\/$//gi;
				$VARserver_ip=$PROMPTserver_ip;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END server_ip prompting and check  #####


		##### BEGIN DB_server prompting and check #####
		if (length($VARDB_server)<7)
			{	
			$VARDB_server = 'localhost';
			}
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nDB server address or press enter for default: [$VARDB_server] ");
			$PROMPTDB_server = <STDIN>;
			chomp($PROMPTDB_server);
			if (length($PROMPTDB_server)>6)
				{
				$PROMPTDB_server =~ s/ |\n|\r|\t|\/$//gi;
				$VARDB_server=$PROMPTDB_server;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END DB_server prompting and check  #####

		##### BEGIN DB_database prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nDB database name or press enter for default: [$VARDB_database] ");
			$PROMPTDB_database = <STDIN>;
			chomp($PROMPTDB_database);
			if (length($PROMPTDB_database)>1)
				{
				$PROMPTDB_database =~ s/ |\n|\r|\t|\/$//gi;
				$VARDB_database=$PROMPTDB_database;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END DB_database prompting and check  #####

		##### BEGIN DB_user prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nDB user login or press enter for default: [$VARDB_user] ");
			$PROMPTDB_user = <STDIN>;
			chomp($PROMPTDB_user);
			if (length($PROMPTDB_user)>1)
				{
				$PROMPTDB_user =~ s/ |\n|\r|\t|\/$//gi;
				$VARDB_user=$PROMPTDB_user;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END DB_user prompting and check  #####

		##### BEGIN DB_pass prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nDB user password or press enter for default: [$VARDB_pass] ");
			$PROMPTDB_pass = <STDIN>;
			chomp($PROMPTDB_pass);
			if (length($PROMPTDB_pass)>1)
				{
				$PROMPTDB_pass =~ s/ |\n|\r|\t|\/$//gi;
				$VARDB_pass=$PROMPTDB_pass;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END DB_pass prompting and check  #####

		##### BEGIN DB_port prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nDB connection port or press enter for default: [$VARDB_port] ");
			$PROMPTDB_port = <STDIN>;
			chomp($PROMPTDB_port);
			if (length($PROMPTDB_port)>1)
				{
				$PROMPTDB_port =~ s/ |\n|\r|\t|\/$//gi;
				$VARDB_port=$PROMPTDB_port;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END DB_port prompting and check  #####

		##### BEGIN active_keepalives prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print "\nNumeric list of the astGUIclient processes to be kept running\n";
			print "(value should be listing of characters with no spaces: 123456)\n";
			print " X - NO KEEPALIVE PROCESSES (use only if you want none to be keepalive)\n";
			print " 1 - AST_update\n";
			print " 2 - AST_send_listen\n";
			print " 3 - AST_VDauto_dial\n";
			print " 4 - AST_VDremote_agents\n";
			print " 5 - AST_VDadapt (If multi-server system, this must only be on one server)\n";
			print " 6 - FastAGI_log\n";
			print " 7 - AST_VDauto_dial_FILL (only for multi-server, this must only be on one server)\n";
			print "Enter active keepalives or press enter for default: [$VARactive_keepalives] ";
			$PROMPTactive_keepalives = <STDIN>;
			chomp($PROMPTactive_keepalives);
			if (length($PROMPTactive_keepalives)>0)
				{
				$PROMPTactive_keepalives =~ s/ |\n|\r|\t|\/$//gi;
				$VARactive_keepalives=$PROMPTactive_keepalives;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END active_keepalives prompting and check  #####

		##### BEGIN fastagi_log_min_servers prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nFastAGI log minimum child servers: [$VARfastagi_log_min_servers] ");
			$PROMPTfastagi_log_min_servers = <STDIN>;
			chomp($PROMPTfastagi_log_min_servers);
			if (length($PROMPTfastagi_log_min_servers)>0)
				{
				$PROMPTfastagi_log_min_servers =~ s/ |\n|\r|\t|\/$//gi;
				$VARfastagi_log_min_servers=$PROMPTfastagi_log_min_servers;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END fastagi_log_min_servers prompting and check  #####

		##### BEGIN fastagi_log_max_servers prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nFastAGI log maximum child servers: [$VARfastagi_log_max_servers] ");
			$PROMPTfastagi_log_max_servers = <STDIN>;
			chomp($PROMPTfastagi_log_max_servers);
			if (length($PROMPTfastagi_log_max_servers)>0)
				{
				$PROMPTfastagi_log_max_servers =~ s/ |\n|\r|\t|\/$//gi;
				$VARfastagi_log_max_servers=$PROMPTfastagi_log_max_servers;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END fastagi_log_max_servers prompting and check  #####

		##### BEGIN fastagi_log_min_spare_servers prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nFastAGI log minimum spare child servers: [$VARfastagi_log_min_spare_servers] ");
			$PROMPTfastagi_log_min_spare_servers = <STDIN>;
			chomp($PROMPTfastagi_log_min_spare_servers);
			if (length($PROMPTfastagi_log_min_spare_servers)>0)
				{
				$PROMPTfastagi_log_min_spare_servers =~ s/ |\n|\r|\t|\/$//gi;
				$VARfastagi_log_min_spare_servers=$PROMPTfastagi_log_min_spare_servers;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END fastagi_log_min_spare_servers prompting and check  #####

		##### BEGIN fastagi_log_max_spare_servers prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nFastAGI log maximum spare child servers: [$VARfastagi_log_max_spare_servers] ");
			$PROMPTfastagi_log_max_spare_servers = <STDIN>;
			chomp($PROMPTfastagi_log_max_spare_servers);
			if (length($PROMPTfastagi_log_max_spare_servers)>0)
				{
				$PROMPTfastagi_log_max_spare_servers =~ s/ |\n|\r|\t|\/$//gi;
				$VARfastagi_log_max_spare_servers=$PROMPTfastagi_log_max_spare_servers;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END fastagi_log_max_spare_servers prompting and check  #####

		##### BEGIN fastagi_log_max_requests prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nFastAGI log maximum requests per child server: [$VARfastagi_log_max_requests] ");
			$PROMPTfastagi_log_max_requests = <STDIN>;
			chomp($PROMPTfastagi_log_max_requests);
			if (length($PROMPTfastagi_log_max_requests)>0)
				{
				$PROMPTfastagi_log_max_requests =~ s/ |\n|\r|\t|\/$//gi;
				$VARfastagi_log_max_requests=$PROMPTfastagi_log_max_requests;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END fastagi_log_max_requests prompting and check  #####

		##### BEGIN fastagi_log_checkfordead prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nFastAGI log check-for-dead seconds: [$VARfastagi_log_checkfordead] ");
			$PROMPTfastagi_log_checkfordead = <STDIN>;
			chomp($PROMPTfastagi_log_checkfordead);
			if (length($PROMPTfastagi_log_checkfordead)>0)
				{
				$PROMPTfastagi_log_checkfordead =~ s/ |\n|\r|\t|\/$//gi;
				$VARfastagi_log_checkfordead=$PROMPTfastagi_log_checkfordead;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END fastagi_log_checkfordead prompting and check  #####

		##### BEGIN fastagi_log_checkforwait prompting and check #####
		$continue='NO';
		while ($continue =~/NO/)
			{
			print("\nFastAGI log check-for-wait seconds: [$VARfastagi_log_checkforwait] ");
			$PROMPTfastagi_log_checkforwait = <STDIN>;
			chomp($PROMPTfastagi_log_checkforwait);
			if (length($PROMPTfastagi_log_checkforwait)>0)
				{
				$PROMPTfastagi_log_checkforwait =~ s/ |\n|\r|\t|\/$//gi;
				$VARfastagi_log_checkforwait=$PROMPTfastagi_log_checkforwait;
				$continue='YES';
				}
			else
				{
				$continue='YES';
				}
			}
		##### END fastagi_log_checkforwait prompting and check  #####


		print "\n";
		print "  defined home path:        $PATHhome\n";
		print "  defined logs path:        $PATHlogs\n";
		print "  defined agi-bin path:     $PATHagi\n";
		print "  defined webroot path:     $PATHweb\n";
		print "  defined sounds path:      $PATHsounds\n";
		print "  defined monitor path:     $PATHmonitor\n";
		print "  defined server_ip:        $VARserver_ip\n";
		print "  defined DB_server:        $VARDB_server\n";
		print "  defined DB_database:      $VARDB_database\n";
		print "  defined DB_user:          $VARDB_user\n";
		print "  defined DB_pass:          $VARDB_pass\n";
		print "  defined DB_port:          $VARDB_port\n";
		print "  defined active_keepalives $VARactive_keepalives\n";
		print "  defined fastagi_log_min_servers:       $VARfastagi_log_min_servers\n";
		print "  defined fastagi_log_max_servers:       $VARfastagi_log_max_servers\n";
		print "  defined fastagi_log_min_spare_servers: $VARfastagi_log_min_spare_servers\n";
		print "  defined fastagi_log_max_spare_servers: $VARfastagi_log_max_spare_servers\n";
		print "  defined fastagi_log_max_requests:      $VARfastagi_log_max_requests\n";
		print "  defined fastagi_log_checkfordead:      $VARfastagi_log_checkfordead\n";
		print "  defined fastagi_log_checkforwait:      $VARfastagi_log_checkforwait\n";
		print "\n";

		print("Are these settings correct?(y/n): [y] ");
		$PROMPTconfig = <STDIN>;
		chomp($PROMPTconfig);
		if ( (length($PROMPTconfig)<1) or ($PROMPTconfig =~ /y/i) )
			{
			$config_finished='YES';
			}
		}
	}

print "Writing to astguiclient.conf file: $PATHconf\n";

open(conf, ">$PATHconf") || die "can't open $PATHconf: $!\n";
print conf "# astguiclient.conf - configuration elements for the astguiclient package\n";
print conf "# this is the astguiclient configuration file \n";
print conf "# all comments will be lost if you run install.pl again\n";
print conf "\n";
print conf "# Paths used by astGUIclient\n";
print conf "PATHhome => $PATHhome\n";
print conf "PATHlogs => $PATHlogs\n";
print conf "PATHagi => $PATHagi\n";
print conf "PATHweb => $PATHweb\n";
print conf "PATHsounds => $PATHsounds\n";
print conf "PATHmonitor => $PATHmonitor\n";
print conf "\n";
print conf "# The IP address of this machine\n";
print conf "VARserver_ip => $VARserver_ip\n";
print conf "\n";
print conf "# Database connection information\n";
print conf "VARDB_server => $VARDB_server\n";
print conf "VARDB_database => $VARDB_database\n";
print conf "VARDB_user => $VARDB_user\n";
print conf "VARDB_pass => $VARDB_pass\n";
print conf "VARDB_port => $VARDB_port\n";
print conf "\n";
print conf "# Alpha-Numeric list of the astGUIclient processes to be kept running\n";
print conf "# (value should be listing of characters with no spaces: 123456)\n";
print conf "#  X - NO KEEPALIVE PROCESSES (use only if you want none to be keepalive)\n";
print conf "#  1 - AST_update\n";
print conf "#  2 - AST_send_listen\n";
print conf "#  3 - AST_VDauto_dial\n";
print conf "#  4 - AST_VDremote_agents\n";
print conf "#  5 - AST_VDadapt (If multi-server system, this must only be on one server)\n";
print conf "#  6 - FastAGI_log\n";
print conf "#  7 - AST_VDauto_dial_FILL (only for multi-server, this must only be on one server)\n";
print conf "VARactive_keepalives => $VARactive_keepalives\n";
print conf "\n";
print conf "# Settings for FastAGI logging server\n";
print conf "VARfastagi_log_min_servers => $VARfastagi_log_min_servers\n";
print conf "VARfastagi_log_max_servers => $VARfastagi_log_max_servers\n";
print conf "VARfastagi_log_min_spare_servers => $VARfastagi_log_min_spare_servers\n";
print conf "VARfastagi_log_max_spare_servers => $VARfastagi_log_max_spare_servers\n";
print conf "VARfastagi_log_max_requests => $VARfastagi_log_max_requests\n";
print conf "VARfastagi_log_checkfordead => $VARfastagi_log_checkfordead\n";
print conf "VARfastagi_log_checkforwait => $VARfastagi_log_checkforwait\n";
close(conf);


print "\nSTARTING ASTGUICLIENT INSTALLATION PHASE...\n";

if ($WEBONLY < 1)
	{
	print "Creating $PATHhome/LEADS_IN/DONE directories...\n";
	`mkdir $PATHhome/LEADS_IN`;
	`mkdir $PATHhome/LEADS_IN/DONE`;
	`chmod -R 0766 $PATHhome/LEADS_IN`;

	print "Creating $PATHmonitor directories...\n";
	`mkdir $PATHmonitor/monitor`;
	`mkdir $PATHmonitor/monitor/ORIG`;
	`mkdir $PATHmonitor/monitor/DONE`;
	`chmod -R 0766 $PATHmonitor/monitor`;

	print "Copying bin scripts to $PATHhome ...\n";
	`cp -f ./bin/* $PATHhome/`;

	print "setting cron scripts to executable...\n";
	`chmod 0755 $PATHhome/*`;

	print "Copying extras files to $PATHhome ...\n";
	`cp -f ./extras/GMT_USA_zip.txt $PATHhome/`;
	`cp -f ./extras/phone_codes_GMT.txt $PATHhome/`;
	`cp -f ./extras/MySQL_AST_CREATE_tables.sql $PATHhome/`;

	print "Copying agi-bin scripts to $PATHagi ...\n";
	`cp -f ./agi/* $PATHagi/`;

	print "setting agi-bin scripts to executable...\n";
	`chmod 0755 $PATHagi/*`;

	print "Copying sounds to $PATHsounds...\n";
	`cp -f ./sounds/* $PATHsounds/`;
	}
if ($NOWEB < 1)
	{
	print "Creating $PATHweb web directories...\n";
	`mkdir $PATHweb/agc/`;
	`mkdir $PATHweb/astguiclient/`;
	`mkdir $PATHweb/vicidial/`;
	`mkdir $PATHweb/vicidial/ploticus/`;
	`mkdir $PATHweb/vicidial/agent_reports/`;

	print "Copying web files...\n";
	`cp -f -R ./www/* $PATHweb/`;

	print "setting web scripts to executable...\n";
	`chmod -R 0755 $PATHweb/agc/`;
	`chmod -R 0755 $PATHweb/astguiclient/`;
	`chmod -R 0755 $PATHweb/vicidial/`;
	`chmod 0777 $PATHweb/agc/`;
	`chmod 0777 $PATHweb/astguiclient/`;
	`chmod 0777 $PATHweb/vicidial/`;
	`chmod 0777 $PATHweb/vicidial/ploticus/`;
	`chmod 0777 $PATHweb/vicidial/agent_reports/`;
	}

print "\nASTGUICLIENT INSTALLATION FINISHED!     ENJOY!\n";

$secy = time();		$secz = ($secy - $secX);		$minz = ($secz/60);		# calculate script runtime so far
print "\n     - process runtime      ($secz sec) ($minz minutes)\n";


exit;
