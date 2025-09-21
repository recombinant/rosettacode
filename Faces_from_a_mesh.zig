// https://rosettacode.org/wiki/Faces_from_a_mesh
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try stdout.print("Perimeter format equality checks:\n", .{});
    {
        const equal = try perimEqual(allocator, &[_]u32{ 8, 1, 3 }, &[_]u32{ 1, 3, 8 });
        try stdout.print("  Q == R is {}\n", .{equal});
    }
    {
        const equal = try perimEqual(allocator, &[_]u32{ 18, 8, 14, 10, 12, 17, 19 }, &[_]u32{ 8, 14, 10, 12, 17, 19, 18 });
        try stdout.print("  U == V is {}\n", .{equal});
    }
    const e: []const Edge = &[_]Edge{ .{ 7, 11 }, .{ 1, 11 }, .{ 1, 7 } };
    const f: []const Edge = &[_]Edge{ .{ 11, 23 }, .{ 1, 17 }, .{ 17, 23 }, .{ 1, 11 } };
    const g: []const Edge = &[_]Edge{ .{ 8, 14 }, .{ 17, 19 }, .{ 10, 12 }, .{ 10, 14 }, .{ 12, 17 }, .{ 8, 18 }, .{ 18, 19 } };
    const h: []const Edge = &[_]Edge{ .{ 1, 3 }, .{ 9, 11 }, .{ 3, 11 }, .{ 1, 11 } };
    try stdout.print("\nEdge to perimeter format translations:\n", .{});
    for ([_][]const Edge{ e, f, g, h }, 0..) |face, i| {
        if (faceToPerim(allocator, face)) |perim| {
            try stdout.print("  {c} => {any}\n", .{ @as(u8, @truncate(i)) + 'E', perim });
            allocator.free(perim);
        } else |err| {
            const msg: []const u8 = switch (err) {
                EdgeError.EmptyFace => "no points in face",
                EdgeError.EdgePairOrder => "edge points out of order",
                EdgeError.PerimeterBroken => "perimeter broken",
                EdgeError.ExtraneousEdges => "extra points not incorporated in perimeter",
                error.OutOfMemory => "out of memory",
            };
            try stdout.print("  {c} => Invalid edge format ({s})\n", .{ @as(u8, @truncate(i)) + 'E', msg });
        }
    }
    try stdout.flush();
}

/// Check two perimeters are equal.
fn perimEqual(allocator: Allocator, p1: []const u32, p2: []const u32) !bool {
    if (std.mem.eql(u32, p1, p2)) return true;
    if (p1.len != p2.len) return false;

    for (p1) |p| if (std.mem.indexOfScalar(u32, p2, p) == null) return false;

    // use copy to avoid mutating 'p1'
    const p1_copy = try allocator.dupe(u32, p1);
    defer allocator.free(p1_copy);

    // check clockwise and counter-clockwise
    for (0..2) |_| {
        for (0..p1_copy.len) |_| {
            if (std.mem.eql(u32, p1_copy, p2)) return true;
            // do circular shift to left
            std.mem.rotate(u32, p1_copy, 1);
        }
        // now check in opposite direction
        std.mem.reverse(u32, p1_copy);
    }
    return false;
}

const Edge = [2]u32;

fn lessThanFn(_: void, lhs: Edge, rhs: Edge) bool {
    if (lhs[0] != rhs[0])
        return lhs[0] < rhs[0]
    else
        return lhs[1] < rhs[1];
}

const EdgeError = error{
    EmptyFace,
    EdgePairOrder,
    PerimeterBroken,
    ExtraneousEdges,
};

/// Translates a face to perimeter format.
/// Caller owns returned slice memory.
fn faceToPerim(allocator: Allocator, face: []const Edge) (EdgeError || Allocator.Error)![]u32 {
    if (face.len == 0) return EdgeError.EmptyFace;

    // use copy to avoid mutating 'face'
    // edges are considered unordered
    var edges: std.ArrayList(Edge) = try .initCapacity(allocator, face.len);
    defer edges.deinit(allocator);
    for (face) |point| {
        // check edge pairs are in correct order
        if (point[1] <= point[0]) return EdgeError.EdgePairOrder;
        try edges.append(allocator, point);
    }
    // sort to start at lowest numbered edge combo
    std.sort.insertion(Edge, edges.items, {}, lessThanFn);

    var perim: std.ArrayList(u32) = try .initCapacity(allocator, edges.items.len);
    errdefer perim.deinit(allocator);
    // remove first edge
    const first_edge = edges.orderedRemove(0);
    const first_point = first_edge[0];
    var next_point = first_edge[1];
    try perim.append(allocator, first_point);
    try perim.append(allocator, next_point);

    outer: while (edges.items.len != 0) {
        for (edges.items, 0..) |e, i| {
            if (e[0] == next_point or e[1] == next_point) {
                next_point = if (e[0] == next_point) e[1] else e[0];
                // remove i'th edge
                _ = edges.swapRemove(i);
                if (next_point == first_point)
                    if (edges.items.len == 0)
                        break :outer
                    else
                        return EdgeError.ExtraneousEdges;
                try perim.append(allocator, next_point);
                continue :outer;
            }
        }
        return EdgeError.PerimeterBroken;
    }
    return try perim.toOwnedSlice(allocator);
}
