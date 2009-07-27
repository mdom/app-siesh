use strict;
use warnings;

use Test::More;
use Net::ManageSieve::Siesh;
use File::Temp qw(tempfile);

my $configfile = 't/conf.pl';

sub read_configfile {
    my $configfile = shift;
    my $config;
    if ( !-f $configfile ) {
        die "Need $configfile to test library\n";
    }
    unless ( $config = do $configfile, ) {
        die "couldn't parse $configfile\n"         if $@;
        die "couldn't compile $configfile\n"       if !defined $config;
        die "$configfile should return hash ref\n" if !$config;
    }
    for my $key (qw(host password user)) {
        if ( !defined( $config->{$key} ) ) {
            die "$key not defined in $configfile\n";
        }
    }
    return $config;
}

sub script_exists {
    my ( $self, $scriptname ) = @_;
    my %script = map { $_ => 1 } @{ $self->listscripts };
    return defined( $script{$scriptname} );
}

my $config = eval { read_configfile 't/conf.pl' };

if ($@) {
    plan skip_all => $@;
}
else {

    plan tests => 14;

    ## These UUIDs were generate by
    ## http://www.famkruithof.net/uuid/uuidgen and are provided in the
    ## hope that these do not clash with any real scripts.
    my @scriptnames = qw(
      4e205510-75d1-11de-8a39-0800200c9a66
      4e205511-75d1-11de-8a39-0800200c9a66
    );

    my ( $fh, $tempfile ) = tempfile( UNLINK => 1 );
    my $filter;
    { $/ = undef; $filter = <DATA>; }
    print {$fh} $filter;


    ok(
        my $sieve =
          Net::ManageSieve::Siesh->new( $config->{host}, tls => 'require' ),
        'connecting to sieve server'
    );
    ok( $sieve->login( $config->{user}, $config->{password} ), 'logging in' );

    for (@scriptnames) {
	if (script_exists($sieve,$_)) {
        	BAIL_OUT( "$_ already exist on the server, that's very unlikely!");
	}
    }

    ok( $sieve->putfile( $tempfile, $scriptnames[0] ), 'uploading script' );
    ok ( script_exists($sieve,$scriptnames[0]), 'script was really uploaded');
    ok( $sieve->copyscript( $scriptnames[0], $scriptnames[1] ), 'copying script' );
    ok ( script_exists($sieve,$scriptnames[1]), 'script was really copied');
    ok( $sieve->movescript( $scriptnames[0], $scriptnames[1] ),
        'renaming script' );
    ok ( ! script_exists($sieve,$scriptnames[0]), 'script was really moved');

    ok( $sieve->getfile( $scriptnames[1], $tempfile ), 'downloading script' );

    ok( ! $sieve->is_active($scriptnames[1]), "$scriptnames[1] is not active");
    ok(   $sieve->activate($scriptnames[1]), "activating $scriptnames[1]");

    ok(   $sieve->is_active($scriptnames[1]), "$scriptnames[1] is really active");
    ok(   $sieve->deactivate($scriptnames[1]), "deactivating $scriptnames[1]");
    ok( ! $sieve->is_active($scriptnames[1]), "$scriptnames[1] is really deactive");

    is( $sieve->cat($scriptnames[1]), '# This filter does nothing at all', 'catting testscript');

    for (@scriptnames) {
        $sieve->deletescript($_);
    }
}

__DATA__
# This filter does nothing at all
