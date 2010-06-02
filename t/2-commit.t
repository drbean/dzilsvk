#!perl

use strict;
use warnings;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use SVK;
use SVK::XD;
use Path::Class;
use Test::More   tests => 1;
use Cwd;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t commit)),
});

chdir $zilla->tempdir->subdir('source');
mkdir 'svk_depot';
my $depot = getcwd . '/svk_depot';
my $output;
my $xd = SVK::XD->new;
$xd->_create_depot( $depot );
my $svk = SVK->new (xd => $xd, output => \$output);
$svk->depotmap( '/dzil/', $depot );
$svk->checkout('/dzil/', '.');
$svk->ignore( 'svk_depot' );
$svk->commit( '-m', 'ignore repo in working copy!' );
$svk->add( qw{ dist.ini Changes } );
$svk->commit( message => 'initial commit' );

# do a release, with changes and dist.ini updated
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
$zilla->release;

# check if dist.ini and changelog have been committed
my ($log) = $svk->log( 'HEAD' );
is( $log->message, "v1.23\n\n- foo\n- bar\n- baz\n", 'commit message taken from changelog' );

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
