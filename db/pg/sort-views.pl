#!/usr/bin/perl

use strict;

sub print_view_tree {
  my ($tree, $view_from, $view_sources) = @_;

  foreach my $view_to (@{$tree->{$view_from}}) {
    print_view_tree($tree, $view_to, $view_sources);
  }

  print $view_sources->{$view_from};
  $view_sources->{$view_from} = '';
}

sub print_sorted_views {
  my ($view_sources, $view_names) = @_;
  my %tree = ();

  foreach my $view (@$view_names) {
    $tree{$view} = [];
  }

  foreach my $view_from (@$view_names) {
    foreach my $view_to (@$view_names) {
      next if $view_from eq $view_to;
      push @{$tree{$view_from}}, $view_to
          if $view_sources->{$view_from} =~ /[\s,(]$view_to[\s,)]/;
    }
  }

  foreach my $view (@$view_names) {
    print_view_tree(\%tree, $view, $view_sources);
  }
}

my %views = ();
my @view_names = ();

my $view_name = '';
while (<>) {

  if (/^\s*COMMIT\s+TRANSACTION\s*;/) {
    $view_name = '';
    print_sorted_views(\%views, \@view_names);
  }

  if (/^--\s+View:\s+(\S+)/) {
    $view_name = $1;
    push @view_names, $1;
  }

  if ($view_name) {
    $views{$1} .= $_;
  } else {
    print;
  }
}
