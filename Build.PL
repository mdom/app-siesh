use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name         => 'App-Siesh',
    license           => 'perl',
    dist_author       => 'Mario Domgoergen <mario@domgoergen.com>',
    dist_version_from => 'bin/siesh',
    dist_abstract     => 'interactive sieve shell',
    requires          => {
        'File::Temp'       => 0,
        'IO::Prompt'       => 0,
        'Term::ShellUI'    => 0,
        'Net::ManageSieve' => 0,
        'IO::Socket::SSL'  => 0,
        'Config::Find'     => 0,
        'parent'           => 0,
    },
    build_requires     => { 'Test::More' => 0, },
    create_makefile_pl => 'passthrough',
    create_readme     => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/mdom/app-siesh',
        },
    }

);

$builder->create_build_script();
