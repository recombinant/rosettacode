// https://rosettacode.org/wiki/Determine_if_two_triangles_overlap
// Translation of C
const std = @import("std");
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const Trigon = Triangle(f64); // single location to change floating point type

    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 5, .y = 0 }, .{ .x = 0, .y = 5 });
        var t2 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 5, .y = 0 }, .{ .x = 0, .y = 6 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{}) });
    }
    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = 5 }, .{ .x = 5, .y = 0 });
        var t2 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = 5 }, .{ .x = 5, .y = 0 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{ .allow_reversed = true }) });
    }
    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 5, .y = 0 }, .{ .x = 0, .y = 5 });
        var t2 = Trigon.init(.{ .x = -10, .y = 0 }, .{ .x = -5, .y = 0 }, .{ .x = -1, .y = 6 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{}) });
    }
    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 5, .y = 0 }, .{ .x = 2.5, .y = 5 });
        var t2 = Trigon.init(.{ .x = 0, .y = 4 }, .{ .x = 2.5, .y = -1 }, .{ .x = 5, .y = 4 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{}) });
    }
    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 1, .y = 1 }, .{ .x = 0, .y = 2 });
        var t2 = Trigon.init(.{ .x = 2, .y = 1 }, .{ .x = 3, .y = 0 }, .{ .x = 3, .y = 2 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{}) });
    }
    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 1, .y = 1 }, .{ .x = 0, .y = 2 });
        var t2 = Trigon.init(.{ .x = 2, .y = 1 }, .{ .x = 3, .y = -2 }, .{ .x = 3, .y = 4 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{}) });
    }
    try stdout.writeAll("\nBarely touching:\n");
    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 });
        var t2 = Trigon.init(.{ .x = 1, .y = 0 }, .{ .x = 2, .y = 0 }, .{ .x = 1, .y = 1 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{ .eps = 0.0 }) });
    }
    try stdout.writeAll("\nBarely touching:\n");
    {
        var t1 = Trigon.init(.{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 });
        var t2 = Trigon.init(.{ .x = 1, .y = 0 }, .{ .x = 2, .y = 0 }, .{ .x = 1, .y = 1 });
        try stdout.print("{} and {} overlap = {}\n", .{ t1, t2, Trigon.tri2D(&t1, &t2, .{ .on_boundary = false }) });
    }
}

fn Point(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,

        pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("({d},{d})", .{ self.x, self.y });
        }
    };
}

fn Triangle(comptime T: type) type {
    return struct {
        const Self = @This();
        points: [3]Point(T),

        pub fn init(p0: Point(T), p1: Point(T), p2: Point(T)) Self {
            return Self{ .points = .{ p0, p1, p2 } };
        }

        pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("{},{},{}", .{ self.points[0], self.points[1], self.points[2] });
        }

        fn tri2D(
            t1: *Triangle(T),
            t2: *Triangle(T),
            params: struct {
                eps: T = math.floatEps(T),
                allow_reversed: bool = false,
                on_boundary: bool = true,
            },
        ) bool {
            const allow_reversed = params.allow_reversed;
            // Triangles must be expressed anti-clockwise
            t1.checkWinding(allow_reversed) catch return false;
            t2.checkWinding(allow_reversed) catch return false;

            const FuncPtr = *const fn (*const Point(T), *const Point(T), *const Point(T), f64) bool;
            const check_edge: FuncPtr = if (params.on_boundary)
                // Points on the boundary are considered as colliding
                boundaryCollideCheck
            else
                // Points on the boundary are not considered as colliding
                boundaryNotCollideCheck;

            const eps = params.eps;

            // For edge E of triangle 1,
            for (0..3) |i| {
                const j = (i + 1) % 3;

                // Check all points of triangle 2 lay on the external side of
                // the edge E. If they do, the triangles do not collide.
                if (check_edge(&t1.points[i], &t1.points[j], &t2.points[0], eps) and
                    check_edge(&t1.points[i], &t1.points[j], &t2.points[1], eps) and
                    check_edge(&t1.points[i], &t1.points[j], &t2.points[2], eps))
                {
                    return false;
                }
            }

            // For edge E of triangle 2,
            for (0..3) |i| {
                const j = (i + 1) % 3;

                // Check all points of triangle 1 lay on the external side of
                // the edge E. If they do, the triangles do not collide.
                if (check_edge(&t2.points[i], &t2.points[j], &t1.points[0], eps) and
                    check_edge(&t2.points[i], &t2.points[j], &t1.points[1], eps) and
                    check_edge(&t2.points[i], &t2.points[j], &t1.points[2], eps))
                {
                    return false;
                }
            }

            // The triangles collide
            return true;
        }

        const CheckWindingError = error{
            PositiveDeterminant,
        };

        fn checkWinding(self: *Self, allow_reversed: bool) !void {
            const det_tri = Self.det2D(&self.points[0], &self.points[1], &self.points[2]);
            if (det_tri < 0) {
                if (allow_reversed) {
                    mem.swap(Point(T), &self.points[1], &self.points[2]);
                } else {
                    return CheckWindingError.PositiveDeterminant;
                }
            }
        }

        const PointPtr = *const Point(T); // Simplify to reduce code clutter.

        fn det2D(p1: PointPtr, p2: PointPtr, p3: PointPtr) T {
            return p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y);
        }

        fn boundaryCollideCheck(p1: PointPtr, p2: PointPtr, p3: PointPtr, eps: T) bool {
            return det2D(p1, p2, p3) < eps;
        }

        fn boundaryNotCollideCheck(p1: PointPtr, p2: PointPtr, p3: PointPtr, eps: T) bool {
            return det2D(p1, p2, p3) <= eps;
        }
    };
}
