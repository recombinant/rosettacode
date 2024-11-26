// https://rosettacode.org/wiki/Miller–Rabin_primality_test
// Translation of
// https://algoteka.com/samples/46/miller%25E2%2580%2593rabin-primality-test-c-plus-plus-simple-64-bit-implementation
const std = @import("std");

pub fn main() !void {
    // -------------------------------------------- random number
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    std.debug.print("{}\n", .{primeTest(5127821565631733, random, .{})});
    // https://t5k.org/lists/2small/0bit.html
    std.debug.print("{}\n", .{primeTest(std.math.pow(u64, 2, 63) - 471, random, .{})});
}

/// Compute a*b % mod
fn modmult(a_: u64, b_: u64, mod: u64) u64 {
    var a = a_;
    var b = b_;
    var result: u64 = 0;
    while (b != 0) {
        if (b % 2 == 1)
            result = (result + a) % mod;
        a = (a + a) % mod;
        b /= 2;
    }
    return result;
}

/// Compute a^b % mod
fn modpow(a_: u64, b_: u64, mod: u64) u64 {
    var a = a_;
    var b = b_;
    var result: u64 = 1;
    while (b != 0) {
        if (b % 2 == 1)
            result = modmult(result, a, mod);
        a = modmult(a, a, mod);
        b /= 2;
    }
    return result;
}

const PrimeTestOptions = struct {
    num_tests: usize = 20,
};

/// Miller–Rabin primality test.
fn primeTest(n: u64, random: std.Random, options: PrimeTestOptions) bool {
    const primes = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23 };
    for (primes) |p|
        if (n % p == 0)
            return n == p;
    if (n < primes[primes.len - 1])
        return false;

    var d = n - 1;
    var s: usize = 0;
    while (d % 2 == 0) {
        s += 1;
        d /= 2;
    }
    for (0..options.num_tests) |_| {
        const a = random.intRangeAtMost(u64, 2, n - 2);
        var x = modpow(a, d, n);
        for (0..s) |_| {
            const y = modmult(x, x, n);
            if (y == 1 and x != 1 and x != n - 1) {
                // Nontrivial square root of 1 modulo n
                // (x+1)(x-1) divisible by n, meaning gcd(x+1, n) is a factor of n, negating primality
                return false;
            }
            x = y;
        }
        if (x != 1)
            return false;
    }
    // Number is prime with likelihood of (1/4)^num_tests
    return true;
}

const testing = std.testing;
test "primeTest primes" {
    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();

    const primes = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };
    for (primes) |p|
        try testing.expect(primeTest(p, random, .{}));
}

test "primeTest composites" {
    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();

    const primes = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };
    var i: u64 = 1;
    while (i < 31) : (i += 1)
        if (std.mem.indexOfScalar(u64, &primes, i) == null)
            try testing.expect(!primeTest(i, random, .{}));
}

test "primeTest large primes" {
    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();

    const n = std.math.pow(u64, 2, 62);
    // https://t5k.org/lists/2small/0bit.html
    var primes = [_]u64{ 57, 87, 117, 143, 153, 167, 171, 195, 203, 273 };
    for (&primes) |*p| {
        p.* = n - p.*;
    }
    for (primes) |p| try testing.expect(primeTest(p, random, .{}));
}

test "primeTest large composites" {
    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();

    const n = std.math.pow(u64, 2, 62);
    // https://t5k.org/lists/2small/0bit.html
    var primes = [_]u64{ 57, 87, 117, 143, 153, 167, 171, 195, 203, 273 };
    for (&primes) |*p| {
        p.* = n - p.*;
    }
    var i = primes[primes.len - 1];
    while (i <= n) : (i += 1)
        if (std.mem.indexOfScalar(u64, &primes, i) == null)
            try testing.expect(!primeTest(i, random, .{}));
}
