#!perl

use strict;
use warnings;

# use lib 'lib';

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use SVN::Repos;
use SVK;
use SVK::XD;
use Path::Class;
use Test::More   tests => 3;
use Cwd; use File::Basename;
use YAML qw/DumpFile/;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t tag)),
});

my $name = $zilla->name;
my $version = $zilla->version;

my $tempdir = $zilla->tempdir;
my $depotname = basename $tempdir;
SVN::Repos::create("$tempdir/local", undef, undef, undef,
				   {'fs-type' => $ENV{SVNFSTYPE} || 'fsfs',
					'bdb-txn-nosync' => '1',
					'bdb-log-autoremove' => '1'});
my $xd = SVK::XD->new( giantlock => "$tempdir/lock",
	statefile => "$tempdir/config",
	svkpath => "$tempdir",
	);
DumpFile "$tempdir/config", { depotmap => { $depotname => "$tempdir/local" } };
$xd->load();
$xd->store();
my $output;
my $svk = SVK->new (xd => $xd, output => \$output);

chdir $zilla->tempdir->subdir('source');
$svk->import('-t', '-m', 'dzil plugin tags', "/$depotname/$name" );
$svk->ignore( "$name-$version.tar.gz");
$svk->commit( '-m', 'ignore tarball built by release.' );

# do the release
$zilla->release;

# check if tag has been correctly created
my @tags = $svk->tag;
is( scalar(@tags), 1, 'one tag created' );
is( $tags[0], 'v1.23', 'new tag created after new version' );

# attempting to release again should fail
eval { $zilla->release };

like($@, qr/tag v1\.23 already exists/, 'prohibit duplicate tag');

