// https://rosettacode.org/wiki/Feigenbaum_constant_calculation
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Feigenbaum constant calculation:\n");

    const max_i = 12;
    const max_j = 10;
    var a1: f64 = 1.0;
    var a2: f64 = 0.0;
    var d1: f64 = 3.2;
    try stdout.print("{s:2}  {s:10}  {s:10}\n", .{ "i", "a", "d" });

    for (2..max_i + 2) |i| {
        var a = a1 + (a1 - a2) / d1;
        for (0..max_j) |_| { // Newton
            var x: f64 = 0;
            var y: f64 = 0;
            for (0..std.math.pow(usize, 2, i)) |_| {
                y = 1 - 2 * y * x;
                x = a - x * x;
            }
            a -= x / y;
        }
        const d = (a1 - a2) / (a - a1);
        try stdout.print("{d:>2}  {d:1.8}  {d:1.8}\n", .{ i, a, d });

        d1 = d;
        a2 = a1;
        a1 = a;
    }

    try stdout.flush();
}
