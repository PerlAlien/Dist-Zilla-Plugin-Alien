package Dist::Zilla::PluginBundle::Alien;
# ABSTRACT: Dist::Zilla::PluginBundle::Basic for Alien

use Moose;
use Dist::Zilla;
use Dist::Zilla::Plugin::Alien;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=head1 SYNOPSIS

In your B<dist.ini>:

  name = Alien-ffmpeg

  [@Alien]
  repo = http://ffmpeg.org/releases

=head1 DESCRIPTION

This plugin bundle allows to use L<Dist::Zilla::Plugin::Alien> together
with L<Dist::Zilla::PluginBundle::Basic>.

=cut

use Dist::Zilla::PluginBundle::Basic;

# multiple build/install commands return as an arrayref
sub mvp_multivalue_args {
  Dist::Zilla::Plugin::Alien->mvp_multivalue_args;
};

sub configure {
  my ($self) = @_;

  $self->add_bundle('Filter' => {
    -bundle => '@Basic',
    -remove => ['MakeMaker'],
  });

  $self->add_plugins([ 'Alien' => {
    map { $_ => $self->payload->{$_} } keys %{$self->payload},
  }]);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
