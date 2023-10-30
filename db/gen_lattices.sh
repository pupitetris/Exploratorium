#!/bin/bash

DBFILE=$1

while read -r lang; do
  while read -r diagram; do
    fname=../theories-$lang/$diagram/lattice.json
    echo "Generating $fname"
    ./gen_lattice.pl $DBFILE $diagram $lang > $fname
  done < <(sqlite3 $DBFILE "SELECT code FROM diagram")
done < <(sqlite3 $DBFILE "SELECT lang_code FROM lang")