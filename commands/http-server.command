#!/bin/sh

SRCDIR=$(dirname "$0")

clear
cd "$SRCDIR"/..
http-server -p 8080
