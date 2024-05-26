#!/bin/bash

source $(dirname "$0")/common.sh

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
    echo "DROP TABLE IF EXISTS $table;"
    echo
    sqlite3 "$DBFILE" ".schema $table" |
      pg_format -U 0 -L -T |
      sed -E $'s/ (ON|DEFERRABLE|REFERENCES|PRIMARY|NOT|DEFAULT|UNIQUE|COLLATE) /\\\n\t\t\\1 /g'
    echo
    echo
  done

sqlite3 "$DBFILE" "
SELECT name FROM sqlite_schema
       WHERE type = 'view'
       ORDER BY name" |
  while read -r view; do
    echo "-- View: $view"
    echo "DROP VIEW IF EXISTS $view;"
    echo
    sqlite3 "$DBFILE" ".schema $view" |
      pg_format -U 0 -L -T |
      sed -E $'s/ (ON) /\\\n\t\t\\1 /g' |
      grep -v $'^[ \t]*/\*[^*]\+\*/[ \t]*$'
    echo
    echo
  done

echo "COMMIT TRANSACTION;"
echo "PRAGMA foreign_keys = on;"
