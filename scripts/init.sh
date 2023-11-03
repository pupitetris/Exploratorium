#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

"$SCRIPTDIR"/db_init.sh "$DBFILE"
"$SCRIPTDIR"/build.sh "$DBFILE"
