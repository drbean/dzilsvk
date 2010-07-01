use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	dist_version => 0.01,
    module_name         => 'Dist::Zilla::Plugin::SVK',
    license             => 'perl',
    dist_author         => 'Dr Bean',
);

$builder->create_build_script();
