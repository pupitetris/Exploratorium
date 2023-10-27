#!/bin/bash

SQLITE_VERSION=$(sqlite3 --version 2>/dev/null | cut -f1 -d\ )
IFS=. read major minor rel <<< $SQLITE_VERSION
if [ $(printf %02d%03d $major $minor) -lt 3040 ]; then
  echo "sqlite3 version $SQLITE_VERSION is older than 3.40, which is needed for STRICT tables." >&2
  exit 1
fi

DBFILE=exploratorium.db

[ -e $DBFILE ] && mv -f $DBFILE $DBFILE.bak

sqlite3 $DBFILE < ddl.sql &&
  sqlite3 $DBFILE < data.sql

./gen_diagram_catalogs.sh $DBFILE
