+------------------------------------------------------------------------------+
|      Asterisk GUI client - astguiclient - second public release 0.9          |
|    created by Matt Florell <mattf@vicimarketing.com> <info@eflo.net>         |
|  project started 2003-10-06   http://sourceforge.net/projects/astguiclient/  |
+------------------------------------------------------------------------------+

This suite of programs is designed to work with the Asterisk Open-source PBX
(http://www.asterisk.org) as a cross-platform GUI client and the supporting 
server side applications necessary for the features of the GUI application to 
work with Asterisk.

Included in this distribution of the Asterisk GUI client are:

- AST_WINphoneAPP_0.9.pl - the GUI application itself
   + Runs under UNIX Xwindows or Win32
   + On UNIX requires perl and tcl and Tk perl modules installed
      + ActiveState 5.8.0 is recommended for Linux due to Perl/Tk memory leak
   + On Win32 requires ActiveState Perl 5.8.0
   + Both require Net::Telnet and Net::MySQL perl Modules (Win32 version in lib)
   + Variables and options must be defined in libs/AST_VICI_conf.pl file

 - AST_VICI_conf.pl - file where you define your variables for the client app
   + Must be present in one of the libs_path folders

 - AST_update.pl - command line DB updater
   + Ideally is run on the Asterisk server locally
   + Requires Net::Telnet, Net::MySQL and Time::HiRes perl Modules

 - ADMIN_keepalive_AST_update.pl - checks to see that updater is running
   + Must put entry for this script in the cron as "* * * * * /path/script"

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
   + Must put entry for this script in the cron as "* * * * * /path/script"

 - ADMIN_listener_restart.pl - automatically restart ACQS 
   + Assumes installation in /home/cron/

 - ADMIN_restart_roll_logs.pl - rolls logs over datestamp upon restart
   + put this script in your machine's startup routine

 - call_log.agi - AGI/perl programm for call logging (OPTIONAL)
   + Runs under Asterisk Server
   + Must be present in the /var/lib/asterisk/agi-bin/ directory
   + Requires perl and Net::MySQL

 - agi-dtmf.agi - AGI/perl program that plays DTMF tines for conferences
   + Runs on Asterisk Server
   + Must be present in the /var/lib/asterisk/agi-bin/ directory
   + Requires DTMF sounds to be copied to /var/lib/asterisk/sounds/

 - CONF_Asterisk.txt - text file with instructions on what needs to be added to 
    the Asterisk configurations files

 - CONF_MySQL.txt - text file with instructions on what needs to be added to    
    the MySQL database "asterisk" that must be created for the suite to run

 - README.txt - this file

 - ACQS.txt - Readme file describing the Asterisk Central Queue System


DESCRIPTION:
This program was designed as a GUI client for the Asterisk PBX with Digium 
Zaptel cards and SIP VOIP hard or softphones as extensions, it could be adapted 
to other functions, but It was designed for Zap/SIP users. The program will run 
on X and Win32.


TO BE ADDED:
I plan on adding a popup RINGING-FLASH window to the application in the future, 
this would allow for people to have their ringers turned off(which is welcome 
thing in a customer-service-type environment) there are many ways to do this, 
I'm just trying to figure out the least intrusive way of coding it right now. We 
are toying with the idea of adding a "Hijack" feature that would allow you to 
take any channel from whoever they are talking to and direct it to your phone, 
but we're not sure that's such a good idea.


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
