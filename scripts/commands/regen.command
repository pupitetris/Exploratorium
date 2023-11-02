#!/bin/sh

SCRIPTDIR=$(dirname "$0")/..

clear
"$SCRIPTDIR"/gen_pages.sh "$SCRIPTDIR"/../db/exploratorium.db
