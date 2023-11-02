#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

"$SCRIPTDIR"/gen_diagram_catalogs.sh "$DBFILE"
"$SCRIPTDIR"/gen_lattices.sh "$DBFILE"
"$SCRIPTDIR"/gen_pages.sh "$DBFILE"
