+------------------------------------------------------------------------------+
|      Asterisk GUI client - astguiclient - ninth public release 1.0.3         |
|           created by astGUIclient group <astguiclient@eflo.net>              |
|  project started 2003-10-06   http://sourceforge.net/projects/astguiclient/  |
+------------------------------------------------------------------------------+

This suite of programs is designed to work with the Asterisk Open-source PBX
(http://www.asterisk.org) as a cross-platform GUI client and the supporting 
server side applications necessary for the features of the GUI application to 
work with Asterisk.

 ***** Description, notes and changes below *****

Included in this distribution of the Asterisk GUI client are:

 - README.txt - this file

 - SCRATCH_INSTALL.txt - detailed instructions of how to fully install Asterisk 
with astguiclient from scratch. Also you could use this doc to install from 
PHASE 6 of the document if you have an existing Asterisk installation you want 
to put astguiclient onto.

 - ACQS.txt - Readme file describing the Asterisk Central Queue System

 - VICIDIAL.txt - Readme file describing the VICIDIAL auto-dialing system

 ** It may be easier to follow the SCRATCH_INSTALL directions than these**
 - CONF_Asterisk.txt - text file with instructions on what needs to be added to 
    the Asterisk configurations files

 - CONF_MySQL.txt - text file with instructions on what needs to be added to    
    the MySQL database "asterisk" that must be created for the suite to run

 - CONF_VICIDIAL_MySQL.txt - text file with instructions on what needs to be
    added to the MySQL "asterisk" db that must be created for vicidial to run

 - install_server_files.pl - perl script to put files in the right place on the 
server. run as "perl install_server_files.pl"

 - start_asterisk_boot.pl - starts asterisk through a screen, good for system 
boot time startups of asterisk.

- MySQL_AST_CREATE_tables.sql - used to create tables for astguiclient and 
vicidial in your MySQL database

- astGUIclient_1.0.3.pl - the GUI application itself
   + Runs under UNIX Xwindows or Win32
   + On UNIX requires perl and tcl and Tk perl modules installed
      + ActiveState 5.8.0 is recommended for Linux due to Perl/Tk memory leak
   + On Win32 requires ActiveState Perl 5.8.0
   + Both require Net::Telnet and Net::MySQL perl Modules (Win32 version in lib)
   + Variables and options must be defined in libs/AST_VICI_conf.pl file

 - astVICIDIAL_0.6.pl - the VICIDIAL GUI client auto-dialing application
   + same application run specs as the AST_WINphoneAPP above
   + additionally requires Time::HiRes perl module

 - AST_VICI_conf.pl - file where you define your variables for the client app
   + Must be present in one of the libs_path folders

 - AST_update.pl - command line DB updater
   + Ideally is run on the Asterisk server locally
   + Requires Net::Telnet, Net::MySQL and Time::HiRes perl Modules

 - AST_vm_update.pl - command line DB voicemail count updater
   + Ideally is run on the Asterisk server locally
   + Requires Net::Telnet, Net::MySQL and Time::HiRes perl Modules
   + place in the cron as "* * * * * /path/to/script"

 - ADMIN_keepalive_AST_update.pl - checks to see that updater is running
   + Must put entry for this script in the cron as "* * * * * /path/to/script"

 - AST_CRON_mix_recordings.pl - command line recording mixer to be put in cron
   + Runs under UNIX CLI in the cron of the Asterisk Server
   + Requires perl (Net::FTP and Net::Ping optional if FTPing to archive server)

 - AST_SERVER_conf.pl - file where you define your variables for the server apps
   + Must be present in the /home/cron/ directory

 - AST_manager_listen.pl - listener for the Asterisk Central Queue System (ACQS)
   + Must be present in the /home/cron/ directory
   + Requires Net::Telnet, Net::MySQL and Time::HiRes perl Modules

 - AST_manager_send.pl - send-spawn for the ACQS
   + Must be present in the /home/cron/ directory
   + Requires Net::Telnet, Net::MySQL and Time::HiRes perl Modules

 - AST_send_action_child.pl - blind-send for the ACQS
   + Must be present in the /home/cron/ directory
   + Requires Net::Telnet, Net::MySQL perl Modules

 - ADMIN_keepalive_AST_send_listen.pl - checks to see that ACQS is running
   + Must put entry for this script in the cron as "* * * * * /path/to/script"

 - AST_manager_kill_hung_congested.pl - kills CONGEST Local/ channels
   + To be used with VICIDIAL
   + Must put entry for this script in the cron as "* * * * * /path/to/script"

 - ADMIN_listener_restart.pl - automatically restart ACQS 
   + Assumes installation in /home/cron/

 - ADMIN_restart_roll_logs.pl - rolls logs over datestamp upon restart
   + put this script in your machine's startup routine

 - AST_reset_mysql_vars.pl - resets MySQL tables 
   + To be used with VICIDIAL
   + put this script in your machine's startup routine

 - call_log.agi - AGI/perl programm for call logging (OPTIONAL)
   + Runs under Asterisk Server
   + Must be present in the /var/lib/asterisk/agi-bin/ directory
   + Requires perl and Net::MySQL

 - call_inbound.agi - AGI/perl programm for CallerID popup info (OPTIONAL)
   + Runs under Asterisk Server
   + Must be present in the /var/lib/asterisk/agi-bin/ directory
   + Requires perl and Net::MySQL

 - agi-dtmf.agi - AGI/perl program that plays DTMF tines for conferences
   + Runs on Asterisk Server
   + Must be present in the /var/lib/asterisk/agi-bin/ directory
   + Requires DTMF sounds to be copied to /var/lib/asterisk/sounds/

 - agi-VDADtransfer.agi - AGI/perl program that transfers calls to VICIDIAL reps
   + Runs on Asterisk Server
   + Must be present in the /var/lib/asterisk/agi-bin/ directory

 - AST_VDauto_dial.pl - script to automatically call leads for VICIDIAL
   + To be used with VICIDIAL
   + kept running with the associated keepalive script in the cron

 - AST_VDhopper.pl - script to keep leads in the VICIDIAL hopper
   + To be used with VICIDIAL

 - ADMIN_keepalive_AST_VDautodial.pl - checks to see that VDAD is running
   + Must put entry for this script in the cron as "* * * * * /path/to/script"

 - VICIDIAL_IN_new_leads_file.pl - script to load lead files into VICIDIAL
   + To be used with VICIDIAL

 - ASTGUICLIENT Web admin pages - administration for ASTGUICLIENT
   + must be installed on machine with PHP and MySQL enabled
   + must be able to read/write/update to asterisk MySQL database
   + welcome.php - just a welcome page
   + admin.php - all admin functions for ASTGUICLIENT database
   + user_stats.php - look at live user stats
   + remote_inbound.php - custom script to grab parked inbound calls remotely
   + inbound_popup.php - from remote_inbound page

 - VICIDIAL Web admin pages - administration for VICIDIAL campaigns
   + must be installed on machine with PHP and MySQL enabled
   + must be able to read/write/update to asterisk MySQL database
   + welcome.php - just a welcome page
   + admin.php - all admin functions for VICIDIAL
   + user_stats.php - look at live user stats
   + record_conf_1_hour.php - record a VICIDIAL conference for 1 hour
   + closer.php - where closers log in to grab calls sent from fronters
   + closer_popup.php - from closer page, sends call to closers phone
   + closer_dispo.php - from closer_popup, allows dispositioning of call


DESCRIPTION:
This program was designed as a GUI client for the Asterisk PBX with Digium 
Zaptel cards and SIP VOIP hard or softphones as extensions, it could be adapted 
to other functions, but It was designed for Zap/SIP users. The program will run 
on X and Win32.


TO BE ADDED:
We are toying with the idea of adding a "Hijack" feature that would allow you 
to take any channel from whoever they are talking to and direct it to your 
phone, but we're not sure that's such a good idea. We are also looking at adding
a separate operator-specific GUI app to allow for better extension monitoring 
and transferring options that operators require. We are also looking at creating 
an inbound-agent-specific GUI that would ideally work with Asterisk queues.


NOTES:
There are several features/processes that could have been done many different 
ways in this suite, one for example is call parking. After tinkering with 
Asterisk/AGI-only call parking where all of the call parking would be achieved 
with no need for a GUI client, I discovered that my implementation did not 
function well on all single line phones or the Grandstream phones. I settled on 
the current method of call-parking by creating a record in a table for a call 
parked and Redirecting the call to a constant music extension to take any phone 
button pressing out of the loop. We haven't had any problems since we switched 
to this method of call parking. Many of the other decisions of how to program 
features in this suite we arrived at through similar trial-and-error methods. If 
anyone has suggestions/praises/criticisms I would love to hear them.


KNOWN BUGS:
- on VICIDIAL changing from manual dialing to autodialing can cause manager 
  commands to not be executed, when switching from manual-dial to auto, logout
  and close the astVICIDIAL app and open it back up
- on VICIDIAL autodial, very rarely the app will freeze, just close it and log
  back in again and everything should be fine


VERSION HISTORY:

0.7 - First public release - 2003-11-18
This is the first release of the Asterisk GUI Client code, it is entirely 
written in Perl with portability and rapid development/testing in mind. The perl 
code is NOT strict, it was written loose and fast and has been functioning 
rather well in a production environment of 60 clients for one month now.

0.8 - Second public release - 2003-12-09
- Several bug fixes
- New button for monitoring live extensions on Zap channels
- Changed the method that the live channels/phone were populated on the 
listboxes of the client app.
- Changed the Asterisk/Manager commands to work correctly with new Asterisk CVS 
versions requirements. 
- A new routine was enabled to allow for making sure that the updater is   
running and bringing up a popup alert window on the client if the updater has 
not updated in the last 6 seconds. (this also added a new MySQL table)
- Changed the updater to run every 450 milliseconds instead of every 333 
milliseconds. 
- Updater changed to allow for ringing channels to appear in the live_channels 
table. 

0.9 - Third public release - 2004-02-05
The majority of the work in this release it to make it more stable and fix some 
pretty bad bugs. We created the Asterisk Central Queue System to address the 
problem with buffer-overflows in the manager interface of Asterisk causing total 
system deadlocks. We also completed and touched-up many other features that we 
didn't finish in previous releases. Here is the list of changes:
- Several bug fixes
- Inclusion of listing for active SIP/Local channels and ability to hang them up
- Completely changed the method of conferencing to be more fluid
- Added HELP popup screen
- Added intrasystem calling funtionality
- Updater changed to allow for SIP/Local channels
- Recording for conferences is now able to record all audio in and out
- Added ability to send DTMF tones within a conference
- Changed alert window for updater being down timeout to 20 seconds
- Added an option for using the new Asterisk Central Queue System(ACQS) that 
reduces the risk of deadlocks that occur with buffer-overflows on remote manager 
interface connections
- Included new script to run at boot time and rotate the logs as well as a 
keepalive script for the new ACQS 
- Changed non-AGI server-side scripts to allow for a single config file
- Detailed activity logging to text file option added
- Activity logging added to all non-AGI server applications

0.9.2 - Fourth public release - 2004-03-08
- several bug fixes for the GUI client and ACQS applications
- addition of the new VICIDIAL auto-dialer application and admin web pages
- added new script to reset MySQL tables
- added new script to kill CONGEST Local/ channels

0.9.4 - Fifth public release - 2004-03-12
- a few bug fixes for the GUI and server apps
- addition of callerID popup for the GUI
- callerID buttons to launch web pages from callerID popup
- addition of voicemail count display to GUI
- addition of button to directly connect to voicemail
- addition of voicemail counter updater
- MySQL table "phones" modified and "inbound" table added(see CONF_MySQL.txt)
- new extensions.conf entries need to be added to use callerid and vmail GUI

1.0.0 - Sixth public release - 2004-03-26
- a few bug fixes for the GUI and server apps
- Major documentation changes with the addition of the SCRATCH_INSTALL.txt file 
that goes step-by-step through the entire install process of an asterisk server 
from blank hardware to astguiclient installation and configuration.
- added pretty buttons to the WINphoneAPP
- added blind transfer to voicemail, blind transfer to another extension and 
blind external transfer
- new install script created to put server files in default positions and set 
permissions to execute
- new sql file to create all tables by running a script execute command in MySQL

1.0.1 - Seventh public release - 2004-04-27
- a few bug fixes for the GUI and server apps
- minor changes to WINphoneAPP
- major changes to VICIDIAL client code:
   + rearranged VICIDIAL buttons and added some color to DIAL and HANGUP buttons
   + allowed for call parking with different park music per-campaign
   + allowed for webpage forms launched from GUI with call info
   + allowed for different web form web page per-campaign
   + allowed agents using VICIDIAL client to send calls with data to a closer
   + new call-closer functionality is web-based for flexibility
   + added new DTMF dialpad for sending tones quickly
- fixed bugs in VICIDIAL web admin pages
- fixed bugs in ASTGUICLIENT web admin pages
- added code from Paul Concepcion to allow admin pages to work with globals off
- added common database connection file for each set of PHP admin pages
- made small changes to the MySQL database Schema
  (NOTE: if upgrading from 1.0.0 run the upgrade_1.0.1.sql script in MySQL)

1.0.2 - Eighth public release - 2004-06-03
- a few bug fixes for the GUI apps
- corrected documentation errors in SCRATCH_INSTALL instructions
- updated SCRATCH_INSTALL instructions for some newer software
- corrected errors in SQL install queries
- corrected errors in server installation scripts
- WINphoneAPP config option to allow one persistant mysql DB connection
- WINphoneAPP config option to allow modification of info refresh interval
- VICIDIAL modified to allow for auto-dial of next number
  (NOTE: if upgrading from 1.0.1 you do not need to update any web pages or 
   server apps, this update is only a client GUI and docs update. Note that the 
   AST_VICI_conf.pl has been updated, so you may need to modify your client 
   configs to enable new features.)

1.0.3 - Ninth public release - 2004-07-XX
- a few bug fixes for the GUI apps
- changed the recording to show recording ID when recording is started
- VICIDIAL overhauled:
  + added Time::HiRes module requirement to better control time increments
  + changed to dial from a small hopper of pre-ordered leads per campaign
  + added cron script to always keep leads in the hopper every minute
  + added a counter to see how many times a lead is called
  + added ability to dial campaign by how many times lead called
  + added some new stats to the admin web pages
  + created a limited predictive-dialer that will dial a certain amount of leads
  per logged in agent and direct the calls that are picked up to the next agent
  + ability to transfer the called line and the 3rd party call into a separate 
  meetme room and continue on dialing
 UPGRADE NOTES:
  * if upgrading from 1.0.2 you need to update the web pages and all 
   server apps. 
  * if upgrading from 1.0.2 run the upgrade_1.0.3.sql script in MySQL
  * if upgrading from 1.0.2 you may want to run AST_upgrade_1.0.3.pl to update
   your called counts of your leads in vicidial_list.
  * AST_SERVER_conf.pl has been updated, so you may need to modify your server 
   configs to enable new features.
  * client app names have been changed to astVICIDIAL and astGUIclient

