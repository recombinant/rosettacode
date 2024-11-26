// https://rosettacode.org/wiki/Hierholze%27s_Algorithm
// translated from
// https://algoteka.com/samples/41/hierholzer%2527s-eulerian-cycle-algorithm-c-plus-plus-o%2528m%2529-readable-solution
const std = @import("std");
const mem = std.mem;

const print = std.debug.print;

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var graph1 = try EulerGraph.init(allocator, 3);
    defer graph1.deinit();
    try graph1.addArc(0, 1);
    try graph1.addArc(1, 2);
    try graph1.addArc(2, 0);

    const result1 = try graph1.getEulerianPath(0);
    defer allocator.free(result1);
    printGraph(result1);
    print("\n", .{});

    var graph2 = try EulerGraph.init(allocator, 7);
    defer graph2.deinit();
    try graph2.addArc(0, 1);
    try graph2.addArc(0, 6);
    try graph2.addArc(1, 2);
    try graph2.addArc(2, 0);
    try graph2.addArc(2, 3);
    try graph2.addArc(3, 4);
    try graph2.addArc(4, 2);
    try graph2.addArc(4, 5);
    try graph2.addArc(5, 0);
    try graph2.addArc(6, 4);

    const result2 = try graph2.getEulerianPath(0);
    defer allocator.free(result2);
    printGraph(result2);
    print("\n", .{});
}

fn printGraph(vertices: []usize) void {
    for (vertices, 1..) |vertex, i| {
        print("{}", .{vertex});
        if (i != vertices.len)
            print("->", .{});
    }
}

const EulerGraph = struct {
    allocator: mem.Allocator,
    nodes: []Node,
    arcs: ArcList,

    const ArcPointerList = std.ArrayList(*Arc);

    // Note: pointers to Arc structs within std.SegmentedList are
    // not invalidated if the SegmentedList grows.
    const ArcList = std.SegmentedList(Arc, 256);

    const Arc = struct {
        u: u16,
        v: u16,
    };
    const Node = struct {
        index: usize,
        arcs: ArcPointerList, // Arcs that exit this node
        fn init(allocator: mem.Allocator, index: usize) Node {
            return Node{
                .index = index,
                .arcs = ArcPointerList.init(allocator),
            };
        }
        fn deinit(self: *const Node) void {
            self.arcs.deinit();
        }
    };
    fn init(allocator: mem.Allocator, num_nodes: usize) !EulerGraph {
        const nodes = try allocator.alloc(Node, num_nodes);
        for (nodes, 0..) |*node, i|
            node.* = Node.init(allocator, i);
        return .{
            .allocator = allocator,
            .nodes = nodes,
            .arcs = ArcList{},
        };
    }
    fn deinit(self: *EulerGraph) void {
        for (self.nodes) |node|
            node.deinit();
        self.allocator.free(self.nodes);
    }
    fn addArc(self: *EulerGraph, u: u16, v: u16) !void {
        const arc_ptr = try self.arcs.addOne(self.allocator);
        arc_ptr.* = Arc{ .u = u, .v = v };
        try self.nodes[u].arcs.append(arc_ptr);
    }
    /// Caller owns returned slice
    fn getEulerianPath(self: *EulerGraph, start: usize) ![]usize {
        // The constructed eulerian cycle. Initially reversed
        var eulerian_path = std.ArrayList(usize).init(self.allocator);
        // The current arc we are looking at for each node
        const arc_i = try self.allocator.alloc(usize, self.nodes.len);
        defer self.allocator.free(arc_i);
        @memset(arc_i, 0);
        // The current path we are on
        var node_stack = try NodeStack.init(self.allocator, start);
        defer node_stack.deinit();

        while (node_stack.size() > 0) {
            const node_i: usize = node_stack.top();
            const node = self.nodes[node_i];

            if (arc_i[node_i] < node.arcs.items.len) {
                // We haven't traversed all arcs on that node yet
                try node_stack.push(node.arcs.items[arc_i[node_i]].v);
                arc_i[node_i] += 1;
            } else {
                // We have traversed all arcs for this node, so add the node to Eulerian cycle
                try eulerian_path.append(node_i);
                node_stack.pop();
            }
        }
        mem.reverse(usize, eulerian_path.items);
        return eulerian_path.toOwnedSlice();
    }
};

/// Thin wrapper around std.ArrayList to emulate a stack.
const NodeStack = struct {
    stack: std.ArrayList(usize),

    fn init(allocator: mem.Allocator, start: usize) !NodeStack {
        var stack = std.ArrayList(usize).init(allocator);
        try stack.append(start);
        return NodeStack{
            .stack = stack,
        };
    }
    fn deinit(self: *const NodeStack) void {
        self.stack.deinit();
    }
    fn size(self: *const NodeStack) usize {
        return self.stack.items.len;
    }
    fn push(self: *NodeStack, node: usize) !void {
        try self.stack.append(node);
    }
    fn pop(self: *NodeStack) void {
        _ = self.stack.pop();
    }
    fn top(self: *const NodeStack) usize {
        return self.stack.items[self.stack.items.len - 1];
    }
};
