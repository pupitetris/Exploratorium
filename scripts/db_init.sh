#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

require_sqlite

[ -e "$DBFILE" ] && mv -f "$DBFILE" "$DBFILE".bak

sqlite3 "$DBFILE" < "$DBDIR"/ddl.sql &&
  sqlite3 "$DBFILE" < "$DBDIR"/data.sql

test_dbfile "$DBFILE"
