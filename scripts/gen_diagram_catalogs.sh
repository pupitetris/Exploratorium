#!/bin/bash

source $(dirname "$0")/common.sh

DBDSN=${1:-$DEFAULT_DBDSN}

require_sqlite "$DBDSN"

while read -r lang; do
  while IFS=\| read -r context_id context; do
    diagram_dir=$(get_diagram_dir $lang $context)

    mkdir -p "$diagram_dir"
    if [ ! -e "$diagram_dir"/pos.json ]; then
      echo '[]' > "$diagram_dir"/pos.json
    fi
    if [ ! -e "$diagram_dir"/config.js ]; then
      echo 'window.Config = {
  VIEWBOX: "0 0 1920 1024",
  NODE_RADIUS: 23,
  TEXTBOX_PADDING: 8,
  LABELS_ORIGIN_X: 30,
  LABELS_ORIGIN_Y: 5,
  LABELS_HEIGHT: 35,
  LABELS_SEPARATION: 14,
  LINK_STRENGTH: 0,
  USE_EDITOR: false
}' > "$diagram_dir"/config.js
    fi

    echo "
SELECT Attribute,Class,Title,Formula,Explanation,Reference FROM v_attributes
       WHERE Lang='$lang' AND Context='$context'" |
      sqlite3 -header "$DBDSN" > "$diagram_dir"/attr_desc.csv

    echo "
SELECT v.Code, v.Title_$lang AS Title
  FROM v_attribute_classes AS v
       NATURAL JOIN
       (
               SELECT DISTINCT attr_class.code AS Code,
                               ord
                 FROM context
                      NATURAL JOIN attribute_context
                      NATURAL JOIN attr_context_class
                      JOIN attr_class USING
                      (
                              attr_class_id
                      )
                WHERE context_id = $context_id
       )
 ORDER BY ord" |
      sqlite3 -header "$DBDSN" > "$diagram_dir"/attr_class_desc.csv
  done < <(sqlite3 "$DBDSN" "SELECT context_id, code FROM context" | filter_contexts)
done < <(sqlite3 "$DBDSN" "SELECT lang_code FROM lang")
