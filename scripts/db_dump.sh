#!/bin/bash

SCRIPTDIR=$(dirname "$0")

DBFILE=$1

"$SCRIPTDIR"/db_dump_ddl.sh "$DBFILE" > "$SCRIPTDIR"/../db/ddl.sql
"$SCRIPTDIR"/db_dump_data.sh "$DBFILE" > "$SCRIPTDIR"/../db/data.sql
