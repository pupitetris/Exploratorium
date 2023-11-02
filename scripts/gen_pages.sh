#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

require_sqlite "$DBFILE"

while read -r lang; do

  (
    # gen_pages.pl is location agnostic, but this produces reports
    # that are easier on the eyes:
    cd "$SCRIPTDIR/../tt"
    ../scripts/gen_pages.pl master-$lang.md --force
  )

done < <(sqlite3 "$DBFILE" "SELECT lang_code FROM lang")
