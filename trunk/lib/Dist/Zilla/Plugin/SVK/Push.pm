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

has push_to => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  lazy => 1,
  default => sub { [ qw(origin) ] },
);


sub after_release {
    my $self = shift;
	# push everything on remote branch
	$self->log("pushing to remote");
	system( 'svk push' );
	$self->log_debug( "The local changes" );
	my $info = qx "svk info";
	$info =~ m/^.*\n[^\/]*(\/.*)$/m; my $depotpath = $1;
	my $remote = $self->push_to;
	my $tagger = $self->zilla->plugin_named('SVK::Tag');
	my $project = $tagger->project || $self->zilla->name;
	my $project_dir = lc $project;
	$project_dir =~ s/::/-/g;
	my $tag_dir = $tagger->tag_directory;
	my $tag = $tagger->_format_tag($self->tag_format, $self->zilla);
	my $message = $tagger->_format_tag($self->tag_message, $self->zilla);
	my $remotetagpath = "$remote/$project_dir/$tag_dir/$tag";
	system( "svk cp $depotpath $remotetagpath -m $message" );
	$self->log_debug( "The tags too" );
}

1;
__END__

=for Pod::Coverage
    after_release
    mvp_multivalue_args

=head1 SYNOPSIS

In your F<dist.ini>:

    [SVK::Push]
    push_to = //mirror      ; this is the default, the project is underneath


=head1 DESCRIPTION

Once the release is done, this plugin will push current svk branch to
remote that it was copied from, but the associated tags need the mirror name.


The plugin accepts the following options:

=over 4

=item * 

push_to - the name of the remote repo to push to. The default is F<//mirror>. The project and tags subdirectories underneath the remote are from F<Tag.pm>, 


=back
