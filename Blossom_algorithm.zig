// https://rosettacode.org/wiki/Blossom_algorithm
// {{works with|Zig|0.17.1}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;
    const io: Io = init.io;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    // The supplementary examples are from the Crow solution
    const examples: []const struct {
        name: []const u8,
        n: usize,
        edges: []const [2]usize,
    } = &.{
        .{ .name = "The 5-cycle", .n = 5, .edges = &.{ .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 4 }, .{ 4, 0 } } },
        .{ .name = "The Peterson graph", .n = 10, .edges = &.{ .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 4 }, .{ 4, 0 }, .{ 0, 5 }, .{ 1, 6 }, .{ 2, 7 }, .{ 3, 8 }, .{ 4, 9 }, .{ 5, 7 }, .{ 7, 9 }, .{ 9, 6 }, .{ 6, 8 }, .{ 8, 5 } } },
        .{ .name = "A triangle in the way", .n = 6, .edges = &.{ .{ 0, 1 }, .{ 0, 3 }, .{ 0, 5 }, .{ 1, 2 }, .{ 1, 4 }, .{ 2, 4 }, .{ 2, 5 } } },
        .{ .name = "Two triangles joined by an edge", .n = 6, .edges = &.{ .{ 0, 1 }, .{ 1, 2 }, .{ 2, 0 }, .{ 3, 4 }, .{ 4, 5 }, .{ 5, 3 }, .{ 2, 3 } } },
        .{ .name = "A star (one centre, five leaves)", .n = 6, .edges = &.{ .{ 0, 1 }, .{ 0, 2 }, .{ 0, 3 }, .{ 0, 4 }, .{ 0, 5 } } },
    };
    // ----------------------------------------------------------
    for (examples) |example| {
        const n = example.n;
        // ----------------------------
        // Count neighbors for each vertex
        var counts = allocator.alloc(usize, n) catch @panic("OOM");
        defer allocator.free(counts);
        @memset(counts, 0);

        for (example.edges) |edge| {
            counts[edge[0]] += 1;
            counts[edge[1]] += 1;
        }
        // ----------------------------
        var adj = allocator.alloc([]usize, n) catch @panic("OOM");
        defer {
            for (adj) |neighbors|
                allocator.free(neighbors);
            allocator.free(adj);
        }
        // Allocate space for neighbors
        for (0..n) |i| {
            adj[i] = allocator.alloc(usize, counts[i]) catch @panic("OOM");
            counts[i] = 0; // Reset to use as index
        }
        // ----------------------------
        // Fill adjacency lists
        for (example.edges) |edge| {
            const u = edge[0];
            const v = edge[1];
            adj[u][counts[u]] = v;
            counts[u] += 1;
            adj[v][counts[v]] = u;
            counts[v] += 1;
        }
        // ----------------------------
        var blossom = Blossom.init(allocator, adj);
        defer blossom.deinit();

        const result = blossom.solve();
        defer allocator.free(result.matching);

        try stdout.print("{s}: {} vertices, {} edges\n", .{ example.name, example.n, example.edges.len });
        try stdout.print("  Maximum matching size: {d}\n", .{result.size});
        try stdout.writeAll("  Matched pairs: ");

        var comma = false;
        for (0..n) |u|
            if (result.matching[u]) |v|
                if (u < v) {
                    if (comma)
                        try stdout.writeByte(',');
                    try stdout.print(" {d} - {d}", .{ u, v });
                    comma = true;
                };
        try stdout.writeAll("\n\n");
    }
    // ----------------------------------------------------------
    try stdout.flush();
}

const Blossom = struct {
    n: usize,
    adj: [][]usize,
    matching: []?usize, // matching[v] = u if v--u is matched
    parent: []?usize, // parent in the alternating tree
    base: []usize, // base[v] = base vertex of blossom containing v
    used: []bool, // used[v] = whether v is in the BFS tree
    blossom: []bool, // helper array for marking blossoms
    q: std.Deque(usize), // FIFO
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, adj: [][]usize) Blossom {
        const n = adj.len;
        const matching = allocator.alloc(?usize, n) catch @panic("OOM");
        const parent = allocator.alloc(?usize, n) catch @panic("OOM");
        var base = allocator.alloc(usize, n) catch @panic("OOM");
        const used = allocator.alloc(bool, n) catch @panic("OOM");
        const blossom = allocator.alloc(bool, n) catch @panic("OOM");
        const q: std.Deque(usize) = .empty;

        @memset(matching, null);
        @memset(parent, null);
        for (0..n) |i|
            base[i] = i;
        @memset(used, false);
        @memset(blossom, false);

        return Blossom{
            .n = n,
            .adj = adj,
            .matching = matching,
            .parent = parent,
            .base = base,
            .used = used,
            .blossom = blossom,
            .q = q,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Blossom) void {
        self.allocator.free(self.matching);
        self.allocator.free(self.parent);
        self.allocator.free(self.base);
        self.allocator.free(self.used);
        self.allocator.free(self.blossom);
        self.q.deinit(self.allocator);
    }

    // Find least common ancestor of a and b in the forest of alternating tree.
    fn lca(self: *const Blossom, a_in: usize, b_in: usize) usize {
        var a = a_in;
        var b = b_in;
        var used_path = self.allocator.alloc(bool, self.n) catch @panic("OOM");
        defer self.allocator.free(used_path);
        @memset(used_path, false);

        // climb from a
        while (true) {
            a = self.base[a];
            used_path[a] = true;
            if (self.matching[a]) |ma|
                if (self.parent[ma]) |pa| {
                    a = pa;
                    continue;
                };
            break;
        }

        // climb from b until we hit a marked vertex
        while (true) {
            b = self.base[b];
            if (used_path[b])
                return b;
            if (self.matching[b]) |mb|
                if (self.parent[mb]) |pb| {
                    b = pb;
                    continue;
                };
            // In a valid alternating forest this should always terminate
            unreachable;
        }
    }

    // Mark vertices along the path from v to base b, setting their parent to x.
    fn markPath(self: *Blossom, v_in: usize, b: usize, x_in: usize) void {
        var v = v_in;
        var x = x_in;
        while (self.base[v] != b) {
            const mv = self.matching[v].?;
            self.blossom[self.base[v]] = true;
            self.blossom[self.base[mv]] = true;
            self.parent[v] = x;
            x = mv;
            v = self.parent[x].?;
        }
    }

    // Try to find an augmenting path starting from root.
    fn findPath(self: *Blossom, root: usize) bool {
        // Reset BFS state
        @memset(self.used, false);
        @memset(self.parent, null);
        for (0..self.n) |i|
            self.base[i] = i;
        self.q.head = 0;
        self.q.len = 0;

        self.used[root] = true;
        self.q.pushBack(self.allocator, root) catch @panic("OOM");

        while (self.q.popFront()) |v| {
            for (self.adj[v]) |u| {
                if (self.base[v] == self.base[u] or self.matching[v] == u)
                    continue;
                // Found a blossom
                if (u == root or
                    (self.matching[u] != null and self.parent[self.matching[u].?] != null))
                {
                    const curbase = self.lca(v, u);
                    @memset(self.blossom, false);
                    self.markPath(v, curbase, u);
                    self.markPath(u, curbase, v);
                    for (0..self.n) |i|
                        if (self.blossom[self.base[i]]) {
                            self.base[i] = curbase;
                            if (!self.used[i]) {
                                self.used[i] = true;
                                self.q.pushBack(self.allocator, i) catch @panic("OOM");
                            }
                        };
                }
                // Otherwise, try to extend the alternating tree
                else if (self.parent[u] == null) {
                    self.parent[u] = v;
                    // If u is free, we've found an augmenting path
                    if (self.matching[u] == null) {
                        var cur = u;
                        while (self.parent[cur]) |prev| {
                            const next = self.matching[prev];
                            self.matching[cur] = prev;
                            self.matching[prev] = cur;
                            cur = next orelse break;
                        }
                        return true;
                    }
                    // Otherwise enqueue the matched partner
                    const mu = self.matching[u].?;
                    if (!self.used[mu]) {
                        self.used[mu] = true;
                        self.q.pushBack(self.allocator, mu) catch @panic("OOM");
                    }
                }
            }
        }
        return false;
    }

    // Main solver: returns (matching, size_of_matching)
    fn solve(self: *Blossom) struct { matching: []?usize, size: usize } {
        var res: usize = 0;
        for (0..self.n) |v|
            if (self.matching[v] == null and self.findPath(v)) {
                res += 1;
            };

        const result_matching = self.allocator.alloc(?usize, self.n) catch @panic("OOM");
        @memcpy(result_matching, self.matching);

        return .{ .matching = result_matching, .size = res };
    }
};
