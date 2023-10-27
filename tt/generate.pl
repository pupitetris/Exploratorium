#!/usr/bin/env perl

use strict;

use JSON; # libjson-perl
use Template; # libtemplate-perl
use File::Basename qw(dirname);
use Encode qw(encode_utf8);

sub block_get_text {
  my $block = shift;
  my $type = $block->{'t'};
  my $cont = $block->{'c'};

  if ($type eq 'Str') {
    return $cont;
  }
  if ($type eq 'Space' || $type eq 'SoftBreak') {
    return ' ';
  }
  if ($type eq 'Plain') {
    return cont_get_text($cont);
  }
  if ($type eq 'LineBreak') {
    return "<br>\n";
  }
  if ($type eq 'Strong') {
    return '<strong>' . cont_get_text($cont) . '</strong>';
  }
  if ($type eq 'Emph') {
    return '<em>' . cont_get_text($cont) . '</em>';
  }
  if ($type eq 'Quoted') {
    return '<q class="' . lc($cont->[0]{'t'}) . '">' . cont_get_text($cont->[1]) . '</q>';
  }
  if ($type eq 'Link') {
    return '<a href="' . $cont->[2][0] . '">' . cont_get_text($cont->[1]) . '</a>';
  }
  if ($type eq 'BulletList') {
    return "\n<ul>\n  " . join ("\n  ", map { '<li>' . cont_get_text($_) . '</li>' } @$cont) . "\n</ul>\n";
  }
  if ($type eq 'CodeBlock') {
    return '<pre class="' . join(' ', @{$cont->[0][1]}) . '">' . $cont->[1] . '</pre>';
  }
  if ($type eq 'RawInline' && $cont->[0] eq 'html') {
    return $cont->[1];
  }
  warn "block_get_text: Unrecognized type $type";
  return '';
}

sub cont_get_text {
  my $cont = shift;
  if (ref $cont eq 'ARRAY') {
    return join('', map { block_get_text($_) } @$cont);
  }
  if (ref $cont eq 'HASH') {
    return block_get_text($cont);
  }
  return $cont;
}

sub block_get_header {
  my $block = shift;
  my $cont = $block->{'c'};
  return {
    'level' => $cont->[0] - 1,
        'id' => $cont->[1][0],
        'title' => cont_get_text($cont->[2]),
        'children' => []
  };
}

sub cont_get_link {
  my $cont = shift;
  if (ref $cont eq 'ARRAY') {
    return map { cont_get_link($_) } @$cont;
  }
  if (ref $cont eq 'HASH') {
    if ($cont->{'t'} eq 'Plain') {
      return cont_get_link($cont->{'c'});
    }
    if ($cont->{'t'} eq 'Link') {
      return {
        'text' => cont_get_text($cont->{'c'}[1]),
            'href' => $cont->{'c'}[2][0]
      }
    }
    warn "cont_get_link: Unrecognized type $cont->{'t'}";
  }
}

sub json_get_structure {
  my $js = shift;

  my @stack = ();
  my $obj;
  foreach my $block (@{$js->{'blocks'}}) {
    if ($block->{'t'} eq 'Header') {
      my $h = block_get_header($block);
      my $lvl = $h->{'level'};

      if ($lvl < scalar(@stack)) {
        $obj = $stack[$lvl - 1];
        splice @stack, $lvl;
      }

      if ($lvl == scalar(@stack)) {
        if ($obj) {
          if (exists $obj->{$h->{'id'}}) {
            warn 'Struct key colission: ' . $h->{'id'} . ' in ' . $obj->{'id'};
          }
          $obj->{$h->{'id'}} = $h;
          push @{$obj->{'children'}}, $h;
        }
        $obj = $h;
        push @stack, $obj;
      } else {
        die "MD can't declare subheadings more than 1 level lower than previous heading. ($h->{'title'})";
      }
    } elsif ($block->{'t'} eq 'BulletList') {
      if (scalar @stack > 2) {
        # Not metadata such as Navigation or Menu.
        push @{$obj->{'children'}}, block_get_text($block);
      } else {
        # Metadata
        foreach my $item (@{$block->{'c'}}) {
          push @{$obj->{'children'}}, cont_get_link($item);
        }
      }
    } elsif ($block->{'t'} eq 'Para') {
      push @{$obj->{'children'}}, cont_get_text($block->{'c'});
    } elsif ($block->{'t'} eq 'CodeBlock') {
      if ($block->{'c'}[0][1][0] eq 'json' &&
          $block->{'c'}[0][1][1] eq 'config') {
        $obj->{'config'} = decode_json(encode_utf8($block->{'c'}[1]));
      } else {
        push @{$obj->{'children'}}, block_get_text($block);
      }
    }
  }

  return $stack[0];
}

sub get_basedir {
  my $fname = shift;
  return '' if $fname !~ /\//;
  my @dirs = map('..', split('/', $fname));
  $dirs[$#dirs] = '';
  return join('/', @dirs);
}

my $master_md = shift @ARGV;
if ($master_md eq '') {
  die "No input file specified";
}
if (! -e $master_md) {
  die "Input file $master_md not found";
}

my $target = shift @ARGV;

my $srcdir = dirname(__FILE__);
if ($srcdir ne '.') {
  $srcdir .= '/';
} else {
  $srcdir = '';
}

my $cmd = "pandoc --from commonmark_x+gfm_auto_identifiers -t json \"$master_md\"";

open my $pipe, "$cmd|" || die "Error running $cmd";
my $json_str = <$pipe>;
close $pipe;

my $js = decode_json($json_str) || die "Error parsing json";
my $struct = json_get_structure($js);

my $output_path = "${srcdir}..";
my $main_template = "${srcdir}main.tt";

my $tt;
if ($target ne 'clean') {
  my $tt_conf = {
    ENCODING => 'utf8',
    POST_CHOMP => 1,
    TRIM => 1,
    VARIABLES => $struct,
    EVAL_PERL => 1,
    PRE_PROCESS => $main_template
  };
  $tt = Template->new($tt_conf) || die $Template::Error;
}

my $target_found = 0;
foreach my $page (@{$struct->{'pages'}{'children'}}) {
  my $conf = $page->{'config'};
  my $output = $conf->{'output'};
  my $output_fname = $output_path . '/' . $output;

  if ($target eq '--clean') {
    print "Deleting $output_fname\n";
    unlink $output_fname;
    next;
  }
  next if $target && $target !~ /^--/ && $target ne $output;

  $target_found = 1 if $target eq $output;

  my $template = $srcdir . $conf->{'template'};
  my $mod_output = -M $output_fname;
  next if $target ne '--force' &&
      -M $master_md > $mod_output &&
      -M $template > $mod_output &&
      -M $main_template > $mod_output;

  $page->{'basedir'} = get_basedir($output);
  print "Generating $output_fname\n";
  $tt->process($template, { 'page' => $page }, $output_fname, { binmode => ':utf8' }) || die $tt->error();
}

die "Target \"$target\" not found" if $target && $target !~ /^--/ && !$target_found;

1;
