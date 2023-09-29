(function () {
    function reticulo () {
	function calcDistance (link, i) {
	    var ret = 0;
	    if (link.source && link.source.level)
		ret = link.source.level;
	    return ret * 10;
	}

	function forceTick(link, node) {
	    link.attr("x1", function(d) { return d.source.x; })
		.attr("y1", function(d) { return d.source.y; })
		.attr("x2", function(d) { return d.target.x; })
		.attr("y2", function(d) { return d.target.y; });

	    node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
	}

	function dblclick(d) {
	    window.isDoubleClick = 2;
	    d3.select(this).classed("fixed", d.fixed = !d.fixed);
	}

	function getGraphNodeByHash(hash) {
	    for (let node of graph.nodes) {
		if (node.hash == hash)
		    return node;
	    }
	    console.warn("Node with hash " + hash + " not found!");
	    return undefined;
	}

	function recursiveClass(d, key, className, state) {
	    var ele = d3.select('.node.notvisited[hash="' + d.hash + '"]');

	    if (ele.empty())
		return;

	    ele.classed("notvisited", false);
	    ele.classed(className, state);

	    for (let hash of d[key]) {
		var node = getGraphNodeByHash(hash);

		if (node != undefined) {
		    var link = d3.select('.link[source-hash="' + d.hash + '"][target-hash="' + node.hash + '"]');
		    if (!link.empty())
			link.classed(className, state);
		    var link = d3.select('.link[source-hash="' + node.hash + '"][target-hash="' + d.hash + '"]');
		    if (!link.empty())
			link.classed(className, state);

		    recursiveClass(node, key, className, state);
		}
	    }
	}

	function click(d) {
	    if (window.dragEvent)
		return;

	    window.setTimeout (function () {
		if (window.isDoubleClick) {
		    window.isDoubleClick--;
		    return;
		}
		
		var nodeEles = d3.selectAll(".node");
		nodeEles.classed("inactive", true);
		d3.selectAll(".link").classed("inactive", true);
		
		nodeEles.classed("notvisited", true);
		recursiveClass(d, "children", "inactive", false);
		nodeEles.classed("notvisited", true);
		recursiveClass(d, "parents", "inactive", false);
		nodeEles.classed("notvisited", false);
	    }, 250);
	}

	function dragstart(d) {
	    window.dragEvent = d3.event.sourceEvent;
	    //  d3.select(this).classed("fixed", d.fixed = true);
	}

	function dragend(d) {
	    if (d3.event.sourceEvent.timeStamp - window.dragEvent.timeStamp < 400 &&
		window.dragEvent.clientX - d3.event.sourceEvent.clientX < 5 &&
		window.dragEvent.clientY - d3.event.sourceEvent.clientY < 5)
		// looks like a click. Let the click process it by undefining the drag start event.
		window.dragEvent = undefined;
	    else
		// undefine the drag start event after a timeout so the click event enters first and finds it.
		window.setTimeout (function () { window.dragEvent = undefined; }, 50);
	}

	this.saveJson = function(graph) {
	    if (graph == undefined)
		return;

	    function filter (key, value) {
		switch (key) {
		    //		case 'fixed':
		    /*		case 'px':
				case 'x':
				return value - 358.82019008772886 + 25;
				case 'py':
				case 'y':
				return value - 571.6625302823484 + 75;*/
		    //			return undefined;
		case 'source':
		case 'target':
		    return value.index;
		}
		return value;
	    };

	    var json = JSON.stringify (graph, filter, 4);
	    document.getElementById('output').value = json;
	}

	function editorSetup(activate) {
	    if (!activate) {
		var url = new URL(window.location);
		if (url.hash != '#editor')
		    return;
	    }

	    d3.select("#editor").html('<div class="text-center"><input type="button" value="Save" onclick="Reticulo.saveJson(window.graph)"><textarea id="output"></textarea></div>');
	}

	this.main = function () {
	    editorSetup(this.config.USE_EDITOR);

	    if (!this.config.DESCRIPTIONS_SOURCE)
		this.config.DESCRIPTIONS_SOURCE = "desc.csv";
	    if (!this.config.LATTICE_SOURCE)
		this.config.LATTICE_SOURCE = "lattice.json";
	    
	    var svg = d3.select("#d1").append("svg")
	    svg.attr("xmlns", "http://www.w3.org/2000/svg")
		.attr("viewBox", this.config.VIEWBOX);

	    svg.append("defs")
		.html('<linearGradient id="textbox-bg-gradient" x1="0" x2="0" y1="0" y2="1">' +
		      '<stop class="textbox-bg-stop1" offset="0%"></stop>' +
		      '<stop class="textbox-bg-stop2" offset="100%"></stop>' +
		      '</linearGradient>');

	    var link = svg.selectAll(".link");
	    var node = svg.selectAll(".node");

	    var force = d3.layout.force()
		.charge(-20)
		.chargeDistance(100)
		.linkStrength(this.config.LINK_STRENGTH)
		.linkDistance(calcDistance)
		.friction(0.5)
		.gravity(0)
		.on('tick', function () { forceTick(link, node); });

	    var drag = force.drag()
		.on("dragstart", dragstart)
		.on("dragend", dragend);

	    var that = this;
	    d3.csv(this.config.DESCRIPTIONS_SOURCE,function(error,datos){
		if (error) throw error;

		function getAttrId (attr) {
		    return attr.replace (/[^A-Za-z0-9]/g, "");
		}

		var adata = d3.map(datos, function (ele){return ele.Atributo});

		var attrDesc = d3.select("#attr-desc");
		for (let desc of datos) {
		    attrDesc.append ("div")
			.attr("id", "attr-desc-" + getAttrId (desc.Atributo))
			.html('<span class="attr-desc-ind">' + desc.Independent + '</span>' +
			      '<span class="attr-desc-exp">' + desc.Explanation + '</span>');
		}
		MathJax.Hub.Queue (["Typeset", MathJax.Hub, attrDesc.node ()]);
		
		d3.json(that.config.LATTICE_SOURCE, function(error, graph) {
		    if (error) throw error;

		    window.graph = graph;

		    function appendClave (claveEle, i, desc) {
			claveEle.append("rect")
			    .attr("class", "box-" + desc.key + " textbox-box")
			    .attr("x", 0)
			    .attr("y", i * 32)
			    .attr("width", 50)
			    .attr("height", 25);

			claveEle.append("rect")
			    .attr("class", "textbox-bg")
			    .attr("x", 0)
			    .attr("y", i * 32)
			    .attr("width", 50)
			    .attr("height", 25);

			claveEle.append("text")
			    .attr("class", "textbox-text")
			    .attr("x", 57)
			    .attr("y", i * 32 + 18)
			    .text(desc.desc);
		    }

		    var clave = svg.append("g")
			.attr("class", "clave")
			.attr("transform", "translate(50,110)");

		    for (var i = 0; i < graph.classDescriptions.length; i++)
			appendClave (clave, i, graph.classDescriptions[i]);

		    force
			.nodes(graph.nodes)
			.links(graph.links)
			.start ();

		    link = link.data(graph.links)
			.enter().append(createLink());

		    node = node.data(graph.nodes)
			.enter().append(createNode())
			.on("click", click)
			.on("dblclick", dblclick)
			.call(drag);

		    function createLink() {
			return function(d) {
			    var line = d3.select(document.createElementNS(d3.ns.prefix.svg, "line"))
				.attr("class", "link")
				.attr("source-hash", d.source.hash)
				.attr("target-hash", d.target.hash);
			    return line.node();
			}
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
			    window.setTimeout (function () { textBoxSetBBox(textBox); }, 100);
			}
		    }

		    function createTextBox(eleClass, offset, str) {
			return function(d,i) {
			    
			    var group = d3.select(document.createElementNS(d3.ns.prefix.svg, "g"))
				.attr("transform", "translate(" + offset + ")")
				.attr("class", eleClass);
			    group.append("rect")
				.attr("class", eleClass + "-box textbox-box");
			    group.append("rect")
				.attr("class", "textbox-bg");
			    group.append("text")
				.attr("class", eleClass + "-text textbox-text")
				.text(str);

			    return group.node();
			};
		    }

		    function observeForBBox (textBoxes) {
			var observer = new MutationObserver (
			    function (mutations) {
				for (var i = 0; i < textBoxes.length; i++) {
				    var tb = textBoxes[i];
				    if (document.contains (tb.node())) {
					textBoxSetBBox(tb);
					textBoxes.splice(i, 1);
					if (textBoxes.length == 0) {
					    observer.disconnect ();
					    return;
					}
					i--;
				    }
				}
			    }
			);
			observer.observe (document, 
					  {attributes: false, childList: true, characterData: false, subtree:true});			
		    }

		    function createNode() {
			return function(d) {
			    
			    var group = d3.select(document.createElementNS(d3.ns.prefix.svg, "g"))
				.attr("class", "node")
				.attr("hash", d.hash);

			    var dot = group.append("g")
				.attr("class", "node-dot");

			    dot.append ("circle")
				.attr("class", "node-bg")
				.attr("r", that.config.NODE_RADIUS);

			    if (d.labelAttributes.length > 0) {
				
				dot.append("path")
				    .attr("class", "node-new-attribute")
				    .attr("d","M " + (-that.config.NODE_RADIUS) +
					  " 0 A " + that.config.NODE_RADIUS + " " + that.config.NODE_RADIUS + " 0 0 1 " + that.config.NODE_RADIUS +
					  " 0 Z");

				var x = that.config.LABELS_ORIGIN_X;
				var y = that.config.LABELS_ORIGIN_Y - (that.config.LABELS_HEIGHT / 2) - (that.config.LABELS_SEPARATION * 2);

				var textBoxes = [];
				for (var i = 0; i < d.labelAttributes.length; i++) {
				    
				    var attr = d.labelAttributes[i];
				    var textBox = group.append(
					createTextBox("box-" + graph.classes[attr] +
						      " attributes-label", x + "," + y, attr));

				    textBox.property("atributo", attr);
				    textBox.on("click", darInfo);
				    
				    textBoxes.push (textBox);	
				    y -= that.config.LABELS_HEIGHT + that.config.LABELS_SEPARATION;
				}
				observeForBBox (textBoxes);
			    }

			    if (d.labelObjects.length > 0) {

				y -= that.config.LABELS_SEPARATION;
				dot.append("path")
				    .attr("class", "node-new-object")
				    .attr("d","M " + (-that.config.NODE_RADIUS) +
					  " 0 A " + that.config.NODE_RADIUS +
					  " " + that.config.NODE_RADIUS +
					  " 0 0 0 " + that.config.NODE_RADIUS + " 0 Z");

				var textBoxes = [];
				var x = that.config.LABELS_ORIGIN_X;
				var y = that.config.LABELS_ORIGIN_Y +
				    (that.config.LABELS_HEIGHT / 2) +
				    (that.config.LABELS_SEPARATION * 2);
				for (var i = 0; i < d.labelObjects.length; i++) {
				    var id = d.labelObjects[i];
				    var textBox = group.append(createTextBox("objects-label", x + "," + y, graph.context[id].name));
				    textBoxes.push (textBox);
				    y += that.config.LABELS_HEIGHT - that.config.LABELS_SEPARATION;
				}
				observeForBBox(textBoxes);
			    }
			    
			    dot.append ("circle")
				.attr("class", "node-basic")
				.attr("r", that.config.NODE_RADIUS);
			    
			    //dot.on("click", function () { click (group.node()); });

			    return group.node();
			}
		    }

		    function darInfo(d,i){
			d3.event.stopPropagation();
			
			var attr = d3.event.target.parentNode.atributo;
			var d2 = d3.select("#d2");

			d2.html("");
			
			if (window.info_attr_id && 
			    getAttrId(attr) == window.info_attr_id) {
			    window.info_attr_id = undefined;
			    return;
			}
			window.info_attr_id = getAttrId(attr);

			var rec = adata.get(attr);

			var coordInd = d3.select("#attr-desc-" + getAttrId(attr) + ' .attr-desc-ind').html();
			var exp = d3.select("#attr-desc-" + getAttrId(attr) + ' .attr-desc-exp').html();

			d2.append("h2")
			    .html(coordInd);
			d2.append("p")
			    .html(exp);
		    }
		})
	    });
	}
    };

    var R = window.Reticulo = new reticulo();
} ());
