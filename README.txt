+------------------------------------------------------------------------------+
|      Asterisk GUI client - astguiclient - second public release 0.8          |
|    created by Matt Florell <mattf@vicimarketing.com> <info@eflo.net>         |
|  project started 2003-10-06   http://sourceforge.net/projects/astguiclient/  |
+------------------------------------------------------------------------------+

This suite of programs is designed to work with the Asterisk Open-source PBX
(http://www.asterisk.org) as a cross-platform GUI client and the supporting 
server side applications necessary for the features of the GUI application to 
work with Asterisk.

Included in this distribution of the Asterisk GUI client are:

- AST_WINphoneAPP_0.8.pl - the GUI application itself
   + Runs under UNIX Xwindows or Win32
   + On UNIX requires perl and tcl and Tk perl modules installed
      + ActiveState 5.8.0 is recommended for Linux due to Perl/Tk memory leak
   + On Win32 requires ActiveState Perl 5.8.0
   + Both require Net::Telnet and Net::MySQL perl Modules (Win32 version in lib)
   + Variables and options must be defined in libs/AST_VICI_conf.pl file

- AST_SQL_update_channels.pl - command line DB updater
   + Runs under UNIX CLI or Win CLI
   + On UNIX requires perl
   + On Win32 requires ActiveState Perl 5.8.0
   + Both require Net::Telnet, Net::MySQL and Time::HiRes perl Modules

 - AST_CRON_mix_recordings.pl - command line recording mixer to be put in cron
   + Runs under UNIX CLI in the cron of the Asterisk Server
   + Requires perl (Net::FTP and Net::Ping optional if FTPing to archive server)

 - call_log.agi - AGI/perl programm for call logging (OPTIONAL)
   + Runs under Asterisk Server
   + Requires perl and Net::MySQL

 - CONF_Asterisk.txt - text file with instructions on what needs to be added to 
    the Asterisk configurations files

 - CONF_MySQL.txt - text file with instructions on what needs to be added to    
    the MySQL database "asterisk" that must be created for the suite to run

 - README.txt - this file


DESCRIPTION:
This program was designed as a GUI client for the Asterisk PBX with Digium 
Zaptel cards and SIP VOIP hard or softphones as extensions, it could be adapted 
to other functions, but It was designed for Zap/SIP users. The program will run 
on X and Win32.


TO BE ADDED:
I plan on adding a popup RINGING-FLASH window to the application in the future, 
this would allow for people to have their ringers turned off(which is welcome 
thing in a customer-service-type environment) there are many ways to do this, 
I'm just trying to figure out the least intrusive way of coding it right now.
I am also considering forking the windows and unix clients into separate 
applications so that I can take advantage of the strengths of each platform to 
add more customization to the client app as well as application tray and web 
browser integration on each. Although this would mean more work, more files and 
more confusion on my end.


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


