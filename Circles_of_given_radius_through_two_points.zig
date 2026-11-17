// https://rosettacode.org/wiki/Circles_of_given_radius_through_two_points
// {{works with|Zig|0.17.1}}
// {{trans|Crow}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Writer = Io.Writer;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    // ----------------------------------------------------------

    try report(.{ .x = 0.1234, .y = 0.9876 }, .{ .x = 0.8765, .y = 0.2345 }, 2.0, stdout);
    try report(.{ .x = 0.0, .y = 2.0 }, .{ .x = 0.0, .y = 0.0 }, 1.0, stdout);
    try report(.{ .x = 0.1234, .y = 0.9876 }, .{ .x = 0.1234, .y = 0.9876 }, 2.0, stdout);
    try report(.{ .x = 0.1234, .y = 0.9876 }, .{ .x = 0.8765, .y = 0.2345 }, 0.5, stdout);
    try report(.{ .x = 0.1234, .y = 0.9876 }, .{ .x = 0.1234, .y = 0.9876 }, 0.0, stdout);

    // ----------------------------------------------------------
    try stdout.flush();
}

fn report(p: Point, q: Point, r: f64, w: *Writer) !void {
    try w.print("Points {f} and {f}, radius {d}:\n    ", .{ p, q, r });
    const found = circles(p, q, r) catch |err| {
        switch (err) {
            error.Coincident => try w.writeAll("the points coincide: infinitely many circles of this radius pass through them\n"),
            error.ZeroRadius => try w.writeAll("no circle: a radius of zero draws none through two points\n"),
            error.Separation => try w.writeAll("no circle: the points are farther apart than a diameter\n"),
        }
        return;
    };
    if (found[1] != null)
        try w.print("two circles, centred at {f} and {f}\n", .{ found[0].c, found[1].?.c })
    else if (found[0].r == 0.0)
        try w.print("one circle of radius {}, the point {f} itself\n", .{ found[0].r, found[0].c })
    else
        try w.print("one circle, the points a diameter of it, centred at {f}\n", .{found[0].c});
}

const Point = struct {
    x: f64,
    y: f64,
    pub fn format(self: *const Point, w: *Writer) !void {
        try w.print("({d:.4}, {d:.4})", .{ self.x, self.y });
    }
};

const Circle = struct {
    c: Point,
    r: f64,
};

fn circles(p: Point, q: Point, r: f64) !struct { Circle, ?Circle } {
    const dx = q.x - p.x;
    const dy = q.y - p.y;
    const apart = std.math.hypot(dx, dy);
    if (apart == 0.0) {
        if (r == 0.0)
            return .{ .{ .c = .{ .x = p.x, .y = p.y }, .r = 0.0 }, null };
        return error.Coincident;
    }
    if (r == 0.0)
        return error.ZeroRadius;
    if (apart > 2.0 * r)
        return error.Separation;
    const mx = (p.x + q.x) / 2.0;
    const my = (p.y + q.y) / 2.0;
    if (apart == 2.0 * r)
        return .{ .{ .c = .{ .x = mx, .y = my }, .r = r }, null };
    const d = @sqrt(r * r - std.math.pow(f64, (apart / 2.0), 2));
    return .{
        .{ .c = .{ .x = mx - d * dy / apart, .y = my + d * dx / apart }, .r = r },
        .{ .c = .{ .x = mx + d * dy / apart, .y = my - d * dx / apart }, .r = r },
    };
}
