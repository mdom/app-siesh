use strict;
use warnings;

use Test::More;
use Net::ManageSieve::Siesh;
use File::Temp qw(tempfile);
use App::Siesh;


if ( not -f 't/siesh.conf' ) {
    plan skip_all => 'Author test. Only run if t/siesh.conf exists.',

}
else {
    my $config = App::Siesh->read_config('t/siesh.conf');

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
    {
        local $/ = undef;
        $filter = <DATA>;
        print {$fh} $filter;
        close $fh;
    }


    ok(
        my $sieve =
          Net::ManageSieve::Siesh->new( $config->{host}, tls => 'require' ),
        'connecting to sieve server'
    );
    ok( $sieve->login( $config->{user}, $config->{password} ), 'logging in' );

    for (@scriptnames) {
	if ($sieve->script_exists($_)) {
        	BAIL_OUT( "$_ already exist on the server, that's very unlikely!");
	}
    }

    ok( $sieve->putfile( $tempfile, $scriptnames[0] ), 'uploading script' );
    ok ( $sieve->script_exists($scriptnames[0]), 'script was really uploaded');
    ok( $sieve->copyscript( $scriptnames[0], $scriptnames[1] ), 'copying script' );
    ok ( $sieve->script_exists($scriptnames[1]), 'script was really copied');
    ok( $sieve->movescript( $scriptnames[0], $scriptnames[1] ),
        'renaming script' );
    ok ( ! $sieve->script_exists($scriptnames[0]), 'script was really moved');

    ok( $sieve->getfile( $scriptnames[1], $tempfile ), 'downloading script' );

    ok( ! $sieve->is_active($scriptnames[1]), "$scriptnames[1] is not active");
    ok(   $sieve->activate($scriptnames[1]), "activating $scriptnames[1]");

    ok(   $sieve->is_active($scriptnames[1]), "$scriptnames[1] is really active");
    ok(   $sieve->deactivate($scriptnames[1]), "deactivating $scriptnames[1]");
    ok( ! $sieve->is_active($scriptnames[1]), "$scriptnames[1] is really deactive");

    for (@scriptnames) {
        $sieve->deletescript($_) if $sieve->script_exists($_);
    }
}

__DATA__
# This filter does nothing at all
