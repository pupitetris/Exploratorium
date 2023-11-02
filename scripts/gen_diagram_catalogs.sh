#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

require_sqlite "$DBFILE"

while read -r lang; do
  while IFS=\| read -r diagram_id diagram; do
    echo "
SELECT Attribute,Class,Title,Formula,Explanation,Reference FROM v_attributes
       WHERE Lang='$lang' AND Diagram='$diagram'" |
      sqlite3 -header "$DBFILE" > \
              "$SCRIPTDIR"/../site/theories/$lang/$diagram/attr_desc.csv

    echo "
SELECT v.Code, v.Title_$lang AS Title
  FROM v_attribute_classes AS v
       NATURAL JOIN
       (
               SELECT DISTINCT attr_class.code AS Code,
                               ord
                 FROM diagram
                      NATURAL JOIN attribute_diagram
                      NATURAL JOIN attr_diagram_class
                      JOIN attr_class USING
                      (
                              attr_class_id
                      )
                WHERE diagram_id = $diagram_id
       )
 ORDER BY ord" |
      sqlite3 -header "$DBFILE" > \
              "$SCRIPTDIR"/../site/theories/$lang/$diagram/attr_class_desc.csv
  done < <(sqlite3 "$DBFILE" "SELECT diagram_id, code FROM diagram")
done < <(sqlite3 "$DBFILE" "SELECT lang_code FROM lang")
