#!/bin/sh

clear

SCRIPTDIR=$(dirname "$0")/..
source "$SCRIPTDIR"/common.sh

"$SCRIPTDIR"/deploy.sh
