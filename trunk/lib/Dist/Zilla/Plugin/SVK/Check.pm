use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK::Check;
# ABSTRACT: check your svk repository before releasing

use SVK; use SVK::XD;
use Moose;

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::Git::DirtyFiles';

use Cwd;

# -- public methods

sub before_release {
    my $self = shift;
    my $output;
	my $xd = SVK::XD->new( depotmap => {
			'dzil' => '/home/drbean/dzil/svk_depot' } );
	my $svk = SVK->new( xd => $xd, output => \$output );

    # fetch current branch
	my ( undef, $branch, undef, $cinfo, undef ) = 
		$xd->find_repos_from_co( getcwd, undef );
	my $depotpath = $cinfo->{depotpath};
	my $firstpart = qr|^/(.*?)/|;
	( my $depotname = $depotpath ) =~ s|$firstpart.*$|$1|;
	( my $project = $branch ) =~ s|$firstpart.*$|$1|;

use orz;

    # check if some changes are staged for commit
    my @output = $svk->diff( { cached=>1, 'name-status'=>1 } );
    if ( @output ) {
        my $errmsg =
            "branch $branch has some changes staged for commit:\n" .
            join "\n", map { "\t$_" } @output;
        $self->log_fatal($errmsg);
    }

    # everything but files listed in allow_dirty should be in a
    # clean state
    my @output = $self->list_dirty_files($svk);
    if ( @output ) {
        my $errmsg =
            "branch \$branch has some uncommitted files:\n" .
            join "\n", map { "\t$_" } @output;
        $self->log_fatal($errmsg);
    }

no orz;

    # no files should be untracked
    # DOTO or TODO? including dot files?
	my @file = glob '*';
    my @output = grep {
		$svk->status($_); $output =~ m/^\?\s(.*)$/; $1 }
			@file;
    if ( @output ) {
        my $errmsg =
            "branch \$branch has some unversioned files:\n" .
            join "\n", map { "\t$_" } @output;
        $self->log_fatal($errmsg);
    }

    $self->log( "branch \$branch is in a clean state and no unversioned files" );

}

1;
__END__

=for Pod::Coverage
    before_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [SVK::Check]
    allow_dirty = dist.ini
    allow_dirty = README
    changelog = Changes      ; this is the default


=head1 DESCRIPTION

This plugin checks that svk is in a clean state before releasing. The following checks are performed before releasing:

=over 4

=item * there should be no unversioned files in the working copy

=item * the working copy should be without local modifications. The files listed in C<allow_dirty> can be modified locally, though.

=back

If those conditions are not met, the plugin will die, and the release will thus be aborted. This lets you fix the problems before continuing.


The plugin accepts the following options:

=over 4

=item * changelog - the name of your changelog file. defaults to F<Changes>.

=item * allow_dirty - a file that is allowed to have local modifications.  This option may appear multiple times.  The default list is F<dist.ini> and the changelog file given by C<changelog>.  You can use C<allow_dirty => to prohibit all local modifications.

=back

