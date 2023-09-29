#!/bin/bash

SRCDIR=$(dirname "$0")

clear
cd "$SRCDIR"
./generate.pl master.md --force
./generate.pl master-es.md --force
