#!/bin/bash

source $(dirname "$0")/common.sh

INPUT=$1
shift

OUTDIR=$1
shift

if [ -z "$INPUT" -o -z "$OUTDIR" ]; then
    echo "Usage: $0 file.ods outdir" >&2
    exit 1
fi

if [ ! -d "$OUTDIR" ]; then
    echo "$0: '$OUTDIR' is not a directory" >&2
    exit 2
fi

cp -f "$INPUT" "$OUTDIR" &&
    (
	[ "${SCRIPTDIR:0:1}" != / ] && SCRIPTDIR=$PWD/$SCRIPTDIR
	INPUT=$(basename "$INPUT")

	cd "$OUTDIR"

	verbose=0
	[ -n "$DEBUG" ] && verbose=1
	"$SCRIPTDIR"/xlsx2csv.pl -A -N -v $verbose "$INPUT"

	ls *.csv |
	    while read fname; do
		name=${fname%.*}
		[ -n "$DEBUG" ] && echo "$name" >&2
		mv "$name".csv "$name".csv1
		{
		    if [ "${name:0:4}" = cat_ ]; then
			# For catalogs, remove empty columns and rows
			num_cols=$(csvcut -n "$name".csv1 | grep -c -v '^ *[0-9]\+: *$')
			csvcut -S -x -c 1-$num_cols "$name".csv1 | grep -v '^,'
		    else
			csvcut -S -x "$name".csv1
		    fi
		} | tee "$name".csv |
		    csvformat -D \| > "$name".psv
		[ -z "$DEBUG" ] && rm -f "$name".csv1
	    done
    )

exit 0
