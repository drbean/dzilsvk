#!perl

use strict;
use warnings;

use Dist::Zilla     1.093250;
use Dist::Zilla::Tester;
use SVK;
use SVK::XD;
use SVK::Command;
use Path::Class;
use Test::More      tests => 3;
use Test::Exception;
use Cwd;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir(qw(t check)),
});

chdir $zilla->tempdir->subdir('source');
my $output;
my $xd = SVK::XD->new( depotmap => { 'dzil' => '/home/drbean/dzil/svk_depot' });
my $svk = SVK->new (xd => $xd, output => \$output);
$svk->checkout('/dzil/', '.');

# create initial .gitignore
# we cannot ship it in the dist, since PruneCruft plugin would trim it
append_to_file('.gitignore', 'Foo-*');
$svk->ignore( '.gitignore' );
$svk->commit( '-m', 'ignore file for git' );

# untracked files
throws_ok { $zilla->release } qr/unversioned files/, 'unversioned files';

# modified files
$svk->add( qw{ dist.ini Changes foobar } );
throws_ok { $zilla->release } qr/uncommitted files/, 'uncommitted files';
$svk->commit( { message => 'initial commit' } );

# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
lives_ok { $zilla->release } 'Changes and dist.ini can be modified';

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
