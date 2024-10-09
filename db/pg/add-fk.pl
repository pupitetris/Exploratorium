#!/usr/bin/perl

use strict;

sub print_fks {
  my $fkeys = shift;
  my $tables = shift;

  foreach my $table (@$tables) {
    foreach my $fk (@{$fkeys->{$table}}) {
      my $src = $fk->[0];
      $src =~ s/^\s+//;
      $src =~ s/\s+$//;
      if ($src !~ /^FOREIGN KEY/) {
        $src =~ /^(\S+)/;
        $src = "FOREIGN KEY ($1)";
      }
      my $dest = $fk->[1];
      my $destcol = $fk->[2];
      my $mods = $fk->[3];
      print "ALTER TABLE $table
	ADD $src
	REFERENCES ${dest}($destcol)
$mods;

";
    }
  }
}

my %fkeys = ();
my @fk_tables = ();

my $fk = '';
my $prev = '';
while (<>) {
  if (/^\s*CREATE\s+TABLE\s+(\S+)/) {
    $fk = $1;
  }
  if (/^\s*REFERENCES\s+(\S+)\s+\(([^)]+)/) {
    my $res = [ 0, $1, $2 ];
    $prev =~ /^\s*(\S+)/;
    $res->[0] = $prev;
    my $mods = '';
    while ($_ !~ /,\s*$/) {
      $_ = <>;
      $mods .= $_;
    }
    $mods =~ s/,\s*$//;
    push @$res, $mods;

    if (!exists $fkeys{$fk}) {
      $fkeys{$fk} = [] ;
      push @fk_tables, $fk;
    }
    push @{$fkeys{$fk}}, $res;

    $_ = '';
    $_ .= ",\n" if $prev !~ /^\s*FOREIGN\s+KEY\s+/;
  }
  print_fks(\%fkeys, \@fk_tables) if /^\s*COMMIT\s+TRANSACTION\s*;\s*$/;
  $prev = $_;
  next if /^\s*FOREIGN\s+KEY\s+/;
  print;
}
