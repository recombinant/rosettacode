// https://rosettacode.org/wiki/Factorions
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // cache factorials from 0 to 11
    var factorial: [12]usize = undefined;
    factorial[0] = 1;
    for (1..factorial.len) |n|
        factorial[n] = factorial[n - 1] * n;

    for (9..12 + 1) |base| {
        try stdout.print("The factorions for base {d} are:\n", .{base});
        for (1..1_500_000) |i| {
            var n: usize = i;

            var sum: usize = 0;
            while (n >= base) {
                sum += factorial[n % base];
                n /= base;
            }
            sum += factorial[n];

            if (sum == i)
                try printFactorion(i, @intCast(base), stdout);
        }
        try stdout.writeByte('\n');
    }
    try stdout.flush();
}

fn printFactorion(n: usize, base: u8, w: *Io.Writer) !void {
    if (base != 10) {
        var buffer: [10]u8 = undefined;
        const len = std.fmt.printInt(&buffer, n, base, .lower, .{});
        try w.print("  {s} (decimal {})\n", .{ buffer[0..len], n });
    } else {
        try w.print("  {}\n", .{n});
    }
    try w.flush();
}
