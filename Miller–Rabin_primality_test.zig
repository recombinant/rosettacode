// https://rosettacode.org/wiki/Miller–Rabin_primality_test
// {{works with|Zig|0.15.1}}
// Translation of
// https://algoteka.com/samples/46/miller%25E2%2580%2593rabin-primality-test-c-plus-plus-simple-64-bit-implementation
const std = @import("std");

pub fn main() !void {
    // -------------------------------------------- random number
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    std.debug.print("{} (expected true)\n", .{primeTest(@as(u64, 5127821565631733), random, .{})});

    // https://t5k.org/lists/2small/0bit.html
    std.debug.print("{} (expected true)\n", .{primeTest(std.math.pow(u64, 2, 63) - 471, random, .{})});

    // https://t5k.org/lists/2small/300bit.html
    std.debug.print("{} (expected true)\n", .{primeTest(std.math.pow(u401, 2, 400) - 593, random, .{})});

    // https://t5k.org/lists/2small/300bit.html
    std.debug.print("{} (expected false)\n", .{primeTest(std.math.pow(u401, 2, 400) - 591, random, .{})});
}

/// Compute a*b % mod
fn modmult(T: type, a_: T, b_: T, mod: T) T {
    var a = a_;
    var b = b_;
    var result: T = 0;
    while (b != 0) {
        if (b % 2 == 1)
            result = (result + a) % mod;
        a = (a + a) % mod;
        b /= 2;
    }
    return result;
}

/// Compute a^b % mod
fn modpow(T: type, a_: T, b_: T, mod: T) T {
    var a = a_;
    var b = b_;
    var result: T = 1;
    while (b != 0) {
        if (b % 2 == 1)
            result = modmult(T, result, a, mod);
        a = modmult(T, a, a, mod);
        b /= 2;
    }
    return result;
}

const PrimeTestOptions = struct {
    num_tests: usize = 20,
};

/// Miller–Rabin primality test.
fn primeTest(n: anytype, random: std.Random, options: PrimeTestOptions) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("primeTest() expected unsigned integer argument, found " ++ @typeName(T));
    if (@typeInfo(T).int.bits < 6)
        @compileError("primeTest() expected minimum 6 bit argument, found " ++ @typeName(T));

    const primes = [_]T{ 2, 3, 5, 7, 11, 13, 17, 19, 23 };
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
        const a = random.intRangeAtMost(T, 2, n - 2);
        var x = modpow(T, a, d, n);
        for (0..s) |_| {
            const y = modmult(T, x, x, n);
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
    var prng: std.Random.DefaultPrng = .init(testing.random_seed);
    const random = prng.random();

    const primes = [_]u7{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };
    for (primes) |p|
        try testing.expect(primeTest(p, random, .{}));
}

test "primeTest composites" {
    var prng: std.Random.DefaultPrng = .init(testing.random_seed);
    const random = prng.random();

    const primes = [_]u7{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29 };
    var i: u7 = 1;
    while (i < 31) : (i += 1)
        if (std.mem.indexOfScalar(u7, &primes, i) == null)
            try testing.expect(!primeTest(i, random, .{}));
}

test "primeTest large primes" {
    var prng: std.Random.DefaultPrng = .init(testing.random_seed);
    const random = prng.random();

    const n64 = std.math.pow(u64, 2, 62);
    // https://t5k.org/lists/2small/0bit.html
    var primes64 = [_]u64{ 57, 87, 117, 143, 153, 167, 171, 195, 203, 273 };
    for (&primes64) |*p|
        p.* = n64 - p.*;
    for (primes64) |p| try testing.expect(primeTest(p, random, .{}));

    const n128 = std.math.pow(u128, 2, 126);
    // https://t5k.org/lists/2small/100bit.html
    var primes128 = [_]u128{ 137, 203, 237, 261, 335, 341, 465, 663, 671, 783 };
    for (&primes128) |*p|
        p.* = n128 - p.*;
    for (primes128) |p| try testing.expect(primeTest(p, random, .{}));
}

test "primeTest large composites" {
    var prng: std.Random.DefaultPrng = .init(testing.random_seed);
    const random = prng.random();

    const n64 = std.math.pow(u64, 2, 62);
    // https://t5k.org/lists/2small/0bit.html
    var primes64 = [_]u64{ 57, 87, 117, 143, 153, 167, 171, 195, 203, 273 };
    for (&primes64) |*p|
        p.* = n64 - p.*;
    var i = primes64[primes64.len - 1];
    while (i <= n64) : (i += 1)
        if (std.mem.indexOfScalar(u64, &primes64, i) == null)
            try testing.expect(!primeTest(i, random, .{}));

    const n128 = std.math.pow(u127, 2, 126);
    // https://t5k.org/lists/2small/100bit.html
    var primes128 = [_]u128{ 137, 203, 237, 261, 335, 341, 465, 663, 671, 783 };
    for (&primes128) |*p|
        p.* = n128 - p.*;
    var j = primes128[primes128.len - 1];
    while (j <= n128) : (j += 1)
        if (std.mem.indexOfScalar(u128, &primes128, j) == null)
            try testing.expect(!primeTest(j, random, .{}));
}
