if [ -n "$CONFIGFILE" ]; then
  source "$CONFIGFILE" || exit 1
fi

SCRIPTDIR=${SCRIPTDIR:-$(dirname "$0")}

if [ -z "$CONFIGFILE" ]; then
  CONFIGFILE=$SCRIPTDIR/config.sh
  if [ -e "$CONFIGFILE" ]; then
    source "$CONFIGFILE" || exit 1
  else
    CONFIGFILE=
  fi
fi

PROJECTDIR=${PROJECTDIR:-$SCRIPTDIR/..}
DBDIR=${DBDIR:-$PROJECTDIR/db}
SITEDIR=${SITEDIR:-$PROJECTDIR/site}
DIAGRAMSUBDIR=${DIAGRAMSUBDIR:-theories}
DIAGRAMDIR=${DIAGRAMDIR:-$SITEDIR/$DIAGRAMSUBDIR}
DEFAULT_DBDSN=${DEFAULT_DBDSN:-$DBDIR/exploratorium.db}
DEPLOY_HOST=${DEPLOY_HOST:-remo}
DEPLOY_REMOTEDIR=${DEPLOY_REMOTEDIR:-Exploratorium}

if [ -n "$CONFIGFILE" ]; then
  source "$CONFIGFILE" || exit 1
fi

function test_dbfile {
  local dbfile="$1"

  if [ ! -e "$dbfile" ]; then
    echo "$0: DBDSN '$dbfile' does not exist" >&2
    exit 1
  fi

  if [ "$(sqlite3 "$dbfile" "SELECT 'OK'")" != OK ]; then
    echo "$0: Error opening DBDSN '$dbfile'" >&2
    exit 1
  fi
}

function require_sqlite {
  local sqlite_version=$(sqlite3 --version 2>/dev/null | cut -f1 -d\ )

  IFS=. read major minor rel <<< $sqlite_version
  if [ $(printf %02d%03d $major $minor) -lt 3040 ]; then
    echo "$0: sqlite3 version $sqlite_version is older than 3.40, which is needed for STRICT tables" >&2
    exit 1
  fi

  local dbfile="$1"
  if [ ! -z "$dbfile" ]; then
    test_dbfile "$dbfile"
  fi
}

function require_inkscape {
  if [ -e "/Applications/Inkscape.app/Contents/MacOS/inkscape" ]; then
    echo "/Applications/Inkscape.app/Contents/MacOS/inkscape"
  elif [ -e "$HOME"/bin/[Ii]nkscape* ]; then
    echo "$HOME"/bin/[Ii]nkscape*
  elif ! which inkscape; then
    echo "$0: inkscape not found" >&2
    exit 1
  fi
}
