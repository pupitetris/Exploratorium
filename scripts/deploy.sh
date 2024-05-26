#!/bin/bash

source $(dirname "$0")/common.sh

# You need to configure a "Host remo" section in ~/.ssh/config for this to work:
rsync --info=all2,name1 -aP $SITEDIR/ remo:Exploratorium
