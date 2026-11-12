// https://rosettacode.org/wiki/Borůvka_algorithm
// {{works with|Zig|0.17.1}}
// {{trans|Crow}}
// Copied from rosettacode and tweaked.
// OOM means "out of memory". An irrecoverable error.
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Io = std.Io;
const Writer = Io.Writer;

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;
    const io: Io = init.io;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    try runTaskExample(allocator, stdout);
    try stdout.writeByte('\n');

    // The seven-town graph of Wikipedia's Kruskal and Prim articles.
    try runByStages(
        allocator,
        "Towns A to G, by stages:",
        &.{ 'A', 'B', 'C', 'D', 'E', 'F', 'G' },
        &.{ .{ .u = 0, .v = 1, .weight = 7 }, .{ .u = 0, .v = 3, .weight = 5 }, .{ .u = 1, .v = 2, .weight = 8 }, .{ .u = 1, .v = 3, .weight = 9 }, .{ .u = 1, .v = 4, .weight = 7 }, .{ .u = 2, .v = 4, .weight = 5 }, .{ .u = 3, .v = 4, .weight = 15 }, .{ .u = 3, .v = 5, .weight = 6 }, .{ .u = 4, .v = 5, .weight = 8 }, .{ .u = 4, .v = 6, .weight = 9 }, .{ .u = 5, .v = 6, .weight = 11 } },
        stdout,
    );
    try stdout.writeByte('\n');

    try runByStages(
        allocator,
        "Two islands (a minimum spanning forest):",
        &.{ 'P', 'Q', 'R', 'S', 'T' },
        &.{ .{ .u = 0, .v = 1, .weight = 3 }, .{ .u = 1, .v = 2, .weight = 1 }, .{ .u = 0, .v = 2, .weight = 2 }, .{ .u = 3, .v = 4, .weight = 7 } },
        stdout,
    );
    // ----------------------------------------------------------
    try stdout.flush();
}

fn runTaskExample(allocator: Allocator, w: *Writer) !void {
    const edges: []const Edge = &.{ .{ .u = 0, .v = 1, .weight = 10.0 }, .{ .u = 0, .v = 2, .weight = 6.0 }, .{ .u = 0, .v = 3, .weight = 5.0 }, .{ .u = 1, .v = 3, .weight = 15.0 }, .{ .u = 2, .v = 3, .weight = 4.0 } };
    const picks = evaluateBoruvkaMST(allocator, 4, edges);
    defer allocator.free(picks);

    for (picks) |p|
        try w.print("Edge {}--{} with weight {} is included in the minimum spanning tree\n", .{ p.edge.u, p.edge.v, p.edge.weight });
    try w.print("Weight of minimum spanning tree is {}\n", .{calcTotalWeight(picks)});
}

fn runByStages(allocator: Allocator, title: []const u8, names: []const u8, edges: []const Edge, w: *Writer) !void {
    try w.print("{s}\n", .{title});
    var stage: u16 = 0;

    const picks = evaluateBoruvkaMST(allocator, names.len, edges);
    defer allocator.free(picks);
    for (picks) |p| {
        if (p.stage != stage) {
            stage = p.stage;
            try w.print("  Stage {}:\n", .{stage});
        }
        try w.print("    {c}-{c} ({})\n", .{ names[p.edge.u], names[p.edge.v], p.edge.weight });
    }
    try w.print("  {} edges of weight {} in all: ", .{ picks.len, calcTotalWeight(picks) });

    const trees = names.len - picks.len;
    if (trees == 1)
        try w.writeAll("one tree\n")
    else
        try w.print("{} trees\n", .{trees});
}

// Each stage finds, for every tree of the forest, its cheapest edge to another
// tree (ties broken by the edge's place in the list, so no cycle can form),
// then adds those edges, joining trees through a union-find by rank, until one
// tree is left.

const Edge = struct {
    u: u16,
    v: u16,
    weight: f64,
};
const Forest = struct {
    parent: []u16,
    rank: []u16,

    fn init(allocator: Allocator, n: usize) Forest {
        const parent = allocator.alloc(u16, n) catch @panic("OOM");
        const rank = allocator.alloc(u16, n) catch @panic("OOM");

        // Initialize parent slice (each vertex is its own parent)
        for (parent, 0..) |*p, i|
            p.* = @truncate(i);
        @memset(rank, 0);

        return .{ .parent = parent, .rank = rank };
    }
    fn deinit(self: *const Forest, allocator: Allocator) void {
        allocator.free(self.parent);
        allocator.free(self.rank);
    }
    /// The trees of roots a and b made one, the lower-ranked under the other.
    fn joined(self: *Forest, a: u16, b: u16) void {
        switch (std.math.order(self.rank[a], self.rank[b])) {
            .lt => self.parent[a] = b,
            .gt => self.parent[b] = a,
            .eq => {
                self.parent[b] = a;
                self.rank[a] = self.rank[a] + 1;
            },
        }
    }
};
const Pick = struct {
    stage: u16,
    edge: *const Edge,
};

fn root(parent: []const u16, x_: u16) u16 {
    var x = x_;
    while (parent[x] != x)
        x = parent[x];
    return x;
}

/// Caller owns returned slice memory
fn findCheapestEdges(allocator: Allocator, f: Forest, edges: []const Edge) []const ?usize {
    var cheapest = allocator.alloc(?usize, f.parent.len) catch @panic("OOM");
    @memset(cheapest, null);

    for (edges, 0..) |e, i| {
        const a = root(f.parent, e.u);
        const b = root(f.parent, e.v);
        if (a != b) {
            if (cheapest[a] == null or edges[cheapest[a].?].weight > e.weight)
                cheapest[a] = i;
            if (cheapest[b] == null or edges[cheapest[b].?].weight > e.weight)
                cheapest[b] = i;
        }
    }
    return cheapest;
}

/// Returns the edges of a minimum spanning tree (a forest, if the graph falls apart),
/// each with the stage that added it.
///
/// Caller owns returned slice memory.
fn evaluateBoruvkaMST(allocator: Allocator, n: usize, edges: []const Edge) []Pick {
    var f: Forest = .init(allocator, n);
    defer f.deinit(allocator);
    var picks: ArrayList(Pick) = .empty; // note: toOwnedSlice()
    var trees = n;
    var stage: u16 = 0;

    var grown = true;
    while (trees > 1 and grown) {
        stage += 1;
        grown = false;
        const cheapest_edges = findCheapestEdges(allocator, f, edges);
        defer allocator.free(cheapest_edges);
        for (cheapest_edges) |cheap_edge| {
            if (cheap_edge) |i| {
                const a = root(f.parent, edges[i].u);
                const b = root(f.parent, edges[i].v);
                if (a != b) {
                    f.joined(a, b);
                    picks.append(allocator, .{ .stage = stage, .edge = &edges[i] }) catch @panic("OOM");
                    trees -= 1;
                    grown = true;
                }
            }
        }
    }
    return picks.toOwnedSlice(allocator) catch @panic("OOM");
}

fn calcTotalWeight(picks: []const Pick) f64 {
    var total: f64 = 0.0;
    for (picks) |p|
        total += p.edge.weight;
    return total;
}
