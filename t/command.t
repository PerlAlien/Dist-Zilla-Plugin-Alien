use strict;
use warnings;
use Test::More;
use Test::DZil;

subtest 'build_command' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            build_command => [ 'foo', 'bar', 'baz' ],
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is_deeply $plugin->module_build_args->{alien_build_commands}, [qw( foo bar baz )];
};

subtest 'install_command' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            install_command => [ 'foo', 'bar', 'baz' ],
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is_deeply $plugin->module_build_args->{alien_install_commands}, [qw( foo bar baz )];
};

subtest 'test_command' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          [ 'Alien' => {
            repo => 'http://localhost/foo/bar',
            test_command => [ 'foo', 'bar', 'baz' ],
          } ],
        ),
      },
    }
  );

  $tzil->build;

  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Alien') } @{ $tzil->plugins };

  is_deeply $plugin->module_build_args->{alien_test_commands}, [qw( foo bar baz )];
};

done_testing;
