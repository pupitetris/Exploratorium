#!/bin/bash

clear

SCRIPTDIR=$(dirname "$0")/..
source "$SCRIPTDIR"/common.sh

"$SCRIPTDIR"/gen_pages.sh "$DEFAULT_DBDSN"
