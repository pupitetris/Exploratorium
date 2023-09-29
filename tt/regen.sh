#!/bin/bash

SRCDIR=$(dirname "$0")

clear
cd "$SRCDIR"
./generate.pl master.md --force
./generate.pl master-es.md --force
echo
read -n 1 -s -p "Press any key to continue..."
