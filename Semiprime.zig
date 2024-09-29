// https://www.rosettacode.org/wiki/Semiprime
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var v: u32 = 1675;
    while (v <= 1680) : (v += 1)
        try stdout.print("{d} {s} semiprime\n", .{ v, if (isSemiPrime(v)) "is" else "isn't" });
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
