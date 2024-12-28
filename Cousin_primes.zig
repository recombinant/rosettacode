// https://rosettacode.org/wiki/Cousin_primes
const std = @import("std");
const math = std.math;
const print = std.debug.print;

fn Sieve(comptime max: usize) type {
    return struct {
        const Self = @This();
        const T = std.StaticBitSet(max + 1);

        primes: T,

        fn init() Self {
            var result = Self{ .primes = T.initFull() };

            const primes = &result.primes;
            primes.unset(0);
            primes.unset(1);

            const limit = max + 1;
            const root_limit = math.sqrt(limit) + 1;
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

pub fn main() void {
    const limit = 1000;
    var eratosthenes = Sieve(limit).init();

    var count: usize = 0;
    for (1..limit - 3) |p|
        if (eratosthenes.isPrime(p) and eratosthenes.isPrime(p + 4)) {
            count += 1;
            print("{d:4}: :{d:4}\n", .{ p, p + 4 });
        };

    print("There are {d} cousin prime pairs below {d}\n", .{ count, limit });
}
