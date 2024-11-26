// https://rosettacode.org/wiki/Convex_hull
// Translation of
// https://algoteka.com/samples/35/graham-scan-convex-hull-algorithm-c-plus-plus-o%2528n-log-n%2529-readable-solution
const std = @import("std");

const print = std.debug.print;

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var points = [_]Point{
        Point.init(16, 3),  Point.init(12, 17), Point.init(0, 6),
        Point.init(-4, -6), Point.init(16, 6),  Point.init(16, -7),
        Point.init(16, -3), Point.init(17, -4), Point.init(5, 19),
        Point.init(19, -8), Point.init(3, 16),  Point.init(12, 13),
        Point.init(3, -4),  Point.init(17, 5),  Point.init(-3, 15),
        Point.init(-3, -9), Point.init(0, 11),  Point.init(-9, -3),
        Point.init(-4, -2), Point.init(12, 10),
    };
    const hull = try grahamScan(allocator, &points);
    defer allocator.free(hull);
    for (hull, 1..) |pt, i| {
        print("{}", .{pt});
        if (i != hull.len)
            print(", ", .{});
    }
    print("\n", .{});
}

/// Caller owns returned slice memory.
/// `points` may be reordered.
fn grahamScan(allocator: std.mem.Allocator, points: []Point) ![]Point {
    if (points.len < 3) return try allocator.dupe(Point, points);

    const first_point = blk: {
        var pt0 = points[0];
        for (points[1..]) |pt|
            if (pt.lessThan(pt0)) {
                pt0 = pt;
            };
        break :blk pt0;
    };
    // Sort the points by angle to the chosen first point
    std.mem.sort(Point, points, first_point, Point.lessThanPolarAngle);

    var result = std.ArrayList(Point).init(allocator);
    for (points) |pt| {
        // For as long as the last 3 points cause the hull to be non-convex, discard the middle one
        while (result.items.len >= 2) {
            const a = result.items; // for readability
            if ((a[a.len - 1].sub(a[a.len - 2])).rotate90().mul(pt.sub(a[a.len - 1])) <= 0)
                _ = result.pop()
            else
                break;
        }
        try result.append(pt);
    }
    return result.toOwnedSlice();
}

const Point = struct {
    x: f64,
    y: f64,
    fn init(x: f64, y: f64) Point {
        return .{ .x = x, .y = y };
    }
    pub fn format(self: *const Point, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
    fn lessThan(self: Point, other: Point) bool {
        return switch (std.math.order(self.x, other.x)) {
            .lt => true,
            .eq => self.y < other.y,
            .gt => false,
        };
    }
    fn lessThanPolarAngle(first_point: Point, lhs: Point, rhs: Point) bool {
        if (std.meta.eql(lhs, first_point))
            return !std.meta.eql(rhs, first_point)
        else if (std.meta.eql(rhs, first_point))
            return false;
        // const dir = (lhs - first_point).rotate90() * (rhs - first_point);
        const dir = (lhs.sub(first_point)).rotate90().mul(rhs.sub(first_point));
        // If the points are on a line with first point, sort by distance (manhattan is equivalent here)
        // (lhs - first_point).manhattan_length() < (rhs - first_point).manhattan_length();
        if (dir == 0)
            return (lhs.sub(first_point)).manhattanLength() < (rhs.sub(first_point)).manhattanLength();
        return dir > 0;
        // Alternative approach, closer to common algorithm formulation but inferior:
        // return atan2(lhs.y - first_point.y, lhs.x - first_point.x) < atan2(rhs.y - first_point.y, rhs.x - first_point.x);
    }
    fn sub(self: Point, other: Point) Point {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }
    fn mul(self: Point, other: Point) f64 {
        return self.x * other.x + self.y * other.y;
    }
    /// Rotate 90 degrees counter-clockwise
    fn rotate90(self: Point) Point {
        return .{ .x = -self.y, .y = self.x };
    }
    fn manhattanLength(self: Point) f64 {
        return @abs(self.x) + @abs(self.y);
    }
};
