#!/bin/bash

source $(dirname "$0")/common.sh

rsync --info=all2,name1 -aP "$SITEDIR/" "$DEPLOY_HOST:$DEPLOY_REMOTEDIR"
