// https://rosettacode.org/wiki/Ramer-Douglas-Peucker_line_simplification
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() void {
    const line = &[_]Point{
        Point.init(0, 0),    Point.init(1, 0.1),
        Point.init(2, -0.1), Point.init(3, 5),
        Point.init(4, 6),    Point.init(5, 7),
        Point.init(6, 8.1),  Point.init(7, 9),
        Point.init(8, 9),    Point.init(9, 9),
    };

    var output: [line.len]Point = undefined;
    const reduced = ramerDouglasPeucker(&output, line, 1);

    for (reduced) |p|
        std.debug.print("({d}, {d}) ", .{ p.x, p.y });

    std.debug.print("\n", .{});
}

const Point = struct {
    x: f64,
    y: f64,

    fn init(x: f64, y: f64) Point {
        return Point{ .x = x, .y = y };
    }
};

/// Returns the distance from point p to the line between p1 and p2
fn perpendicularDistance(p: Point, p1: Point, p2: Point) f64 {
    const dx = p2.x - p1.x;
    const dy = p2.y - p1.y;
    const d = std.math.hypot(dx, dy);
    return @abs(p.x * dy - p.y * dx + p2.x * p1.y - p2.y * p1.x) / d;
}

/// https://en.wikipedia.org/wiki/Ramer–Douglas–Peucker_algorithm#Pseudocode
fn ramerDouglasPeucker(output: []Point, points: []const Point, epsilon: f64) []Point {
    // Find the point with the maximum distance
    var dmax: f64 = 0;
    var index: usize = 0;
    const end = points.len - 1;

    std.debug.assert(!std.meta.eql(points[0], points[end]));

    for (points[1..end], 1..) |p, i| {
        const d = perpendicularDistance(p, points[0], points[end]);
        if (d > dmax) {
            dmax = d;
            index = i;
        }
    }
    // If max distance is greater than epsilon, recursively simplify
    if (dmax > epsilon) {
        // Recursive call
        const result1 = ramerDouglasPeucker(output, points[0 .. index + 1], epsilon);
        const result2 = ramerDouglasPeucker(output[result1.len - 1 ..], points[index..points.len], epsilon);
        return output[0 .. result1.len + result2.len - 1];
    } else {
        output[0] = points[0];
        output[1] = points[end];
        return output[0..2];
    }
}

const testing = std.testing;
test perpendicularDistance {
    try testing.expectEqual(1, perpendicularDistance(
        Point{ .x = 0, .y = 0 },
        Point{ .x = 1, .y = 1 },
        Point{ .x = 1, .y = -1 },
    ));
    try testing.expectEqual(1, perpendicularDistance(
        Point{ .x = 4, .y = 1 },
        Point{ .x = 5, .y = 2 },
        Point{ .x = 5, .y = 0 },
    ));
}
