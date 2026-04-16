// https://www.rosettacode.org/wiki/Almost_prime
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");
const Io = std.Io;

fn kprime(n0: u32, k: u32) bool {
    var n = n0;
    var p: u32 = 2;
    var f: u32 = 0;
    while (f < k and p * p <= n) : (p += 1)
        while (0 == n % p) {
            n /= p;
            f += 1;
        };

    return f + @intFromBool(n > 1) == k;
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var k: u32 = 1;
    while (k <= 5) : (k += 1) {
        try stdout.print("k = {d}:", .{k});

        var i: u32 = 2;
        var c: u32 = 0;
        while (c < 10) : (i += 1)
            if (kprime(i, k)) {
                try stdout.print(" {d}", .{i});
                c += 1;
            };

        try stdout.writeByte('\n');
    }
    try stdout.flush();
}
