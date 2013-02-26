package Dist::Zilla::Plugin::Alien;
# ABSTRACT: Use Alien::Base with Dist::Zilla

use Moose;
extends 'Dist::Zilla::Plugin::ModuleBuild';
with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::FileGatherer';

=head1 SYNOPSIS

In your B<dist.ini>:

  name = Alien-myapp

  [Alien]
  repo = http://myapp.org/releases
  bins = myapp myapp_helper
  # the following parameters are based on the dist name automatically
  name = myapp
  pattern_prefix = myapp-
  pattern_version = ([\d\.]+)
  pattern_suffix = \.tar\.gz
  pattern = myapp-([\d\.]+)\.tar\.gz

=head1 DESCRIPTION

This is a simple wrapper around Alien::Base, to make it very simple to
generate a distribution that uses it. You only need to make a module like
in this case Alien::myapp which extends Alien::Base and additionally a url
that points to the path where the downloadable .tar.gz of the application
or library can be found. For more informations about the parameter, please
checkout also the L<Alien::Base> documentation. The B<repo> paramter is
automatically taken apart to supply the procotol, host and other parameters
for L<Alien::Base>.

B<Note>: Please be aware that B<Alien::Base> uses B<Module::Build>, which
means you shouldn't have L<Dist::Zilla::Plugin::MakeMaker> loaded. For our
case, this means, you can't just easily use it together with the common
L<Dist::Zilla::PluginBundle::Basic>, because this includes it. As alternative
you can use L<Dist::Zilla::PluginBundle::Alien> which is also included in this
distribution.

=head1 ATTRIBUTES

=head2 repo

The only required parameter, defines the path for the packages of the product
you want to alienfy. This must not include the filename.

=head2 pattern

The pattern is used to define the filename to be expected from the repo of the
alienfied product.

=head2 bins

A space seperated list of all binaries that should be wrapped to be executable
from the perl environment (if you use perlbrew or local::lib this also
guarantees that its available via the PATH).

=head2 name

The name of the Alien package, this is used for the pattern matching filename.
If none is given, then the name of the distribution is used, but the B<Alien->
is cut off.

=cut

use URI;

has name => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_name {
	my ( $self ) = @_;
	my $name = $self->zilla->name;
	$name =~ s/^Alien-//g;
	return $name;
}

has bins => (
	isa => 'Str',
	is => 'rw',
	predicate => 'has_bins',
);

has split_bins => (
	isa => 'ArrayRef',
	is => 'rw',
	lazy_build => 1,
);
sub _build_split_bins { $_[0]->has_bins ? [split(/\s+/,$_[0]->bins)] : [] }

has repo => (
	isa => 'Str',
	is => 'rw',
	required => 1,
);

has repo_uri => (
	isa => 'URI',
	is => 'rw',
	lazy_build => 1,
);
sub _build_repo_uri {
	my ( $self ) = @_;
	URI->new($self->repo);
}

has pattern_prefix => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern_prefix {
	my ( $self ) = @_;
	return $self->name.'-';
}

has pattern_version => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern_version { '([\d\.]+)' }

has pattern_suffix => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern_suffix { '\\.tar\\.gz' }

has pattern => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern {
	my ( $self ) = @_;
	join("",
		$self->pattern_prefix.
		$self->pattern_version.
		$self->pattern_suffix
	);
}

sub register_prereqs {
	my ( $self ) = @_;
	$self->zilla->register_prereqs({
			type  => 'requires',
			phase => 'configure',
		},
		'Alien::Base' => '0.002',
		'File::ShareDir' => '1.03',
		'Path::Class' => '0.013',
	);
	$self->zilla->register_prereqs({
			type  => 'requires',
			phase => 'runtime',
		},
		'Alien::Base' => '0.002',
		'File::ShareDir' => '1.03',
		'Path::Class' => '0.013',
	);
}

has "+mb_class" => (
	default => 'Alien::Base::ModuleBuild',
);

sub gather_files {
	my ( $self ) = @_;

	my $template = <<'__EOT__';
#!/usr/bin/env perl
# PODNAME: {{ $bin }}
# ABSTRACT: Command {{ $bin }} of {{ $dist->name }}

$|=1;

use strict;
use warnings;
use File::ShareDir ':ALL';
use Path::Class;

my $abs = file(dist_dir('{{ $dist->name }}'),'bin','{{ $bin }}')->cleanup->absolute;

exec($abs, @ARGV) or print STDERR "couldn't exec {{ $bin }}: $!";

__EOT__

	for (@{$self->split_bins}) {
		my $content = $self->fill_in_string(
			$template,
			{
				dist => \($self->zilla),
				bin => $_,
			},	
		);

		my $file = Dist::Zilla::File::InMemory->new({
			content => $content,
			name    => 'bin/'.$_,
		});

		$self->add_file($file);
	}
}

around module_build_args => sub {
	my ($orig, $self, @args) = @_;
	my $pattern = $self->pattern;
	return {
		%{ $self->$orig(@args) },
		alien_name => $self->name,
		alien_repository => {
			protocol => $self->repo_uri->scheme,
			host => $self->repo_uri->host_port,
			location => $self->repo_uri->path,
			pattern => qr/^$pattern$/,
		},
	};
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
