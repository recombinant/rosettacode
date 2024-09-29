// https://rosettacode.org/wiki/Chowla_numbers
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    {
        for (1..38) |i|
            print("chowla({}) = {}\n", .{ i, chowla(i) });
    }
    {
        const limit = 10_000_000;
        const c = sieve(limit);
        var count: usize = 1;
        var power: usize = 100;
        var i: usize = 3;
        while (i < limit) : (i += 2) {
            if (!c.isSet(i))
                count += 1;
            if (i == power - 1) {
                print("Count of primes up to {} = {}\n", .{ power, count });
                power *= 10;
            }
        }
    }
    {
        const limit = 35_000_000;
        var count: usize = 0;
        var k: usize = 2;
        var kk: usize = 3;

        while (true) {
            const p = k * kk;
            if (p > limit) break;
            if (chowla(p) == (p - 1)) {
                print("{} is a number that is perfect\n", .{p});
                count += 1;
            }
            k = kk + 1;
            kk += k;
        }
        print("There are {} perfect numbers <= 35,000,000\n", .{count});
    }
}

fn chowla(n: usize) usize {
    var sum: usize = 0;
    var i: usize = 2;
    while ((i * i) <= n) : (i += 1)
        if (n % i == 0) {
            const j = n / i;
            sum += i + if (i == j) 0 else j;
        };
    return sum;
}

fn sieve(comptime limit: usize) std.StaticBitSet(limit) {
    // True denotes composite, false denotes prime.
    // Only interested in odd numbers >= 3
    var c = std.StaticBitSet(limit).initEmpty();
    for (0..3) |i|
        c.unset(i);

    var i: usize = 3;
    while ((i * 3) < limit) : (i += 2)
        if (!c.isSet(i) and (chowla(i) == 0)) {
            var j = 3 * i;
            while (j < limit) : (j += 2 * i)
                c.set(j);
        };

    return c;
}
