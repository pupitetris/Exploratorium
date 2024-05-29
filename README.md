# Exploratorium

Website for the [Space-Time Theories
Exploratorium](https://remo.cua.uam.mx/vis/Exploratorium/).

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
