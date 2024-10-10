// https://rosettacode.org/wiki/Map_range
// Translation of C
const std = @import("std");

const print = std.debug.print;

pub fn main() void {
    print("Mapping [0,10] to [-1,0] at intervals of 1:\n", .{});

    var n: f64 = 0;
    while (n <= 10) : (n += 1)
        print("f({d}) = {d:.1}\n", .{ n, mapRange(0, 10, -1, 0, n) });
}

fn mapRange(a1: f64, a2: f64, b1: f64, b2: f64, s: f64) f64 {
    return (b1 + (s - a1) * (b2 - b1) / (a2 - a1));
}
