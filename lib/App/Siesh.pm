package App::Siesh;

use strict;
use warnings;

use Term::ShellUI;
use Net::ManageSieve::Siesh;
use File::Temp qw/tempfile/;

our $VERSION = '0.10';

sub run {
    my ( $class, %config ) = @_;

    # Set defaults for Net::ManageSieve::Siesh construction
    $config{user} ||= $ENV{USER};
    $config{host} ||= 'imap';

    my @params = ();

    foreach ( 'debug', 'port' ) {
        push @params, ucfirst($_), $config{$_}
          if defined $config{$_};
    }

    push @params, 'tls', $config{'tls'}
      if defined $config{'tls'};

    my $sieve = Net::ManageSieve::Siesh->new( $config{host}, @params )
      or die "Can't connect to $config{host}: $!\n";

    $sieve->auth( $config{user}, $config{password} ) or die "$@\n";

    my $term = new Term::ShellUI(
        history_file => '~/.siesh_history',
        prompt       => 'siesh> ',
        commands     => {
            "help" => {
                desc   => "Print this help page.",
                args   => sub { shift->help_args( undef, @_ ); },
                method => sub { shift->help_call( undef, @_ ); },
            },
            "put" => {
                desc    => 'Upload a script onto the server.',
                maxargs => 2,
                minargs => 2,
                proc =>
                  sub { $sieve->putfile(@_) or die $sieve->error() . "\n" },
                args => sub { shift->complete_files(@_); },
            },
            "get" => {
                desc    => "Fetch a script from the server and store locally.",
                maxargs => 2,
                minargs => 2,
                proc =>
                  sub { $sieve->getfile(@_) or die $sieve->error() . "\n" },
                args => sub { shift->complete_files(@_); },
            },
            "quit" => {
                desc    => "Quit siesh.",
                maxargs => 0,
                method  => sub { $sieve->logout; shift->exit_requested(1); }
            },
            "list" => {
                desc    => "List all scripts stored on the server.",
                maxargs => 0,
                proc    => sub { $sieve->print_script_listing },
            },
            "activate" => {
                desc    => "Mark a script as active.",
                maxargs => 1,
                proc =>
                  sub { $sieve->setactive(shift) or die $sieve->error() . "\n" }
                ,
                args => sub { complete_scripts( @_, $sieve ) },
            },
            "edit" => {
                desc    => 'Edit script using $EDITOR.',
                maxargs => 1,
                proc    => sub { $sieve->edit_script(shift) },
                args => sub { complete_scripts( @_, $sieve ) },
            },
            "view" => {
                desc    => 'Examine the contents of a script using $PAGER.',
                maxargs => 1,
                proc    => sub { $sieve->view_script(shift) },
                args    => sub { complete_scripts( @_, $sieve ) },
            },
            "delete" => {
                desc    => "Delete a script from the server.",
                minargs => 1,
                proc    => sub { $sieve->delete(shift) },
                args    => sub { complete_scripts( @_, $sieve ) },
            },
            "cat" => {
                desc    => "Show the contents of a script on stdout.",
                minargs => 1,
                proc    => sub { $sieve->cat(shift) },
                args    => sub { complete_scripts( @_, $sieve ) },
            },
            "copy" => {
                desc    => 'Make a copy of a script under another name.',
                maxargs => 2,
                minargs => 2,
                proc =>
                  sub { $sieve->copyscript(@_) or die $sieve->error() . "\n" },
                args => sub { complete_scripts( @_, $sieve ) },
            },
            "move" => {
                desc    => 'Rename a script on the server.',
                maxargs => 2,
                minargs => 2,
                proc =>
                  sub { $sieve->movescript(@_) or die $sieve->error() . "\n" },
                args => sub { complete_scripts( @_, $sieve ) },
            },
            "deactivate" => {
                desc    => 'Mark the currently activated script as inactive.',
                maxargs => 0,
                proc =>
                  sub { $sieve->deactivate() or die $sieve->error() . "\n" },
                args => sub { complete_scripts( @_, $sieve ) },
            },
            "q"      => { alias => 'quit',       exclude_from_completion => 1 },
            "logout" => { alias => 'quit',       exclude_from_completion => 1 },
            "h"      => { alias => "help",       exclude_from_completion => 1 },
            "ls"     => { alias => "list",       exclude_from_completion => 1 },
            "dir"    => { alias => "list",       exclude_from_completion => 1 },
            "rm"     => { alias => "delete",     exclude_from_completion => 1 },
            "vi"     => { alias => "edit",       exclude_from_completion => 1 },
            "less"   => { alias => "less",       exclude_from_completion => 1 },
            "more"   => { alias => "less",       exclude_from_completion => 1 },
            "touch"  => { alias => "edit",       exclude_from_completion => 1 },
            "type"   => { alias => "cat",        exclude_from_completion => 1 },
            "cp"     => { alias => "copy",       exclude_from_completion => 1 },
            "mv"     => { alias => "move",       exclude_from_completion => 1 },
            "set"    => { alias => "activate",   exclude_from_completion => 1 },
            "unset"  => { alias => "deactivate", exclude_from_completion => 1 },
        },
    );

    $term->{term}->ornaments(0);
    $term->run();
}

sub complete_scripts {
    my ( $self, $cmp, $sieve ) = @_;
    return [ grep { index( $_, $cmp->{str} ) == 0 }
          @{ $sieve->listscripts() } ];
}

1;

__END__

=head1 NAME

App::Siesh - interactive sieve shell

=head1 SYNOPSIS

	App::Siesh->run(
	    debug => 0,
	    user  => 'dom',
	    host  => 'imap',
	    tls   => 'require',
	    port  => '2000',
	    password => 'secret',
	);

=head1 DESCRIPTION

App::Siesh provides a shell-like interface for manipulating sieve scripts
using the ManageSieve protocol.

=head1 OPTIONS

=over 4

=item debug

Enable debugging.

=item user

Specifies the username to use when logging into the sieve server. This
option defaults to the value of the environment variable C<USER>.

=item host

Specifies the machine to connect to. Defaults to C<imap>.

=item port

Specifies the remote port to connect to. Defaults to C<2000>.

=item tls

Specifies whether TLS is required ("require") or optional
("auto"). Defaults to unset, disabling TLS.

=item password

Specifies the password to login.

=back

=head1 COMMANDS

=over 4

=item B<list> 

Prints a list of all scripts on the server. The currently active script,
if any, is marked by a I<*> (astersik).

Synonyms: B<ls>

=item B<delete> I<script-name> I<...>

Deletes a script. It's not possible to delete the currently active
script, so please use deactivate first. There's no way to undelete a
deleted script.

Synonyms: B<rm>

=item B<edit> I<script-name>

Edits a script on the server without downloading it explicitly to your
disk first. Under the hood it creates a temporary file, puts the script
content in it and calls C<$ENV{EDITOR}> on it. After that the script is
uploaded back. It's also possible to create and edit a new script with
this command.

If your script is syntactical incorrect, you will be prompted to
re-edit the file or throw away your changes.

=item B<activate> I<script-name>

Activates the listed script. User may have multiple Sieve scripts on
the server, yet only one script may be used for filtering of incoming
messages. This is called the active script. Users may have zero or one
active scripts

=item B<deactivate>

Deactivate all scripts. Deactivation of all your scripts results in no
filtering at all.

=item B<cat> I<script-name> I<...>

Print scripts on the standard output.

=item B<quit>

Terminates the sessiion with the remote SIEVE server. An end of file
will also terminate the session and exit.

=item B<help>

Print a short description of all commands.

=item B<put> I<file-name> I<script-name>

Store a local file as script on the remote machine.

=item B<get> I<file-name> I<local-name>

Retrieve a remote script and store it on the local machine.

=back

=head1 SEE ALSO

L<siesh>, L<Net::ManageSieve::Siesh>, L<Net::ManageSieve>

=head1 AUTHOR

Mario Domgoergen <dom@math.uni-bonn.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
