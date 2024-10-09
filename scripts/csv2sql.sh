#!/bin/bash

source $(dirname "$0")/common.sh

INDIR=$1
shift

if [ -z "$INDIR" ]; then
    echo "Usage: $0 directory" >&2
    exit 1
fi

function get_reader {
    local header
    IFS= read -r header
    echo -n 'IFS=\| read -r '
    tr \| ' ' <<<$header
}

function cat2sql {
    local table=$1
    local fname=${2:-$table}
    local func=render_$table

    cat <<EOF
-- Table: $table
DELETE FROM $table;

EOF

    cat cat_$fname.psv | {
	reader=$(get_reader)
	seq=1
	while $func "$reader" "$table" $seq; do
	    let seq++
	done
    }

    echo
    echo
}

function contexts2cat {
    echo "attribute_id|context_id" > cat_attribute_context.psv
    echo "object_id|attribute_id|context_id" > cat_object_attribute.psv
    echo "object_id|context_id" > cat_object_context.psv

    ls *.psv | grep -vi ^cat_ |
	while read psv; do
	    local context_id=$(sed -n '1s/^Context:|\([0-9]\+\).*/\1/;T;p' "$psv")
	    if [ -z "$context_id" ]; then
		# Not a Context table
		break
	    fi

	    # First element will be ignored during iterations:
	    local attr_ids=(999)
	    IFS=\| attr_ids+=($(sed -n '2p' "$psv" | cut -f12- -d\|))
	    for ((i=1; i < ${#attr_ids[@]}; i++)); do
		echo "${attr_ids[$i]}|$context_id"
	    done >> cat_attribute_context.psv
	    
	    sed -n '12,${s/^[ |]\+//;p}' "$psv" | cut -f1,9- -d\| |
		while IFS=\| read -r -a data; do
		    local object_id=${data[0]}
		    echo "$object_id|$context_id" >> cat_object_context.psv
		    for ((i=1; i < ${#data[@]}; i++)); do
			if [ "${data[$i]}" = 1 ]; then
			    echo "$object_id|${attr_ids[$i]}|$context_id"
			fi
		    done
		done >> cat_object_attribute.psv
	done
}

function esc {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\'/\\\'}
    printf "'%s'" "${s//\"/\\\"}"
}

function str_or_NULL {
    if [ -z "$1" ]; then
	echo -n NULL
    else
	esc "$1"
    fi
}

function render_attr_class {
    local reader=$1
    local table=$2
    local seq=$3
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%s,%d);\n" \
	   "$table" "$attr_class_id" "$(esc "$attr_class_code")" "$seq"
}

function render_attr_class_desc {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,'en',%s);\n" \
	   "$table" "$attr_class_id" "$(esc "$attr_class_title_en")"
    printf "INSERT INTO %s VALUES(%d,'es',%s);\n" \
	   "$table" "$attr_class_id" "$(esc "$attr_class_title_es")"
}

function render_attr_context_class {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,1,%d,%s);\n" \
	   "$table" "$attribute_id" "$attribute_attr_class_id" "$(str_or_NULL "$attribute_reference")"
}

function render_attribute {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%s);\n" \
	   "$table" "$attribute_id" "$(str_or_NULL "$attribute_formula")"
}

function render_attribute_context {
    local reader=$1
    local table=$2

    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%d);\n" \
	   "$table" "$attribute_id" "$context_id"
}

function render_attribute_desc {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,1,'en',%s,%s,%s,%s);\n" \
	   "$table" "$attribute_id" "$(esc "$attribute_label_en")" "$(str_or_NULL "$attribute_title_en")" \
	   "$(str_or_NULL "$attribute_explanation_en")" NULL
    printf "INSERT INTO %s VALUES(%d,1,'es',%s,%s,%s,%s);\n" \
	   "$table" "$attribute_id" "$(esc "$attribute_label_es")" "$(str_or_NULL "$attribute_title_es")" \
	   "$(str_or_NULL "$attribute_explanation_es")" NULL
}

function render_context {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%d,%s);\n" \
	   "$table" "$context_id" "$context_class_id" "$(esc "$context_code")"
}

function render_context_class {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%s);\n" \
	   "$table" "$context_class_id" "$(esc "$context_class_code")"
}

function render_lang {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%s,%s);\n" \
	   "$table" "$(esc "$lang_code")" "$(esc "$lang_label")"
}

function render_object {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%s);\n" \
	   "$table" "$object_id" "$(esc "$object_code")"
}

function render_object_attribute {
    local reader=$1
    local table=$2

    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%d,%d,%d,%d);\n" \
	   "$table" "$object_id" "$context_id" "$attribute_id" "$context_id" 1
}

function render_object_context {
    local reader=$1
    local table=$2

    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,%d);\n" \
	   "$table" "$object_id" "$context_id"
}

function render_object_desc {
    local reader=$1
    local table=$2
    
    eval "$reader" || return 1
    printf "INSERT INTO %s VALUES(%d,'en',%s);\n" \
	   "$table" "$object_id" "$(esc "$object_label_en")"
    printf "INSERT INTO %s VALUES(%d,'es',%s);\n" \
	   "$table" "$object_id" "$(esc "$object_label_es")"
}

(
    cd $INDIR

    cat <<EOF
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

EOF

    contexts2cat

    cat2sql attr_class
    cat2sql attr_class_desc attr_class
    cat2sql attr_context_class attribute
    cat2sql attribute
    cat2sql attribute_context
    cat2sql attribute_desc attribute
    cat2sql context
    cat2sql context_class
    cat2sql lang
    cat2sql object
    cat2sql object_attribute
    cat2sql object_context
    cat2sql object_desc object

    cat <<EOF
COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
EOF
)
