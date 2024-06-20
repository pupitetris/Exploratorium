#!/bin/sh

./sort-views.pl "$@" |
  sed '
/^\s*PRAGMA\s\+foreign_keys\s*=\s*off\s*;\s*$/{
  N
  s/^.*\n\(\s*BEGIN\s\+TRANSACTION\s*;\)/\1\nSET CONSTRAINTS ALL DEFERRED;/
  a \
\
CREATE COLLATION IF NOT EXISTS NOCASE (\
	provider = icu,\
	locale = '\'und-u-ks-level2\'',\
	deterministic = true\
);\

}
/^\s*PRAGMA\s/d
s/\(^\|\s\)STRICT\(\s\|;\)/\2/
/\sINTEGER\s*$/{
  N
  /NOT NULL/N
  /PRIMARY\s\+KEY/{
    s/\s\+AUTOINCREMENT//
    s/^\(\s*\S\+\s\+\)INTEGER\(\s*\n\s*PRIMARY\s\+KEY\s*\),/\1SERIAL\2,/
    s/^\(\s*\S\+\s\+\)INTEGER\s*\n\s*NOT\s\+NULL\(\s*\n\s*PRIMARY\s\+KEY\s*\),/\1SERIAL\2,/
  }
}
' |
  ./add-fk.pl |
  sed -z 's/\s*\n\s*,/,/g'
