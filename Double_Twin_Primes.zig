// https://rosettacode.org/wiki/Double_Twin_Primes
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const sieve: Sieve(1000) = .init();
    print("Double twin primes under 1,000:\n", .{});

    var i: u32 = 3;
    while (i < 992) : (i += 2)
        if (sieve.isPrime(i) and sieve.isPrime(i + 2) and sieve.isPrime(i + 6) and sieve.isPrime(i + 8))
            print("{d:4} {d:4} {d:4} {d:4}\n", .{ i, i + 2, i + 6, i + 8 });
}

/// Sieve of Eratosthenes
fn Sieve(comptime max: usize) type {
    return struct {
        const Self = @This();
        const T = std.StaticBitSet(max + 1);

        primes: T,

        fn init() Self {
            var result: Self = .{ .primes = T.initFull() };

            const primes = &result.primes;
            primes.unset(0);
            primes.unset(1);

            const limit = max + 1;
            const root_limit = std.math.sqrt(limit) + 1;
            // Sieve of Eratosthenes
            for (2..root_limit) |n|
                if (primes.isSet(n)) {
                    var k = n * n;
                    while (k < limit) : (k += n)
                        primes.unset(k);
                };

            return result;
        }

        fn isPrime(self: *const Self, n: usize) bool {
            return self.primes.isSet(n);
        }
    };
}

// fn isPrime(n: u32) bool {
//     if (n < 2) return false;
//     if (n % 2 == 0) return n == 2;
//     if (n % 3 == 0) return n == 3;
//     var d: u32 = 5;
//     while (d * d <= n) {
//         if (n % d == 0) return false;
//         d += 2;
//         if (n % d == 0) return false;
//         d += 4;
//     }
//     return true;
// }

const testing = std.testing;

test "isPrime" {
    const sieve: Sieve(1000) = .init();

    const primes = [_]u32{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 991, 997 };
    const non_primes = [_]u32{ 0, 1, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 996, 998 };

    for (&primes) |n|
        try testing.expect(sieve.isPrime(n));
    for (&non_primes) |n|
        try testing.expect(!sieve.isPrime(n));
}
