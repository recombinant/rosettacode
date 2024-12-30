// https://rosettacode.org/wiki/Ultra_useful_primes
// Uses Miller-Rabin primality test from https://rosettacode.org/wiki/Miller–Rabin_primality_test
const std = @import("std");

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    inline for (1..11) |i|
        std.debug.print("{d:2} {d}\n", .{ i, useful(@intCast(i), random) });
}

fn useful(comptime n: u16, random: std.Random) u16 {
    var k: u16 = 1;
    // The number of integer bits in T depends on n
    const T = if (n < 6) u64 else std.meta.Int(.unsigned, std.math.pow(u16, 2, n) + 1);
    // std.debug.print("({}) ", .{ T });
    var np = std.math.pow(T, 2, @as(T, @intCast(std.math.pow(u16, 2, n)))) - 1;
    while (true) {
        // std.debug.print("{}=", .{k});
        if (primeTest(np, random, .{}))
            return k;
        k += 2;
        np -= 2;
    }
    unreachable;
}

// --------------------------------------------------------------
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
// --------------------------------------------------------------
