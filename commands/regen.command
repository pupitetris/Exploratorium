#!/bin/sh

SRCDIR=$(dirname "$0")

clear
cd "$SRCDIR"/../tt
./generate.pl master.md --force
./generate.pl master-es.md --force
