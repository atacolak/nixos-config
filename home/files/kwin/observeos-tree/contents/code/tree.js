.pragma library

var workspace = null;
var qt = null;
var root = null;
var cursor = null;
var pendingSplit = null;
var lastSeq = -1;
var layoutScope = "unknown";
var cmdPath = "__OBSERVEOS_CMD_PATH__";

function init(ws, qtObj) {
    workspace = ws;
    qt = qtObj;
    print("OBSERVEOS_TREE: init " + cmdPath);
}

function tick(ws, qtObj) {
    workspace = ws;
    qt = qtObj;
    var raw = readCmd();
    if (!raw) {
        return;
    }
    var msg = null;
    try {
        msg = JSON.parse(raw);
    } catch (err) {
        return;
    }
    if (msg.seq === lastSeq) {
        return;
    }
    lastSeq = msg.seq;
    var out = {seq: msg.seq, ok: false, op: msg.op || "", detail: "", tree: null};
    try {
        var handled = handle(msg);
        out.ok = !!handled.ok;
        out.op = handled.op || out.op;
        out.detail = handled.detail || "";
        out.tree = handled.tree || inspectPayload();
    } catch (err) {
        out.ok = false;
        out.detail = String(err);
        out.tree = inspectPayload();
    }
    print("OBSERVEOS_TREE_RESULT:" + JSON.stringify(out));
}

function readCmd() {
    if (!cmdPath || cmdPath.indexOf("__OBSERVEOS") === 0) {
        return "";
    }
    try {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + cmdPath, false);
        xhr.send();
        if (xhr.responseText) {
            return xhr.responseText;
        }
    } catch (err) {
        print("OBSERVEOS_TREE_READERR:" + err);
    }
    return "";
}

function handle(msg) {
    ensureTree();
    var op = msg.op;
    if (op === "split") {
        return doSplit(msg.direction);
    }
    if (op === "attach") {
        return doAttach(msg.window_id, msg.caption || "");
    }
    if (op === "ensure") {
        applyLayout();
        return {ok: true, op: "ensure"};
    }
    if (op === "focus_parent") {
        return doFocusParent();
    }
    if (op === "focus_child") {
        return doFocusChild();
    }
    if (op === "set_layout") {
        return doSetLayout(msg.kind);
    }
    if (op === "move") {
        return doMove(msg.direction);
    }
    if (op === "resize") {
        return doResize(msg.direction, msg.step);
    }
    if (op === "close_leaf") {
        return doCloseLeaf();
    }
    if (op === "inspect") {
        applyLayout();
        return {ok: true, op: "inspect", tree: inspectPayload()};
    }
    return {ok: false, op: op, detail: "unknown op"};
}

function doSplit(direction) {
    if (direction !== "horizontal" && direction !== "vertical") {
        return {ok: false, op: "split(" + direction + ")", detail: "unknown direction"};
    }
    pendingSplit = direction;
    return {ok: true, op: "split(" + direction + ")"};
}

function doAttach(windowId, caption) {
    if (!windowId) {
        return {ok: false, op: "attach", detail: "missing window"};
    }
    ensureTree();
    if (knownIds(root).indexOf(windowId) === -1) {
        insertWindow(windowId, caption);
    }
    pendingSplit = null;
    applyLayout();
    return {ok: true, op: "spawn_at_focused(" + caption + ")", detail: windowId};
}

function doFocusParent() {
    if (!cursor) {
        return {ok: false, op: "focus_parent", detail: "no cursor"};
    }
    if (!cursor.parent) {
        applyLayout();
        return {ok: true, op: "focus_parent", detail: "already root"};
    }
    cursor = cursor.parent;
    applyLayout();
    return {ok: true, op: "focus_parent"};
}

function doFocusChild() {
    if (!cursor) {
        return {ok: false, op: "focus_child", detail: "no cursor"};
    }
    if (cursor.kind === "leaf") {
        applyLayout();
        return {ok: true, op: "focus_child", detail: "already leaf"};
    }
    if (!cursor.children || !cursor.children.length) {
        return {ok: false, op: "focus_child", detail: "empty container"};
    }
    var idx = Math.min(Math.max(cursor.selected || 0, 0), cursor.children.length - 1);
    cursor = cursor.children[idx];
    applyLayout();
    return {ok: true, op: "focus_child"};
}

function doSetLayout(kind) {
    if (kind !== "tabbed" && kind !== "stacked") {
        return {ok: false, op: "set_layout(" + kind + ")", detail: "unknown layout"};
    }
    var node = cursor;
    if (!node) {
        return {ok: false, op: "set_layout(" + kind + ")", detail: "no cursor"};
    }
    if (node.kind === "leaf" && node.parent) {
        node = node.parent;
    }
    if (node.kind === "leaf") {
        return {ok: false, op: "set_layout(" + kind + ")", detail: "no container"};
    }
    node.kind = kind === "tabbed" ? "tabs" : "stack";
    cursor = node;
    layoutScope = "subtree";
    applyLayout();
    return {ok: true, op: "set_layout(" + kind + ")", detail: "subtree"};
}

function doMove(direction) {
    var target = focusedLeaf();
    if (!target || !target.parent) {
        return {ok: false, op: "move(" + direction + ")", detail: "no sibling container"};
    }
    var parent = target.parent;
    var idx = parent.children.indexOf(target);
    var delta = indexDelta(direction, parent.direction || "horizontal");
    if (delta === null) {
        return {ok: false, op: "move(" + direction + ")", detail: "direction does not match split"};
    }
    var other = idx + delta;
    if (other < 0 || other >= parent.children.length) {
        return {ok: false, op: "move(" + direction + ")", detail: "no neighbor"};
    }
    var tmp = parent.children[idx];
    parent.children[idx] = parent.children[other];
    parent.children[other] = tmp;
    cursor = target;
    applyLayout();
    return {ok: true, op: "move(" + direction + ")"};
}

function doResize(direction, step) {
    var target = focusedLeaf();
    if (!target || !target.parent) {
        return {ok: false, op: "resize", detail: "no split parent"};
    }
    var parent = target.parent;
    while (parent && parent.kind !== "split") {
        parent = parent.parent;
    }
    if (!parent || parent.children.length < 2) {
        return {ok: false, op: "resize", detail: "no split parent"};
    }
    var child = target;
    while (child.parent !== parent) {
        if (!child.parent) {
            return {ok: false, op: "resize", detail: "orphaned"};
        }
        child = child.parent;
    }
    var idx = parent.children.indexOf(child);
    var axis = parent.direction || "horizontal";
    var grow = growIndex(direction, axis);
    if (grow === null) {
        return {ok: false, op: "resize", detail: "direction does not match split"};
    }
    var neighbor = idx + grow;
    if (neighbor < 0 || neighbor >= parent.children.length) {
        neighbor = idx - grow;
    }
    if (neighbor < 0 || neighbor >= parent.children.length) {
        return {ok: false, op: "resize", detail: "no neighbor"};
    }
    assignAreas(root, screenRect());
    var area = parent.area;
    var span = axis === "horizontal" ? area.width : area.height;
    if (!span) {
        return {ok: false, op: "resize", detail: "empty parent extent"};
    }
    if (!parent.weights || parent.weights.length !== parent.children.length) {
        parent.weights = parent.children.map(function () { return 1.0; });
    }
    var sizes = splitSizes(parent.weights, span, axis);
    var amount = Math.abs(step);
    sizes[idx] += amount;
    sizes[neighbor] -= amount;
    if (sizes[idx] < 1 || sizes[neighbor] < 1) {
        return {ok: false, op: "resize", detail: "cannot apply pixel step"};
    }
    parent.weights = sizes.map(function (n) { return n; });
    applyLayout();
    return {ok: true, op: "resize(" + direction + "," + step + ")"};
}

function doCloseLeaf() {
    var target = focusedLeaf();
    if (!target || !target.window_id) {
        return {ok: false, op: "close_leaf", detail: "no focused leaf"};
    }
    var windowId = target.window_id;
    var win = findWindow(windowId);
    if (win) {
        win.closeWindow();
    }
    removeNode(target);
    applyLayout();
    return {ok: true, op: "close_leaf", detail: windowId};
}

function ensureTree() {
    var windows = visibleWindows();
    var known = knownIds(root);
    var unmanaged = [];
    for (var i = 0; i < windows.length; i++) {
        if (known.indexOf(windows[i].id) === -1) {
            unmanaged.push(windows[i]);
        }
    }
    if (!root) {
        if (!unmanaged.length) {
            return;
        }
        if (unmanaged.length === 1) {
            root = makeLeaf(unmanaged[0].id, unmanaged[0].caption);
        } else {
            var nodes = [];
            for (var n = 0; n < unmanaged.length; n++) {
                nodes.push(makeLeaf(unmanaged[n].id, unmanaged[n].caption));
            }
            root = {
                kind: "split",
                direction: "horizontal",
                weights: nodes.map(function () { return 1.0; }),
                children: nodes,
                parent: null,
                selected: 0
            };
            for (var p = 0; p < nodes.length; p++) {
                nodes[p].parent = root;
            }
        }
        cursor = firstLeaf(root);
        return;
    }
    for (var u = 0; u < unmanaged.length; u++) {
        insertWindow(unmanaged[u].id, unmanaged[u].caption);
    }
}

function insertWindow(windowId, caption) {
    var newNode = makeLeaf(windowId, caption);
    if (!root) {
        root = newNode;
        cursor = newNode;
        return;
    }
    var direction = pendingSplit || "vertical";
    var target = cursor || firstLeaf(root);
    if (!target) {
        root = newNode;
        cursor = newNode;
        return;
    }
    if (target.kind !== "leaf") {
        var child = firstLeaf(target) || target;
        if (child.kind === "leaf") {
            target = child;
        }
    }
    var container = splitLeaf(target, direction, newNode);
    if (root === target || root.kind === "leaf") {
        root = container;
    }
    cursor = newNode;
}

function splitLeaf(target, direction, newLeaf) {
    var container = {
        kind: "split",
        direction: direction,
        weights: [0.5, 0.5],
        children: [target, newLeaf],
        parent: target.parent || null,
        selected: 0
    };
    newLeaf.parent = container;
    var parent = target.parent;
    target.parent = container;
    if (!parent) {
        container.parent = null;
        return container;
    }
    var idx = parent.children.indexOf(target);
    parent.children[idx] = container;
    return container;
}

function removeNode(node) {
    var parent = node.parent;
    if (!parent) {
        root = null;
        cursor = null;
        return;
    }
    var idx = parent.children.indexOf(node);
    var nextChildren = [];
    var nextWeights = [];
    for (var i = 0; i < parent.children.length; i++) {
        if (parent.children[i] !== node) {
            nextChildren.push(parent.children[i]);
            if (parent.weights && i < parent.weights.length) {
                nextWeights.push(parent.weights[i]);
            }
        }
    }
    parent.children = nextChildren;
    if (parent.weights) {
        parent.weights = nextWeights.length === parent.children.length
            ? nextWeights
            : parent.children.map(function () { return 1.0; });
    }
    if (parent.children.length === 1) {
        var survivor = parent.children[0];
        var grand = parent.parent;
        survivor.parent = grand || null;
        if (!grand) {
            root = survivor;
        } else {
            var gidx = grand.children.indexOf(parent);
            if (gidx >= 0) {
                grand.children[gidx] = survivor;
            }
        }
        cursor = firstLeaf(survivor) || survivor;
        return;
    }
    if (parent.children.length) {
        cursor = firstLeaf(parent.children[0]) || parent;
    } else {
        cursor = parent.parent || parent;
    }
}

function applyLayout() {
    var area = screenRect();
    var placements = [];
    layoutNode(root, area, placements);
    for (var i = 0; i < placements.length; i++) {
        var item = placements[i];
        var win = findWindow(item.id);
        if (!win) {
            continue;
        }
        setGeom(win, item.x, item.y, item.width, item.height, item.minimized);
    }
    var focus = focusedLeaf();
    if (focus && focus.window_id) {
        var fw = findWindow(focus.window_id);
        if (fw) {
            workspace.activeWindow = fw;
        }
    }
}

function layoutNode(node, area, out) {
    if (!node) {
        return;
    }
    node.area = area;
    if (node.kind === "leaf") {
        if (node.window_id) {
            out.push({
                id: node.window_id,
                x: area.x,
                y: area.y,
                width: area.width,
                height: area.height,
                minimized: false
            });
        }
        return;
    }
    if (!node.children || !node.children.length) {
        return;
    }
    if (node.kind === "tabs" || node.kind === "stack") {
        var selected = Math.min(Math.max(node.selected || 0, 0), node.children.length - 1);
        if (node.kind === "stack") {
            var strip = 24;
            for (var i = 0; i < node.children.length; i++) {
                if (i === selected) {
                    layoutNode(node.children[i], {
                        x: area.x,
                        y: area.y + strip * node.children.length,
                        width: area.width,
                        height: Math.max(1, area.height - strip * node.children.length)
                    }, out);
                } else {
                    layoutNode(node.children[i], {
                        x: area.x,
                        y: area.y + strip * i,
                        width: area.width,
                        height: strip
                    }, out);
                }
            }
            return;
        }
        for (var t = 0; t < node.children.length; t++) {
            var start = out.length;
            layoutNode(node.children[t], area, out);
            if (t !== selected) {
                for (var u = start; u < out.length; u++) {
                    out[u].minimized = true;
                }
            }
        }
        return;
    }
    var weights = node.weights && node.weights.length === node.children.length
        ? node.weights
        : node.children.map(function () { return 1.0; });
    var rects = splitRects(area, node.direction || "horizontal", weights);
    for (var k = 0; k < node.children.length; k++) {
        layoutNode(node.children[k], rects[k], out);
    }
}

function assignAreas(node, area) {
    if (!node) {
        return;
    }
    node.area = area;
    if (node.kind === "split" && node.children && node.children.length) {
        var weights = node.weights && node.weights.length === node.children.length
            ? node.weights
            : node.children.map(function () { return 1.0; });
        var rects = splitRects(area, node.direction || "horizontal", weights);
        for (var i = 0; i < node.children.length; i++) {
            assignAreas(node.children[i], rects[i]);
        }
        return;
    }
    if (node.children) {
        for (var j = 0; j < node.children.length; j++) {
            assignAreas(node.children[j], area);
        }
    }
}

function splitRects(area, direction, weights) {
    var count = weights.length;
    var total = 0;
    for (var i = 0; i < count; i++) {
        total += weights[i];
    }
    if (!total) {
        total = count;
    }
    var rects = [];
    if (direction === "vertical") {
        var y = area.y;
        var remaining = area.height;
        for (var v = 0; v < count; v++) {
            var height = v === count - 1 ? remaining : Math.max(1, Math.round(area.height * (weights[v] / total)));
            height = Math.min(height, remaining);
            remaining -= height;
            rects.push({x: area.x, y: y, width: area.width, height: height});
            y += height;
        }
        return rects;
    }
    var x = area.x;
    var remainingW = area.width;
    for (var h = 0; h < count; h++) {
        var width = h === count - 1 ? remainingW : Math.max(1, Math.round(area.width * (weights[h] / total)));
        width = Math.min(width, remainingW);
        remainingW -= width;
        rects.push({x: x, y: area.y, width: width, height: area.height});
        x += width;
    }
    return rects;
}

function splitSizes(weights, span, direction) {
    var rects = splitRects({x: 0, y: 0, width: span, height: span}, direction, weights);
    var out = [];
    for (var i = 0; i < rects.length; i++) {
        out.push(direction === "vertical" ? rects[i].height : rects[i].width);
    }
    return out;
}

function setGeom(win, x, y, width, height, minimized) {
    try {
        if (win.tile) {
            win.tile = null;
        }
    } catch (err) {}
    if (minimized) {
        win.minimized = true;
        if (qt && qt.rect) {
            win.frameGeometry = qt.rect(-20000, -20000, 16, 16);
        } else {
            win.frameGeometry = {x: -20000, y: -20000, width: 16, height: 16};
        }
        return;
    }
    win.minimized = false;
    if (qt && qt.rect) {
        win.frameGeometry = qt.rect(x, y, width, height);
    } else {
        win.frameGeometry = {x: x, y: y, width: width, height: height};
    }
}

function screenRect() {
    try {
        var screens = workspace.screens;
        if (screens && screens.length) {
            var g = screens[0].geometry;
            return {x: g.x, y: g.y, width: g.width, height: g.height};
        }
    } catch (err) {}
    return {x: 0, y: 0, width: 1280, height: 720};
}

function listWindows() {
    if (!workspace) {
        return [];
    }
    if (workspace.windows) {
        return toArray(workspace.windows);
    }
    if (workspace.windowList) {
        return toArray(workspace.windowList);
    }
    if (workspace.stackingOrder) {
        return toArray(workspace.stackingOrder);
    }
    if (typeof workspace.clientList === "function") {
        return toArray(workspace.clientList);
    }
    return [];
}

function toArray(list) {
    if (!list) {
        return [];
    }
    if (typeof list === "function") {
        try {
            list = list.call(workspace);
        } catch (err) {
            return [];
        }
    }
    var out = [];
    var len = list.length;
    if (typeof len !== "number") {
        return out;
    }
    for (var i = 0; i < len; i++) {
        out.push(list[i]);
    }
    return out;
}

function findWindow(id) {
    var windows = listWindows();
    for (var i = 0; i < windows.length; i++) {
        if (String(windows[i].internalId) === id) {
            return windows[i];
        }
    }
    return null;
}

function visibleWindows() {
    var windows = listWindows();
    var out = [];
    for (var i = 0; i < windows.length; i++) {
        var w = windows[i];
        var g = w.frameGeometry;
        if (g && g.width > 0 && g.height > 0) {
            out.push({id: String(w.internalId), caption: String(w.caption)});
        }
    }
    return out;
}

function makeLeaf(windowId, caption) {
    return {
        kind: "leaf",
        window_id: windowId,
        caption: caption || "",
        children: [],
        parent: null,
        selected: 0,
        weights: []
    };
}

function firstLeaf(node) {
    if (!node) {
        return null;
    }
    if (node.kind === "leaf") {
        return node;
    }
    if (!node.children || !node.children.length) {
        return null;
    }
    var idx = Math.min(Math.max(node.selected || 0, 0), node.children.length - 1);
    return firstLeaf(node.children[idx]);
}

function focusedLeaf() {
    if (!cursor) {
        return null;
    }
    if (cursor.kind === "leaf") {
        return cursor;
    }
    return firstLeaf(cursor);
}

function knownIds(node) {
    var ids = [];
    collectIds(node, ids);
    return ids;
}

function collectIds(node, ids) {
    if (!node) {
        return;
    }
    if (node.kind === "leaf" && node.window_id) {
        ids.push(node.window_id);
        return;
    }
    if (!node.children) {
        return;
    }
    for (var i = 0; i < node.children.length; i++) {
        collectIds(node.children[i], ids);
    }
}

function toDict(node) {
    if (!node) {
        return null;
    }
    var children = [];
    if (node.children) {
        for (var i = 0; i < node.children.length; i++) {
            children.push(toDict(node.children[i]));
        }
    }
    return {
        kind: node.kind,
        direction: node.direction || null,
        window_id: node.window_id || null,
        caption: node.caption || "",
        selected: node.selected || 0,
        children: children
    };
}

function hasSplit(node, direction) {
    if (!node) {
        return false;
    }
    if (node.kind === "split" && node.direction === direction) {
        return true;
    }
    if (!node.children) {
        return false;
    }
    for (var i = 0; i < node.children.length; i++) {
        if (hasSplit(node.children[i], direction)) {
            return true;
        }
    }
    return false;
}

function inspectPayload() {
    return {
        backend: "observeos-tree",
        root: toDict(root),
        local_vertical_split: hasSplit(root, "vertical"),
        local_horizontal_split: hasSplit(root, "horizontal"),
        layout_scope: layoutScope,
        missing: []
    };
}

function indexDelta(direction, splitDirection) {
    if (splitDirection === "horizontal" && direction === "right") {
        return 1;
    }
    if (splitDirection === "horizontal" && direction === "left") {
        return -1;
    }
    if (splitDirection === "vertical" && direction === "down") {
        return 1;
    }
    if (splitDirection === "vertical" && direction === "up") {
        return -1;
    }
    if (direction === "right") {
        return 1;
    }
    if (direction === "left") {
        return -1;
    }
    return null;
}

function growIndex(direction, splitDirection) {
    if (splitDirection === "horizontal") {
        if (direction === "right") {
            return 1;
        }
        if (direction === "left") {
            return -1;
        }
        return 1;
    }
    if (direction === "down") {
        return 1;
    }
    if (direction === "up") {
        return -1;
    }
    return 1;
}
