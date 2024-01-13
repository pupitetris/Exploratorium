#!/bin/bash

source $(dirname $0)/common.sh

set -x

TREEDIR="$SCRIPTDIR"/../gravity-tree

mkdir -p "$SITEDIR"/gravity-tree/Authors
grep 'xlink:href="Authors/' "$TREEDIR"/GravityTree2024Fotos.svg |
  cut -f2 -d\" |
  while read img; do
set -x

    convert "$TREEDIR/$img" -resize x50 "$SITEDIR/gravity-tree/$img"
  done

if [ ! -e "$SITEDIR"/gravity-tree/Blur ]; then
  cp -a "$TREEDIR"/Blur "$SITEDIR"/gravity-tree
fi

INKSCAPE=/Applications/Inkscape.app/Contents/MacOS/inkscape
#INKSCAPE="$HOME"/bin/Inkscape-091e20e-x86_64.AppImage

$INKSCAPE "$TREEDIR"/GravityTree2024Fotos.svg \
          --export-filename="$SITEDIR"/gravity-tree/gravity-tree.svg \
          --export-text-to-path \
          --export-plain-svg \
          --export-type=svg

