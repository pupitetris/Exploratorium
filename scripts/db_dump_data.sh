#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

require_sqlite "$DBFILE"

echo "PRAGMA foreign_keys = off;"
echo "BEGIN TRANSACTION;"
echo

sqlite3 "$DBFILE" "
SELECT name FROM sqlite_schema
       WHERE type = 'table'
             AND name NOT LIKE 'sqlite_%'
       ORDER BY name" |
  while read -r table; do
    echo "-- Table: $table"
    echo "DELETE FROM $table;"
    echo
    sqlite3 "$DBFILE" ".mode insert $table" "SELECT * FROM $table"
    echo
    echo
  done

echo "COMMIT TRANSACTION;"
echo "PRAGMA foreign_keys = on;"
