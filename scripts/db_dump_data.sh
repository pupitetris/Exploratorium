#!/bin/bash

source $(dirname "$0")/common.sh

DBDSN=${1:-$DEFAULT_DBDSN}

require_sqlite "$DBDSN"

echo "PRAGMA foreign_keys = off;"
echo "BEGIN TRANSACTION;"
echo

sqlite3 "$DBDSN" "
SELECT name FROM sqlite_schema
       WHERE type = 'table'
             AND name NOT LIKE 'sqlite_%'
       ORDER BY name" |
  while read -r table; do
    echo "-- Table: $table"
    echo "DELETE FROM $table;"
    echo
    sqlite3 "$DBDSN" ".mode insert $table" "SELECT * FROM $table"
    echo
    echo
  done

echo "COMMIT TRANSACTION;"
echo "PRAGMA foreign_keys = on;"
