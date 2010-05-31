#!perl

use strict;
use warnings;

# use lib 'lib';

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use SVK;
use SVK::XD;
use Path::Class;
use Test::More   tests => 3;
use Cwd;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t tag)),
});

chdir $zilla->tempdir->subdir('source');
mkdir 'svk_depot';
my $depot = getcwd . '/svk_depot';
my $output;
my $xd = SVK::XD->new;
$xd->_create_depot( $depot );
# SVK::Command->invoke($xd, 'depotmap', undef, '/dzil/', $depot );
my $svk = SVK->new (xd => $xd, output => \$output);
$svk->depotmap( '/dzil/', $depot );
$svk->checkout('/dzil/', '.');
$svk->ignore( 'svk_depot' );
$svk->commit( '-m', 'ignore repo in working copy!' );

$svk->add( qw{ dist.ini Changes } );
$svk->commit( { message => 'initial commit' } );

# do the release
$zilla->release;

# check if tag has been correctly created
my @tags = $svk->tag;
is( scalar(@tags), 1, 'one tag created' );
is( $tags[0], 'v1.23', 'new tag created after new version' );

# attempting to release again should fail
eval { $zilla->release };

like($@, qr/tag v1\.23 already exists/, 'prohibit duplicate tag');

