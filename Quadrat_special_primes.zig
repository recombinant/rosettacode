// https://rosettacode.org/wiki/Quadrat_special_primes

// see also: https://rosettacode.org/wiki/Cubic_special_primes
const std = @import("std");
const print = std.debug.print;

// TODO: change output to match the more informative output of Wren.

pub fn main() void {
    const npl = 10; // numbers per line
    const limit = 16_000;
    var p: u32 = 2;
    var j: u32 = 1;
    var count: u16 = 1;
    print("{d:5} ", .{p});
    while (true) {
        while (true) {
            if (isPrime(p + j * j))
                break;
            j += 1;
        }
        p += j * j;
        if (p >= limit)
            break;
        count += 1;
        const sep: u8 = if (count % npl != 0) ' ' else '\n';
        print("{d:5}{c}", .{ p, sep });
        j = 1;
    }
    if (count % npl != 0) print("\n", .{});
    print("\nThere are {d} matching Quadrat Special Primes below {d}\n", .{ count, limit });
}

fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u32 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}
