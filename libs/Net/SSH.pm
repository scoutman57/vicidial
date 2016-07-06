package Net::SSH;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $ssh $equalspace $DEBUG @ssh_options);
use Exporter;
use IO::File;
use IPC::Open2;
use IPC::Open3;

@ISA = qw(Exporter);
@EXPORT_OK = qw( ssh issh ssh_cmd sshopen2 sshopen3 );
$VERSION = '0.07';

$DEBUG = 0;

$ssh = "ssh";

=head1 NAME

Net::SSH - Perl extension for secure shell

=head1 SYNOPSIS

  use Net::SSH qw(ssh issh sshopen2 sshopen3);

  ssh('user@hostname', $command);

  issh('user@hostname', $command);

  ssh_cmd('user@hostname', $command);
  ssh_cmd( {
    user => 'user',
    host => 'host.name',
    command => 'command',
    args => [ '-arg1', '-arg2' ],
    stdin_string => "string\n",
  } );

  sshopen2('user@hostname', $reader, $writer, $command);

  sshopen3('user@hostname', $writer, $reader, $error, $command);

=head1 DESCRIPTION

Simple wrappers around ssh commands.

For an all-perl implementation that does not require the system B<ssh> command,
see L<Net::SSH::Perl> instead.

=head1 SUBROUTINES

=over 4

=item ssh [USER@]HOST, COMMAND [, ARGS ... ]

Calls ssh in batch mode.

=cut

sub ssh {
  my($host, @command) = @_;
  @ssh_options = &_ssh_options unless @ssh_options;
  my @cmd = ($ssh, @ssh_options, $host, @command);
  warn "[Net::SSH::ssh] executing ". join(' ', @cmd). "\n"
    if $DEBUG;
  system(@cmd);
}

=item issh [USER@]HOST, COMMAND [, ARGS ... ]

Prints the ssh command to be executed, waits for the user to confirm, and
(optionally) executes the command.

=cut

sub issh {
  my($host, @command) = @_;
  my @cmd = ($ssh, $host, @command);
  print join(' ', @cmd), "\n";
  if ( &_yesno ) {
    system(@cmd);
  }
}

=item ssh_cmd [USER@]HOST, COMMAND [, ARGS ... ]

=item ssh_cmd OPTIONS_HASHREF

Calls ssh in batch mode.  Throws a fatal error if data occurs on the command's
STDERR.  Returns any data from the command's STDOUT.

If using the hashref-style of passing arguments, possible keys are:

  user (optional)
  host (requried)
  command (required)
  args (optional, arrayref)
  stdin_string (optional) - written to the command's STDIN

=cut

sub ssh_cmd {
  my($host, $stdin_string, @command);
  if ( ref($_[0]) ) {
    my $opt = shift;
    $host = $opt->{host};
    $host = $opt->{user}. '@'. $host if exists $opt->{user};
    @command = ( $opt->{command} );
    push @command, @{ $opt->{args} } if exists $opt->{args};
    $stdin_string = $opt->{stdin_string};
  } else {
    ($host, @command) = @_;
    undef $stdin_string;
  }

  my $reader = IO::File->new();
  my $writer = IO::File->new();
  my $error  = IO::File->new();

  sshopen3( $host, $writer, $reader, $error, @command ) or die $!;

  print $writer $stdin_string if defined $stdin_string;
  close $writer;

  local $/ = undef;
  my $output_stream = <$reader>;
  my $error_stream = <$error>;

  if ( length $error_stream ) {
    die "[Net:SSH::ssh_cmd] STDERR $error_stream";
  }

  return $output_stream;

}

=item sshopen2 [USER@]HOST, READER, WRITER, COMMAND [, ARGS ... ]

Connects the supplied filehandles to the ssh process (in batch mode).

=cut

sub sshopen2 {
  my($host, $reader, $writer, @command) = @_;
  @ssh_options = &_ssh_options unless @ssh_options;
  open2($reader, $writer, $ssh, @ssh_options, $host, @command);
}

=item sshopen3 HOST, WRITER, READER, ERROR, COMMAND [, ARGS ... ]

Connects the supplied filehandles to the ssh process (in batch mode).

=cut

sub sshopen3 {
  my($host, $writer, $reader, $error, @command) = @_;
  @ssh_options = &_ssh_options unless @ssh_options;
  open3($writer, $reader, $error, $ssh, @ssh_options, $host, @command);
}

sub _yesno {
  print "Proceed [y/N]:";
  my $x = scalar(<STDIN>);
  $x =~ /^y/i;
}

sub _ssh_options {
  my $reader = IO::File->new();
  my $writer = IO::File->new();
  my $error  = IO::File->new();
  open3($writer, $reader, $error, $ssh, '-V');
  my $ssh_version = <$error>;
  chomp($ssh_version);
  if ( $ssh_version =~ /.*OpenSSH[-|_](\w+)\./ && $1 == 1 ) {
    $equalspace = " ";
  } else {
    $equalspace = "=";
  }
  my @options = ( '-o', 'BatchMode'.$equalspace.'yes' );
  if ( $ssh_version =~ /.*OpenSSH[-|_](\w+)\./ && $1 > 1 ) {
    unshift @options, '-T';
  }
  @options;
}

=back

=head1 EXAMPLE

  use Net::SSH qw(sshopen2);
  use strict;

  my $user = "username";
  my $host = "hostname";
  my $cmd = "command";

  sshopen2("$user\@$host", *READER, *WRITER, "$cmd") || die "ssh: $!";

  while (<READER>) {
      chomp();
      print "$_\n";
  }

  close(READER);
  close(WRITER);

=head1 FREQUENTLY ASKED QUESTIONS

Q: How do you supply a password to connect with ssh within a perl script
using the Net::SSH module?

A: You don't.  Use RSA or DSA keys.  See the ssh-keygen(1) manpage.

Q: My script is "leaking" ssh processes.

A: See L<perlfaq8/"How do I avoid zombies on a Unix system">, L<IPC::Open2>,
L<IPC::Open3> and L<perlfunc/waitpid>.

=head1 AUTHORS

Ivan Kohler <ivan-netssh_pod@420.am>

John Harrison <japh@in-ta.net> contributed an example for the documentation.

Martin Langhoff <martin@cwa.co.nz> contributed the ssh_cmd command, and
Jeff Finucane <jeff@cmh.net> updated it and took care of the 0.04 release.

Anthony Awtrey <tony@awtrey.com> contributed a fix for those still using
OpenSSH v1.

=head1 COPYRIGHT

Copyright (c) 2002 Ivan Kohler.
Copyright (c) 2002 Freeside Internet Services, LLC
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

Not OO.

Look at IPC::Session (also fsh)

=head1 SEE ALSO

For an all-perl implementation that does not require the system B<ssh> command,
see L<Net::SSH::Perl> instead.

ssh-keygen(1), ssh(1), L<IO::File>, L<IPC::Open2>, L<IPC::Open3>

=cut

1;

