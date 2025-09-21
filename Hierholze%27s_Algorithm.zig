// https://rosettacode.org/wiki/Hierholze%27s_Algorithm
// {{works with|Zig|0.15.1}}
// translated from
// https://algoteka.com/samples/41/hierholzer%2527s-eulerian-cycle-algorithm-c-plus-plus-o%2528m%2529-readable-solution
const std = @import("std");

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------
    var graph1: EulerGraph = try .init(allocator, 3);
    defer graph1.deinit();
    try graph1.addArc(0, 1);
    try graph1.addArc(1, 2);
    try graph1.addArc(2, 0);

    const result1 = try graph1.getEulerianPath(0);
    defer allocator.free(result1);
    try printGraph(result1, stdout);
    try stdout.writeByte('\n');

    var graph2: EulerGraph = try .init(allocator, 7);
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
    try printGraph(result2, stdout);
    try stdout.writeByte('\n');
    //
    try stdout.flush();
}

fn printGraph(vertices: []usize, w: *std.Io.Writer) !void {
    for (vertices, 1..) |vertex, i| {
        try w.print("{}", .{vertex});
        if (i != vertices.len)
            try w.writeAll("->");
    }
}

const EulerGraph = struct {
    allocator: std.mem.Allocator,
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
        fn init(index: usize) Node {
            return Node{
                .index = index,
                .arcs = .empty,
            };
        }
        fn deinit(self: *Node, allocator: std.mem.Allocator) void {
            self.arcs.deinit(allocator);
        }
    };
    fn init(allocator: std.mem.Allocator, num_nodes: usize) !EulerGraph {
        const nodes = try allocator.alloc(Node, num_nodes);
        for (nodes, 0..) |*node, i|
            node.* = .init(i);
        return .{
            .allocator = allocator,
            .nodes = nodes,
            .arcs = ArcList{},
        };
    }
    fn deinit(self: *EulerGraph) void {
        for (self.nodes) |*node|
            node.deinit(self.allocator);
        self.allocator.free(self.nodes);
    }
    fn addArc(self: *EulerGraph, u: u16, v: u16) !void {
        const arc_ptr = try self.arcs.addOne(self.allocator);
        arc_ptr.* = Arc{ .u = u, .v = v };
        try self.nodes[u].arcs.append(self.allocator, arc_ptr);
    }
    /// Caller owns returned slice
    fn getEulerianPath(self: *EulerGraph, start: usize) ![]usize {
        // The constructed eulerian cycle. Initially reversed
        var eulerian_path: std.ArrayList(usize) = .empty;
        // The current arc we are looking at for each node
        const arc_i = try self.allocator.alloc(usize, self.nodes.len);
        defer self.allocator.free(arc_i);
        @memset(arc_i, 0);
        // The current path we are on
        var node_stack: NodeStack = try .init(self.allocator, start);
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
                try eulerian_path.append(self.allocator, node_i);
                node_stack.pop();
            }
        }
        std.mem.reverse(usize, eulerian_path.items);
        return eulerian_path.toOwnedSlice(self.allocator);
    }
};

/// Thin wrapper around std.ArrayList to emulate a stack.
const NodeStack = struct {
    allocator: std.mem.Allocator,
    stack: std.ArrayList(usize),

    fn init(allocator: std.mem.Allocator, start: usize) !NodeStack {
        var stack: std.ArrayList(usize) = .empty;
        try stack.append(allocator, start);
        return NodeStack{
            .allocator = allocator,
            .stack = stack,
        };
    }
    fn deinit(self: *NodeStack) void {
        self.stack.deinit(self.allocator);
    }
    fn size(self: *const NodeStack) usize {
        return self.stack.items.len;
    }
    fn push(self: *NodeStack, node: usize) !void {
        try self.stack.append(self.allocator, node);
    }
    fn pop(self: *NodeStack) void {
        _ = self.stack.pop();
    }
    fn top(self: *const NodeStack) usize {
        return self.stack.items[self.stack.items.len - 1];
    }
};
