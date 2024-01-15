#!/bin/bash

source $(dirname $0)/common.sh

TREEDIR="$SCRIPTDIR"/../gravity-tree

mkdir -p "$SITEDIR"/gravity-tree/Authors
grep 'xlink:href="Authors/' "$TREEDIR"/GravityTree2024Fotos.svg |
  cut -f2 -d\" |
  while read img; do
    if [ "$TREEDIR/$img" -nt "$SITEDIR/gravity-tree/$img" ]; then
      convert "$TREEDIR/$img" -resize x50 "$SITEDIR/gravity-tree/$img"
    fi
  done

if [ ! -e "$SITEDIR"/gravity-tree/Blur ]; then
  cp -a "$TREEDIR"/Blur "$SITEDIR"/gravity-tree
fi

INKSCAPE=$(require_inkscape)
if [ "$TREEDIR"/GravityTree2024Fotos.svg -nt "$TREEDIR"/gravity-tree.svg ]; then
  "$INKSCAPE" "$TREEDIR"/GravityTree2024Fotos.svg \
              --export-filename="$TREEDIR"/gravity-tree.svg \
              --export-text-to-path \
              --export-plain-svg \
              --export-type=svg
fi
