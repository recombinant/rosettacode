// https://rosettacode.org/wiki/Smallest_enclosing_circle_problem
// Translated from Wren following the same C++ code:
// https://www.geeksforgeeks.org/minimum-enclosing-circle-set-2-welzls-algorithm/?ref=rp
const std = @import("std");
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Allocator ------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();

    // Random number generator ----------------------------
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    // ----------------------------------------------------
    const point_arrays: []const []const Point = &[_][]const Point{
        &[_]Point{ Point{ .x = 0, .y = 0 }, Point{ .x = 0, .y = 1 }, Point{ .x = 1, .y = 0 } },
        &[_]Point{ Point{ .x = 5, .y = -2 }, Point{ .x = -3, .y = -2 }, Point{ .x = -2, .y = 5 }, Point{ .x = 1, .y = 6 }, Point{ .x = 0, .y = 2 } },
    };

    for (point_arrays) |points|
        try stdout.print("\n{d:.2}\n", .{try welzl(allocator, rand, points)});
}

const Point = struct {
    x: f64,
    y: f64,

    fn distance(self: Point, other: Point) f64 {
        return math.hypot(self.x - other.x, self.y - other.y);
    }
    fn distSq(self: Point, other: Point) f64 {
        return (self.x - other.x) * (self.x - other.x) + (self.y - other.y) * (self.y - other.y);
    }

    /// Custom formatter for Point struct
    pub fn format(self: Point, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len == 0) {
            return std.fmt.format(writer, "Point({}, {})", .{ self.x, self.y });
        } else if (comptime mem.eql(u8, fmt, "d")) {
            try writer.writeAll("Point(x=");
            try std.fmt.formatType(self.x, "d", options, writer, std.options.fmt_max_depth);
            try writer.writeAll(", y=");
            try std.fmt.formatType(self.y, "d", options, writer, std.options.fmt_max_depth);
            try writer.writeAll(")");
            return;
        } else {
            @compileError("unknown format character: '" ++ fmt ++ "'");
        }
    }
};

const Circle = struct {
    c: Point,
    r: f64,

    fn contains(self: Circle, p: Point) bool {
        return self.c.distSq(p) <= self.r * self.r;
    }

    fn encloses(self: Circle, points: []const Point) bool {
        for (points) |p|
            if (!self.contains(p)) return false;
        return true;
    }

    // returns a unique circle that intersects 3 points
    fn from3(pt1: Point, pt2: Point, pt3: Point) Circle {
        var center = getCircleCenter(pt1, pt2, pt3);
        center.x += pt1.x;
        center.y += pt1.y;
        return Circle{ .c = center, .r = center.distance(pt1) };
    }

    // returns the smallest circle that intersects 2 points
    fn from2(A: Point, B: Point) Circle {
        // Set the center to be the midpoint of A and B
        const C = Point{ .x = (A.x + B.x) / 2, .y = (A.y + B.y) / 2 };

        // Set the radius to be half the distance AB
        return .{ .c = C, .r = A.distance(B) / 2 };
    }

    /// Custom formatter for Circle struct
    pub fn format(self: Circle, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len == 0) {
            return std.fmt.format(writer, "Circle({}, {})", .{ self.c, self.r });
        } else if (comptime mem.eql(u8, fmt, "d")) {
            try writer.writeAll("Circle(center=");
            try self.c.format(fmt, options, writer);
            try writer.writeAll(", radius=");
            try std.fmt.formatType(self.r, "d", options, writer, std.options.fmt_max_depth);
            try writer.writeAll(")");
            return;
        } else {
            @compileError("unknown format character: '" ++ fmt ++ "'");
        }
    }
};

// returns the center of a circle defined by 3 points
fn getCircleCenter(pt1: Point, pt2: Point, pt3: Point) Point {
    const bx = pt2.x - pt1.x;
    const by = pt2.y - pt1.y;
    const cx = pt3.x - pt1.x;
    const cy = pt3.y - pt1.y;

    const b = bx * bx + by * by;
    const c = cx * cx + cy * cy;
    const d = bx * cy - by * cx;
    return Point{ .x = (cy * b - by * c) / (2 * d), .y = (bx * c - cx * b) / (2 * d) };
}

fn welzl(allocator: mem.Allocator, rand: std.Random, input_points: []const Point) !Circle {
    const points = try allocator.dupe(Point, input_points);
    defer allocator.free(points);
    rand.shuffle(Point, points);

    var boundary_points = std.ArrayList(Point).init(allocator);
    boundary_points.deinit();

    return try welzl_helper(rand, points, boundary_points);
}

// Returns the MEC using Welzl's algorithm
// Takes a set of input points P and a set R
// points on the circle boundary.
// n represents the number of points in P
// that are not yet processed.
fn welzl_helper(rand: std.Random, points: []Point, R: std.ArrayList(Point)) !Circle {
    // Base case when all points processed or |R| = 3
    if (points.len == 0 or R.items.len == 3) return try secTrivial(R.items);

    // Pick a random point randomly
    const idx = rand.uintLessThan(usize, points.len);
    const p: Point = points[idx];

    // Put the picked point at the end of P
    // since it's more efficient than
    // deleting from the middle of the vector
    mem.swap(Point, &points[idx], &points[points.len - 1]);
    const points_slice = points[0 .. points.len - 1];

    // Get the MEC circle d from the
    // set of points P - {p}
    const d: Circle = try welzl_helper(rand, points_slice, R);

    if (d.contains(p)) return d;

    var boundary_points = try R.clone();
    defer boundary_points.deinit();
    // Otherwise, must be on the boundary of the MEC
    try boundary_points.append(p);

    // Return the MEC for P - {p} and R U {p}
    return try welzl_helper(rand, points_slice, boundary_points);
}

const TrivalCircleError = error{
    MoreThan3Points,
};

// Function to return the minimum enclosing circle for 3 points or fewer.
fn secTrivial(points: []Point) TrivalCircleError!Circle {
    return switch (points.len) {
        0 => .{ .c = Point{ .x = 0, .y = 0 }, .r = 0 },
        1 => .{ .c = points[0], .r = 0 },
        2 => Circle.from2(points[0], points[1]),
        3 => blk: {
            // Check for any enclosure by combinations of two points.
            for (points[0..2], 0..) |pt1, i| {
                for (points[i..3]) |pt2| {
                    const c = Circle.from2(pt1, pt2);
                    if (c.encloses(points))
                        return c;
                }
            }
            break :blk Circle.from3(points[0], points[1], points[2]);
        },
        else => TrivalCircleError.MoreThan3Points,
    };
}
