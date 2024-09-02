#!/bin/bash

source $(dirname "$0")/common.sh

DBDSN=${1:-$DEFAULT_DBDSN}

require_sqlite "$DBDSN"

"$SCRIPTDIR"/gen_gravitytree.sh

ttdir="$PROJECTDIR/tt"
gen_pages=$(realpath -s --relative-to="$ttdir" "$SCRIPTDIR"/gen_pages.pl)

(
    # gen_pages.pl is location agnostic, but this produces reports
    # that are easier on the eyes:
    cd "$ttdir"
    while read -r lang; do
	"$gen_pages" $(printf "$MASTER_NAME" $lang) --force
    done
) < <(sqlite3 "$DBDSN" "SELECT lang_code FROM lang")
