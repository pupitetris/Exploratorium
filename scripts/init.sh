#!/bin/bash

source $(dirname "$0")/common.sh

DBDSN=${1:-$DEFAULT_DBDSN}

"$SCRIPTDIR"/db_init.sh "$DBDSN"

# Force a full regenerate for lattices:
> "$DBDIR"/tmp_gen_lattices_data.sql.prev

"$SCRIPTDIR"/build.sh "$DBDSN"
