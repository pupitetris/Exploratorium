#!/bin/bash

source $(dirname "$0")/common.sh

DBDSN=${1:-$DEFAULT_DBDSN}

"$SCRIPTDIR"/db_dump_ddl.sh "$DBDSN" > "$DBDIR"/ddl.sql &&
  "$SCRIPTDIR"/db_dump_data.sh "$DBDSN" > "$DBDIR"/data.sql
