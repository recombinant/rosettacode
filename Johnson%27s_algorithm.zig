// https://rosettacode.org/wikiJohnson%27s_algorithm
// {{works with|Zig|0.17.1}}
// {{trans|Java}}
// Copied from rosettacode, code refactored and corrected.
// It works for the sample provided.
// The comments are mostly original.
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Io = std.Io;
const PriorityQueue = std.PriorityQueue;
const INF = std.math.inf(f64);
const isInf = std.math.isInf;

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;
    const io: Io = init.io;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    // The element (i, j) is the weight of the edge from vertex i to vertex j.
    // INF, for infinity, means that there is no edge from vertex i to vertex j.
    const graph: []const []const f64 = &.{
        // zig fmt: off
        &.{ 0.0, -5.0, 2.0, 3.0 },
        &.{ INF,  0.0, 4.0, INF },
        &.{ INF,  INF, 0.0, 1.0 },
        &.{ INF,  INF, INF, 0.0 },
        // zig fmt: on
    };

    const result = applyJohnsonsAlgorithm(allocator, graph) catch {
        try stdout.writeAll("A negative cycle was detected in the graph.\n");
        return;
    };
    defer {
        for (result) |row|
            allocator.free(row);
        allocator.free(result);
    }

    try stdout.writeAll("All pairs shortest paths:\n");
    try stdout.writeAll("The element (i, j) is the shortest path between vertex i and vertex j.\n");

    for (result) |row| {
        try stdout.writeByte('[');
        for (row) |number| {
            if (isInf(number))
                try stdout.writeAll("  ∞ ")
            else
                try stdout.print("{d:>3} ", .{number});
        }
        try stdout.writeAll("]\n");
    }
    // ----------------------------------------------------------
    try stdout.flush();
}

const Edge = struct {
    u: usize,
    v: usize,
    weight: f64,
};

const VertexAndWeight = struct {
    v: usize,
    weight: f64,
};

const WeightAndVertex = struct {
    weight: f64,
    vertex: usize,

    pub fn compare(context: void, a: WeightAndVertex, b: WeightAndVertex) std.math.Order {
        _ = context;
        return std.math.order(a.weight, b.weight);
    }
};

pub fn applyJohnsonsAlgorithm(allocator: Allocator, graph: []const []const f64) ![][]const f64 {
    const vertex_count = graph.len;
    var original_edges: ArrayList(Edge) = .empty;
    defer original_edges.deinit(allocator);

    // Step 0: Build a list of edges for the original graph
    for (0..vertex_count) |i|
        for (0..vertex_count) |j| {
            const weight = graph[i][j];
            if (i == j) {
                if (weight != 0.0)
                    std.log.warn("graph[i][i] for i = {d} is {d}, expected to be 0.0, resetting it to 0.0\n", .{ i, weight });
            } else if (!isInf(weight)) {
                original_edges.append(allocator, .{ .u = i, .v = j, .weight = weight }) catch @panic("OOM");
            }
        };

    // Step 1: Form the augmented graph
    // Add a new vertex with index 'vertex_count' and having 0-weight edges to all the original vertices
    var augmented_edges: ArrayList(Edge) = .empty;
    augmented_edges.ensureTotalCapacityPrecise(allocator, original_edges.items.len + vertex_count) catch @panic("OOM");
    defer augmented_edges.deinit(allocator);

    augmented_edges.appendSlice(allocator, original_edges.items) catch @panic("OOM");
    for (0..vertex_count) |i|
        augmented_edges.append(allocator, .{ .u = vertex_count, .v = i, .weight = 0.0 }) catch @panic("OOM");

    // Step 2: Invoke the Bellman-Ford Algorithm starting from the new vertex
    // Throws an error if a negative cycle was detected by the Bellman-Ford Algorithm
    const h_values = try applyBellmanFordAlgorithm(allocator, vertex_count + 1, augmented_edges.items, vertex_count);
    defer allocator.free(h_values);

    // Remove the value for the augmented vertex
    const values = h_values[0 .. h_values.len - 1];

    // Step 3: Reweight the edges
    var reweighted_adjacencies: AutoHashMap(usize, ArrayList(VertexAndWeight)) = .init(allocator);
    defer {
        var it = reweighted_adjacencies.valueIterator();
        while (it.next()) |value|
            value.deinit(allocator);
        reweighted_adjacencies.deinit();
    }

    for (original_edges.items) |edge| {
        // Ensure the 'values' are valid before reweighting
        if (isInf(values[edge.u]) or isInf(values[edge.v]))
            std.log.warn("invalid hValues detected by the Bellman-Ford Algorithm.\n", .{});

        const reweight = edge.weight + values[edge.u] - values[edge.v];
        const gop = reweighted_adjacencies.getOrPut(edge.u) catch @panic("OOM");
        if (!gop.found_existing)
            gop.value_ptr.* = .empty;
        gop.value_ptr.append(allocator, .{ .v = edge.v, .weight = reweight }) catch @panic("OOM");
    }

    // Step 4: Invoke Dijkstra's Algorithm starting from each vertex on the reweighted graph
    const all_pairs_shortest_paths: [][]const f64 = allocator.alloc([]const f64, vertex_count) catch @panic("OOM");
    errdefer allocator.free(all_pairs_shortest_paths);

    for (all_pairs_shortest_paths, 0..vertex_count) |*path, u| {
        // Possible error.NegativeCycle
        const distances = try applyDijkstraAlgorithm(allocator, vertex_count, &reweighted_adjacencies, u, values);
        path.* = distances;
    }

    // Step 5: Return the result matrix
    return all_pairs_shortest_paths;
}

fn applyBellmanFordAlgorithm(allocator: Allocator, augmented_vertex_count: usize, edges: []const Edge, source_vertex: usize) ![]const f64 {
    var distances: []f64 = allocator.alloc(f64, augmented_vertex_count) catch @panic("OOM");
    errdefer allocator.free(distances);

    @memset(distances, INF);
    distances[source_vertex] = 0.0;

    // Relax the edges (augmented_vertex_count - 1) times
    var updated = true;
    for (0..augmented_vertex_count - 1) |_| {
        if (!updated) break;
        updated = false;

        for (edges) |edge| {
            if (!isInf(distances[edge.u]) and distances[edge.u] + edge.weight < distances[edge.v]) {
                distances[edge.v] = distances[edge.u] + edge.weight;
                updated = true;
            }
        }
    }

    // Check for negative cycles in the graph
    for (edges) |edge|
        if (!isInf(distances[edge.u]) and distances[edge.u] + edge.weight < distances[edge.v])
            return error.NegativeCycle; // Indicates a negative cycle has been detected

    return distances;
}

fn applyDijkstraAlgorithm(
    allocator: Allocator,
    vertex_count: usize,
    reweighted_adjacencies: *const AutoHashMap(usize, ArrayList(VertexAndWeight)),
    source_vertex: usize,
    values: []const f64,
) ![]const f64 {
    var distances: []f64 = allocator.alloc(f64, vertex_count) catch @panic("OOM");
    defer allocator.free(distances);
    @memset(distances, INF);
    distances[source_vertex] = 0.0;

    var final_distances: []f64 = allocator.alloc(f64, vertex_count) catch @panic("OOM");
    @memset(final_distances, INF);

    var priority_queue: PriorityQueue(WeightAndVertex, void, WeightAndVertex.compare) = .empty;
    defer priority_queue.deinit(allocator);

    priority_queue.push(allocator, .{ .weight = 0.0, .vertex = source_vertex }) catch @panic("OOM");

    while (priority_queue.pop()) |weight_and_vertex| {
        const vertex = weight_and_vertex.vertex;
        if (weight_and_vertex.weight > distances[vertex])
            continue;

        // Store the final shortest path distance, translated back to the distance in the original graph
        if (isInf(final_distances[vertex])) {
            if (isInf(distances[vertex]))
                // This should not happen, but is included as a safety check
                final_distances[vertex] = INF
            else
                // Translate distance back to its original weight: d(u,v) = d'(u,v) - h[u] + h[v]
                final_distances[vertex] = distances[vertex] - values[source_vertex] + values[vertex];
        }

        // Relax the edges outgoing from vertex
        if (reweighted_adjacencies.get(vertex)) |adjacencies|
            for (adjacencies.items) |pair|
                if (!isInf(distances[vertex]) and distances[vertex] + pair.weight < distances[pair.v]) {
                    distances[pair.v] = distances[vertex] + pair.weight;
                    priority_queue.push(allocator, .{ .weight = distances[pair.v], .vertex = pair.v }) catch @panic("OOM");
                };
    }

    // Translate distance back to its original weight for any remaining reachable vertices
    for (0..vertex_count) |i|
        if (isInf(final_distances[i]) and !isInf(distances[i])) {
            final_distances[i] = distances[i] - values[source_vertex] + values[i];
        };

    return final_distances;
}
