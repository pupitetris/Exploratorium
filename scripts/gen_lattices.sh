#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

require_sqlite "$DBFILE"

while read -r lang; do
  while read -r diagram; do
    fname="$SCRIPTDIR"/../site/theories/$lang/$diagram/lattice.json
    echo "Generating $fname"
    "$SCRIPTDIR"/gen_lattice.sh "$DBFILE" $diagram $lang > "$fname"
  done < <(sqlite3 "$DBFILE" "SELECT code FROM diagram")
done < <(sqlite3 "$DBFILE" "SELECT lang_code FROM lang")
