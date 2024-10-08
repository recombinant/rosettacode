// https://rosettacode.org/wiki/Length_of_an_arc_between_two_angles
const std = @import("std");
const math = std.math;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("{d:.7}\n", .{calcArcLength1(10, 10, 120)});

    try stdout.print("{d:.7}\n", .{calcArcLength2(10, .{ .angle1 = 10, .angle2 = 120 })});

    try stdout.print("{d:.7}\n", .{calcArcLength3(10, 10, 120)});
}

/// Simple 3 parameters
fn calcArcLength1(radius: f64, angle1: f64, angle2: f64) f64 {
    return math.degreesToRadians(360 - @abs(angle2 - angle1)) * radius;
}

/// Simple 2 parameters
/// second parameter is a struct containing the two angles
fn calcArcLength2(radius: f64, a: struct { angle1: f64, angle2: f64 }) f64 {
    return math.degreesToRadians(360 - @abs(a.angle2 - a.angle1)) * radius;
}

/// As per calcArcLength1() with comptime type checking.
fn calcArcLength3(radius: anytype, angle1: anytype, angle2: anytype) if (@TypeOf(radius, angle1, angle2) == comptime_int) comptime_float else @TypeOf(radius, angle1, angle2) {
    const T = if (@TypeOf(radius, angle1, angle2) == comptime_int) comptime_float else @TypeOf(radius, angle1, angle2);

    switch (@typeInfo(T)) {
        .float, .comptime_float => return math.degreesToRadians(360 - @abs(angle2 - angle1)) * radius,
        else => {},
    }
    @compileError("Inputs must be float or a comptime number");
}
