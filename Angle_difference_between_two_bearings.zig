// https://rosettacode.org/wiki/Angle_difference_between_two_bearings
const std = @import("std");
const math = std.math;
const print = std.debug.print;

fn getDifference(b1: anytype, b2: anytype) @TypeOf(b1, b2) {
    const info_b1 = @typeInfo(@TypeOf(b1));
    const info_b2 = @typeInfo(@TypeOf(b2));
    if (info_b1 == .Int and info_b1.Int.signedness != .signed) {
        @compileError("b1 must be floating point, comptime integer, or signed integer.");
    }
    if (info_b2 == .Int and info_b1.Int.signedness != .signed) {
        @compileError("b2 must be floating point, comptime integer, or signed integer.");
    }
    return math.wrap(b2 - b1, 180);
}

pub fn main() void {
    print("{d}\n", .{getDifference(20, 45)});
    print("{d}\n", .{getDifference(-45, 45)});
    print("{d}\n", .{getDifference(-85, 90)});
    print("{d}\n", .{getDifference(-95, 90)});
    print("{d}\n", .{getDifference(-45, 125)});
    print("{d}\n", .{getDifference(-45, 145)});
    print("{d}\n", .{getDifference(29.4803, -88.6381)});
    print("{d}\n", .{getDifference(-78.3251, -159.036)});
    print("{d}\n", .{getDifference(-70099.74233810938, 29840.67437876723)});
    print("{d}\n", .{getDifference(-165313.6666297357, 33693.9894517456)});
    print("{d}\n", .{getDifference(1174.8380510598456, -154146.66490124757)});
    print("{d}\n", .{getDifference(60175.77306795546, 42213.07192354373)});
}
