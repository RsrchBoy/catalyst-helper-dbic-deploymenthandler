package Catalyst::Helper::DBIC::DeploymentHandler;

# ABSTRACT: Create a script/myapp_dbicdh.pl to help manage your DBIC deployments

use namespace::autoclean;
use common::sense;

use File::Spec;

sub mk_stuff {
    my ($self, $helper, $args) = @_;

    #my $app = lc $helper->{app};

    my $base = $helper->{base};
    my $app  = lc $helper->{app};

    $app =~ s/::/_/g;

    my $script = File::Spec->catfile($base, 'script', $app.'_dbicdh.pl');
    $helper->render_file('dbicdh', $script);
    chmod 0755, $script;
}


1;

__DATA__

__pod__

=head1 SYNOPSIS

./script/myapp_create.pl DBIC::DeploymentHandler

=head1 DESCRIPTION

This is a Catalyst helper module that builds a
L<DBIx::Class::DeploymentHandler> script for you.

=head1 TODO

Schemas not named MyApp::DB::Schema.

Determine the db type automatically

=head1 AUTHOR

While I put together this helper module, this code is largely based on the
information (and code) in
L<DBIx::Class::DeploymentHandler::Manual::CatalystIntro>.  Any errors are mine.

=head1 SEE ALSO

L<DBIx::Class::DeploymentHandler>, L<DBIx::Class>,
L<DBIx::Class::DeploymentHandler::Manual::CatalystIntro>

=cut

__dbicdh__
#!/usr/bin/env perl

use strict;
use warnings;

use v5.10;

use aliased 'DBIx::Class::DeploymentHandler' => 'DH';
use FindBin;
use lib "$FindBin::Bin/../lib";
use [% app %]::DB::Schema;
use Config::JFDI;

my $config = Config::JFDI->new( name => '[% app %]' );
my $config_hash  = $config->get;
my $connect_info = $config_hash->{'Model::DB'}{'connect_info'};
my $schema       = [% app %]::DB::Schema->connect($connect_info);

my $dh = DH->new({
  schema           => $schema,
  script_directory => "$FindBin::Bin/../dbicdh",
  databases        => 'MySQL',
});

sub prep_install { $dh->prepare_install }
sub install {
  prep_install();
  $dh->install;
}

sub prep_upgrade {
  $dh->prepare_deploy;
  $dh->prepare_upgrade;
}

sub upgrade {
  die 'Please update the version in Schema.pm'
    if $dh->version_storage->version_rs->search({version => $dh->schema_version})->count;

  die 'We only support positive integers for versions around these parts.'
    unless $dh->schema_version =~ /^\d+$/;

  prep_upgrade();
  $dh->upgrade;
}

sub current_version {
  say $dh->database_version;
}

sub help {
say <<'OUT';
usage:
  install
  upgrade
  current-version
OUT
}

help unless $ARGV[0];

given ( $ARGV[0] ) {

    when ('install')         { install()         }
    when ('prepare-install') { prep_install()    }
    when ('upgrade')         { upgrade()         }
    when ('prepare-upgrade') { prep_upgrade()    }
    when ('current-version') { current_version() }
}

1;
