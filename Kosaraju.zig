// https://rosettacode.org/wiki/Kosaraju
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
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
    // 1. For each vertex u of the graph, mark u as unvisited. Let L be empty.
    var k: Kosajaru = try .init(allocator, g);
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

const Kosajaru = struct {
    allocator: std.mem.Allocator,
    g: []const []const u32,
    vis: []bool,
    L: []u32,
    x: usize, // index for filling L in reverse order
    t: []std.ArrayList(u32), // transpose graph

    fn init(allocator: std.mem.Allocator, g: []const []const u32) !Kosajaru {
        const vis = try allocator.alloc(bool, g.len);
        @memset(vis, false);
        const L = try allocator.alloc(u32, g.len);
        @memset(L, 0);
        const t = try allocator.alloc(std.ArrayList(u32), g.len);
        for (t) |*v| v.* = .empty;
        return .{
            .allocator = allocator,
            .g = g,
            .vis = vis,
            .L = L,
            .x = g.len,
            .t = t,
        };
    }
    fn deinit(self: *Kosajaru) void {
        for (self.t) |*v| v.deinit(self.allocator);
        self.allocator.free(self.t);
        self.allocator.free(self.L);
        self.allocator.free(self.vis);
    }
    fn visit(self: *Kosajaru, u: u32) !void {
        if (!self.vis[u]) {
            self.vis[u] = true;
            for (self.g[u]) |v| {
                try self.visit(v);
                try self.t[v].append(self.allocator, u); // construct transpose
            }
            self.x -= 1;
            self.L[self.x] = u;
        }
    }
    fn assign(self: *Kosajaru, c_: *[]u32, u: u32, root: u32) void {
        // repurpose vis to mean "unassigned"
        if (self.vis[u]) {
            self.vis[u] = false;
            c_.*[u] = root;
            for (self.t[u].items) |v|
                self.assign(c_, v, root);
        }
    }
};
