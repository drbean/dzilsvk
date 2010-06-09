#!perl

use strict;
use warnings;

# use lib 'lib';

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use SVN::Repos;
use Path::Class;
use Test::More   tests => 3;
use Cwd; use File::Basename;
use Try::Tiny;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t tag)),
});

my $name = $zilla->name;
my $version = $zilla->version;

my $tempdir = $zilla->tempdir;
my $depotname = basename( "$tempdir" );
try { system( "svnadmin create $tempdir/local" ); } catch {
	warn "Can't create $tempdir/local: $_" };

system( "svk depotmap -i $depotname $tempdir/local" );

chdir $zilla->tempdir->subdir('source');
system( "svk import -t -m 'dzil plugin tags' /$depotname/$name" );
system( "svk ignore $name-$version.tar.gz");
system( "svk commit -m 'ignore tarball built by release.'" );

# do the release
$zilla->release;

# check if tag has been correctly created
my $taglog = qx "svk log -r HEAD /$depotname/$name/tags/";
# is( scalar(@tags), 1, 'one tag created' );
# is( $tags[0], 'v1.23', 'new tag created after new version' );

# attempting to release again should fail
eval { $zilla->release };

like($@, qr/tag v1\.23 already exists/, 'prohibit duplicate tag');

