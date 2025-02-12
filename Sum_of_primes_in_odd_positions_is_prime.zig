// https://rosettacode.org/wiki/Sum_of_primes_in_odd_positions_is_prime
const std = @import("std");

pub fn main() !void {
    var t0 = try std.time.Timer.start();

    var sum: u32 = 0;

    const writer = std.io.getStdOut().writer();
    try writer.writeAll(" i   p[i]  Σp[i]\n");
    try writer.writeAll("----------------\n");

    var i: usize = 1;
    var p: u16 = 2;
    var inc: u16 = 1;
    while (p < 1000) : ({
        p += inc;
        inc = 2;
    }) {
        if (isPrime(p)) {
            if (i & 1 != 0) {
                sum += p;
                if (isPrime(sum))
                    try writer.print("{d:3}   {d:3}  {d:5}\n", .{ i, p, sum });
            }
            i += 1;
        }
    }
    try writer.writeByte('\n');

    std.log.info("processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
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
