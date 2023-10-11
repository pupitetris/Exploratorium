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

    function getGraphNodeByHash(hash) {
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

    function recursiveClassed(datum, keys, classes) {
      var ele = d3.select('.node.notvisited[hash="' + datum.hash + '"]');

      if (ele.empty())
        return;

      ele.classed("notvisited", false);
      multiClassed(ele, classes);

      for (let key of keys) {
        for (let hash of datum[key]) {
          var node = getGraphNodeByHash(hash);

          if (node == undefined)
            continue;

          var link = d3.select('.link[source-hash="' + datum.hash + '"][target-hash="' + node.hash + '"]');
          if (!link.empty())
            multiClassed(link, classes);
          var link = d3.select('.link[source-hash="' + node.hash + '"][target-hash="' + datum.hash + '"]');
          if (!link.empty())
            multiClassed(link, classes);

          recursiveClassed(node, [ key ], classes);
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

    function nodeClick(event, datum, nodes, links) {
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
        recursiveClassed(datum, [ "children", "parents" ],
                       { inactive: false, active: true });
        nodes.classed("notvisited", false);

        if (setInactive) {
          infimumNode.classed("inactive", true);
          links.filter(".infimum.active").classed("inactive", true);
        }
      }, 250);
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

    function svgClick(event, nodes, links) {
      if (event.target.nodeName != "svg")
        return;

      clearActiveSelection(nodes, links);
    }

    this.saveJson = function(graph) {
      if (graph == undefined)
        return;

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
      document.getElementById("output").value = json;
    }

    function editorSetup(editor, activate) {
      if (!activate) {
        var url = new URL(window.location);
        if (url.hash != "#editor")
          return;
      }

      editor
        .html('<div class="text-center">' +
              '<input type="button" value="Save" onclick="Reticulo.saveJson(window.graph)">' +
              '<textarea id="output"></textarea>' +
              '</div>');
      return editor;
    }

    function infoboxClosedCB() {
      window.info_attr_id = undefined;
    }

    function floatboxSetup(floatbox, closeCB) {
      floatbox.select("button.btn-close")
        .on("click", () => {
          if (closeCB)
            closeCB();
          floatbox.style("display", "none");
        });

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
          .html(`<span class="textbox-box box-${desc.key}"></span>${desc.desc}`);
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
        offset_x: vb[0],
        offset_y: vb[1],
        width: vb[2],
        height: vb[3]
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

    function getAttrId(attr) {
      return attr
        .toLowerCase()
        .replace(/&#[0-9]+;|&#x[0-9a-fA-F]+;|&[0-9a-zA-Z]{2,};|./gu, (m) => {
          if (m.length >= 4 && m[0] === '&')
            return m.substr(1, m.length - 2);
          if (m.length === 1) {
            if (m === " ")
              return "-";
            if (m.match(/[a-zA-Z0-9\s\t\n\r~`!@#$%^&*_+=(){}[\]/\\,?:;|.-]/))
              return m;
          }
          return `${m.codePointAt(0)}-`;
        })
        .replace(/[^-a-z0-9]/g, "")
        .replace(/-+/g, "-")
        .replace(/-$/g, "");
    }

    function eventStop(event) {
      event.stopPropagation();
    }

    this.main = function() {
      editorSetup(d3.select("#editor"), this.config.USE_EDITOR);

      if (!this.config.DESCRIPTIONS_SOURCE)
        this.config.DESCRIPTIONS_SOURCE = "desc.csv";
      if (!this.config.LATTICE_SOURCE)
        this.config.LATTICE_SOURCE = "lattice.json";

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

      var that = this;
      function csvLoaded(datos, attrDesc) {
        var check = new Map();
        for (let desc of datos) {
          var attr_id = getAttrId(desc.Atributo);
          if (check.has(attr_id)) {
            console.warn("Colission between " + check.get(attr_id) + " and " +
                         desc.Atributo + ". attr_id: " + attr_id);
            continue;
          }
          check.set(attr_id, desc.Atributo);
          attrDesc.append("div")
            .attr("id", "attr-desc-" + attr_id)
            .html('<span class="attr-desc-ind">' + desc.Independent + '</span>' +
                  '<span class="attr-desc-exp">' + desc.Explanation + '</span>');
        }
        MathJax.Hub.Queue(["Typeset", MathJax.Hub, attrDesc.node()]);
        d3.json(that.config.LATTICE_SOURCE).then(latticeJsonLoaded);
      }

      d3.csv(this.config.DESCRIPTIONS_SOURCE)
        .then((data) => csvLoaded(data, d3.select("#attr-desc")));

      function latticeJsonLoaded(graph) {
        window.graph = graph;

        legendSetup(legend, toolbar, graph.classDescriptions);

        force
          .nodes(graph.nodes)
          .force("link").links(graph.links);
        window.setTimeout(function() { force.stop(); }, 100);

        links = links.data(graph.links)
          .enter().append(createLink);

        nodes = nodes.data(graph.nodes)
          .enter().append(createNode)
          .on("click", (event, datum) => nodeClick(event, datum, nodes, links))
          .on("dblclick", nodeDblclick);

        nodes.call(nodeDragSetup(nodes, links, zoom, translateExtents));

        function createLink(datum) {
          var line = d3.select(document.createElementNS(d3.namespaces.svg, "line"))
              .attr("class", "link")
              .attr("source-hash", datum.source.hash)
              .attr("target-hash", datum.target.hash);
          if (datum.target.level == 0)
            line.classed("infimum", true);
          return line.node();
        }

        function textBoxSetBBox(textBox) {
          var text = textBox.select("text");
          var rect = textBox.selectAll("rect");

          try {
            var bounds = text.node().getBBox();
            rect.attr("x", bounds.x - that.config.TEXTBOX_PADDING)
              .attr("y", bounds.y - that.config.TEXTBOX_PADDING)
              .attr("width", bounds.width + (that.config.TEXTBOX_PADDING * 2))
              .attr("height", bounds.height + (that.config.TEXTBOX_PADDING * 2));
          }
          catch (e) {
            window.setTimeout(function() { textBoxSetBBox(textBox); }, 100);
          }
        }

        function createTextBox(eleClass, offset_x, offset_y, text) {
          var group = d3.select(document.createElementNS(d3.namespaces.svg, "g"))
              .attr("transform", `translate(${offset_x},${offset_y})`)
              .attr("class", eleClass)
              .on("click", eventStop);
          group.append("rect")
            .attr("class", eleClass + "-box textbox-box");
          group.append("rect")
            .attr("class", "textbox-bg");
          group.append("text")
            .attr("class", eleClass + "-text textbox-text")
            .text(text);

          return group.node();
        }

        function observeForBBox(textBoxes) {
          var observer = new MutationObserver(
            function(mutations) {
              for (var i = 0; i < textBoxes.length; i++) {
                var tb = textBoxes[i];
                if (document.contains(tb.node())) {
                  textBoxSetBBox(tb);
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
              .attr("class", "node")
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

            var textBoxes = [];
            for (var i = 0; i < datum.labelAttributes.length; i++) {
              var attr = datum.labelAttributes[i];

              var attr_id = getAttrId(attr);
              var expNode = d3.select("#attr-desc-" + attr_id + " .attr-desc-exp");
              var exp = '';
              if (!expNode.empty())
                exp = expNode.html();
              var eleClass = "box-" + graph.classes[attr];
              if (exp != '')
                eleClass += " hasexp";
              eleClass += " attributes-label"

              var textBox = group
                  .append(() => createTextBox(eleClass, x, y, attr))
                  .on("click", darInfo)
                  .property("atributo", attr);

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

        function darInfo(event) {
          event.stopPropagation();

          var attr = event.target.parentNode.atributo;
          var infocont = infobox.select(".cont");

          var attr_id = getAttrId(attr);

          var coordInd = d3.select("#attr-desc-" + attr_id + " .attr-desc-ind");
          var exp = d3.select("#attr-desc-" + attr_id + " .attr-desc-exp");

          if (!coordInd || coordInd.empty() || coordInd.html() == '' ||
              !exp || exp.empty() || exp.html() == '') {
            return;
          }

          if (window.info_attr_id != null &&
              attr_id == window.info_attr_id) {
            closeInfoBox();
            return;
          }
          window.info_attr_id = attr_id;

          infocont.html("");
          infocont.append("h2")
            .html(coordInd.html());
          infocont.append("p")
            .html(exp.html());

          infobox.style("display", "block");
        }
      }
    }
  }

  window.Reticulo = new reticulo();
} ());
