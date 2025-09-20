// https://rosettacode.org/wiki/Convex_hull
// {{works with|Zig|0.15.1}}
// Translation of
// https://algoteka.com/samples/35/graham-scan-convex-hull-algorithm-c-plus-plus-o%2528n-log-n%2529-readable-solution
const std = @import("std");

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------
    var points = [_]Point{
        .init(16, 3),  .init(12, 17), .init(0, 6),
        .init(-4, -6), .init(16, 6),  .init(16, -7),
        .init(16, -3), .init(17, -4), .init(5, 19),
        .init(19, -8), .init(3, 16),  .init(12, 13),
        .init(3, -4),  .init(17, 5),  .init(-3, 15),
        .init(-3, -9), .init(0, 11),  .init(-9, -3),
        .init(-4, -2), .init(12, 10),
    };
    const hull = try grahamScan(allocator, &points);
    defer allocator.free(hull);
    for (hull, 1..) |pt, i| {
        try stdout.print("{f}", .{pt});
        if (i != hull.len)
            try stdout.print(", ", .{});
    }
    try stdout.writeByte('\n');
    // --------------------------------------------------------------
    try stdout.flush();
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
    std.mem.sortUnstable(Point, points, first_point, Point.lessThanPolarAngle);

    var result: std.ArrayList(Point) = .empty;
    for (points) |pt| {
        // For as long as the last 3 points cause the hull to be non-convex, discard the middle one
        while (result.items.len >= 2) {
            const a = result.items; // for readability
            if ((a[a.len - 1].sub(a[a.len - 2])).rotate90().mul(pt.sub(a[a.len - 1])) <= 0)
                _ = result.pop()
            else
                break;
        }
        try result.append(allocator, pt);
    }
    return result.toOwnedSlice(allocator);
}

const Point = struct {
    x: f64,
    y: f64,
    fn init(x: f64, y: f64) Point {
        return .{ .x = x, .y = y };
    }
    pub fn format(self: *const Point, writer: *std.Io.Writer) std.Io.Writer.Error!void {
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
