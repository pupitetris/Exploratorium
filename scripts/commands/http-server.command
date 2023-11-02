#!/bin/sh

SRCDIR=$(dirname "$0")

clear
cd "$SRCDIR"/../../site
http-server -p 8080
