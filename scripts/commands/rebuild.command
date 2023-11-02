#!/bin/sh

SCRIPTDIR=$(dirname "$0")/..

DBDIR=$SCRIPTDIR/../db
DBFILE="$DBDIR"/exploratorium.db

clear
"$SCRIPTDIR"/build.sh "$DBFILE"
