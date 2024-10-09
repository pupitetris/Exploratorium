#!/bin/bash

source $(dirname "$0")/common.sh

TREEDIR=$PROJECTDIR/gravity-tree
OUTDIR=$SITEDIR/gravity-tree

mkdir -p "$OUTDIR"/Authors
grep 'xlink:href="Authors/' "$TREEDIR"/GravityTree2024Fotos.svg |
  cut -f2 -d\" |
  while read img; do
    if [ "$TREEDIR/$img" -nt "$OUTDIR/$img" ]; then
      convert "$TREEDIR/$img" -resize x50 "$OUTDIR/$img"
    fi
  done

if [ ! -e "$OUTDIR"/Blur ]; then
  cp -a "$TREEDIR"/Blur "$OUTDIR"
fi

INKSCAPE=$(require_inkscape)
if [ "$TREEDIR"/GravityTree2024Fotos.svg -nt "$OUTDIR"/gravity-tree.svg ]; then
  "$INKSCAPE" "$TREEDIR"/GravityTree2024Fotos.svg \
              --export-filename="$OUTDIR"/gravity-tree.svg \
              --export-text-to-path \
              --export-plain-svg \
              --export-type=svg
fi
