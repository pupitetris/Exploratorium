#!/usr/bin/env -S wolframscript -script

SCRIPTDIR = AbsoluteFileName[DirectoryName[$ScriptCommandLine[[1]]]];

Get[SCRIPTDIR <> "/fca.wl"];

(*CLASSPATH = "//Applications/conexp-1.3/*";*)
CLASSPATH = SCRIPTDIR <> "/../bin/conexp-1.3/";

DBFILE = $ScriptCommandLine[[2]];
CONTEXT = $ScriptCommandLine[[3]];
LANG = $ScriptCommandLine[[4]];

DEBUG = Length[$ScriptCommandLine] > 4;
DEBUGOUTPUT = "stderr";

FcaInit["ClassPath" -> CLASSPATH,
        "DebugOutput" -> DEBUGOUTPUT];

result = FcaImportDBContextAsContext[DBFILE, CONTEXT, LANG];
context = result[["context"]];
model = result[["model"]];
attributes = result[["attributes"]];
objects = result[["objects"]];
objectsByName = result[["objectsByName"]];

DEBUG && FcaDebugContext[context, objects, attributes];

result = FcaComputeLattice[model];
concepts = result[["lattice"]];
implications = result[["implications"]];
associations = result[["associations"]];

DEBUG && FcaDebugConcepts[concepts, attributes, objects];
DEBUG && FcaDebugImplications[implications, attributes];
DEBUG && FcaDebugAssociations[associations, attributes];

acontext = FcaContextToAssociation[context, objects, attributes];
lconcepts = FcaConceptsToList[concepts, objects, attributes];
lnodes = FcaConceptsToAssociationList[concepts, lconcepts, objectsByName];

anodes = Association[
     Map[Function[anode, anode[["hash"]] -> anode], lnodes]
];

DEBUG && FcaDebug["\nanodes:\n\n", anodes, "\n\n"]

links = FcaGetNodeLinks[lnodes, anodes];

DEBUG && FcaDebug["links:\n\n", links, "\n\n"]

Export[Streams["stdout"],
     Association[
          "context" -> acontext,
          "concepts" -> lconcepts,
          "nodes" -> lnodes,
          "links" -> links
     ], "JSON"];
