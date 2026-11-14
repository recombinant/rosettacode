// https://rosettacode.org/wiki/Bron–Kerbosch_algorithm
// {{works with|Zig|0.17.1}}
// {{trans|Crow}}
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
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    // ----------------------------------------------------------
    // the task's graph: every edge is listed both ways
    const task: []const [2]u8 = &.{
        .{ 'a', 'b' }, .{ 'b', 'a' }, .{ 'a', 'c' }, .{ 'c', 'a' }, .{ 'b', 'c' },
        .{ 'c', 'b' }, .{ 'd', 'e' }, .{ 'e', 'd' }, .{ 'd', 'f' }, .{ 'f', 'd' },
        .{ 'e', 'f' }, .{ 'f', 'e' },
    };
    try show(allocator, task, stdout);

    try stdout.writeByte('\n');

    // cliques that share vertices: a, b, c, d whole, three triangles, and g with h only a pair
    const overlapping: []const [2]u8 = &.{
        .{ 'a', 'b' }, .{ 'a', 'c' }, .{ 'a', 'd' }, .{ 'b', 'c' }, .{ 'b', 'd' },
        .{ 'c', 'd' }, .{ 'c', 'e' }, .{ 'd', 'e' }, .{ 'e', 'f' }, .{ 'e', 'g' },
        .{ 'f', 'g' }, .{ 'g', 'h' }, .{ 'h', 'i' }, .{ 'h', 'j' }, .{ 'i', 'j' },
    };
    try show(allocator, overlapping, stdout);
    // ----------------------------------------------------------
    try stdout.flush();
}

fn show(allocator: Allocator, edges: []const [2]u8, w: *Writer) !void {
    var g: Graph = .init(allocator);
    defer g.deinit();
    try g.populate(edges);

    const cliques: []const Clique = try g.applyBronKerbosch();
    for (cliques) |clique| {
        try w.print("{f}\n", .{clique});
        clique.deinit(allocator);
    }
    allocator.free(cliques);
}

/// The graph is a map from each vertex to its neighbours, and R, P and X are lists of
/// vertices. With pivoting: the pivot is the vertex of P and X with the most neighbours,
/// and only the vertices of P that are not its neighbours start a branch.
const Graph = struct {
    allocator: Allocator,
    g: std.AutoHashMap(u8, ArrayList(u8)),

    fn init(allocator: Allocator) Graph {
        return .{
            .allocator = allocator,
            .g = .init(allocator),
        };
    }
    fn deinit(self: *Graph) void {
        var it = self.g.valueIterator();
        while (it.next()) |list|
            list.deinit(self.allocator);
        self.g.deinit();
    }
    /// every vertex's neighbours, each edge taken both ways
    fn populate(self: *Graph, edges: []const [2]u8) !void {
        for (edges) |e| {
            try self.joined(e[0], e[1]);
            try self.joined(e[1], e[0]);
        }
    }
    /// the graph with the edge from a to b added, once
    fn joined(self: *Graph, a: u8, b: u8) !void {
        const gop = try self.g.getOrPut(a);
        if (!gop.found_existing) {
            gop.value_ptr.* = .empty;
        } else if (std.mem.findScalar(u8, gop.value_ptr.*.items, b) != null) {
            return;
        }
        try gop.value_ptr.*.append(self.allocator, b);
    }
    /// the vertex of vs with the most neighbours, the first of them on a tie
    fn findPivotOf(self: *const Graph, vs: []const u8) u8 {
        var best: u8 = vs[0];
        for (vs) |v|
            if (self.g.get(v).?.items.len > self.g.get(best).?.items.len) {
                best = v;
            };
        return best;
    }

    fn applyBronKerbosch(self: *const Graph) ![]const Clique {
        const r = try self.allocator.alloc(u8, 0);
        var p: ArrayList(u8) = .empty;
        var x: ArrayList(u8) = .empty;
        defer self.allocator.free(r);
        defer p.deinit(self.allocator);
        defer x.deinit(self.allocator);

        var it = self.g.keyIterator();
        while (it.next()) |vertex|
            try p.append(self.allocator, vertex.*);

        const cliques: []Clique = try applyBronKerbosch_(self, r, &p, &x);
        std.mem.sortUnstable(Clique, cliques, {}, Clique.lessThan);
        return cliques;
    }
    /// the maximal cliques of more than two vertices that hold every vertex of r, some of p
    /// and none of x, each as its vertices in order in a slice
    fn applyBronKerbosch_(self: *const Graph, r: []const u8, p: *ArrayList(u8), x: *ArrayList(u8)) ![]Clique {
        if (p.items.len == 0 and x.items.len == 0) {
            if (r.len > 2) {
                const vertices: []u8 = try self.allocator.dupe(u8, r);
                std.mem.sortUnstable(u8, vertices, {}, std.sort.asc(u8));
                const cliques = try self.allocator.alloc(Clique, 1);
                cliques[0] = .init(vertices);
                return cliques;
            } else {
                return try self.allocator.alloc(Clique, 0);
            }
        }
        const vs: []const u8 = try std.mem.concat(self.allocator, u8, &.{ p.items, x.items });
        const pivot = self.findPivotOf(vs);
        self.allocator.free(vs);

        const pivot_list: []const u8 = self.g.get(pivot).?.items;
        var candidates: ArrayList(u8) = .empty;
        defer candidates.deinit(self.allocator);
        for (p.items) |v|
            if (std.mem.findScalar(u8, pivot_list, v) == null) {
                try candidates.append(self.allocator, v);
            };

        var clique_list: ArrayList(Clique) = .empty;
        for (candidates.items) |v| {
            const r_: []const u8 = try std.mem.concat(self.allocator, u8, &.{ r, &[_]u8{v} });
            defer self.allocator.free(r_);
            var p_: ArrayList(u8) = try common(self.allocator, p.items, self.g.get(v).?.items);
            defer p_.deinit(self.allocator);
            var x_: ArrayList(u8) = try common(self.allocator, x.items, self.g.get(v).?.items);
            defer x_.deinit(self.allocator);

            const cliques: []const Clique = try self.applyBronKerbosch_(r_, &p_, &x_);
            defer self.allocator.free(cliques);
            try clique_list.appendSlice(self.allocator, cliques);

            if (std.mem.findScalar(u8, p.items, v)) |pos|
                _ = p.swapRemove(pos);

            try x.append(self.allocator, v);
        }
        return try clique_list.toOwnedSlice(self.allocator);
    }
};

const Clique = struct {
    vertices: []const u8,

    /// Clique now owns vertices slice
    fn init(vertices: []const u8) Clique {
        return .{
            .vertices = vertices,
        };
    }
    fn deinit(self: *const Clique, allocator: Allocator) void {
        allocator.free(self.vertices);
    }
    fn lessThan(_: void, lhs: Clique, rhs: Clique) bool {
        return std.mem.order(u8, lhs.vertices, rhs.vertices) == .lt;
    }
    pub fn format(self: *const Clique, w: *Writer) !void {
        switch (self.vertices.len) {
            0 => unreachable,
            else => {
                try w.print("{c}", .{self.vertices[0]});
                for (self.vertices[1..]) |vertex|
                    try w.print(", {c}", .{vertex});
            },
        }
    }
};

/// the items of xs that ys holds too (intersection of xs and ys)
fn common(allocator: Allocator, xs: []const u8, ys: []const u8) !ArrayList(u8) {
    var both: ArrayList(u8) = .empty;
    for (xs) |x|
        if (std.mem.findScalar(u8, ys, x) != null)
            try both.append(allocator, x);
    return both;
}
