#!/bin/bash

source $(dirname "$0")/common.sh

FORCE=
if [ "$1" = -f ]; then
    FORCE=1
    shift
fi

INPUT=$1
shift

OUTPUT=${1:-$DEFAULT_DBDSN}
shift

if [ -z "$INPUT" -o -z "$OUTPUT" ]; then
    cat >&2 <<EOF
Usage: $0 [-f] file.ods [file.db]

 -f		force overwriting the output file
 file.ods	input OpenDocument Spreadsheet file
 file.db	output sqlite3 file. Default: \$DEFAULT_DBDSN
		($DEFAULT_DBDSN)
EOF
    exit 1
fi

if [ -n "$FORCE" -a -e "$OUTPUT" ]; then
    {
	echo "$0: Output file '$OUTPUT' already exists."
	echo "	Use -f to force overwrite."
    } >&2
    exit 3
fi

TMPDIR=$(mktemp --tmpdir -d exploratorium-ods2sql.XXXXXXXXXX)

"$SCRIPTDIR"/ods2csv.sh "$INPUT" "$TMPDIR" &&
    "$SCRIPTDIR"/csv2sql.sh "$TMPDIR" > "$TMPDIR"/data.sql ||
	exit 2

require_sqlite

sqlite3 "$TMPDIR"/output.db < "$DBDIR"/ddl.sql &&
    sqlite3 "$TMPDIR"/output.db < "$TMPDIR"/data.sql &&
    cp -f "$TMPDIR"/output.db "$OUTPUT"

[ -z "$DEBUG" ] && rm -rf "$TMPDIR"
