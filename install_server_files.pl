#!/usr/bin/perl

############################################
# install_server_files.pl - puts server files in the right places
#
# modify the variables below to customize for your system.
#
# path to home directory: (assumes it already exists)
$home =		'/home/cron';

# path to agi-bin directory: (assumes it already exists)
$agibin =	'/var/lib/asterisk/agi-bin';

# path to web root directory: (assumes it already exists)
#$webroot =	'/home/www/htdocs';
$webroot =	'/usr/local/apache2/htdocs';

# path to asterisk sounds directory: (assumes it already exists)
$sounds =	'/var/lib/asterisk/sounds';

# path to asterisk recordings directory: (assumes it already exists)
$monitor =	'/var/spool/asterisk';

############################################

$secX = time();

# constants
$DB=1;  # Debug flag, set to 0 for no debug messages, lots of output
$US='_';
$MT[0]='';
$LANG_FILE='./languages.txt';
$LANG_FILE_ADMIN='./languages_admin.txt';

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
	print "allowed run time options:\n  [-t] = test\n  [-debug] = verbose debug messages\n[--language-web-build] = build only the multi-language client files\n\n";
	}
	else
	{
		if ($args =~ /-debug/i)
		{
		$DB=1; # Debug flag
		}
		if ($args =~ /--language-web-build/i)
		{
		$LANG=1;
		print "\n----- LANGUAGE WEB SCRIPT ONLY BUILD -----\n\n";
		}
		if ($args =~ /-t/i)
		{
		$TEST=1;
		$T=1;
		}
	}
}
else
{
#	print "no command line options set\n";
}
### end parsing run-time options ###


if ($LANG)
{
open(lang, "$LANG_FILE_ADMIN") || die "can't open $LANG_FILE_ADMIN: $!\n";
@lang = <lang>;
close(lang);
	&translate_pages;

@lang=@MT;
@LANGUAGES=@MT;
@FILES=@MT;
@TRANSLATIONS=@MT;

open(lang, "$LANG_FILE") || die "can't open $LANG_FILE: $!\n";
@lang = <lang>;
close(lang);
	&translate_pages;

}

else
{
print "INSTALLING SERVER SIDE COMPONENTS...\n";

print "Creating cron/LOGS directory...\n";
`mkdir $home/LOGS/`;

print "setting LOGS directory to executable...\n";
`chmod 0766 $home/LOGS`;

print "Creating $home/VICIDIAL/LEADS_IN/DONE directory...\n";
`mkdir $home/VICIDIAL`;
`mkdir $home/VICIDIAL/LEADS_IN`;
`mkdir $home/VICIDIAL/LEADS_IN/DONE`;
`chmod -R 0766 $home/VICIDIAL`;

print "Creating $monitor directories...\n";
`mkdir $monitor/monitor`;
`mkdir $monitor/monitor/ORIG`;
`mkdir $monitor/monitor/DONE`;
`chmod -R 0766 $monitor/monitor`;

print "Copying cron scripts...\n";
`cp -f ./ADMIN_adjust_GMTnow_on_leads.pl $home/`;
`cp -f ./ADMIN_area_code_populate.pl $home/`;
`cp -f ./ADMIN_keepalive_AST_send_listen.pl $home/`;
`cp -f ./ADMIN_keepalive_send_listen.at $home/`;
`cp -f ./ADMIN_keepalive_AST_update.pl $home/`;
`cp -f ./ADMIN_keepalive_AST_VDautodial.pl $home/`;
`cp -f ./ADMIN_keepalive_AST_VDremote_agents.pl $home/`;
`cp -f ./ADMIN_restart_roll_logs.pl $home/`;
`cp -f ./AST_conf_update.pl $home/`;
`cp -f ./AST_CRON_mix_recordings.pl $home/`;
`cp -f ./AST_CRON_mix_recordings_BASIC.pl $home/`;
`cp -f ./AST_DB_optimize.pl $home/`;
`cp -f ./AST_flush_DBqueue.pl $home/`;
`cp -f ./AST_manager_kill_hung_congested.pl $home/`;
`cp -f ./AST_manager_listen.pl $home/`;
`cp -f ./AST_manager_send.pl $home/`;
`cp -f ./AST_reset_mysql_vars.pl $home/`;
`cp -f ./AST_send_action_child.pl $home/`;
`cp -f ./AST_SERVER_conf.pl $home/`;
`cp -f ./AST_update.pl $home/`;
`cp -f ./AST_VDauto_dial.pl $home/`;
`cp -f ./AST_VDhopper.pl $home/`;
`cp -f ./AST_VDremote_agents.pl $home/`;
`cp -f ./AST_vm_update.pl $home/`;
`cp -f ./phone_codes_GMT.txt $home/`;
`cp -f ./start_asterisk_boot.pl $home/`;
`cp -f ./VICIDIAL_IN_new_leads_file.pl $home/`;
`cp -f ./test_VICIDIAL_lead_file.txt $home/VICIDIAL/LEADS_IN/`;


print "setting cron scripts to executable...\n";
`chmod 0755 $home/*`;

print "Copying agi-bin scripts...\n";
`cp -f ./agi-dtmf.agi $agibin/`;
`cp -f ./agi-VDADtransfer.agi $agibin/`;
`cp -f ./agi-VDADcloser.agi $agibin/`;
`cp -f ./agi-VDADcloser_inbound.agi $agibin/`;
`cp -f ./agi-VDADcloser_inboundANI.agi $agibin/`;
`cp -f ./agi-VDADcloser_inboundCID.agi $agibin/`;
`cp -f ./agi-VDADcloser_inbound_NOCID.agi $agibin/`;
`cp -f ./agi-VDADcloser_inbound_5ID.agi $agibin/`;
`cp -f ./call_inbound.agi $agibin/`;
`cp -f ./call_log.agi $agibin/`;
`cp -f ./call_logCID.agi $agibin/`;
`cp -f ./call_park.agi $agibin/`;
`cp -f ./call_park_EXT.agi $agibin/`;
`cp -f ./call_park_I.agi $agibin/`;
`cp -f ./call_park_L.agi $agibin/`;
`cp -f ./call_park_W.agi $agibin/`;
`cp -f ./debug_speak.agi $agibin/`;
`cp -f ./invalid_speak.agi $agibin/`;


print "setting agi-bin scripts to executable...\n";
`chmod 0755 $agibin/*`;

print "Copying sounds...\n";
`cp -f ./DTMF_sounds/* $sounds/`;

print "Creating vicidial web directory...\n";
`mkdir $webroot/vicidial/`;
`mkdir $webroot/vicidial/ploticus/`;

print "Copying VICIDIALweb php files...\n";
`cp -f ./VICIDIAL_web/* $webroot/vicidial/`;

print "setting VICIDIALweb scripts to executable...\n";
`chmod 0755 -R $webroot/vicidial/`;
`chmod 0777 $webroot/vicidial/`;
`chmod 0777 $webroot/vicidial/ploticus/`;

print "Creating agc web directory...\n";
`mkdir $webroot/agc/`;

print "Copying agc php files...\n";
`cp -R -f ./agc/* $webroot/agc/`;

print "setting agc scripts to executable...\n";
`chmod 0755 -R $webroot/agc/`;
`chmod 0777 $webroot/agc/`;

print "Creating astguiclient web directory...\n";
`mkdir $webroot/astguiclient/`;

print "Copying astguiclient web php files...\n";
`cp -f ./astguiclient_web/* $webroot/astguiclient/`;

print "setting astguiclient web scripts to executable...\n";
`chmod 0755 -R $webroot/astguiclient/`;
`chmod 0777 $webroot/astguiclient/`;

}



$secy = time();		$secz = ($secy - $secX);		$minz = ($secz/60);		# calculate script runtime so far
print "\n     - process runtime      ($secz sec) ($minz minutes)\n";
print "\n\nDONE and EXITING\n";


exit;



sub translate_pages
{
#***LANGUAGES***
#en-English|es-Espaol|fr|de|it|
#***FILES***
#agc/astguiclient.php
#agc/vicidial.php
#***TRANSLATIONS***
#English|Ingls|Anglais|Englisch|Inglese|
#Spanish|Espaol||||

##### PARSE THE LANGUAGES SETTING FILE #####
$section='';
$i=0;
$Lct=0; $Fct=0; $Tct=0;
foreach(@lang)
	{
	if ($lang[$i] !~ /^\#/)
		{
		if ($lang[$i] =~ /^\*\*\*/) 
			{
			$section = $lang[$i];
			$section =~ s/\*|\n|\r//gi;
		#	print "section heading: $section: $lang[$i]";
			}
		else
			{
			if ($section =~ /LANGUAGES/)
				{
				$LANGUAGES = $lang[$i];
				$Lct++;
				}
			else
				{
				if ($section =~ /FILES/)
					{
				#	print "section: $section    line: $lang[$i]";
					$FILES[$Fct] = $lang[$i];
					$Fct++;
					}
				else
					{
					if ($section =~ /TRANSLATIONS/)
						{
					#	print "section: $section    line: $lang[$i]";
						$TRANSLATIONS[$Tct] = $lang[$i];
						$Tct++;
						}
					}
				}
			}
		}
	$i++;
	}

if ($DB)
	{
	print "LANGUAGE FILE PARSE RESULTS:   $#lang lines in file\n";
	print "LANGUAGES:    $LANGUAGES\n";
	print "FILES:        $Fct\n";
	print "TRANSLATIONS: $Tct\n";
	}

##### LOOP THROUGH THE LANGUAGES    && ($lang_list[$i] !~ /^en/) )
@lang_list = split(/\|/, $LANGUAGES);
@lang_link_list = @lang_list;
$i=0;
$gif = '.gif';
foreach(@lang_list)
	{
	if (length($lang_list[$i]) > 2) 
		{
		@lang_detail  = split(/-/, $lang_list[$i]);
		$lang_abb = $lang_detail[0];
		$lang_name = $lang_detail[1];

		##### LOOP THROUGH THE FILES
		$Fct=0;
		foreach(@FILES)
			{
			$a=0;
			@file_detail  = split(/\|/, $FILES[$Fct]);
			$file_path = $file_detail[0];
			$file_name = $file_detail[1];
			$file_name =~ s/\t|\r|\n//gi;
			$file_passthru = $file_detail[2];
			$file_passthru =~ s/\t|\r|\n//gi;
			if (-e "$webroot/$file_path/$file_name")
				{
				open(file, "$webroot/$file_path/$file_name") || die "can't open $webroot/$file_path/$file_name: $!\n";
				@file = @MT;
				@file = <file>;
				close(file);

				print "File exists: ./$file_path/$file_name\n";
				if (-e "$webroot/$file_path$US$lang_abb")
					{
					print "Lang Directory exists: $webroot/$file_path$US$lang_abb\n";
					}
				else
					{
					`mkdir $webroot/$file_path$US$lang_abb`;
					`chmod 0777 $webroot/$file_path$US$lang_abb`;
					print "Lang Directory created: $webroot/$file_path$US$lang_abb\n";
					}

				if ($file_passthru < 1)
					{
					##### LOOP THROUGH THE TRANSLATIONS
					$Tct=0;
					foreach(@TRANSLATIONS)
						{
						@TRANSline = split(/\|/, $TRANSLATIONS[$Tct]);
						$ORIGtext = "$TRANSline[0]";
						$TRANStext = "$TRANSline[$i]";
						$LINESct=0;
						foreach(@file)
							{
							if ($file[$LINESct] !~ /^\#|^\s*function |'INCALL'|'PAUSED'|'READY'|'NEW'|xmlhttp|ILPV |ILPA |SELECT cmd_line_f/)
								{
								if ($file[$LINESct] =~ /INTERNATIONALIZATION-LINKS-PLACEHOLDER-VICIDIAL/)
									{
									$file[$LINESct] =~ s/INTERNATIONALIZATION-LINKS-PLACEHOLDER-VICIDIAL/ILPV/g;
									$e=0;
									$gif = '.gif';
									foreach(@lang_link_list)
										{
										if (length($lang_link_list[$e]) > 2) 
											{
											@lang_list_detail  = split(/-/, $lang_link_list[$e]);
											$lang_list_abb = $lang_list_detail[0];
											$lang_list_name = $lang_list_detail[1];
											if ($lang_list_abb =~ /$lang_abb/) {$list_bgcolor = ' BGCOLOR=\"#CCFFCC\"';}
											else {$list_bgcolor = '';}
											$file[$LINESct] .= "echo \"<TD WIDTH=100 ALIGN=RIGHT VALIGN=TOP $list_bgcolor NOWRAP><a href=\\\"../$file_path$US$lang_list_abb/$file_name?relogin=YES&VD_login=\$VD_login&VD_campaign=\$VD_campaign&phone_login=\$phone_login&phone_pass=\$phone_pass&VD_pass=\$VD_pass\\\">$lang_list_name <img src=\\\"../agc/images/$lang_list_abb$gif\\\" BORDER=0 HEIGHT=14 WIDTH=20></a></TD>\\n\";";
											}
										$e++;
										}
									}
								else
									{
									if ($file[$LINESct] =~ /INTERNATIONALIZATION-LINKS-PLACEHOLDER-AGC/)
										{
										$file[$LINESct] =~ s/INTERNATIONALIZATION-LINKS-PLACEHOLDER-AGC/ILPA/g;
										$e=0;
										$gif = '.gif';
										foreach(@lang_link_list)
											{
											if (length($lang_link_list[$e]) > 2) 
												{
												@lang_list_detail  = split(/-/, $lang_link_list[$e]);
												$lang_list_abb = $lang_list_detail[0];
												$lang_list_name = $lang_list_detail[1];
												if ($lang_list_abb =~ /$lang_abb/) {$list_bgcolor = ' BGCOLOR=\"#CCFFCC\"';}
												else {$list_bgcolor = '';}
												$file[$LINESct] .= "echo \"<TD WIDTH=100 ALIGN=RIGHT VALIGN=TOP $list_bgcolor NOWRAP><a href=\\\"../$file_path$US$lang_list_abb/$file_name?relogin=YES&user=\$user&pass=\$pass&phone_login=\$phone_login&phone_pass=\$phone_pass\\\">$lang_list_name <img src=\\\"../agc/images/$lang_list_abb$gif\\\" BORDER=0 HEIGHT=14 WIDTH=20></a></TD>\\n\";";
												}
											$e++;
											}
										}
									else
										{
										if ( ($lang_abb =~ /^en/) && ($Tct > 2) )
											{
											$file[$LINESct] =~ s/\.\/images\//\.\.\/agc\/images\//g;
											$file[$LINESct] =~ s/\"help.gif/\"..\/astguiclient\/help.gif/g;
											}
										if ($lang_abb !~ /^en/)
											{$file[$LINESct] =~ s/$ORIGtext/$TRANStext/g;}
										}
									}
								}
							$LINESct++;

							if ($a =~ /00000$/i) {print "$a     $file[$LINESct]\n|$ORIGtext|$TRANStext|";}
							$a++;
							}
						$Tct++;
						}
					}
				### open the translation result file for writing ###
				open(out, ">$webroot/$file_path$US$lang_abb/$file_name")
						|| die "Can't open $webroot/$file_path$US$lang_abb/$file_name: $!\n";
		#		print out "Header(\"Content-type: text/html; charset=utf-8\");\n";
				$LINESct=0;
				foreach(@file)
					{
					print out "$file[$LINESct]";
					$LINESct++;
					}
				close(out);
				print "\n";
				print "File Written: $webroot/$file_path$US$lang_abb/$file_name\n";
				}
			else
				{
				print "File does not exist: $webroot/$file_path/$file_name\n";
				}
			$Fct++;
			}

		}
	$i++;
	}

}