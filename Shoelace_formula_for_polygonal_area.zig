// https://rosettacode.org/wiki/Shoelace_formula_for_polygonal_area
// {{works with|Zig|0.15.1}}
const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    const points = [_]Point{
        .{ .x = 3, .y = 4 }, .{ .x = 5, .y = 11 }, .{ .x = 12, .y = 8 },
        .{ .x = 9, .y = 5 }, .{ .x = 5, .y = 6 },
    };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{d}\n", .{shoelace(points[0..])});

    try stdout.flush();
}

const Point = struct {
    x: f64,
    y: f64,
};

fn shoelace(points: []const Point) f64 {
    std.debug.assert(points.len > 2);
    var sum: f64 = 0;
    var p0 = points[points.len - 1];
    for (points[0..points.len]) |p1| {
        sum += (p1.x * p0.y) - (p0.x * p1.y);
        p0 = p1;
    }
    return 0.5 * @abs(sum);
}

test "polygon area" {
    const points1 = [_]Point{
        .{ .x = 2, .y = 7 },  .{ .x = 10, .y = 1 },
        .{ .x = 8, .y = 6 },  .{ .x = 11, .y = 7 },
        .{ .x = 7, .y = 10 },
    };
    try testing.expectEqual(32, shoelace(&points1));

    const points2 = [_]Point{
        .{ .x = 1, .y = 6 }, .{ .x = 3, .y = 1 },
        .{ .x = 7, .y = 2 }, .{ .x = 4, .y = 4 },
        .{ .x = 8, .y = 5 },
    };
    try testing.expectEqual(16.5, shoelace(&points2));
}
