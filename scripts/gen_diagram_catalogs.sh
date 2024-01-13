#!/bin/bash

source $(dirname $0)/common.sh

DBFILE=${1:-$DEFAULT_DBFILE}

require_sqlite "$DBFILE"

while read -r lang; do
  while IFS=\| read -r context_id context; do
    echo "
SELECT Attribute,Class,Title,Formula,Explanation,Reference FROM v_attributes
       WHERE Lang='$lang' AND Context='$context'" |
      sqlite3 -header "$DBFILE" > \
              "$SITEDIR"/theories/$lang/$context/attr_desc.csv

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
      sqlite3 -header "$DBFILE" > \
              "$SITEDIR"/theories/$lang/$context/attr_class_desc.csv
  done < <(sqlite3 "$DBFILE" "SELECT context_id, code FROM context")
done < <(sqlite3 "$DBFILE" "SELECT lang_code FROM lang")
