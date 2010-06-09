use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK::Tag;
# ABSTRACT: tag the new version

use SVK;
use SVK::XD;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
use String::Formatter method_stringf => {
  -as => '_format_tag',
  codes => {
    d => sub { require DateTime;
               DateTime->now->format_cldr($_[1] || 'dd-MMM-yyyy') },
    n => sub { "\n" },
    N => sub { $_[0]->name },
    v => sub { $_[0]->version },
  },
};

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::AfterRelease';


# -- attributes

has tag_format  => ( ro, isa=>Str, default => 'v%v' );
has tag_message => ( ro, isa=>Str, default => 'v%v' );
has tag_directory => ( ro, isa=>Str, default => 'tags' );


# -- role implementation

sub before_release {
    my $self = shift;
    my $output;
	my $xd = SVK::XD->new( giantlock => "$tempdir/lock",
		statefile => "$tempdir/config",
		svkpath => "/home/drbean/.svk",
		);
	my $svk = SVK->new( xd => $xd, output => \$output );
	my ( undef, $branch, undef, $cinfo, undef ) = 
		$xd->find_repos_from_co( '.', undef );
	my $depotpath = $cinfo->{depotpath};
	my $firstpart = qr|^/(.*?)/|;
	( my $depotname = $depotpath ) =~ s|$firstpart.*$|$1|;
	( my $project = $branch ) =~ s|$firstpart.*$|$1|;
	my $tags = $self->tag_directory;

    # Make sure a tag with the new version doesn't exist yet:
    my $tag = _format_tag($self->tag_format, $self->zilla);
    $self->log_fatal("tag $tag already exists")
        if qx| $svk ls "/$depotname/$project/$tags/$tag" |;
}

sub after_release {
    my $self = shift;
    my $output;
    my $xd = SVK::XD->new;
	my $svk = SVK->new( xd => $xd, output => \$output );
	my ( undef, $branch, undef, $cinfo, undef ) = 
		$xd->find_repos_from_co( '.', undef );
	my $depotpath = $cinfo->{depotpath};
	my $firstpart = qr|^/(.*?)/|;
	( my $depotname = $depotpath ) =~ s|$firstpart.*$|$1|;
	( my $project = $branch ) =~ s|$firstpart.*$|$1|;
	my $tags = $self->tag_directory;

    # create a tag with the new version
    my $tag = _format_tag($self->tag_format, $self->zilla);
    my $message = _format_tag($self->tag_message, $self->zilla);
	$svk->copy( "/$depotname/$branch", "/$depotname/$project/$tags/$tag",
		'-m', $message );
    $self->log("Tagged $tag");
}

1;
__END__

=for Pod::Coverage
    after_release
    before_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [SVK::Tag]
    tag_format  = v%v       ; this is the default
    tag_message = v%v       ; this is the default
	tag_directory = tags    ; the default is 'tags', as in /project/tags

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact by creating a tag of the present branch. You can set the C<tag_message> attribute to change the message.

It also checks before the release to ensure the tag to be created doesn't already exist.  (You would have to manually delete the existing tag before you could release the same version again, but that is almost never a good idea.)

The plugin accepts the following options:

=over 4

=item * tag_format - format of the tag to apply. Defaults to C<v%v>.

=item * tag_message - format of the commit message. Defaults to C<v%v>.

=item * tag_directory - location of the tags directory, below the project directory. Defaults to C<tags>.

=back

You can use the following codes in both options:

=over 4

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime>.  A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

a newline

=item C<%N>

the distribution name

=item C<%v>

the distribution version

=back
