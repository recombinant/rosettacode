// https://rosettacode.org/wiki/Sieve_of_Eratosthenes
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
    const max_prime = 1000;
    var eratosthenes = Sieve(max_prime).init();

    // print the prime numbers up to and including `max_prime`
    var sep: u8 = ' ';
    var count: usize = 0;
    for (1..max_prime + 1) |n|
        if (eratosthenes.isPrime(n)) {
            count += 1;
            sep = if (count % 20 != 0) ' ' else '\n';
            print("{d:3}{c}", .{ n, sep });
        };
    if (sep != '\n')
        print("\n", .{});
}
