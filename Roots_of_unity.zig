// https://rosettacode.org/wiki/Roots_of_unity
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (1..10) |n|
        for (0..n) |i| {
            var c: f64 = 0;
            var s: f64 = 0;

            if (i == 0)
                c = 1
            else if (n == 4 * i)
                s = 1
            else if (n == 2 * i)
                c = -1
            else if (3 * n == 4 * i)
                s = -1
            else {
                const a = @as(f64, @floatFromInt(i)) * std.math.pi * 2 / @as(f64, @floatFromInt(n));
                c = @cos(a);
                s = @sin(a);
            }

            // TODO: inadequate.
            if (c != 0) try stdout.print("{d:.2}", .{c});
            if (s == 1)
                try stdout.writeAll("i")
            else if (s == -1)
                try stdout.writeAll("-i")
            else if (s != 0) {
                if (s > 0) try stdout.writeAll("+");
                try stdout.print("{d:.2}i", .{s});
            } else {
                try stdout.writeAll("");
            }
            try stdout.writeAll(if (i == n - 1) "\n" else ",  ");
        };

    try stdout.flush();
}
