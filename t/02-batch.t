use strict;
use warnings;
use Test::More;
use App::Siesh;
use Data::Dumper;
use IO::String;
use Test::Output;

sub execute {
	my $cmd = shift;
	App::Siesh->run(%{ App::Siesh->read_config('t/siesh.conf') }, file => IO::String->new( $cmd ) );
}

if ( not -f 't/siesh.conf' ) {
    plan skip_all => 'Author test. Only run if t/siesh.conf exists.',
}
else {
	plan tests => 7;
	execute('rm *');
	stdout_is( sub { execute('ls') },'','rm * succeeded, no files left.');
	execute('put t/filter.txt foo');
	stdout_is( sub { execute('ls') },"foo\n",'foo was uploaded');
	execute('cp foo bar');
	stdout_is( sub { execute('ls') },"bar\nfoo\n",'copied foo to bar');
	execute('mv foo quux');
	stdout_is( sub { execute('ls') },"bar\nquux\n",'moved foo to quux');
	execute('activate bar');
	stdout_is( sub { execute('ls') },"bar *\nquux\n",'activated bar');
	execute('activate quux');
	stdout_is( sub { execute('ls') },"quux *\nbar\n",'activated quux (new ordering)');
	execute('deactivate');
	stdout_is( sub { execute('ls') },"bar\nquux\n",'moved foo to quux');
}

__DATA__
