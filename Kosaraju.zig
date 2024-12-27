// https://rosettacode.org/wiki/Kosaraju
// Translation of Go
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const g = [_][]const u32{
        &.{1},
        &.{2},
        &.{0},
        &.{ 1, 2, 4 },
        &.{ 3, 5 },
        &.{ 2, 6 },
        &.{5},
        &.{ 4, 6, 7 },
    };
    const result = try kosaraju(allocator, &g);
    std.debug.print("{any}", .{result});
    allocator.free(result);
}

/// Allocates memory for the result, which must be freed by the caller.
fn kosaraju(allocator: std.mem.Allocator, g: []const []const u32) ![]u32 {
    // ------------------------- struct for local scope variables
    const Kosajaru = struct {
        const Self = @This();

        allocator_: std.mem.Allocator,
        g: []const []const u32,
        vis: []bool,
        L: []u32,
        x: usize, // index for filling L in reverse order
        t: []std.ArrayList(u32), // transpose graph

        fn init(allocator_: std.mem.Allocator, g_: []const []const u32) !Self {
            const vis = try allocator_.alloc(bool, g_.len);
            @memset(vis, false);
            const L = try allocator_.alloc(u32, g_.len);
            @memset(L, 0);
            const t = try allocator_.alloc(std.ArrayList(u32), g_.len);
            for (t) |*v| v.* = std.ArrayList(u32).init(allocator_);
            return Self{
                .allocator_ = allocator_,
                .g = g_,
                .vis = vis,
                .L = L,
                .x = g_.len,
                .t = t,
            };
        }
        fn deinit(self: *Self) void {
            for (self.t) |v| v.deinit();
            self.allocator_.free(self.t);
            self.allocator_.free(self.L);
            self.allocator_.free(self.vis);
        }
        fn visit(self: *Self, u: u32) !void {
            if (!self.vis[u]) {
                self.vis[u] = true;
                for (self.g[u]) |v| {
                    try self.visit(v);
                    try self.t[v].append(u); // construct transpose
                }
                self.x -= 1;
                self.L[self.x] = u;
            }
        }
        fn assign(self: *Self, c_: *[]u32, u: u32, root: u32) void {
            // repurpose vis to mean "unassigned"
            if (self.vis[u]) {
                self.vis[u] = false;
                c_.*[u] = root;
                for (self.t[u].items) |v|
                    self.assign(c_, v, root);
            }
        }
    };
    // ----------------------------------------------------------
    // 1. For each vertex u of the graph, mark u as unvisited. Let L be empty.
    var k = try Kosajaru.init(allocator, g);
    defer k.deinit();

    // 2. For each vertex u of the graph do visit(u)
    for (0..g.len) |u|
        try k.visit(@truncate(u));

    var c = try allocator.alloc(u32, g.len); // result, the component assignment
    // 3: For each element u of L in order, do assign(u,u)
    for (k.L) |u|
        k.assign(&c, u, u);

    return c;
}
