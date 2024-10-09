#!/bin/bash

clear

SCRIPTDIR=$(dirname "$0")/..
source "$SCRIPTDIR"/common.sh

"$SCRIPTDIR"/build.sh "$DEFAULT_DBDSN"
