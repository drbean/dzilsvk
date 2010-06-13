use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK;
# ABSTRACT: update your git repository after release

use Dist::Zilla 2.100880;    # Need mvp_multivalue_args in Plugin role
1;
__END__


=head1 DESCRIPTION

This set of plugins for L<Dist::Zilla> can do interesting things for
module authors using L<svk|http://svk.bestpractical.com> to track their work. The
following plugins are provided in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::SVK::Check>

=item * L<Dist::Zilla::Plugin::SVK::Commit>

=item * L<Dist::Zilla::Plugin::SVK::Tag>

=item * L<Dist::Zilla::Plugin::SVK::Push>

=back


If you want to use all of them at once, you will be interested by
L<Dist::Zilla::PluginBundle::SVK>.



=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-SVK>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-SVK>

=item * Mailing-list (same as L<Dist::Zilla>)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * SVK repository

L<http://github.com/jquelin/dist-zilla-plugin-git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-SVK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-SVK>

=back

