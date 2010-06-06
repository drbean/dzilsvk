#!perl

use strict;
use warnings;

use lib qw'lib';

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
system( "svk import -t /dzil/project -m 'project'" );

# create initial .gitignore
append_to_file('.gitignore', 'Foo-*');

# untracked files
throws_ok { $zilla->release } qr/unversioned files/,
								'no unversioned files allowed';

unlink grep m/Foo-1\.23\.tar\.gz/, glob '*';

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}

# modified files
append_to_file('foobar', "an uncommitted change\n");
throws_ok { $zilla->release } qr/modified files/,
					'no uncommitted files allowed';
system( "svk commit -m 'initial commit'" );

unlink grep m/Foo-1\.23\.tar\.gz/, glob '*';

# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
lives_ok { $zilla->release } 'Modified Changes and dist.ini allowed';
