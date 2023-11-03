#!/bin/bash

source $(dirname $0)/common.sh

LATTICE_PREF_DIR="$HOME"/.java/.userPrefs/conexp/frontend/latticeeditor
if [ ! -e "$LATTICE_PREF_DIR"/prefs.xml ]; then
  mkdir -p "$LATTICE_PREF_DIR"
  cat > "$LATTICE_PREF_DIR"/prefs.xml <<< '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE preferences SYSTEM "http://java.sun.com/dtd/preferences.dtd"><preferences EXTERNAL_XML_VERSION="1.0"><root type="user"><map/><node name="conexp"><map/><node name="frontend"><map/><node name="latticeeditor"><map><entry key="FIT_TO_SIZE_PROPERTY" value="true"/><entry key="layout" value="MinIntersectionLayout"/><entry key="highlightStrategy" value="FilterIdealHighlightStrategy"/><entry key="showCollisions" value="true"/><entry key="drawObjects" value="AllObjectsLabelsStrategy"/><entry key="gridSizeX" value="80"/><entry key="maxNodeRadius" value="12"/><entry key="gridSizeY" value="80"/><entry key="nodeDrawStrategy" value="MaxNodeRadiusCalcStrategy"/><entry key="edgeDrawStrategy" value="FixedEdgeSizeCalcStrategy"/><entry key="labelsFontSize" value="12"/><entry key="USE_IDEAL_MOVE_STRATEGY_PROPERTY" value="false"/><entry key="drawAttribs" value="AllAttribsLabelsStrategy"/></map></node></node></node></root></preferences>'
fi

if /usr/bin/env perl -mInline::Java -mDBD::SQLite -e '' >/dev/null 2>&1; then
  # Perl detected. Use it as it is faster.
  "$SCRIPTDIR"/gen_lattice.pl "$@"
elif /usr/bin/env wolframscript -version >/dev/null 2>&1; then
  "$SCRIPTDIR"/gen_lattice.wls "$@"
else
  echo $0: No functional runtime found >&2
  exit 1
fi
