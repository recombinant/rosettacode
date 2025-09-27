// https://rosettacode.org/wiki/Hierholze%27s_Algorithm
// {{works with|Zig|0.15.1}}
// {{trans|C++}}

// Copied and refactored from rosettacode
const std = @import("std");

pub fn main() !void {
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------

    // First adjacency list
    var adj1 = try allocator.alloc([]const u16, 3);
    defer allocator.free(adj1);

    adj1[0] = &[_]u16{1};
    adj1[1] = &[_]u16{2};
    adj1[2] = &[_]u16{0};
    try printCircuit(allocator, adj1, stdout);

    // Second adjacency list
    var adj2 = try allocator.alloc([]const u16, 7);
    defer allocator.free(adj2);

    adj2[0] = &[_]u16{ 1, 6 };
    adj2[1] = &[_]u16{2};
    adj2[2] = &[_]u16{ 0, 3 };
    adj2[3] = &[_]u16{4};
    adj2[4] = &[_]u16{ 2, 5 };
    adj2[5] = &[_]u16{0};
    adj2[6] = &[_]u16{4};
    try printCircuit(allocator, adj2, stdout);

    try stdout.flush();
}

fn printCircuit(allocator: std.mem.Allocator, adj: []const []const u16, w: *std.Io.Writer) !void {
    // adj represents the adjacency list of the directed graph
    // edge_count represents the number of edges emerging from a vertex
    var edge_count: std.AutoHashMapUnmanaged(u16, u16) = .empty;
    defer edge_count.deinit(allocator);

    for (adj, 0..) |edges, i| {
        // find the count of edges to keep track of unused edges
        try edge_count.put(allocator, @intCast(i), @intCast(edges.len));
    }

    if (adj.len == 0) return; // empty graph

    // Maintain a stack to keep vertices
    var curr_path: std.ArrayList(u16) = .empty;
    defer curr_path.deinit(allocator);

    // vector to store final circuit
    var circuit: std.ArrayList(u16) = .empty;
    defer circuit.deinit(allocator);

    // Create mutable copies of adjacency lists
    var adj_mutable = try allocator.alloc(std.ArrayList(u16), adj.len);
    defer {
        for (adj_mutable) |*list|
            list.deinit(allocator);
        allocator.free(adj_mutable);
    }

    for (adj, 0..) |edges, i| {
        adj_mutable[i] = .empty;
        try adj_mutable[i].appendSlice(allocator, edges);
    }

    // start from any vertex
    try curr_path.append(allocator, 0);
    var curr_v: u16 = 0; // Current vertex

    while (curr_path.items.len > 0) {
        // If there's remaining edge
        if (edge_count.get(curr_v).? > 0) {
            // Push the vertex
            try curr_path.append(allocator, curr_v);

            // Find the next vertex using an edge
            const next_v = adj_mutable[curr_v].items[adj_mutable[curr_v].items.len - 1];

            // and remove that edge
            edge_count.put(allocator, curr_v, edge_count.get(curr_v).? - 1) catch unreachable;
            _ = adj_mutable[curr_v].pop();

            // Move to next vertex
            curr_v = next_v;
        } else {
            // back-track to find remaining circuit
            try circuit.append(allocator, curr_v);

            // Back-tracking
            curr_v = curr_path.items[curr_path.items.len - 1];
            _ = curr_path.pop();
        }
    }

    // we've got the circuit, now print it in reverse
    std.mem.reverse(u16, circuit.items);
    for (circuit.items, 1..) |item, i| {
        try w.print("{}", .{item});
        if (i != circuit.items.len)
            try w.writeAll(" -> ");
    }
    try w.writeByte('\n');
    // could flush here...
    // try w.flush();
}
