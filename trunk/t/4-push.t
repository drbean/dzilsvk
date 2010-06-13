#!perl

use strict;
use warnings;

use lib 'lib';

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use Cwd          qw{ getcwd  };
use File::Basename;
use File::Temp   qw{ tempdir };
use Path::Class;
use Test::More   tests => 3;
use Try::Tiny;
use Carp;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t push)),
});

my $project = $zilla->name;
my $project_dir = lc $project;
$project_dir =~ s/::/-/g;
my $version = $zilla->version;

my $tempdir = $zilla->tempdir;
# create a repo for local project
my $depotname = basename( "$tempdir" );
try { system( "svnadmin create $tempdir/local" ); } catch {
	carp "Can't create $tempdir/local: $_" };

system( "svk depotmap -i $depotname $tempdir/local" );

# create a remote repo with project
my $remote = tempdir( CLEANUP => 1 );
my $remotename = basename $remote;

try { system( "svnadmin create $remote/local" ); } catch {
	carp "Can't create $remote/local: $_" };
system( "svk depotmap -i $remotename $remote/local" );
system( "svk mkdir /$remotename/$project_dir/trunk -pm '
	$project project trunk_dir on remote $remotename repos.' " );
system( "svk cp /$remotename/$project_dir/trunk /$remotename/$project_dir/tags -m '
	$project project tag_dir on remote $remotename repos.' " );

system( "svk mkdir /$depotname/mirror -m 'mirror of $project repo.'" );
system( "svk mirror /$depotname/mirror/$project_dir file://$remote/local/$project_dir" );
system( "svk sync /$depotname/mirror/$project_dir" );
system( "svk cp /$depotname/mirror/$project_dir /$depotname/local/$project_dir -pm '
	local $project project development'" );

chdir $zilla->tempdir->subdir('source');
system( "svk import -t /$depotname/local/$project_dir/trunk -m 'plugin files'" );
system( "svk ignore $project-$version.tar.gz" );
system( "svk commit -m 'ignore tarball built by release.'" );

system( "svk add dist.ini Changes" );
system( "svk commit -m 'initial commit'" );


# do the release
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
$zilla->release;

# check if everything was pushed
my $log = qx "svk log -r HEAD /$remotename/";
like( $log, qr/v1\.23\n \n  - foo\n  - bar\n  - baz\n/, 'commit pushed' );
my $taglog = qx "svk log -r HEAD /$remotename/$project_dir/tags/";
like( $taglog, qr/v1\.23/, 'new tag pushed after new version' );

system( "svk depotmap -d $depotname" );
system( "svk depotmap -d $remotename" );

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
__END__


# check if tag has been correctly created
my @tags = $git->tag;
is( scalar(@tags), 1, 'one tag pushed' );
