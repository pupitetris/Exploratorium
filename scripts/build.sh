#!/bin/bash

SCRIPTDIR=$(dirname "$0")

DBFILE=$1

"$SCRIPTDIR"/gen_diagram_catalogs.sh "$DBFILE"
"$SCRIPTDIR"/gen_lattices.sh "$DBFILE"
"$SCRIPTDIR"/gen_pages.sh "$DBFILE"
