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
	my $namepart = qr|[^/]*|;
	my $info = qx "svk info";
	$info =~ m/^.*\n[^\/]*(\/.*)$/m; my $depotpath = $1;
	( my $depotname = $depotpath ) =~ s|^/($namepart).*$|$1|;
	my $project = $self->zilla->plugin_named('SVK::Tag')->project ||
			$self->zilla->name;
	my $project_dir = lc $project;
	$project_dir =~ s/::/-/g;
	my $tag_dir = $self->zilla->plugin_named('SVK::Tag')->tag_directory;

	# push everything on remote branch
	$self->log("pushing to remote");
	system( 'svk push' );
	$self->log_debug( "The local changes" );
	my $switchpath = $depotpath;
	$switchpath = dirname( $switchpath ) until basename( $switchpath ) eq
		$project_dir or basename( $switchpath ) eq $depotname;
	$switchpath .= "/$tag_dir";
	system( "svk switch $switchpath" );
	system( 'svk push' );
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


=head1 DESCRIPTION

Once the release is done, this plugin will push current svk branch to
remote that it was copied from, but the associated tags need the mirror name.


The plugin accepts the following options:

=over 4

=item * 

push_to - the name of the remote to push to. The default is F<//mirror/projectname>.


=back
