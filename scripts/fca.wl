(* ::Package:: *)

BeginPackage["FCA`"]

FcaInit::usage =
"Initialize the FCA package, with the options: ClassPath and DebugOutput";

FcaImportDBDiagramAsContext::usage =
"Load the context for a given diagram and language from the specified SQLite database file";

FcaImportCsvAsContext::usage =
"Load data from a context table in CSV format";

FcaComputeLattice::usage =
"Call Conexp algorithms to calculate the lattice, associations and implications";

FcaContextToAssociation::usage =
StringJoin["Convert Conexp context to an Association of the form ",
           "ObjectId-><|name->ObjectName,id->ObjectId,attributes->ObjectAttriutes[]|>"];

FcaConceptsToList::usage =
"Convert concepts to a list of Associations with the intents and extents list for each";

FcaConceptsToAssociationList::usage =
StringJoin["Returns a list of Associations with the properties of the concepts ",
           "(hash, index, level, concept label, parent nodes, child nodes, object labels and attribute labels"];

FcaGetNodeLinks::usage =
StringJoin["Returns a list of Associations with source and target concept index values ",
           "representing the links of the network"];

FcaDebug::usage = "Print concatenation of ToString of arguments using the package debug rules";
FcaDebugContext::usage = "Print Object and Attributes of the context";
FcaDebugConcepts::usage = "Print intent and extent of the concepts";
FcaDebugImplications::usage = "Print implications";
FcaDebugAssociations::usage = "Print associations";

Begin["`Private`"];

Needs["JLink`"];

debugOutput = "";

Options[FcaInit] = {
  "ClassPath" -> "../bin/conexp-1.3",
  "DebugOutput" -> ""
};

FcaInit[OptionsPattern[]] :=
  Module[
    {},

    (* https://mathematica.stackexchange.com/questions/215433/prevent-jlink-from-using-a-disabledpreferencesfactory-with-java-on-linux *)
    JLink`InstallJava`Private`$disablePrefs = False;

    InstallJava[];
    AddToClassPath[OptionValue["ClassPath"]];
    debugOutput = OptionValue["DebugOutput"];
  ];

FcaDebug = debug = If[debugOutput != "",WriteString[debugOutput, ##]]&;

FcaImportDBDiagramAsContext[dbfile_, diagram_, lang_] :=
  Module[
    {
      db, res, session,
      attrDS, attributes, numAttributes,
      objDS, objects, numObjects, objectsByName,
      assigDS, context, i, id, j, attr
    },
    db = DatabaseReference[
      <|
        "Backend" -> "SQLite",
        "Name" -> dbfile
      |>];
    res = DatabaseConnect[db];
    If[!db["Connected"], Return[res]];
    session = StartExternalSession[db];

    attrDS = ExternalEvaluate[session,
                              StringTemplate["SELECT Attribute FROM v_attribute_diagram "
                                             <> "WHERE Diagram = '`1`' AND Lang = '`2`'"][diagram, lang]];
    attributes = Normal[attrDS[All, "Attribute"]];
    numAttributes = Length[attributes];

    objDS = ExternalEvaluate[session,
                             StringTemplate["SELECT Code AS Id, Object AS Name FROM v_object_diagram "
                                            <> "WHERE Diagram = '`1`' AND Lang = '`2`'"][diagram, lang]];
    objects = Normal[objDS[All, "Id"]];
    numObjects = Length[objects];
    objectsByName = Association[Normal[objDS[All, Function[obj, obj["Name"] -> obj["Id"]]]]];

    assigDS = ExternalEvaluate[session,
                               StringTemplate["SELECT ObjectCode AS ObjectId, Attribute FROM v_context_assignments "
                                              <> "WHERE x = 1 AND Diagram = '`1`' AND Lang = '`2`'"][diagram, lang]];
    context = JavaNew["conexp.core.Context", numObjects, numAttributes];
    For[i = 1, i <= numObjects, i++,
        id = objects[[i]];
        context@getObject[i - 1]@setName[objDS[i, "Name"]];
        For[j = 1, j <= numAttributes, j++,
            attr = attributes[[j]];
            If[i == 1, context@getAttribute[j - 1]@setName[attr]];
            If[Length[
              assigDS[Select[Function[r, r[["ObjectId"]] == id && r[["Attribute"]] == attr]]]
               ] > 0,
               context@setRelationAt[i - 1, j - 1, True]
            ]
        ]
    ];
    Association["context" -> context,
                "model" -> JavaNew["conexp.frontend.ContextDocumentModel", context],
                "attributes" -> attributes,
                "objects" -> objects,
                "objectsByName" -> objectsByName
    ]
  ];

(* Load a CSV and convert it to a Conexp context using
the first field as attribute classes,
the second field as attribute names,
the first column as object IDs and
the second column as object names. *)
FcaImportCsvAsContext[filename_] :=
  Module[
    {
      csvlist, classHeader, header, numObjects, numAttributes,
      context, attributes, objects, objectsByName,
      attr, obj, rec, id, name, obj, i, j
    },

    csvlist = Import[filename, CharacterEncoding -> "UTF8"];
    classHeader = Drop[csvlist[[1]], 2];
    header = Drop[csvlist[[2]], 2];
    csvlist = Drop[csvlist, 2];
    numObjects = Length[csvlist];
    numAttributes = Length[header];

    context = JavaNew["conexp.core.Context", numObjects, numAttributes];

    attributes = List[];
    For[i = 1, i <= numAttributes, i++,
        attr = header[[i]];
        obj = context@getAttribute[i - 1];
        obj@setName[attr];
        AppendTo[attributes, attr]
    ];

    objects = List[];
    objectsByName = Association[];
    For[i = 1, i <= numObjects, i++,
        rec = csvlist[[i]];
        id = ToString[rec[[1]]];
        name = rec[[2]];
        obj = context@getObject[i - 1];
        obj@setName[name];
        AppendTo[objects, id];
        objectsByName[[name]] = id;
        rec = Drop[rec, 2];

        For[j = 1, j <= numAttributes, j++,
            If[rec[[j]] != "",
               context@setRelationAt[i - 1, j - 1, True]
            ]
        ]
    ];

    Association["context" -> context,
                "model" -> JavaNew["conexp.frontend.ContextDocumentModel", context],
                "attributes" -> attributes,
                "objects" -> objects,
                "objectsByName" -> objectsByName
    ]
  ];

FcaComputeLattice[model_] :=
  Module[
    {
      latticecomp
    },

    model@resetLatticeComponents[];
    latticecomp = model@getLatticeComponent[0];
    latticecomp@calculateLattice[];
    model@findAssociations[];
    model@findImplications[];

    Association["lattice" -> latticecomp@getLattice[],
                "associations" -> model@getAssociationRules[],
                "implications" -> model@getImplications[]
    ]
  ];

(* Convert objects within a Java Set to a Wolfram List *)
javaObjectSetToList[set_, extractor_, iterator_ : set@iterator[]] :=
  Module[
    {
      list = List[],
      element
    },

    While[iterator@hasNext[],
          element = iterator@next[];
          AppendTo[list, extractor[element]]
    ];

    list
  ];

debugAttributeSet[set_, attrs_] :=
  Module[
    { i },

    For[i = 0, i < set@size[], i++,
        If[set@in[i],
           debug[attrs[[i + 1]], ","]
        ]
    ]
  ];

javaGetObjectHash[object_] :=
  ToString[object@hashCode[]];

FcaContextToAssociation[context_, objects_, attributes_] :=
  Module[
    {
      acontext, i, object, attributesList, j, aobject
    },

    acontext = Association[];
    For[i = 0, i < context@getObjectCount[], i++,
        object = context@getObject[i];
        attributesList = List[];
        For[j = 0, j < context@getAttributeCount[], j++,
            If[context@getRelationAt[i, j],
               AppendTo[attributesList, attributes[[j + 1]]]
            ]
        ];
        aobject = Association["name" -> object@getName[],
                              "id" -> objects[[i + 1]],
                              "attributes" -> attributesList];
        AppendTo[acontext, objects[[i + 1]] -> aobject]
    ];

    acontext
  ];

(* Convert the concept table to a List of Associations *)
FcaConceptsToList[concepts_, objects_, attributes_] :=
  Module[
    {
      lconcepts,
      i, concept, intentList, intent,
      j, extentList, extent,
      aconcept
    },

    lconcepts = List[];
    For[i = 0, i < concepts@conceptsCount[], i++,
        concept = concepts@conceptAt[i];
        intentList = List[];
        intent = concept@getAttribs[];
        For[j = 0, j < intent@size[], j++,
            If[intent@in[j],
               AppendTo[intentList, attributes[[j + 1]]]
            ]
        ];
        extentList = List[];
        extent = concept@getObjects[];
        For[j = 0, j < extent@size[], j++,
            If[extent@in[j],
               AppendTo[extentList, objects[[j + 1]]]
            ]
        ];
        aconcept = Association["intent" -> intentList,
                               "extent" -> extentList];
        AppendTo[lconcepts, aconcept];
    ];

    lconcepts
  ];

getAttribName[attribObject_] :=
  attribObject@getName[];

getObjectId[objectsByName_, object_] :=
  objectsByName[[object@getName[]]];

FcaConceptsToAssociationList[concepts_, lconcepts_, objectsByName_] :=
  Module[
    {
      lnodes, i, node, parents, j, children, anode
    },

    lnodes = List[];
    For[i = 0, i < concepts@conceptsCount[], i++,
        node = concepts@conceptAt[i];
        parents = List[];
        For[j = 0, j < node@getSuccCount[], j++,
            AppendTo[parents, javaGetObjectHash[node@getSucc[j]]]
        ];
        children = List[];
        For[j = 0, j < node@getPredCount[], j++,
            AppendTo[children, javaGetObjectHash[node@getPred[j]]]
        ];
        anode = Association[
          "hash" -> javaGetObjectHash[node],
          "idx" -> i,
          "level" -> node@getHeight[],
          "concept" -> lconcepts[[i + 1]],
          "parents" -> parents,
          "children" -> children,
          "labelObjects" -> javaObjectSetToList[False,
                                                Function[obj, getObjectId[objectsByName, obj]],
                                                node@ownObjectsIterator[]],
          "labelAttributes" -> javaObjectSetToList[False,
                                                   getAttribName,
                                                   node@ownAttribsIterator[]]
        ];
        AppendTo[lnodes, anode];
    ];

    lnodes
  ];

FcaGetNodeLinks[lnodes_, anodes_] :=
  Flatten[
    Map[Function[node,
                 Map[Function[childId,
                              Association["source" -> node["idx"],
                                          "target" -> anodes[childId, "idx"]]
                     ],
                     node["children"]]
        ],
        lnodes]
  ];

FcaDebugContext[context_, objects_, attributes_] :=
  Module[
    { i, attribute, object, j },

    debug["Atributos (", context@getAttributeCount[], "): "];
    For[i = 0, i < context@getAttributeCount[], i++,
        attribute = context@getAttribute[i];
        debug[attribute@getName[], ", "]
    ];
    debug["\n\n"];

    debug["Objetos (", context@getObjectCount[], "):\n\n"];
    For[i = 0, i < context@getObjectCount[], i++,
        object = context@getObject[i];
        debug[object@getName[], " (id: ", objects[[i + 1]], ") "];
        For[j = 0, j < context@getAttributeCount[], j++,
            If[context@getRelationAt[i, j],
               debug[attributes[[j + 1]], " "]
            ]
        ];
        debug["\n\n"]
    ];
  ];

FcaDebugConcepts[concepts_, attributes_, objects_] :=
  Module[
    { i, concept, intent, j, extent },

    For[i = 0, i < concepts@conceptsCount[], i++,
        debug["Concept ", i, "\n"];
        concept = concepts@conceptAt[i];

        intent = concept@getAttribs[];
        debug["Intent (size ", intent@length[], "): "];
        For[j = 0, j < intent@size[], j++,
            If[intent@in[j],
               debug[attributes[[j + 1]], " "]
            ]
        ];
        debug["\n"];

        extent = concept@getObjects[];
        debug["Extent (size ", extent@length[], "): "];
        For[j = 0, j < extent@size[], j++,
            If[extent@in[j],
               debug[objects[[j + 1]], " "]
            ]
        ];
        debug["\n\n"];
    ]
  ];

FcaDebugImplications[implications_, attributes_] :=
  Module[
    { i, implication },

    debug["Implications (", implications@getSize[], ")\n"];
    For[i = 0, i < implications@getSize[], i++,
        implication = implications@getDependency[i];
        debug[i, " <", implication@getObjectCount[], "> "];
        debugAttributeSet[implication@getPremise[], attributes];
        debug[" ==> "];
        debugAttributeSet[implication@getConclusion[], attributes];
        debug["\n"];
    ];
    debug["\n"];
  ];

FcaDebugAssociations[associations_, attributes_] :=
  Module[
    { i, association },

    debug["Associations (", associations@getSize[], ")\n"];
    For[i = 0, i < associations@getSize[], i++,
        association = associations@getDependency[i];
        debug[i, " <", association@getPremiseSupport[], "> "];
        debugAttributeSet[association@getPremise[], attributes];
        debug[" [", association@getConfidence[], "] "];
        debug[" ==> "];
        debug[" <", association@getRuleSupport[], "> "];
        debugAttributeSet[association@getConclusion[], attributes];
        debug["\n"];
    ];
  ];

End[];

EndPackage[];
