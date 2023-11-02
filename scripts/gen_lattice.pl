#!/usr/bin/env perl

use strict;
use warnings;

use DBI qw(:sql_types); # libdbi-perl
use DBD::SQLite::Constants qw(:file_open); # libdbd-sqlite3-perl
use JSON; # libjson-perl
use Data::Dumper;
use File::Path qw(make_path);
use Cwd qw(cwd);

BEGIN {
  my $conexp_dir = cwd() . '/conexp-1.3/*';
  if (!defined $ENV{'CLASSPATH'} || $ENV{'CLASSPATH'} eq '') {
    $ENV{'CLASSPATH'} = $conexp_dir;
  } else {
    $ENV{'CLASSPATH'} .= ';' . $conexp_dir;
  }
}

# libinline-java-perl
use Inline (
  Java => 'study',
  autostudy => 1,
  study => [
    'conexp.core.Context',
    'conexp.frontend.ContextDocumentModel'
  ]
    );

sub sqlFetch {
  my $dbh = shift;
  my $diagram = shift;
  my $lang = shift;
  my $sql = shift;

  my $sth = $dbh->prepare($sql);
  die $DBI::errstr if !defined $sth;

  $sth->bind_param(1, $diagram, SQL_VARCHAR);
  $sth->bind_param(2, $lang, SQL_VARCHAR);

  my $rv = $sth->execute();
  die $sth->errstr if !defined $rv;

  return $sth->fetchall_arrayref({});
}

sub importDiagramAsContext {
  my $dbfile = shift;
  my $diagram = shift;
  my $lang = shift;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '',
                         { sqlite_open_flags => SQLITE_OPEN_READONLY });
  die $DBI::errstr if !defined $dbh;

  my $attr_rh = sqlFetch($dbh, $diagram, $lang,
                         'SELECT Attribute FROM v_attribute_diagram ' .
                         'WHERE Diagram = ? AND Lang = ?');
  my @attributes = map { $_->{'Attribute'} } @$attr_rh;
  my $numAttributes = scalar @attributes;

  my $obj_rh = sqlFetch($dbh, $diagram, $lang,
                        'SELECT Code AS Id, Object AS Name FROM v_object_diagram ' .
                        'WHERE Diagram = ? AND Lang = ?');
  my @objects = map { $_->{'Id'} } @$obj_rh;
  my $numObjects = scalar @objects;
  my %objectsByName = map { $_->{'Name'} => $_->{'Id'} } @$obj_rh;

  my $assig_rh = sqlFetch($dbh, $diagram, $lang,
                          'SELECT ObjectCode AS ObjectId, Attribute FROM v_context_assignments ' .
                          'WHERE x = 1 AND Diagram = ? AND Lang = ?');

  my $context = new conexp::core::Context($numObjects, $numAttributes);
  for (my $i = 0; $i < $numObjects; $i++) {
    my $id = $objects[$i];
    $context->getObject($i)->setName($obj_rh->[$i]{'Name'});
    for (my $j = 0; $j < $numAttributes; $j++) {
      my $attr = $attributes[$j];
      $context->getAttribute($j)->setName($attr) if $i == 1;
      if (scalar(grep { $_->{'ObjectId'} eq $id && $_->{'Attribute'} eq $attr } @$assig_rh) > 0) {
        $context->setRelationAt($i, $j, 1);
      }
    }
  }

  return {
    'model' => new conexp::frontend::ContextDocumentModel($context),
    'context' => $context,
    'attributes' => \@attributes,
    'objects' => \@objects,
    'objectsByName' => \%objectsByName
  };
}

sub objectSetToList {
  my $set = shift;
  my $extractor = shift;
  my $iterator = shift;

  $iterator = $set->iterator() if !defined $iterator;

  my @list = ();

  while ($iterator->hasNext()) {
    my $element = $iterator->next();
    push @list, &$extractor($element);
  }
  return \@list;
}

sub writeAttributeSet {
  my $set = shift;
  my $attrs = shift;

  for (my $i = 0; $i < $set->size(); $i++) {
    if ($set->in($i)) {
      print STDERR $attrs->[$i], ',';
    }
  }
}

sub getObjectHash {
  my $object = shift;
  return $object->hashCode();
}

sub debugContext {
  my $context = shift;
  my $objects = shift;

  my @attributes = ();

  print STDERR 'Attributes (', $context->getAttributeCount(), '): ';
  for (my $i = 0; $i < $context->getAttributeCount(); $i++) {
    my $attribute = $context->getAttribute($i);
    my $name = $attribute->getName();
    push @attributes, $name;
    print STDERR $name, ', ';
  }
  print STDERR "\n\n";

  print STDERR 'Objects (', $context->getObjectCount(), "):\n\n";
  for (my $i = 0; $i < $context->getObjectCount(); $i++) {
    my $object = $context->getObject($i);
    print STDERR $object->getName(), ' (id: ', $objects->[$i], ') ';
    for (my $j = 0; $j < $context->getAttributeCount(); $j++) {
      if ($context->getRelationAt($i, $j)) {
        print STDERR $attributes[$j], " ";
      }
    }
    print STDERR "\n\n";
  }
}

sub debugConcepts {
  my $concepts = shift;
  my $attributes = shift;
  my $objects = shift;

  for (my $i = 0; $i < $concepts->conceptsCount(); $i++) {
    print STDERR 'Concept ', $i, "\n";
    my $concept = $concepts->conceptAt($i);

    my $intent = $concept->getAttribs();
    print STDERR 'Intent (size ', $intent->length(), '): ';
    for (my $j = 0; $j < $intent->size(); $j++) {
      if ($intent->in($j)) {
        print STDERR $attributes->[$j], ' ';
      }
    }
    print STDERR "\n";

    my $extent = $concept->getObjects();
    print STDERR 'Extent (size ', $extent->length(), '): ';
    for (my $j = 0; $j < $extent->size(); $j++) {
      if ($extent->in($j)) {
        print STDERR $objects->[$j], ' ';
      }
    }
    print STDERR "\n\n";
  }
}

sub debugImplications {
  my $implications = shift;
  my $attributes = shift;

  print STDERR 'Implications (', $implications->getSize(), ")\n";
  for (my $i = 0; $i < $implications->getSize(); $i++) {
    my $implication = $implications->getImplication($i);
    print STDERR $i, ' <', $implication->getObjectCount(), '> ';
    writeAttributeSet($implication->getPremise(), $attributes);
    print STDERR ' ==> ';
    writeAttributeSet($implication->getConclusion(), $attributes);
    print STDERR "\n";
  }
  print STDERR "\n";
}

sub debugAssociations {
  my $associations = shift;
  my $attributes = shift;

  print STDERR 'Associations (', $associations->getSize(), ")\n";
  for (my $i = 0; $i < $associations->getSize(); $i++) {
    my $association = $associations->getDependency($i);
    print STDERR $i, ' <', $association->getPremiseSupport(), '> ';
    writeAttributeSet($association->getPremise(), $attributes);
    print STDERR ' [', $association->getConfidence(), '] ';
    print STDERR ' ==> ';
    print STDERR ' <', $association->getRuleSupport(), '> ';
    writeAttributeSet($association->getConclusion(), $attributes);
    print STDERR "\n";
  }
  print STDERR "\n";
}

my $DBFILE = $ARGV[0];
my $DIAGRAM = $ARGV[1];
my $LANG = $ARGV[2];
my $DEBUG = $ARGV[3];

setupLatticePrefs();

my $result = importDiagramAsContext($DBFILE, $DIAGRAM, $LANG);
my $model = $result->{'model'};
my $context = $result->{'context'};
my $attributes = $result->{'attributes'};
my $objects = $result->{'objects'};
my $objectsByName = $result->{'objectsByName'};

debugContext($context, $objects) if $DEBUG;

$model->resetLatticeComponents();
my $latticecomp = $model->getLatticeComponent(0);
$latticecomp->calculateLattice();
my $lattice = $latticecomp->getLattice();
my $concepts = $lattice;

$model->findAssociations();
my $associations = $model->getAssociationRules();

$model->findImplications();
my $implications = $model->getImplications();

debugConcepts($concepts, $attributes, $objects) if $DEBUG;
debugImplications($implications, $attributes) if $DEBUG;
debugAssociations($associations, $attributes) if $DEBUG;

# Convert context to an associative array
my %acontext = ();
for (my $i = 0; $i < $context->getObjectCount(); $i++) {
  my $object = $context->getObject($i);
  my @attributesList = ();
  for (my $j = 0; $j < $context->getAttributeCount(); $j++) {
    if ($context->getRelationAt($i, $j)) {
      push @attributesList, $attributes->[$j];
    }
  }
  my $aobject = {
    'name' => $object->getName(),
        'id' => $objects->[$i],
        'attributes' => \@attributesList
  };
  $acontext{$objects->[$i]} = $aobject;
}

# Convert concept table to a list of associative arrays
my @lconcepts = ();
for (my $i = 0; $i < $concepts->conceptsCount(); $i++) {
  my $concept = $concepts->conceptAt($i);

  my @intentList = ();
  my $intent = $concept->getAttribs();
  for (my $j = 0; $j < $intent->size(); $j++) {
    push @intentList, $attributes->[$j] if $intent->in($j);
  }

  my @extentList = ();
  my $extent = $concept->getObjects();
  for (my $j = 0; $j < $extent->size(); $j++) {
    push @extentList, $objects->[$j] if $extent->in($j);
  }

  my $aconcept = {
    'intent' => \@intentList,
        'extent' => \@extentList
  };
  push @lconcepts, $aconcept;
}

# Convert nodes to a list of associative arrays

sub getAttribName {
  my $attribObject = shift;
  return $attribObject->getName();
}

sub getObjectId {
  my $object = shift;
  return $objectsByName->{$object->getName()};
}

my %anodes = ();
my @lnodes = ();
for (my $i = 0; $i < $concepts->conceptsCount(); $i++) {
  my $node = $concepts->elementAt($i);

  my @parents = ();
  for (my $j = 0; $j < $node->getSuccCount(); $j++) {
    push @parents, getObjectHash($node->getSucc($j));
  }

  my @children = ();
  for (my $j = 0; $j < $node->getPredCount(); $j++) {
    push @children, getObjectHash($node->getPred($j));
  }

  my $hash = getObjectHash($node);
  my $anode = {
    'hash' => $hash,
        'idx' => $i,
        'level' => $node->getHeight(),
        'concept' => $lconcepts[$i],
        'parents' => \@parents,
        'children' => \@children,
        'labelObjects' => objectSetToList(undef, \&getObjectId, $node->ownObjectsIterator()),
        'labelAttributes' => objectSetToList(undef, \&getAttribName, $node->ownAttribsIterator())
  };
  $anodes{$hash} = $anode;
  push @lnodes, $anode;
}

print STDERR Dumper(\%anodes) if $DEBUG;

my @links = ();
foreach my $node (@lnodes) {
  foreach my $child (@{$node->{'children'}}) {
    push @links, {
      'source' => $node->{'idx'},
          'target' => $anodes{$child}->{'idx'}
    };
  }
}

my $json = JSON->new()
    ->pretty
    ->canonical
    ->encode(
  {
    'context' => \%acontext,
        'concepts' => \@lconcepts,
        'nodes' => \@lnodes,
        'links' => \@links
  });

print $json;
