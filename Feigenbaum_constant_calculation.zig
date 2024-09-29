// https://rosettacode.org/wiki/Feigenbaum_constant_calculation
const std = @import("std");
const math = std.math;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    const writer = bw.writer();

    try writer.writeAll("Feigenbaum constant calculation:\n");

    const max_i = 12;
    const max_j = 10;
    var a1: f64 = 1.0;
    var a2: f64 = 0.0;
    var d1: f64 = 3.2;
    try writer.print("{s:2}  {s:10}  {s:10}\n", .{ "i", "a", "d" });

    for (2..max_i + 2) |i| {
        var a = a1 + (a1 - a2) / d1;
        for (0..max_j) |_| { // Newton
            var x: f64 = 0;
            var y: f64 = 0;
            for (0..math.pow(usize, 2, i)) |_| {
                y = 1 - 2 * y * x;
                x = a - x * x;
            }
            a -= x / y;
        }
        const d = (a1 - a2) / (a - a1);
        try writer.print("{d:>2}  {d:1.8}  {d:1.8}\n", .{ i, a, d });

        d1 = d;
        a2 = a1;
        a1 = a;
    }

    try bw.flush();
}
