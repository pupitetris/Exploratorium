#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

"$SCRIPTDIR"/db_init.sh "$DBFILE"

# Force a full regenerate for lattices:
> "$DBDIR"/tmp_gen_lattices_data.sql.prev

"$SCRIPTDIR"/build.sh "$DBFILE"
