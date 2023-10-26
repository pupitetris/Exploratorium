(function() {

  function reticulo() {

    function calcDistance(link, i) {
      var ret = 0;
      if (link.source && link.source.level)
        ret = link.source.level;
      return ret * 10;
    }

    function forceTick(nodes, links) {
      nodes.attr("transform", function(datum) { return `translate(${datum.x},${datum.y})`; });

      links.attr("x1", function(datum) { return datum.source.x; })
        .attr("y1", function(datum) { return datum.source.y; })
        .attr("x2", function(datum) { return datum.target.x; })
        .attr("y2", function(datum) { return datum.target.y; });
    }

    function getGraphNodeByHash(graph, hash) {
      for (let node of graph.nodes) {
        if (node.hash == hash)
          return node;
      }
      console.warn("Node with hash " + hash + " not found!");
      return undefined;
    }

    function multiClassed(ele, classes) {
      for (let className in classes)
        ele.classed(className, classes[className]);
      return ele;
    }

    function recursiveClassed(graph, datum, keys, classes) {
      var ele = d3.select(`.node.notvisited[hash="${datum.hash}"]`);

      if (ele.empty())
        return;

      ele.classed("notvisited", false);
      multiClassed(ele, classes);

      for (let key of keys) {
        for (let hash of datum[key]) {
          var node = getGraphNodeByHash(graph, hash);

          if (node == undefined)
            continue;

          var link = d3.select(`.link[source-hash="${datum.hash}"][target-hash="${node.hash}"]`);
          if (!link.empty())
            multiClassed(link, classes);
          var link = d3.select(`.link[source-hash="${node.hash}"][target-hash="${datum.hash}"]`);
          if (!link.empty())
            multiClassed(link, classes);

          recursiveClassed(graph, node, [ key ], classes);
        }
      }
    }

    function clearActiveSelection(nodes, links) {
      window.active_node_hash = undefined;
      nodes.classed("inactive active", false);
      links.classed("inactive active", false);
    }

    function nodeDblclick(event, datum) {
      window.isDoubleClick = 2;
      d3.select(this).classed("fixed", datum.fixed = !datum.fixed);
    }

    function nodeClick(event, datum, graph, nodes, links) {
      event.stopPropagation();
      var node = d3.select(event.currentTarget);
      var isInfimum = node.classed("infimum");
      window.setTimeout(function() {
        if (window.isDoubleClick) {
          window.isDoubleClick--;
          return;
        }

        if (isInfimum) {
          if (node.classed("inactive")) {
            node.classed("inactive", false);
            links.filter(".infimum.active").classed("inactive", false);
          } else {
            node.classed("inactive", true);
            links.filter(".infimum.active").classed("inactive", true);
          }
          return;
        }

        if (datum.hash == window.active_node_hash) {
          clearActiveSelection(nodes, links);
          return;
        }
        window.active_node_hash = datum.hash;

        var infimumNode = nodes.filter(".infimum");
        var setInactive = infimumNode.classed("inactive") ||
            (!infimumNode.classed("inactive") && !infimumNode.classed("active"));

        nodes
            .classed("inactive", true)
            .classed("active", false);
        links
          .classed("inactive", true)
          .classed("active", false);

        nodes.classed("notvisited", true);
        recursiveClassed(graph, datum, [ "children", "parents" ],
                       { inactive: false, active: true });
        nodes.classed("notvisited", false);

        if (setInactive) {
          infimumNode.classed("inactive", true);
          links.filter(".infimum.active").classed("inactive", true);
        }
      }, 250);
    }

    function infoboxClosedCB() {
      window.info_attr_id = undefined;
    }

    function htmlIfNotEmpty(ele) {
      if (ele.empty())
        return "";
      return ele.html();
    }

    function attributeClick(event, infobox) {
      event.stopPropagation();

      var attr = event.target.parentNode.attribute;
      var infocont = infobox.select(".cont");

      var attr_id = getAttrId(attr);

      var title = htmlIfNotEmpty(d3.select(`#attr-desc-${attr_id} .attr-desc-title`));

      if (title === "") {
        return;
      }

      if (window.info_attr_id != null &&
          attr_id == window.info_attr_id) {
        floatboxClose(infobox, infoboxClosedCB);
        return;
      }
      window.info_attr_id = attr_id;

      infocont.html("");
      infocont.append("h2")
        .html(title);
      infocont.append("div")
        .classed("formula", true)
        .html(htmlIfNotEmpty(d3.select(`#attr-desc-${attr_id} .attr-desc-formula`)));
      infocont.append("div")
        .classed("exp", true)
        .html(htmlIfNotEmpty(d3.select(`#attr-desc-${attr_id} .attr-desc-exp`)));
      infocont.append("div")
        .classed("ref", true)
        .html(htmlIfNotEmpty(d3.select(`#attr-desc-${attr_id} .attr-desc-ref`)));

      infobox.style("display", "block");
    }

    function createNodeDot(radius, hasAttributes, hasLabelObjects) {
      var dot = d3.select(document.createElementNS(d3.namespaces.svg, "g"))
          .classed("node-dot", true);

      dot
        .append("circle")
        .classed("node-bg", true)
        .attr("r", radius);

      if (hasAttributes) {
        dot.append("path")
          .classed("node-new-attribute", true)
          .attr("d", `M ${-radius} 0 A ${radius} ${radius} 0 0 1 ${radius} 0 Z`);
      }

      if (hasLabelObjects) {
        dot.append("path")
          .classed("node-new-object", true)
          .attr("d", `M ${-radius} 0 A ${radius} ${radius} 0 0 0 ${radius} 0 Z`);
      }

      dot.append("circle")
        .classed("node-basic", true)
        .attr("r", radius);

      return dot.node();
    }

    function createLink(datum) {
      var line = d3.select(document.createElementNS(d3.namespaces.svg, "line"))
          .classed("link", true)
          .attr("source-hash", datum.source.hash)
          .attr("target-hash", datum.target.hash);
      if (datum.target.level == 0)
        line.classed("infimum", true);
      return line.node();
    }

    function textBoxSetBBox(textBox, config) {
      var text = textBox.select("text");
      var rect = textBox.selectAll("rect");

      try {
        var bounds = text.node().getBBox();
        rect.attr("x", bounds.x - config.TEXTBOX_PADDING)
          .attr("y", bounds.y - config.TEXTBOX_PADDING)
          .attr("width", bounds.width + (config.TEXTBOX_PADDING * 2))
          .attr("height", bounds.height + (config.TEXTBOX_PADDING * 2));
      }
      catch (e) {
        window.setTimeout(function() { textBoxSetBBox(textBox); }, 100);
      }
    }

    function createTextBox(eleClass, offsetX, offsetY, text, anchor) {
      var group = d3.select(document.createElementNS(d3.namespaces.svg, "g"))
          .classed(eleClass, true)
          .attr("transform", `translate(${offsetX},${offsetY})`)
          .on("click", eventStop);
      group.append("rect")
        .classed(eleClass + "-box textbox-box", true);
      group.append("rect")
        .classed("textbox-bg", true);
      group.append("text")
        .classed(eleClass + "-text textbox-text", true)
        .attr("text-anchor", anchor)
        .text(text);

      return group.node();
    }

    function svgClick(event, nodes, links) {
      if (event.target.nodeName != "svg")
        return;

      clearActiveSelection(nodes, links);
    }

    function configSetup(config) {
      var url = new URL(window.location);
      config.DIAGRAM =
        url.pathname
        .replace(/\/index.html$/, "")
        .replace(/.*\//, "");

      if (!config.USE_EDITOR &&
          url.hash == "#editor") {
        config.USE_EDITOR = true;
      }

      if (!config.ATTR_DESC_SOURCE)
        config.ATTR_DESC_SOURCE = "attr_desc.csv";
      if (!config.LATTICE_SOURCE)
        config.LATTICE_SOURCE = "lattice.json";
      if (!config.ATTR_CLASS_DESC_SOURCE)
        config.ATTR_CLASS_DESC_SOURCE = "attr_class_desc.csv";
    }

    function saveJson(graph, output) {
      function filter(key, value) {
        switch (key) {
          //    case "fixed":
          /*    case "px":
                case "x":
                return value - 358.82019008772886 + 25;
                case "py":
                case "y":
                return value - 571.6625302823484 + 75;*/
          //      return undefined;
        case "source":
        case "target":
          return value.index;
        }
        return value;
      };

      var json = JSON.stringify(graph, filter, 4);
      output.value = json;
    }

    function editorSetup(editor, activate, diagram, graph, viewBox) {
      editor.style("display", "block");

      var keys = ["txtJson", "btnGet", "btnCopy",
                  "txt_offsetX", "txt_offsetY", "txt_width", "txt_height",
                  "btnViewboxSet"];
      var controls = {};
      editor.selectAll("textarea,button,input").each(function (p, i) {
        controls[keys[i]] = d3.select(this);
      });

      controls.btnGet
        .on("click", () => saveJson(graph, controls.txtJson.node()));

      function btnCopyClicked() {
        var txtJson = controls.txtJson.node();
        txtJson.select();
        navigator.clipboard.writeText(txtJson.value);
      }

      navigator.permissions.query({ name: "clipboard-write" })
        .then(function(result) {
          if (result.state == "granted" ||
              result.state == "prompt") {
            controls.btnCopy.on("click", btnCopyClicked);
          } else {
            controls.btnCopy.attr("disabled", true);
          }
        });

      for (var key in viewBox)
        controls[`txt_${key}`].attr("value", viewBox[key]);

      controls.btnViewboxSet
        .on("click", function() {
          for (var key in viewBox) {
            var ctl = controls[`txt_${key}`];
            var num = parseInt(ctl.property("value"));
            if (isNaN(num)) {
              num = 0;
              ctl.property("value", 0);
            }
            viewBox[key] = num;
          }
          diagram.select("svg")
            .attr("viewBox",
                  [ viewBox.offsetX, viewBox.offsetY,
                    viewBox.width, viewBox.height ]);
        });

      return editor;
    }

    function floatboxClose(floatbox, closeCB) {
      if (closeCB)
        closeCB();
      floatbox.style("display", "none");
    }

    function floatboxSetup(floatbox, closeCB) {
      floatbox.select("button.btn-close")
        .on("click", () => floatboxClose(floatbox, closeCB));

      var orig = { x: 0, y: 0 };

      function dragstart(event, datum) {
        orig.y = event.y - this.offsetTop;
        orig.x = event.x - this.offsetLeft;
        d3.select(this)
          .classed("drag", true);
      }

      function dragged(event, datum) {
        var top = event.y - orig.y;
        var left = event.x - orig.x;

        if (top < - (this.clientHeight / 2))
          return;
        if (left < - (this.clientWidth / 2))
          return;
        if (top > window.innerHeight - (this.clientHeight / 2))
          return;
        if (left > window.innerWidth - (this.clientWidth / 2))
          return;

        floatbox.style("top", top + "px");
        floatbox.style("left", left + "px");
      }

      function dragend(event) {
        d3.select(this)
          .classed("drag", false);
      }

      var drag = d3.drag()
          .on("start", dragstart)
          .on("drag", dragged)
          .on("end", dragend);

      floatbox.call(drag);

      return floatbox;
    }

    function legendSetup(legend, toolbar, classDescriptions) {
      var cont = legend.select(".cont");
      for (const desc of classDescriptions)
        cont.append("div")
        .html(`<span class="figure textbox-box box-${desc.Code}"></span>${desc.Title}`);

      var dotRadius = 20;
      var dots = [
        { dot: createNodeDot(dotRadius, false, false), desc: "FCA simple object" },
        { dot: createNodeDot(dotRadius, true, false), desc: "FCA simple object with new attributes" },
        { dot: createNodeDot(dotRadius, false, true), desc: "FCA concept object" },
        { dot: createNodeDot(dotRadius, true, true), desc: "FCA concept object with new attributes" }
      ];
      for (const dot of dots) {
        var div = cont.append("div");
        var svg = div.append("svg")
            .classed("figure", true)
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .attr("viewBox", [-dotRadius - 5, -dotRadius - 5, dotRadius * 2 + 10, dotRadius * 2 + 10])
            .append(() => dot.dot);
        div.append("span")
          .html(dot.desc);
      }

      floatboxSetup(legend, () => toolbar.select(".bi-info-lg").classed("active", false))
        .style("display", "block");
    }

    function nodeDragSetup(nodes, links, zoom, translateExtents) {
      function dragstart(event, datum) {
        d3.select(this)
          .classed("drag", true);
      }

      function dragged(event, datum) {
        datum.x = event.x;
        datum.y = event.y;

        if (updateExtents(datum.x, datum.y, translateExtents))
          zoom.translateExtent(translateExtents);

        forceTick(nodes, links);
      }

      function dragend(event) {
        d3.select(this)
          .classed("drag", false);
      }

      var drag = d3.drag()
          .on("start", dragstart)
          .on("drag", dragged)
          .on("end", dragend);

      return drag;
    }

    function toolbarFullscreen(shell) {
      if (!document.fullscreenElement)
        shell.node().requestFullscreen();
      else
        document.exitFullscreen();
    }

    function toolbarFullscreenChange(shell, btn) {
      if (document.fullscreenElement) {
        shell.classed("fullscreen", true);
        btn.classed("bi-fullscreen", false);
        btn.classed("bi-fullscreen-exit", true);
      } else {
        shell.classed("fullscreen", false);
        btn.classed("bi-fullscreen-exit", false);
        btn.classed("bi-fullscreen", true);
      }
    }

    function toolbarSetup(shell, svg, zoom, legend) {
      var tb = shell.select(".btn-toolbar");
      tb.select(".bi-zoom-out")
        .on("click", () => svg.transition().call(zoom.scaleBy, 0.5));
      tb.select(".zoom-reset")
        .on("click", () => svg.transition().call(zoom.scaleTo, 1));
      tb.select(".bi-zoom-in")
        .on("click", () => svg.transition().call(zoom.scaleBy, 2));

      var fsbtn = tb.select(".bi-fullscreen");
      fsbtn.on("click", function(event) { toolbarFullscreen(shell); });
      shell.node()
        .addEventListener("fullscreenchange", () => toolbarFullscreenChange(shell, fsbtn));

      tb.select(".bi-info-lg")
        .on("click", (event) =>
          legend.style("display", (d3.select(event.target).classed("active"))? "block": "none"));

      return tb;
    }

    function parseViewBox(str) {
      var vb = str.split(/ *,? +/);
      return {
        offsetX: vb[0],
        offsetY: vb[1],
        width:   vb[2],
        height:  vb[3]
      }
    }

    function updateExtents(x, y, extents) {
      var margin = 100;
      var changed = false;

      if (x < extents[0][0]) {
        extents[0][0] = x - margin;
        changed = true;
      } else if (x > extents[1][0]) {
        extents[1][0] = x + margin;
        changed = true;
      }

      if (y < extents[0][1]) {
        extents[0][1] = y - margin;
        changed = true;
      } else if (y > extents[1][1]) {
        extents[1][1] = y + margin;
        changed = true;
      }

      return changed;
    }

    const char2ent = {
      " ": "",
      "*": "ast",
      "=": "eq",
      "≠": "ne"
    }
    function getAttrId(attr) {
      return attr
        .replace(/&#[0-9]+;|&#x[0-9a-fA-F]+;|&[0-9a-zA-Z]{2,};|./gu, (m) => {
          if (m.length >= 4 && m[0] === "&")
            return m.substr(1, m.length - 2);
          if (m.length === 1) {
            if (char2ent[m] !== undefined)
              return char2ent[m] + "-";
            if (m.match(/[a-zA-Z0-9\s\t\n\r~`!@#$%^&_+(){}[\]/\\,?:;|.-]/))
              return m;
          }
          return `${m.codePointAt(0)}-`;
        })
        .replace(/[^-a-zA-Z0-9]/g, "")
        .replace(/-+/g, "-")
        .replace(/-$/g, "");
    }

    function eventStop(event) {
      event.stopPropagation();
    }

    this.main = function() {
      configSetup(this.config);

      var infobox = floatboxSetup(d3.select("#infobox"), infoboxClosedCB);

      var viewBox = parseViewBox(this.config.VIEWBOX);

      var d1 = d3.select("#d1");
      var svg = d1.append("svg")
          .attr("xmlns", "http://www.w3.org/2000/svg")
          .attr("viewBox", this.config.VIEWBOX);

      svg.append("defs")
        .html('<linearGradient id="textbox-bg-gradient" x1="0" y1="0" x2="0" y2="1">' +
              '<stop class="textbox-bg-stop1" offset="0%"></stop>' +
              '<stop class="textbox-bg-stop2" offset="100%"></stop>' +
              '</linearGradient>');

      var root_group = svg.append("g");
      root_group.attr("transform", d3.zoomIdentity);

      var translateExtents = [[-viewBox.width / 4, -viewBox.height / 4],
                              [viewBox.width * 1.5, viewBox.height * 1.5]];

      var zoom = d3.zoom()
          .translateExtent(translateExtents)
          .scaleExtent([0.5, 4])
          .on("zoom", ({transform}) => root_group.attr("transform", transform));
      svg.call(zoom)
        .on("wheel.zoom", null);

      var legend = d3.select("#legend");
      var toolbar = toolbarSetup(d3.select(d1.node().parentNode), svg, zoom, legend);

      var nodes = root_group.selectAll(".node");
      var links = root_group.selectAll(".link");

      svg.on("click", (event) => svgClick(event, nodes, links));

      var force = d3.forceSimulation()
          .force("link", d3.forceLink()
                 .distance(calcDistance)
                 .strength(this.config.LINK_STRENGTH))
          .force("x", d3.forceX(1).strength(0))
          .force("y", d3.forceY(1).strength(0))
          .velocityDecay(0.5)
          .on("tick", () => forceTick(nodes, links));

      var attrClasses = {};
      var that = this;
      function descCsvLoaded(data, attrDesc) {
        var check = new Map();
        for (let desc of data) {
          var attr_id = getAttrId(desc.Attribute);
          if (check.has(attr_id)) {
            console.warn("Colission between " + check.get(attr_id) + " and " +
                         desc.Attribute + ". attr_id: " + attr_id);
            continue;
          }
          check.set(attr_id, desc.Attribute);

          desc.Explanation = '<p>' + desc.Explanation.replaceAll('<br>', '</p><p>') + '</p>';
          attrDesc.append("div")
            .attr("id", "attr-desc-" + attr_id)
            .html('<span class="attr-desc-title">' + desc.Title + '</span>' +
                  '<span class="attr-desc-formula">' + desc.Formula + '</span>' +
                  '<span class="attr-desc-exp">' + desc.Explanation + '</span>' +
                  '<span class="attr-desc-ref">' + desc.Reference + '</span>');
          attrClasses[desc.Attribute] = desc.Class;
        }
        MathJax.Hub.Queue(["Typeset", MathJax.Hub, attrDesc.node()]);
        d3.json(that.config.LATTICE_SOURCE).then(latticeJsonLoaded);
      }

      d3.dsv("|", this.config.ATTR_CLASS_DESC_SOURCE)
        .then((data) => legendSetup(legend, toolbar, data));

      d3.dsv("|", this.config.ATTR_DESC_SOURCE)
        .then((data) => descCsvLoaded(data, d3.select("#attr-desc")));

      function latticeJsonLoaded(graph) {
        graph.classes = attrClasses;

        if (that.config.USE_EDITOR)
          editorSetup(d3.select("#editor"), d1, graph, viewBox);

        force
          .nodes(graph.nodes)
          .force("link").links(graph.links);
        window.setTimeout(function() { force.stop(); }, 100);

        links = links.data(graph.links)
          .enter().append(createLink);

        nodes = nodes.data(graph.nodes)
          .enter().append(createNode)
          .on("click", (event, datum) => nodeClick(event, datum, graph, nodes, links))
          .on("dblclick", nodeDblclick);

        nodes.call(nodeDragSetup(nodes, links, zoom, translateExtents));

        function observeForBBox(textBoxes) {
          var observer = new MutationObserver(
            function(mutations) {
              for (var i = 0; i < textBoxes.length; i++) {
                var tb = textBoxes[i];
                if (document.contains(tb.node())) {
                  textBoxSetBBox(tb, that.config);
                  textBoxes.splice(i, 1);
                  if (textBoxes.length == 0) {
                    observer.disconnect();
                    return;
                  }
                  i--;
                }
              }
            }
          );
          observer.observe(document,
                           {attributes: false, childList: true, characterData: false, subtree: true});
        }

        function createNode(datum) {
          var group = d3.select(document.createElementNS(d3.namespaces.svg, "g"))
              .classed("node", true)
              .attr("hash", datum.hash);

          if (datum.level == 0)
            group.classed("infimum", true);

          var hasAttributes = datum.labelAttributes.length > 0;
          var hasLabelObjects = datum.labelObjects.length > 0;

          group.append(() => createNodeDot(that.config.NODE_RADIUS, hasAttributes, hasLabelObjects))
              .datum(datum);

          if (hasAttributes) {
            var x = that.config.LABELS_ORIGIN_X;
            var y = that.config.LABELS_ORIGIN_Y -
                (that.config.LABELS_HEIGHT / 2) -
                (that.config.LABELS_SEPARATION * 2);
            var start_y = y;

            var textBoxes = [];
            var numAttributes = datum.labelAttributes.length;
            var column2 = (numAttributes > 9)?
                numAttributes / 2 - 1:
                numAttributes;
            var anchor;
            for (var i = 0; i < numAttributes; i++) {
              if (i > column2 && anchor === undefined) {
                x = -that.config.LABELS_ORIGIN_X;
                y = start_y;
                anchor = "end";
              }
              var attr = datum.labelAttributes[i];

              var attr_id = getAttrId(attr);
              var expNode = d3.select("#attr-desc-" + attr_id + " .attr-desc-exp");
              var eleClass = "box-" + graph.classes[attr];
              var exp = "";
              if (!expNode.empty()) {
                exp = expNode.html();
                eleClass += " hasexp";
              }
              eleClass += " attributes-label";

              var textBox = group
                  .append(() => createTextBox(eleClass, x, y, attr, anchor))
                  .on("click", (event) => attributeClick(event, infobox))
                  .property("attribute", attr);

              textBoxes.push(textBox);
              y -= that.config.LABELS_HEIGHT + that.config.LABELS_SEPARATION;
            }
            observeForBBox(textBoxes);
          }

          if (hasLabelObjects) {
            y -= that.config.LABELS_SEPARATION;

            var textBoxes = [];
            var x = that.config.LABELS_ORIGIN_X;
            var y = that.config.LABELS_ORIGIN_Y +
                (that.config.LABELS_HEIGHT / 2) +
                (that.config.LABELS_SEPARATION * 2);
            for (var i = 0; i < datum.labelObjects.length; i++) {
              var id = datum.labelObjects[i];
              var textBox = group.append(() => createTextBox("objects-label",
                                                             x, y,
                                                             graph.context[id].name));
              textBoxes.push(textBox);
              y += that.config.LABELS_HEIGHT - that.config.LABELS_SEPARATION;
            }
            observeForBBox(textBoxes);
          }

          return group.node();
        }
      }
    }
  }

  window.Reticulo = new reticulo();
} ());
