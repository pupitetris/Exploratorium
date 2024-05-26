#!/bin/bash

source $(dirname "$0")/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

"$SCRIPTDIR"/db_dump_ddl.sh "$DBFILE" > "$DBDIR"/ddl.sql &&
  "$SCRIPTDIR"/db_dump_data.sh "$DBFILE" > "$DBDIR"/data.sql
