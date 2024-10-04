// https://rosettacode.org/wiki/Product_of_min_and_max_prime_factors
const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() void {
    const limit = 100;

    const sieve = comptime createSieve(limit + 1);
    assert(sieve.len == limit + 1);

    for (1..limit + 1) |n| {
        const sep: u8 = if (n % 10 == 0) '\n' else ' ';
        const factor1, const factor2 = minmaxFactors(&sieve, n);
        print("{d:6}{c}", .{ factor1 * factor2, sep });
    }
}

/// Minimum and maximum prime factors of n
fn minmaxFactors(sieve: []const bool, n: usize) struct { usize, usize } {
    if (n <= 1)
        return .{ n, n };

    const min_ = blk: {
        for (sieve[2..], 2..) |p, i|
            if (p and n % i == 0)
                break :blk i;
        unreachable;
    };

    const max_ = blk: {
        var i = n;
        while (i >= 2) : (i -= 1)
            if (sieve[i] and n % i == 0)
                break :blk i;
        unreachable;
    };

    return .{ min_, max_ };
}

/// Sieve of Eratosthenes returning an array of bool. Simple.
fn createSieve(comptime limit: anytype) [limit]bool {
    var sieve: [limit]bool = undefined;
    @memset(&sieve, true);
    sieve[0] = false;
    sieve[1] = false;

    var i: usize = 2;
    while (i * i <= limit) : (i += 1) {
        var j = i * i;
        while (j <= limit) : (j += i)
            sieve[j] = false;
    }
    return sieve;
}
