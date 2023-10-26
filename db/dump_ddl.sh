#!/bin/bash

DBFILE=$1

echo "PRAGMA foreign_keys = off;"
echo "BEGIN TRANSACTION;"
echo

sqlite3 $DBFILE "
SELECT name FROM sqlite_schema
       WHERE type = 'table'
             AND name NOT LIKE 'sqlite_%'
       ORDER BY name" |
  while read table; do
    echo "-- Table: $table"
    echo "DROP TABLE IF EXISTS $table;"
    echo
    sqlite3 $DBFILE ".schema $table" |
      pg_format -U 0 -L -T |
      sed 's/ \(ON\|DEFERRABLE\|REFERENCES\|PRIMARY\|NOT\|DEFAULT\|UNIQUE\|COLLATE\) /\n\t\t\1 /g'
    echo
    echo
  done

sqlite3 $DBFILE "
SELECT name FROM sqlite_schema
       WHERE type = 'view'
       ORDER BY name" |
  while read view; do
    echo "-- View: $view"
    echo "DROP VIEW IF EXISTS $view;"
    echo
    sqlite3 $DBFILE ".schema $view"
    echo
    echo
  done

echo "COMMIT TRANSACTION;"
echo "PRAGMA foreign_keys = on;"
