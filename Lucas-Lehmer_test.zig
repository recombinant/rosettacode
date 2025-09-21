// https://rosettacode.org/wiki/Lucas-Lehmer_test
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const T = u2056;
    const upb: T = std.math.log2(std.math.maxInt(T)) / 2;

    var p: u16 = 2;
    try stdout.print(" Mersenne primes:\n", .{});
    while (p <= upb) : (p += 1)
        if (isPrime(p) and isMersennePrime(T, p)) {
            try stdout.print(" M{}", .{p});
            try stdout.flush();
        };
    try stdout.writeByte('\n');

    try stdout.flush();
}

fn isMersennePrime(T: type, p: u16) bool {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isMersennePrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (p == 2) return true;

    // Mersenne prime
    const m_p: T = std.math.shl(T, 1, p) - 1;

    // Lucas-Lehmer test
    var s: T = 4;
    var i: T = 3;
    while (i <= p) : (i += 1)
        s = (s * s - 2) % m_p;
    return s == 0;
}

fn isPrime(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 2) return false;

    inline for ([3]u3{ 2, 3, 5 }) |p| if (n % p == 0) return n == p;

    const wheel = comptime [_]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: T = 7;
    while (true)
        for (wheel) |w| {
            if (p * p > n) return true;
            if (n % p == 0) return false;
            p += w;
        };
}
