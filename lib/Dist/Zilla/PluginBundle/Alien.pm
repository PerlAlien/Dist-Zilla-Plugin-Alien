package Dist::Zilla::PluginBundle::Alien;
# ABSTRACT: Dist::Zilla::PluginBundle::Basic for Alien

use Moose;
use Moose::Autobox;
use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=head1 DESCRIPTION

This plugin bundle allows to use L<Dist::Zilla::Plugin::Alien> together
with L<Dist::Zilla::PluginBundle::Basic>.

  name = Alien-ffmpeg

  [@Alien]
  repo = http://ffmpeg.org/releases

=cut

use Dist::Zilla::PluginBundle::Basic;

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
