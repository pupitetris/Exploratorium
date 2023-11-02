#!/bin/bash

SCRIPTDIR=$(dirname "$0")

DBFILE=$1

while read -r lang; do

  (
    cd "$SCRIPTDIR/../tt"
    ../scripts/gen_pages.pl master-$lang.md --force
  )

done < <(sqlite3 "$DBFILE" "SELECT lang_code FROM lang")
