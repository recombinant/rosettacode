// https://rosettacode.org/wiki/Dijkstra%27s_algorithm
// {{works with|Zig|0.15.1}}
// {{trans|Nim}}
const std = @import("std");

pub fn main() !void {
    // var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var graph: Graph = try .init(allocator, &[_]Edge{
        .{ "a", "b", 7 },  .{ "a", "c", 9 },  .{ "a", "f", 14 },
        .{ "b", "c", 10 }, .{ "b", "d", 15 }, .{ "c", "d", 11 },
        .{ "c", "f", 2 },  .{ "d", "e", 6 },  .{ "e", "f", 9 },
    });
    defer graph.deinit(allocator);

    const path1 = try graph.dijkstraPath(allocator, "a", "e");
    defer allocator.free(path1);
    try printPath(stdout, path1);

    const path2 = try graph.dijkstraPath(allocator, "a", "f");
    defer allocator.free(path2);
    try printPath(stdout, path2);

    try stdout.flush();
}

/// Print a path.
fn printPath(w: *std.Io.Writer, path: []const []const u8) !void {
    try w.print("Shortest path from '{s}' to '{s}': {s}", .{ path[0], path[path.len - 1], path[0] });
    for (path[1..]) |s|
        try w.print(" → {s}", .{s});
    try w.writeByte('\n');
}
// --------------------------------------------------------------
const Edge = struct {
    []const u8, // src
    []const u8, // dst
    u16, // cost
};

const DestCost = struct { []const u8, u64 }; // dst, cost
const DestCostList = std.ArrayList(DestCost);

const Graph = struct {
    vertices: std.StringArrayHashMap(void),
    neighbours: std.StringArrayHashMap(DestCostList),

    /// Initialize a graph from an edge list.
    /// Use floats for costs in order to compare to Inf value.
    fn init(allocator: std.mem.Allocator, edges: []const Edge) !Graph {
        var g: Graph = .{
            .vertices = .init(allocator),
            .neighbours = .init(allocator),
        };
        for (edges) |edge| {
            const src, const dst, const cost = edge;
            try g.vertices.put(src, {});
            try g.vertices.put(dst, {});

            const gop = try g.neighbours.getOrPut(src);
            if (!gop.found_existing)
                gop.value_ptr.* = .empty;
            try gop.value_ptr.append(allocator, .{ dst, cost });
        }
        return g;
    }
    fn deinit(self: *Graph, allocator: std.mem.Allocator) void {
        self.vertices.deinit();
        for (self.neighbours.values()) |*list|
            list.deinit(allocator);
        self.neighbours.deinit();
    }
    /// Find the path from "first" to "last" which minimizes the cost.
    /// Allocates memory for the result, which must be freed by the caller.
    fn dijkstraPath(graph: *Graph, allocator: std.mem.Allocator, first: []const u8, last: []const u8) ![][]const u8 {
        var dist: std.StringArrayHashMap(u64) = .init(allocator);
        defer dist.deinit();
        var previous: std.StringArrayHashMap([]const u8) = .init(allocator);
        defer previous.deinit();
        var not_seen = try graph.vertices.clone();
        defer not_seen.deinit();
        for (graph.vertices.keys()) |vertex|
            try dist.put(vertex, std.math.maxInt(u64));
        try dist.put(first, 0);

        while (not_seen.count() != 0) {
            // Search vertex with minimal distance.
            var vertex1: []const u8 = undefined;
            var mindist: u64 = std.math.maxInt(u64);
            for (not_seen.keys()) |vertex|
                if (dist.get(vertex).? < mindist) {
                    vertex1 = vertex;
                    mindist = dist.get(vertex).?;
                };
            if (std.mem.eql(u8, vertex1, last))
                break;
            _ = not_seen.swapRemove(vertex1);
            // Find shortest paths to neighbours.
            if (graph.neighbours.get(vertex1)) |dest_cost_list|
                for (dest_cost_list.items) |dest_cost| {
                    const vertex2: []const u8, const cost: u64 = dest_cost;

                    if (not_seen.contains(vertex2)) {
                        const altdist = dist.get(vertex1).? + cost;
                        if (altdist < dist.get(vertex2).?) {
                            // Found a shorter path to go to vertex2.
                            try dist.put(vertex2, altdist);
                            // To go to vertex2, go through vertex1.
                            try previous.put(vertex2, vertex1);
                        }
                    }
                };
        }
        // Build the path.
        var result: std.ArrayList([]const u8) = .empty;
        var optional_vertex: ?[]const u8 = last;
        while (optional_vertex) |vertex| {
            try result.append(allocator, vertex);
            optional_vertex = previous.get(vertex);
        }
        std.mem.reverse([]const u8, result.items);
        return result.toOwnedSlice(allocator);
    }
};
