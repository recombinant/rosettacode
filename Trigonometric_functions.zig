// https://www.rosettacode.org/wiki/Trigonometric_functions
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");
const math = std.math;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

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
    var temp = math.asin(@sin(radians));
    try stdout.print("{d} {d}\n", .{ temp, math.radiansToDegrees(temp) });
    // arccosine
    temp = math.acos(@cos(radians));
    try stdout.print("{d} {d}\n", .{ temp, math.radiansToDegrees(temp) });
    // arctangent
    temp = math.atan(@tan(radians));
    try stdout.print("{d} {d}\n", .{ temp, math.radiansToDegrees(temp) });

    try stdout.flush();
}

// The following functions are also available:
// atan2, asinh, acosh, atanh, sinh, cosh, tanh
