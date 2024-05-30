# Exploratorium

Website for the [Space-Time Theories
Exploratorium](https://remo.cua.uam.mx/vis/Exploratorium/).


## Workflow

The following is a graph of the main workflow. Trapezoids represent
files found in this GIT repo, most of which are input files. Skewed
boxes represent files resulting from the output of a process. Rounded
boxes represent user-facing applications that manipulate data. Normal
gray boxes represent a processor. Texts in italics indicate the
location of a file or the processor script/executable.

```mermaid
flowchart TD
    SQL[\SQL Files<br/><i>db/*.sql/] <--> DBP
    subgraph DBP[<b>Database Processor]
        DBI[DB Init<br/><i>scripts/db_init.sh]
        DBD[DB Dumper<br/><i>scripts/db_dump.sh]
    end
    DBP <--> DB[(Database<br/><i>PostgreSQL or<br/>SQLite: db/exploratorium.db)]
    DB --> FCA
    DBC([DB Editor<br/><i>SQLite Studio<br/> or PgModeler]) <--> DB
    subgraph TTP[<b>Template Processor]
        TTGen[Generator<br/><i>scripts/gen_pages.sh]
        MD[\Markdown Files<br/><i>tt/*.md/] -- Web Content --> TTGen
        TT[\Template Files<br/><i>tt/*.tt/] -- HTML Structure --> TTGen
    end
    subgraph FCA[<b>FCA Processor]
        direction TB
        subgraph FG[Generator]
            G[Lattice JSON Generator<br/><i>scripts/gen_lattices.sh]
            G2[Catalog CSV Generator<br/><i>scripts/gen_diagram_catalogs.sh]
        end
        CX[Conexp<br><i>bin/conexp-1.3/*.jar]
        G -- contexts --> CX
        CX -- lattices --> G
    end
    subgraph SITE[<b>Web Site]
        direction LR
        ED([Lattice Viewer / Editor])
        subgraph DAT[Generated Data Files]
            LJ[/"Lattice JSON<br/><i>site/theories/{en,es}/*/lattice.json</i>"/]
            CSV[/"Lattice CSV<br/><i>site/theories/{en,es}/*/*.csv</i>"/]
            LPJ[/"Lattice Position JSON<br/><i>site/theories/{en,es}/*/pos.json</i>"/]
        end
        subgraph LIB[Javascript Libraries]
            D3[\d3<br/><i>site/lib/d3/]
            MJ[\MathJax<br/><i>site/lib/MathJax/]
            JQ[\jQuery<br/><i>site/lib/jQuery/]
            BS[\Bootstrap<br/><i>site/lib/bootstrap/]
        end
        subgraph RES[Resources]
            HTML[/HTML docs<br/><i>site/*.html/]
            CSS[\CSS<br/><i>site/style.css/]
            I[\Images<br/><i>site/img/*/]
            JS[\Javascript<br/><i>site/lib/*.js/]
        end
        ED <---> LPJ
    end
    FCA -- Lattice<br/>JSON & CSV --> SITE
    TTP -- HTML docs --> SITE
    SITE --> DEP
    DEP[<b>Deployer<br/><i>scripts/deploy.sh]
    DEP -- Web Site,<br/>ssh + rsync --> SRV[<b>Web Server]
```


## Installation

The following instructions are for a Linux Debian 12.5 (Bookworm)
installation. For other OSes and distributions, YMMV.

Install the required packages using this command:

```sh
sudo apt install openjdk-17-jre-headless openjdk-17-jre libjson-perl \
  libtemplate-perl libdbi-perl libdbd-sqlite3-perl libdigest-md5-perl \
  libinline-java-perl pandoc sqlite3 pgformatter rsync openssh-client \
  inkscape imagemagick-6.q16 node-http-server
```


### Observations

* All shell scripts have been written specifically for Bash.
* If you wish to execute Conexp in stand-alone mode, as an
  application, you will need to provide a JavaFX implementation to
  Conexp, either by installing a legacy version of Java (prior to Java
  11) or installing [OpenJFX](https://gluonhq.com/products/javafx/).
* `node-http-server` is in the package list as a means to load the web
  site locally for development. If you do not wish to install its
  dependencies, you can instead use `micro-httpd` or `mini-httpd` and
  edit `scripts/command/http-server.command` accordingly.
* `inkscape` and `imagemagick-6.q16` are required to process and
  generate the gravity apple tree. The part executed by inkscape is a
  typeface-sensitive operation and should only be done with the same
  architecture/machine of the author's, otherwise the geometries will
  come out wrong and the graph will be malformed. There is no need to
  install these if the gravity tree will not be regenerated.


## Usage

The Exploratorium comes with a series of scripts that perform the
different transformation stages of the workflow. They are located in
the [scripts](scripts) directory, inside of which there is a
[commands](scripts/commands) directory which contains the most common
operations and are meant to be executed from a file manager by
double-clicking (this functionality has been tested on macOS Finder
and does not work with GNOME Files v.43, so YMMV).


### Generalities

All scripts auto-discover the location of the project directory by
assuming it is the parent of the program's location, and they are
working-directory agnostic, meaning they can be executed from any
location and they will always act by default on the project they are
part of.

#### Configuration and Overriding

The following environment variables can be set to customize the
transformation process:

| Name            | Default                   | Purpose                                                                                                                                                 |
|-----------------|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `CONFIGFILE`    | `$SCRIPTDIR/config.sh`    | Configuration override by means of a sourced shell script. If the default config file is not found, it is not sourced                                   |
| `SCRIPTDIR`     | `$(dirname "$0")`         | Location of the script being invoked                                                                                                                    |
| `PROJECTDIR`    | `$SCRIPTDIR/..`           | Location of the project's main directory                                                                                                                |
| `DBDIR`         | `$PROJECTDIR/db`          | Location of the project's files related to the database, such as initialization SQL and data dumps, and in the case of SQLite, the database binary file |
| `SITEDIR`       | `$PROJECTDIR/site`        | Location of the web site's files. This is the DocumentRoot for a local web server and what is deployed to production                                    |
| `DIAGRAMSUBDIR` | `theories`                | If `DIAGRAMDIR` is not overriden, sets the sub-directory under `$SITEDIR` where diagram files will be put                                               |
| `DIAGRAMDIR`    | `$SITEDIR/$DIAGRAMSUBDIR` | Location where the diagram files will be put                                                                                                            |
| `DEFAULT_DBDSN` | `$DBDIR/exploratorium.db` | Data store name for the database connection. DBI notation, or just the file name of an SQLite database file                                             |

`DEFAULT_DBDSN` can point to a file, which selects SQLite as the
database engine. DBI notation is supported for future-proofing when
the string is prefixed with `DBI:`, as per usual. If credentials are
needed, an external method such as
[pgpass](https://www.postgresql.org/docs/current/libpq-pgpass.html) is
recommended. For programs that require a connection string (a DSN) as
a parameter, `DEFAULT_BDSN` will be taken if none is provided.

If a configuration file is found where `CONFIGFILE` points it will be
sourced and the values of the environment variables set there will
override the default values. Only when `CONFIGFILE` is using its
default value will the sourcing be ommited if the file is not
found. Otherwise, an error will be produced. 

Note: the configuration file is sourced **twice**: once before, and
once after the configuration globals are set. Complex commands within
this file are discouraged.

Example `scripts/config.sh` file:

```sh
SITEDIR=$PROJECTDIR/test-site
DIAGRAMSUBDIR=cosmo
```

This will make `SITEDIR` derive its location from `PROJECTDIR`'s
default value, and make `DIAGRAMDIR` be `$SITEDIR/cosmo`. All other
variables will take their normal default values. Since the
configuration file is in the default location, it will provoke the
overrides automatically.

Of course, you can set or export these variables at the shell level,
for a one-off case and it's the only reliable way to indicate an
alternate configuration file location:

```sh
$ CONFIGFILE=/tmp/new-config.sh scripts/init.sh
```

or if you are using a configuration file for a whole session:

```sh
$ export CONFIGFILE=$HOME/.my-exploratorium-config.sh
$ scripts/gen_diagram_catalogs.sh
$ scripts/gen_lattices.sh
```


### Execution dependencies

The whole of the project is meant to be totally or partially rebuilt
using just one command without user intervention. To illustrate the
execution chain, examine the following dependency tree:

```mermaid
flowchart TD
    init.sh ---> db_init.sh
    init.sh ----> build.sh
    build.sh ---> gen_lattices.sh
    build.sh ---> gen_pages.sh
    build.sh ---> gen_diagram_catalogs.sh
    db_dump.sh ----> db_dump_ddl.sh
    db_dump.sh ----> db_dump_data.sh
    gen_lattice.sh ---> gen_lattice.pl
    gen_lattices.sh ---> db_dump_data.sh
    gen_lattices.sh ---> gen_lattice.sh
    gen_pages.sh ---> gen_gravitytree.sh
```


### Top-level Operations

All of the following programs reside in the `scripts` directory:

#### init.sh

This will take a project that has just been cloned from git and
[initialize the database](#db_initsh) and then [generate the whole web
site](#buildsh). It can be useful if changes to the database or other
sources have just been pulled from git and we want to regenerate the
whole thing.

This program will force the regeneration of all of the lattice files,
regardless of changes in the database.

Invocation:

`init.sh [«DSN»]`

* `«DSN»`: optional Data Source Name, see [`DEFAULT_DBDSN`](#configuration-and-overriding).

#### build.sh

Assume the database is up and running and regenerate the whole web
site: [catalogs](#gen_diagram_catalogssh),
[lattices](#gen_latticessh) and [web pages](#gen_pagessh).

Invocation:

`build.sh [«DSN»]`

* `«DSN»`: optional Data Source Name, see [`DEFAULT_DBDSN`](#configuration-and-overriding).


### Database Operations

The chosen format for the database schema and data control in the git
repo is as SQL statemets. After the repository is cloned from git, the
database is not ready to be worked on: it must be restored from the
SQL scripts.

Conversely, a dump should be performed to convert the database to
plain-text SQL statement scripts for changes to be commited. SQL
output from the dump scripts is what is to be commited to the
repository, where it is easier to keep track of the changes, instead
of pushing binary files which are unnatural for git to manage.

Here a sequence diagram with the expected steps relative to working on
changes to the database:

```mermaid
stateDiagram
    direction TB
    gitclone : git clone
    gitclone --> db_init.sh
    note right of db_init.sh
        Regenerate DB<br/>from SQL files
    end note
    edit : Edit Database<br/>(SQLite Studio)
    db_init.sh --> edit
    edit --> build.sh
    test : Test Local Website
    note right of test
        Run scripts/commands/http-server.command
        to start a local web server for testing
    end note 
    build.sh --> test
    test --> edit
    test --> db_dump.sh: 
    gitcommit : git commit
    db_dump.sh --> gitcommit
    note left of db_dump.sh
        Satisfied with changes,<br/>convert back to SQL
    end note
    gitpush : git push
    gitcommit --> gitpush
    gitcommit --> outside
    outside : Changes Pushed?<br/>(collaborator)
    gitpush --> outside
    gitpull : git pull
    state if_outside <<choice>>
    outside --> if_outside
    if_outside --> gitpull : yes
    if_outside --> edit : no
    gitpull --> db_init.sh
```

#### db_init.sh

Take the SQL statements stored in `$DBDIR/ddl.sql` (SQL statements to
build the database schema) and `$DBDIR/data.sql` (data dumped as SQL
insert statements) and use them to set up a new database.

In the case of SQLite, if the database file already exists, it is
forcefully renamed to its original name plus `.bak` as an additional
suffix to avoid an irrecoverable loss of information in case there are
uncommited changes in the binary that haven't been dumped.

For DBMSes, a dump may be performed, then the database would be
dropped and recreated if possible, but this has its own caveats as
many DBs cannot be dropped if any client is connected to it.

Invocation:

`db_init.sh [«DSN»]`

* `«DSN»`: optional Data Source Name, see [`DEFAULT_DBDSN`](#configuration-and-overriding).

#### db_dump.sh

Dump both the [schema of the database](#db_dump_ddlsh) and [its
data](#db_dump_datash) and store them as SQL statements in
`$DBDIR/ddl.sql` and `$DBDIR/data.sql` respectively.

Invocation:

`db_dump.sh [«DSN»]`

* `«DSN»`: optional Data Source Name, see [`DEFAULT_DBDSN`](#configuration-and-overriding).

#### db_dump_ddl.sh

Perform a dump of the schema of the database and send it to standard
output. [`pg_format`](https://sqlformat.darold.net/) is used to beautify the output.

Invocation:

`db_dump_ddl.sh [«DSN»]`

* `«DSN»`: optional Data Source Name, see [`DEFAULT_DBDSN`](#configuration-and-overriding).

#### db_dump_data.sh

Dump the data from all of the tables and send them as INSERT SQL
statements to standard output.

Invocation:

`db_dump_data.sh [«DSN»]`

* `«DSN»`: optional Data Source Name, see [`DEFAULT_DBDSN`](#configuration-and-overriding).


### Web Site Operations

From the content creator's perspective, to render the web site's pages
and diagrams we have two main inputs: master Markdown files and the
database. For the webmaster, the template files affect the markup and
structure of the pages and of course there are CSS files, images and
Javascript sources to mantain.
