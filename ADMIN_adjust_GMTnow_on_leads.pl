#!/usr/bin/perl

# ADMIN_adjust_GMTnow_on_leads.pl
#
# program goes throught the vicidial_list table and adjusts the gmt_offset_now
# field to change it to today's offset if needed because of Daylight Saving Time
#
# run every time you load leads into the vicidial_list table
# 
# Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#
#
# 50810-1540 - Added database server variable definitions lookup
# 60615-1717 - Added definition GMT lookup from database not flat text file
#

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
	print "allowed run time options:\n  [-q] = quiet\n  [-t] = test\n  [--debug] = debugging messages\n\n";
	}
	else
	{
		if ($args =~ /-q/i)
		{
		$q=1;   $Q=1;
		}
		if ($args =~ /--debug/i)
		{
		$DB=1;
		print "\n-----DEBUGGING -----\n\n";
		}
		if ($args =~ /--debugX/i)
		{
		$DBX=1;
		print "\n----- SUPER-DUPER DEBUGGING -----\n\n";
		}
		if ($args =~ /-t|--test/i)
		{
		$T=1; $TEST=1;
		print "\n-----TESTING -----\n\n";
		}
	}
}
else
{
print "no command line options set\n";
}

if ($DB) {print "STARTING TIME ZONE DAYLIGHT SAVING TIME CALCULATION SCRIPT\n\n\n\n";}

### end parsing run-time options ###

### Make sure this file is in a libs path or put the absolute path to it
require("/home/cron/AST_SERVER_conf.pl");	# local configuration file

if (!$DB_port) {$DB_port='3306';}

$secX = time();
#	$secX = '1079989363';	# epoch for March 22, 2993
#	$secX = '1097989363';	# epoch for October 17, 2004
	
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($secX);
	$mon++;
	$year = ($year + 1900);
	if ($mon < 10) {$mon = "0$mon";}
	if ($mday < 10) {$mday = "0$mday";}
	if ($hour < 10) {$hour = "0$hour";}
	if ($min < 10) {$min = "0$min";}
	if ($sec < 10) {$sec = "0$sec";}
	$dsec = ( ( ($hour * 3600) + ($min * 60) ) + $sec );

use Net::MySQL;
	  
	my $dbhA = Net::MySQL->new(hostname => "$DB_server", database => "$DB_database", user => "$DB_user", password => "$DB_pass", port => "$DB_port") 
	or 	die "Couldn't connect to database: $DB_server - $DB_database\n";


	### Grab Server values from the database
	$stmtA = "SELECT telnet_host,telnet_port,ASTmgrUSERNAME,ASTmgrSECRET,ASTmgrUSERNAMEupdate,ASTmgrUSERNAMElisten,ASTmgrUSERNAMEsend,max_vicidial_trunks,answer_transfer_agent,local_gmt,ext_context FROM servers where server_ip = '$server_ip';";
	$dbhA->query("$stmtA");
	if ($dbhA->has_selected_record)
		{
		$iter=$dbhA->create_record_iterator;
		   while ( $record = $iter->each)
			{
			$DBtelnet_host	=			"$record->[0]";
			$DBtelnet_port	=			"$record->[1]";
			$DBASTmgrUSERNAME	=		"$record->[2]";
			$DBASTmgrSECRET	=			"$record->[3]";
			$DBASTmgrUSERNAMEupdate	=	"$record->[4]";
			$DBASTmgrUSERNAMElisten	=	"$record->[5]";
			$DBASTmgrUSERNAMEsend	=	"$record->[6]";
			$DBmax_vicidial_trunks	=	"$record->[7]";
			$DBanswer_transfer_agent=	"$record->[8]";
			$DBSERVER_GMT		=		"$record->[9]";
			$DBext_context	=			"$record->[10]";
			if ($DBtelnet_host)				{$telnet_host = $DBtelnet_host;}
			if ($DBtelnet_port)				{$telnet_port = $DBtelnet_port;}
			if ($DBASTmgrUSERNAME)			{$ASTmgrUSERNAME = $DBASTmgrUSERNAME;}
			if ($DBASTmgrSECRET)			{$ASTmgrSECRET = $DBASTmgrSECRET;}
			if ($DBASTmgrUSERNAMEupdate)	{$ASTmgrUSERNAMEupdate = $DBASTmgrUSERNAMEupdate;}
			if ($DBASTmgrUSERNAMElisten)	{$ASTmgrUSERNAMElisten = $DBASTmgrUSERNAMElisten;}
			if ($DBASTmgrUSERNAMEsend)		{$ASTmgrUSERNAMEsend = $DBASTmgrUSERNAMEsend;}
			if ($DBmax_vicidial_trunks)		{$max_vicidial_trunks = $DBmax_vicidial_trunks;}
			if ($DBanswer_transfer_agent)	{$answer_transfer_agent = $DBanswer_transfer_agent;}
			if ($DBSERVER_GMT)				{$SERVER_GMT = $DBSERVER_GMT;}
			if ($DBext_context)				{$ext_context = $DBext_context;}
			} 
		}

	$LOCAL_GMT_OFF = $SERVER_GMT;
	$LOCAL_GMT_OFF_STD = $SERVER_GMT;

if ($isdst) {$LOCAL_GMT_OFF++;} 
if ($DB) {print "SEED TIME  $secX      :   $year-$mon-$mday $hour:$min:$sec  LOCAL GMT OFFSET NOW: $LOCAL_GMT_OFF\n";}


	$stmtA = "select distinct phone_code from vicidial_list;";
		if($DBX){print STDERR "\n|$stmtA|\n";}
		$dbhA->query($stmtA);
   if ($dbhA->has_selected_record)
	{
   $iterA=$dbhA->create_record_iterator;
	 $rec_countY=0;
	 @phone_codes=@MT;
	 $phone_codes_list='|';
	   while ($recordA = $iterA->each)
		{
		$phone_codes[$rec_countY] = $recordA->[0];
		$phone_codes_ORIG[$rec_countY] = $recordA->[0];
		$phone_codes[$rec_countY] =~ s/011|0011| |\t|\r|\n//gi;

	#	if ( ($phone_codes_list !~ /\|$phone_codes[$rec_countY]\|/) && (length($phone_codes[$rec_countY]) > 0) )
	#		{
	#		$phone_codes_list .= "$phone_codes[$rec_countY]|";
	#		}

		if ($DBX) {print "|",$recordA->[0],"|","\n";}
		$rec_countY++;
		} 
	}

	if ($DB) {print " - Unique Country dial codes found: $rec_countY\n";}


	$stmtA = "select * from vicidial_phone_codes;";
	if($DBX){print STDERR "\n|$stmtA|\n";}
	$dbhA->query($stmtA);
	if ($dbhA->has_selected_record)
	{
		$iterA=$dbhA->create_record_iterator;
		$rec_countZ=0;
		@codefile=@MT;
		while ($recordA = $iterA->each)
		{
			$codefile[$rec_countZ] = "$recordA->[0]\t$recordA->[1]\t$recordA->[2]\t$recordA->[3]\t$recordA->[4]\t$recordA->[5]\t$recordA->[6]\t$recordA->[7]\n";
			$rec_countZ++;
		} 
	}

	if ($DB) {print " - GMT phone codes records: $rec_countZ\n";}

#	open(codefile, "/home/cron/phone_codes_GMT.txt") || die "can't open /home/cron/phone_codes_GMT.txt: $!\n";
#	@codefile = <codefile>;
#	close(codefile);

$ep=0; $ei=0; $ee=0;
$d=0;
foreach (@phone_codes)
	{
	$match_code = $phone_codes[$d];
	$match_code_ORIG = $phone_codes_ORIG[$d];

	if ($DB) {print "\nRUNNING LOOP FOR COUNTRY CODE: $match_code\n";}

	$e=0;
	foreach (@codefile)
		{
		chomp($codefile[$e]);
		if ($codefile[$e] =~ /^$match_code\t/)
			{
				@m = split(/\t/, $codefile[$e]);
				$area_code = $m[2];
				$area_state = $m[3];
				$area_GMT = $m[4];		$area_GMT =~ s/\+//gi;	$area_GMT = ($area_GMT + 0);
				$area_GMT_method = $m[6];
				if ($area_code =~ /S/)	# look for state override flag in areacode field
					{
					$area_code =~ s/\D//gi;
					$AC_match = " and phone_number LIKE \"$area_code%\" and state='$area_state'";
					if ($DB) {print "  AREA CODE STATE OVERRIDE: $codefile[$e]\n";}
					}
				else
					{
					if ($area_code =~ /\*/) {$AC_match = '';}
					else {$AC_match = " and phone_number LIKE \"$area_code%\"";}
					}
				if ($DBX) {print "PROCESSING THIS LINE: $codefile[$e]\n";}
			$stmtA = "select count(*) from vicidial_list where phone_code='$match_code_ORIG' $AC_match;";
				if($DBX){print STDERR "\n|$stmtA|\n";}
				$dbhA->query($stmtA);
			 $rec_countZ=0;
			if ($dbhA->has_selected_record)
			{
			$iterA=$dbhA->create_record_iterator;
			   while ($recordA = $iterA->each)
				{
				$rec_countZ = $recordA->[0];
				} 
			}
			if (!$rec_countZ)
				{
				if ($DB) {print "   IGNORING: $codefile[$e]\n";}
				$ei++;
				}
			else
				{
					$AC_GMT_diff = ($area_GMT - $LOCAL_GMT_OFF_STD);
					$AC_localtime = ($secX + (3600 * $AC_GMT_diff));
				($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($AC_localtime);
				$year = ($year + 1900);
				$mon++;
				if ($mon < 10) {$mon = "0$mon";}
				if ($mday < 10) {$mday = "0$mday";}
				if ($hour < 10) {$hour = "0$hour";}
				if ($min < 10) {$min = "0$min";}
				if ($sec < 10) {$sec = "0$sec";}
				$dsec = ( ( ($hour * 3600) + ($min * 60) ) + $sec );
				
				$AC_processed=0;
				if ( (!$AC_processed) && ($area_GMT_method =~ /FSA-LSO/) )
					{
					if ($DBX) {print "     First Sunday April to Last Sunday October\n";}
					&USA_dstcalc;
					if ($DBX) {print "     DST: $USA_DST\n";}
					if ($USA_DST) {$area_GMT++;}
					$AC_processed++;
					}
				if ( (!$AC_processed) && ($area_GMT_method =~ /LSM-LSO/) )
					{
					if ($DBX) {print "     Last Sunday March to Last Sunday October\n";}
					&GBR_dstcalc;
					if ($DBX) {print "     DST: $GBR_DST\n";}
					if ($GBR_DST) {$area_GMT++;}
					$AC_processed++;
					}
				if ( (!$AC_processed) && ($area_GMT_method =~ /LSO-LSM/) )
					{
					if ($DBX) {print "     Last Sunday October to Last Sunday March\n";}
					&AUS_dstcalc;
					if ($DBX) {print "     DST: $AUS_DST\n";}
					if ($AUS_DST) {$area_GMT++;}
					$AC_processed++;
					}
				if ( (!$AC_processed) && ($area_GMT_method =~ /FSO-LSM/) )
					{
					if ($DBX) {print "     First Sunday October to Last Sunday March\n";}
					&AUST_dstcalc;
					if ($DBX) {print "     DST: $AUST_DST\n";}
					if ($AUST_DST) {$area_GMT++;}
					$AC_processed++;
					}
				if ( (!$AC_processed) && ($area_GMT_method =~ /FSO-TSM/) )
					{
					if ($DBX) {print "     First Sunday October to Third Sunday March\n";}
					&NZL_dstcalc;
					if ($DBX) {print "     DST: $NZL_DST\n";}
					if ($NZL_DST) {$area_GMT++;}
					$AC_processed++;
					}
				if (!$AC_processed)
					{
					if ($DBX) {print "     No DST Method Found\n";}
					if ($DBX) {print "     DST: 0\n";}
					$AC_processed++;
					}


				if ($AC_processed)
					{
					$stmtA = "select count(*) from vicidial_list where phone_code='$match_code_ORIG' $AC_match and gmt_offset_now != '$area_GMT';";
						if($DBX){print STDERR "\n|$stmtA|\n";}
						$dbhA->query($stmtA);
					 $rec_countW=0;
					if ($dbhA->has_selected_record)
						{
						$iterA=$dbhA->create_record_iterator;
						   while ($recordA = $iterA->each)
							{
							$rec_countW = $recordA->[0];
							} 
						}
					if (!$rec_countW)
						{
						if ($DB) {print "   ALL GMT ALREADY CORRECT FOR : $match_code_ORIG  $area_code   $area_GMT\n";}
						$ei++;
						}
					else
						{
						$stmtA = "update vicidial_list set gmt_offset_now='$area_GMT' where phone_code='$match_code_ORIG' $AC_match and gmt_offset_now != '$area_GMT';";
						if($DB){print STDERR "\n|$stmtA|\n";}
						if (!$T) {$dbhA->query($stmtA); }
						$Prec_countW = sprintf("%8s", $rec_countW);
						if ($DB) {print " $Prec_countW records in $match_code_ORIG  $area_code   updated to $area_GMT\n";}
						$ee++;
				#		sleep(1);
						}
					}
				}
			
			$ep++;
			}
		else
			{
			if ($DBX) {print "   IGNORING: $codefile[$e]\n";}
			$ei++;
			}
		$e++;
		}
	
	$d++;
	}



	$dbhA->close;

if($DB){print "\nDONE\n";}

exit;




sub USA_dstcalc {
#**********************************************************************
# FSA-LSO
#     This is returns 1 if Daylight Savings Time is in effect and 0 if 
#       Standard time is in effect.
#     Based on first Sunday in April and last Sunday in October at 2 am.
#     INPUTS:
#       mm              INTEGER       Month.
#       dd              INTEGER       Day of the month.
#       ns              INTEGER       Seconds into the day.
#       dow             INTEGER       Day of week (0=Sunday, to 6=Saturday)
#     OPTIONAL INPUT:
#       timezone        INTEGER       hour difference UTC - local standard time
#                                      (DEFAULT is blank)
#                                     make calculations based on UTC time, 
#                                     which means shift at 10:00 UTC in April
#                                     and 9:00 UTC in October
#     OUTPUT: 
#                       INTEGER       1 = DST, 0 = not DST
#**********************************************************************
    
	$USA_DST=0;
	$mm = $mon;
	$dd = $mday;
	$ns = $dsec;
	$dow= $wday;

    if ($mm < 4 || $mm > 10) {
	$USA_DST=0;   return 0;
    } elsif ($mm >= 5 && $mm <= 9) {
	$USA_DST=1;   return 1;
    } elsif ($mm == 4) {
	if ($dd > 7) {
	    $USA_DST=1;   return 1;
	} elsif ($dd >= ($dow+1)) {
	    if ($timezone) {
		if ($dow == 0 && $ns < (7200+$timezone*3600)) {
		    $USA_DST=0;   return 0;
		} else {
		    $USA_DST=1;   return 1;
		}
	    } else {
		if ($dow == 0 && $ns < 7200) {
		    $USA_DST=0;   return 0;
		} else {
		    $USA_DST=1;   return 1;
		}
	    }
	} else {
	    $USA_DST=0;   return 0;
	}
    } elsif ($mm == 10) {
	if ($dd < 25) {
	    $USA_DST=1;   return 1;
	} elsif ($dd < ($dow+25)) {
	    $USA_DST=1;   return 1;
	} elsif ($dow == 0) {
	    if ($timezone) { # UTC calculations
		if ($ns < (7200+($timezone-1)*3600)) {
		    $USA_DST=1;   return 1;
		} else {
		    $USA_DST=0;   return 0;
		}
	    } else { # local time calculations
		if ($ns < 7200) {
		    $USA_DST=1;   return 1;
		} else {
		    $USA_DST=0;   return 0;
		}
	    }
	} else {
	    $USA_DST=0;   return 0;
	}
    } # end of month checks
} # end of subroutine dstcalc




sub GBR_dstcalc {
#**********************************************************************
#     This is returns 1 if Daylight Savings Time is in effect and 0 if 
#       Standard time is in effect.
#     Based on last Sunday in March and last Sunday in October at 1 am.
#**********************************************************************
    
	$GBR_DST=0;
	$mm = $mon;
	$dd = $mday;
	$ns = $dsec;
	$dow= $wday;

    if ($mm < 3 || $mm > 10) {
	$GBR_DST=0;   return 0;
    } elsif ($mm >= 4 && $mm <= 9) {
	$GBR_DST=1;   return 1;
    } elsif ($mm == 3) {
	if ($dd < 25) {
	    $GBR_DST=0;   return 0;
	} elsif ($dd < ($dow+25)) {
	    $GBR_DST=0;   return 0;
	} elsif ($dow == 0) {
	    if ($timezone) { # UTC calculations
		if ($ns < (3600+($timezone-1)*3600)) {
		    $GBR_DST=0;   return 0;
		} else {
		    $GBR_DST=1;   return 1;
		}
	    } else { # local time calculations
		if ($ns < 3600) {
		    $GBR_DST=0;   return 0;
		} else {
		    $GBR_DST=1;   return 1;
		}
	    }
	} else {
	    $GBR_DST=1;   return 1;
	}
    } elsif ($mm == 10) {
	if ($dd < 25) {
	    $GBR_DST=1;   return 1;
	} elsif ($dd < ($dow+25)) {
	    $GBR_DST=1;   return 1;
	} elsif ($dow == 0) {
	    if ($timezone) { # UTC calculations
		if ($ns < (3600+($timezone-1)*3600)) {
		    $GBR_DST=1;   return 1;
		} else {
		    $GBR_DST=0;   return 0;
		}
	    } else { # local time calculations
		if ($ns < 3600) {
		    $GBR_DST=1;   return 1;
		} else {
		    $GBR_DST=0;   return 0;
		}
	    }
	} else {
	    $GBR_DST=0;   return 0;
	}
    } # end of month checks
} # end of subroutine dstcalc




sub AUS_dstcalc {
#**********************************************************************
#     This is returns 1 if Daylight Savings Time is in effect and 0 if 
#       Standard time is in effect.
#     Based on last Sunday in October and last Sunday in March at 1 am.
#**********************************************************************
    
	$AUS_DST=0;
	$mm = $mon;
	$dd = $mday;
	$ns = $dsec;
	$dow= $wday;

    if ($mm < 3 || $mm > 10) {
	$AUS_DST=1;   return 1;
    } elsif ($mm >= 4 && $mm <= 9) {
	$AUS_DST=0;   return 0;
    } elsif ($mm == 3) {
	if ($dd < 25) {
	    $AUS_DST=1;   return 1;
	} elsif ($dd < ($dow+25)) {
	    $AUS_DST=1;   return 1;
	} elsif ($dow == 0) {
	    if ($timezone) { # UTC calculations
		if ($ns < (3600+($timezone-1)*3600)) {
		    $AUS_DST=1;   return 1;
		} else {
		    $AUS_DST=0;   return 0;
		}
	    } else { # local time calculations
		if ($ns < 3600) {
		    $AUS_DST=1;   return 1;
		} else {
		    $AUS_DST=0;   return 0;
		}
	    }
	} else {
	    $AUS_DST=0;   return 0;
	}
    } elsif ($mm == 10) {
	if ($dd < 25) {
	    $AUS_DST=0;   return 0;
	} elsif ($dd < ($dow+25)) {
	    $AUS_DST=0;   return 0;
	} elsif ($dow == 0) {
	    if ($timezone) { # UTC calculations
		if ($ns < (3600+($timezone-1)*3600)) {
		    $AUS_DST=0;   return 0;
		} else {
		    $AUS_DST=1;   return 1;
		}
	    } else { # local time calculations
		if ($ns < 3600) {
		    $AUS_DST=0;   return 0;
		} else {
		    $AUS_DST=1;   return 1;
		}
	    }
	} else {
	    $AUS_DST=1;   return 1;
	}
    } # end of month checks
} # end of subroutine dstcalc





sub AUST_dstcalc {
#**********************************************************************
#   TASMANIA ONLY
#     This is returns 1 if Daylight Savings Time is in effect and 0 if 
#       Standard time is in effect.
#     Based on first Sunday in October and last Sunday in March at 1 am.
#**********************************************************************
    
	$AUST_DST=0;
	$mm = $mon;
	$dd = $mday;
	$ns = $dsec;
	$dow= $wday;

    if ($mm < 3 || $mm > 10) {
	$AUST_DST=1;   return 1;
    } elsif ($mm >= 4 && $mm <= 9) {
	$AUST_DST=0;   return 0;
    } elsif ($mm == 3) {
	if ($dd < 25) {
	    $AUST_DST=1;   return 1;
	} elsif ($dd < ($dow+25)) {
	    $AUST_DST=1;   return 1;
	} elsif ($dow == 0) {
	    if ($timezone) { # UTC calculations
		if ($ns < (3600+($timezone-1)*3600)) {
		    $AUST_DST=1;   return 1;
		} else {
		    $AUST_DST=0;   return 0;
		}
	    } else { # local time calculations
		if ($ns < 3600) {
		    $AUST_DST=1;   return 1;
		} else {
		    $AUST_DST=0;   return 0;
		}
	    }
	} else {
	    $AUST_DST=0;   return 0;
	}
    } elsif ($mm == 10) {
	if ($dd > 7) {
	    $AUST_DST=1;   return 1;
	} elsif ($dd >= ($dow+1)) {
	    if ($timezone) {
		if ($dow == 0 && $ns < (7200+$timezone*3600)) {
		    $AUST_DST=0;   return 0;
		} else {
		    $AUST_DST=1;   return 1;
		}
	    } else {
		if ($dow == 0 && $ns < 3600) {
		    $AUST_DST=0;   return 0;
		} else {
		    $AUST_DST=1;   return 1;
		}
	    }
	} else {
	    $AUST_DST=0;   return 0;
	}
    } # end of month checks
} # end of subroutine dstcalc





sub NZL_dstcalc {
#**********************************************************************
#     This is returns 1 if Daylight Savings Time is in effect and 0 if 
#       Standard time is in effect.
#     Based on first Sunday in October and third Sunday in March at 1 am.
#**********************************************************************
    
	$NZL_DST=0;
	$mm = $mon;
	$dd = $mday;
	$ns = $dsec;
	$dow= $wday;

    if ($mm < 3 || $mm > 10) {
	$NZL_DST=1;   return 1;
    } elsif ($mm >= 4 && $mm <= 9) {
	$NZL_DST=0;   return 0;
    } elsif ($mm == 3) {
	if ($dd < 14) {
	    $NZL_DST=1;   return 1;
	} elsif ($dd < ($dow+14)) {
	    $NZL_DST=1;   return 1;
	} elsif ($dow == 0) {
	    if ($timezone) { # UTC calculations
		if ($ns < (3600+($timezone-1)*3600)) {
		    $NZL_DST=1;   return 1;
		} else {
		    $NZL_DST=0;   return 0;
		}
	    } else { # local time calculations
		if ($ns < 3600) {
		    $NZL_DST=1;   return 1;
		} else {
		    $NZL_DST=0;   return 0;
		}
	    }
	} else {
	    $NZL_DST=0;   return 0;
	}
    } elsif ($mm == 10) {
	if ($dd > 7) {
	    $NZL_DST=1;   return 1;
	} elsif ($dd >= ($dow+1)) {
	    if ($timezone) {
		if ($dow == 0 && $ns < (7200+$timezone*3600)) {
		    $NZL_DST=0;   return 0;
		} else {
		    $NZL_DST=1;   return 1;
		}
	    } else {
		if ($dow == 0 && $ns < 3600) {
		    $NZL_DST=0;   return 0;
		} else {
		    $NZL_DST=1;   return 1;
		}
	    }
	} else {
	    $NZL_DST=0;   return 0;
	}
    } # end of month checks
} # end of subroutine dstcalc
