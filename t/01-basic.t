use Test::More;

if (!$ENV{AUHTOR_TEST}) {
	plan skip_all => 'Need information of log into sieve server to test library';
}

plan tests => 1;

BEGIN { use_ok( 'Net::ManageSieve::Siesh' ) };

__END__

my $sieve = Net::ManageSieve::Siesh->new();
$sieve->copy('script1','script2');
$sieve->mv('script2','script3');
$sieve->put('../script.txt','script4');
$sieve->get('script1','../script.txt');
