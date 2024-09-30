// https://www.rosettacode.org/wiki/Trigonometric_functions
// Translation of C
const std = @import("std");
const math = std.math;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const pi: f64 = math.pi;
    // pi / 4 is 45 degrees. All answers should be the same
    const radians = pi / 4;
    const degrees = 45;
    // sine
    try stdout.print("{d} {d}\n", .{ @sin(radians), @sin(math.degreesToRadians(degrees)) });
    // cosine
    try stdout.print("{d} {d}\n", .{ @cos(radians), @cos(math.degreesToRadians(degrees)) });
    // tangent
    try stdout.print("{d} {d}\n", .{ @tan(radians), @tan(math.degreesToRadians(degrees)) });
    // arcsine
    var temp: f64 = math.asin(@as(f64, @sin(radians)));
    try stdout.print("{d} {d}\n", .{ temp, math.radiansToDegrees(temp) });
    // arccosine
    temp = math.acos(@as(f64, @cos(radians)));
    try stdout.print("{d} {d}\n", .{ temp, math.radiansToDegrees(temp) });
    // arctangent
    temp = math.atan(@as(f64, @tan(radians)));
    try stdout.print("{d} {d}\n", .{ temp, math.radiansToDegrees(temp) });
}

// The following functions are also available:
// atan2, asinh, acosh, atanh, sinh, cosh, tanh
