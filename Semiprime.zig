// https://www.rosettacode.org/wiki/Semiprime
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var v: u32 = 1675;
    while (v <= 1680) : (v += 1) {
        try stdout.print("{d} {s} semiprime\n", .{ v, if (isSemiPrime(v)) "is" else "isn't" });
        try stdout.flush();
    }
}

fn isSemiPrime(n0: u32) bool {
    var n = n0;
    var nf: u2 = 0;
    var i: @TypeOf(n) = 2;
    while (i <= n) : (i += 1)
        while (n % i == 0) {
            if (nf == 2)
                return false;
            nf += 1;
            n /= i;
        };
    return nf == 2;
}
