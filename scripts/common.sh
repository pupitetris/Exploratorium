SCRIPTDIR=${SCRIPTDIR:-$(dirname "$0")}
DBDIR=$SCRIPTDIR/../db
DEFAULT_DBFILE="$DBDIR"/exploratorium.db

function require_sqlite {
  local sqlite_version=$(sqlite3 --version 2>/dev/null | cut -f1 -d\ )
  IFS=. read major minor rel <<< $sqlite_version
  if [ $(printf %02d%03d $major $minor) -lt 3040 ]; then
    echo "$0: sqlite3 version $sqlite_version is older than 3.40, which is needed for STRICT tables" >&2
    exit 1
  fi

  local dbfile="$1"
  if [ ! -z "$dbfile" -a -e "$dbfile" ]; then
    if [ "$(sqlite3 "$dbfile" "SELECT 'OK'")" != OK ]; then
      echo "$0: Error opening DBFILE '$dbfile'" >&2
      exit 1
    fi
  fi
}
