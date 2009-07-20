package Net::ManageSieve::Plus;

use warnings;
use strict;
use File::Temp qw/tempfile/;
use Net::ManageSieve;

our @ISA = qw/Net::ManageSieve/;

=head1 NAME

Net::ManageSieve::Plus - Expanding ManagieSieve beyond the Protocol

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Net::ManageSieve::Plus expands Net::ManagieSieve beyond just implementing
the core RFC protocol. There are functions to upload and download files,
deactivating scripts, copy and move them etc.

    use Net::ManageSieve::Plus;

    my $sieve = Net::ManageSieve::Plus->new();
    $sieve->copy('script1','script2');
    $sieve->mv('script2','script3');
    $sieve->put('../script.txt','script4');
    $sieve->get('script1','../script.txt');

If you're just searching for a comamnd line interface to ManageSieve,
please take a look at C<siesh(1)>.

=head1 METHODS

=over 4

=item C<deactivate()>

This function deactivates all active scripts on the server. This has
the same effect as using the function setactive with an empty string
as argument.

=cut

sub deactivate {
	my $self = shift;
	$self->setactive("") or do { $self->_set_error($@) ; return undef };
}

=item C<movescript($oldscriptname,$newscriptname)>

Renames the script. This functions is equivalent to copying a script
and then deleting the source script.

=cut

sub movescript {
	my ($self,$source,$target) = @_;
	$self->copyscript($source,$target);
	$self->deletescript($source) or do { $self->_set_error($@) ; return undef };
}

=item C<copyscript($oldscriptname,$newscriptname)>

Copy the script C<$oldscriptname> to C<$newscriptname>.

=cut

sub copyscript {
	my ($self,$source,$target) = @_;
	my $content = $self->getscript($source) or do { $self->_set_error($@) ; return undef; };
	$self->putscript($target,$content) or do { $self->_set_error($@) ; return undef };
}

=item C<temp_scriptfile($scriptname,$create)>

Calls tempfile from File::Temp and writes the content of C<$scriptname>
into the returned file. Returns the opened filehandle and the
filename. Unless C<$create> is true, return undef if the requested script
does not exist.

=cut

sub temp_scriptfile {
	my ($self,$script,$create) = @_;
	my ($fh,$filename) = eval { tempfile(UNLINK => 1) };
		unless ($fh) { $self->_set_error($@) ; return undef };
	my $content = $self->getscript($script);
		if (!defined($content) and !$create) { $self->_set_error($@) ; return undef };
	$content ||= '';
	print $fh $content or
		do { $self->_set_error($!) ; return undef };
	return $fh,$filename;
}

=item C<putfile($file,$scriptname)>

Uploads C<$file> with the name C<$scriptname> to the server. 

=cut

sub putfile {
	my($self,$file,$name) = @_;
	my $script;
	open(my $fh, '<', $file) or do { $self->_set_error($!) ; return undef };
	{ $/ = undef, $script = <$fh> } 
	close $fh;
	$self->putscript($name,$script) or do { $self->_set_error($@) ; return undef };
}

=item C<getfile($scriptname,$file)>

Downloads the script names <$scriptname> to the file specified by C<$file>.

=cut

sub getfile {
	my($self,$name,$file) = @_;
	my $script = $self->getscript($name) or do { $self->_set_error($@) ; return undef };
	open(my $fh, '>', $file) or do { $self->_set_error($!) ; return undef };
	print $fh $script or do { $self->_set_error($!) ; return undef }; 
	close $fh;
}

=item C<listscripts()>

Returns a list of scripts and the active script. This function overwrites
listscripts provided by Net::ManageSieve in order to return a more
sane data structure. It returns a reference to an array, that holds all
scripts, and a scalar with the name of the active script in list context and just the array reference in scalar context.

=cut

sub listscripts {
	my $self = shift;
	my($scripts);
	unless ( $scripts = $self->SUPER::listscripts() ) {
		$self->_set_error($@);
		return undef;
	}
	my $active = pop @{$scripts};
	return wantarray ? ( $scripts, $active ) : $scripts;
}

=item C<error()>

Returns $@ or $! of a previous failed method. Please notice, that this
method overwrites the method of the same name in C<Net::ManageSieve>
and just returns the error mesage itself.

=back

=cut

sub error {
	my $self = shift;
	return $self->{_last_error};
}

=head1 AUTHOR

Mario Domgoergen, C<< <mario at domgoergen.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-managesieve-plus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-ManageSieve-Plus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

C<siesh(1)>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::ManageSieve::Plus

You can also look for information at:

    L<http://www.math.uni-bonn.de/~dom/siesh/>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1; # End of Net::ManageSieve::Plus
