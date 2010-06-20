use 5.008;
use strict;
use warnings;

package Dist::Zilla::Role::SVK::DirtyFiles;
# ABSTRACT: provide the allow_dirty & changelog attributes

use Moose::Role;
use Moose::Autobox;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str };

use Cwd; use File::Basename;

# -- attributes

=attr allow_dirty

A list of files that are allowed to be dirty in the svk checkout.
Defaults to C<dist.ini> and the changelog (as defined per the
C<changelog> attribute.

=attr changelog

The name of the changelog. Defaults to C<Changes>.

=cut

has allow_dirty => (
  ro, lazy,
  isa     => ArrayRef[Str],
  builder => '_build_allow_dirty',
);
has changelog => ( ro, isa=>Str, default => 'Changes' );

around mvp_multivalue_args => sub {
  my ($orig, $self) = @_;

  my @start = $self->$orig;
  return (@start, 'allow_dirty');
};

# -- builders & initializers

sub _build_allow_dirty { [ 'dist.ini', shift->changelog ] }



=method list_dirty_files

  my @dirty = $plugin->list_dirty_files($listAllowed);

This returns a list of the modified or deleted files in the checkout, filtered against the C<allow_dirty> attribute, excluding dot files.  If C<$listAllowed> is true, only allowed files are listed.  If it's false, only files that are not allowed to be dirty are listed.

In scalar context, returns the number of dirty files.

=cut

sub list_dirty_files
{
  my ($self, $listAllowed) = @_;
  my $allowlist = $self->allow_dirty;
  my %allowed = map { $_ => 1 } @$allowlist;
  my @file = qx "svk status";
  my @uncommitted = grep m/^("?M|D)/, @file;
  chomp @uncommitted;
  s/^.*\s(\S+)$/$1/ for @uncommitted;
  return grep { $allowed{$_} ? $listAllowed : ! $listAllowed } @uncommitted;
} # end list_dirty_files


no Moose::Role;
no MooseX::Has::Sugar;
1;
__END__

=for Pod::Coverage
    mvp_multivalue_args

=head1 DESCRIPTION

This role is used within the svk (was: git) plugin to work with files that are
dirty in the local svk checkout.
