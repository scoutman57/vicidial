#!/usr/bin/perl

print "\nStarting Asterisk...n";

`/usr/bin/screen -L -d -m -S asterisk /usr/sbin/asterisk -vvvvvvvvvvvvvvvvvvvvvgc`;

print "Asterisk started\n";

sleep(10);

