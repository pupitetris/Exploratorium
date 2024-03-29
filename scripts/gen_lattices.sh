#!/bin/bash

source $(dirname $0)/common.sh

if [ "$1" = "-f" ]; then
  shift
  # Force a full regenerate for lattices:
  > "$DBDIR"/tmp_gen_lattices_data.sql.prev
fi

DBFILE=${1:-$DEFAULT_DBFILE}

require_sqlite "$DBFILE"

# Generate list of contexts that changed:
function get_changed_contexts {
  local TMPFILE="$DBDIR"/tmp_gen_lattices_data.sql
  "$SCRIPTDIR"/db_dump_data.sh > "$TMPFILE"
  [ ! -e "$TMPFILE.prev" ] && cp "$DBDIR"/data.sql "$TMPFILE.prev"
  diff -C 0 "$TMPFILE" "$TMPFILE.prev" |
    grep "INSERT INTO object_attribute" | cut -f4 -d, | sort -u |
    while read context_id; do echo -n $context_id,; done |
    sed 's/,$//'
  mv -f "$TMPFILE" "$TMPFILE.prev"
}

CONTEXT_IDS=$(get_changed_contexts)
if [ -z "$CONTEXT_IDS" ]; then
  echo "No changes in contexts detected."
  exit 0
fi

while read -r lang; do
  while read -r context; do
    fname="$SCRIPTDIR"/../site/theories/$lang/$context/lattice.json
    echo "Generating $fname"
    "$SCRIPTDIR"/gen_lattice.sh "$DBFILE" $context $lang > "$fname"
  done < <(sqlite3 "$DBFILE" "SELECT code FROM context WHERE context_id IN ($CONTEXT_IDS)")
done < <(sqlite3 "$DBFILE" "SELECT lang_code FROM lang")
