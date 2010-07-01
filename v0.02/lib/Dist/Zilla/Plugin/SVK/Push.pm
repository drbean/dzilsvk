use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK::Push;
# ABSTRACT: push current branch

use SVK;
use SVK::XD;
use SVK::Util qw/find_dotsvk/;
use File::Basename;

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str };

with 'Dist::Zilla::Role::AfterRelease';

# sub mvp_multivalue_args { qw(push_to) }

# -- attributes

#has push_to => (
#  is   => 'ro',
#  isa  => 'ArrayRef[Str]',
#  lazy => 1,
#  default => sub { [ qw(origin) ] },
#);


sub after_release {
    my $self = shift;
	my $svkpath = find_dotsvk || $ENV{SVKROOT} || $ENV{HOME} . "/.svk";
	my $output;
	my $xd = SVK::XD->new( giantlock => "$svkpath/lock",
		statefile => "$svkpath/config",
		svkpath => $svkpath,
		);
	my $svk = SVK->new( xd => $xd, output => \$output );
	$xd->load();
	my ( undef, $branch, undef, $cinfo, undef ) = 
		$xd->find_repos_from_co( '.', undef );
	my $depotpath = $cinfo->{depotpath};
	my $namepart = qr|[^/]*|;
	( my $depotname = $depotpath ) =~ s|^/($namepart).*$|$1|;
	my $project = $self->zilla->name;
	my $project_dir = lc $project;
	$project_dir =~ s/::/-/g;
	my $tag_dir = $self->zilla->plugin_named('SVK::Tag')->tag_directory;

	# push everything on remote branch
	$self->log("pushing to remote");
	$svk->push;
	$self->log_debug( "The local changes" );
	my $switchpath = $depotpath;
	$switchpath = dirname( $switchpath ) until basename( $switchpath ) eq
		$project_dir or basename( $switchpath ) eq $depotname;
	$switchpath .= "/$tag_dir";
	$svk->switch( $switchpath );
	# $svk->switch("/$depotname/local/Foo/tags");
	$svk->push;
	$self->log_debug( "The tags too" );
}

1;
__END__

=for Pod::Coverage
    after_release
    mvp_multivalue_args

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Push]
    push_to = //mirror/project      ; this is the default
    push_to = origin HEAD:refs/heads/released ; also push to released branch


=head1 DESCRIPTION

Once the release is done, this plugin will push current svk branch to
remote end, with the associated tags.


The plugin accepts the following options:

=over 4

=item * 

push_to - the name of the a remote to push to. The default is F<origin>.
This may be specified multiple times to push to multiple repositories.

=back
