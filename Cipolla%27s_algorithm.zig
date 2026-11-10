// https://rosettacode.org/wiki/Cipolla%27s_algorithm
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const Io = std.Io;
const Random = std.Random;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    // ---------------------------------- random number generator
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    // ----------------------------------------------------------
    try findSolutions(random, 10, 13, stdout);
    try findSolutions(random, 56, 101, stdout);
    try findSolutions(random, 8_218, 10_007, stdout);
    try findSolutions(random, 8_219, 10_007, stdout); // Should have no solution
    try findSolutions(random, 331_575, 1_000_003, stdout);
    try findSolutions(random, 665_165_880, 1_000_000_007, stdout);
    try findSolutions(random, 881_398_088_036, 1_000_000_000_039, stdout);
    try findSolutions(random, 12_345_678_901_234_567, 1_000_000_000_000_000_031, stdout);
    // ----------------------------------------------------------
    try stdout.flush();
}

/// Tonelli-Shanks algorithm to find modular square root x such that x^2 = n (mod p)
fn findSolutions(random: Random, nOrig: u64, p: u64, w: *Io.Writer) !void {
    try w.print("Finding solutions for number = {} and prime = {}:\n", .{ nOrig, p });

    // Ensure n is reduced modulo p for calculations
    const n = nOrig % p;

    if (p == 2) {
        // Special case for p=2: sqrt(n) = n (mod 2)
        if (n == 0) {
            try w.writeAll("Square root of 0 mod 2 is 0\n");
        } else { // n == 1
            try w.writeAll("Square root of 1 mod 2 is 1\n");
        }
        try w.writeByte('\n');
        return;
    }

    if (!isPrime(p)) {
        try w.print("No solutions, since p={} is not an odd prime.\n\n", .{p});
        return;
    }

    // Handle n=0 separately
    if (n == 0) {
        try w.print("Square root of 0 mod {} is 0\n\n", .{p});
        return;
    }

    // Step 1: Check if n is a quadratic residue using Legendre symbol
    const leg_sym = legendreSymbol(n, p);
    if (leg_sym != 1) {
        if (leg_sym == -1) {
            try w.print("No solutions, since {} is not a quadratic residue mod {}\n\n", .{ nOrig, p });
        } else { // legSym == 0 implies n is divisible by p
            try w.print("Square root of 0 mod {} is 0\n\n", .{p}); // Should have been caught by n==0 check
        }
        return;
    }

    // Step 2: Find a quadratic non-residue 'a' mod p
    var a: u64 = undefined;
    var w2: u64 = undefined;
    while (true) {
        // Choose a random 'a' in [1, p-1]
        a = rangeRandom(random, 1, p - 1);
        const a_squared = multiplyModulus(a, a, p);
        // Calculate w2 = (a^2 - n) mod p = (a^2 + p - n) mod p
        w2 = (a_squared + p - n) % p;

        if (legendreSymbol(w2, p) == -1) {
            // Found a suitable 'a', so w2 is a non-residue
            break;
        }
        // If legendreSymbol(w2, p) == 0, means a^2 = n (mod p), so 'a' is a root!
        if (legendreSymbol(w2, p) == 0) {
            const x1 = a;
            const x2 = p - x1;
            try w.print("Square roots of {} are ( {} and {} ) mod {}\n\n", .{ nOrig, x1, x2, p });
            return;
        }
        // Otherwise, legendreSymbol(w2, p) == 1, try another 'a'.
    }

    // Step 3: Compute R = (a + sqrt(w2))^((p+1)/2) in F(p^2)
    const initial_fp2: Fp2 = .{ .x = a, .y = 1 };
    const power = (p + 1) / 2;
    const result_fp2 = powerFp2(initial_fp2, power, p, w2);

    // The roots should be the 'x' component of the result.
    if (result_fp2.y != 0) {
        // This shouldn't happen if n is a quadratic residue and p is prime.
        try w.writeAll("Error in Tonelli-Shanks: Imaginary part is non-zero.\n");
        try w.print("Algorithm failed for n={}, p={}\n\n", .{ nOrig, p });
        return;
    }

    const x1 = result_fp2.x;
    const x2 = p - x1; // The other root is p - x1

    // Verification (optional but good practice)
    if (multiplyModulus(x1, x1, p) == n and multiplyModulus(x2, x2, p) == n) {
        try w.print("Square roots of {} are ( {} and {} ) mod {}\n\n", .{ nOrig, x1, x2, p });
    } else {
        try w.print("Error: Verification failed. x1^2={}, x2^2={}, expected={}\n", .{
            multiplyModulus(x1, x1, p),
            multiplyModulus(x2, x2, p),
            n,
        });
        try w.print("Algorithm failed for n={}, p={}\n\n", .{ nOrig, p });
    }
}

// Random number generator in range [min, max]
fn rangeRandom(random: Random, min: u64, max: u64) u64 {
    if (min > max) return min;
    // directly pull a number in [min, max]
    return random.intRangeAtMost(u64, min, max);
}

// Return a * b mod modulus using u128 intermediate to prevent overflow
fn multiplyModulus(a: u64, b: u64, modulus: u64) u64 {
    if (modulus == 0) {
        @panic("Modulo cannot be zero");
    }
    return @intCast(std.math.mulWide(u64, a, b) % modulus);
}

// Return base^power mod modulus (Modular Exponentiation)
fn powerModulus(base_param: u64, power_param: u64, modulus: u64) u64 {
    if (modulus == 1) return 0; // Edge case: result is always 0 mod 1

    var base = base_param % modulus; // Reduce base initially
    var power = power_param;
    var result: u64 = 1;

    while (power > 0) {
        // If power is odd, multiply result with base
        if ((power & 1) == 1) {
            result = multiplyModulus(result, base, modulus);
        }
        // Square the base and reduce modulo
        base = multiplyModulus(base, base, modulus);
        // Halve the power
        power >>= 1;
    }
    return result;
}

// Helper function for the 'isPrime' function (Miller-Rabin witness test)
fn isWitness(a: u64, n: u64) bool {
    if (a == 0) return false; // 0 is not a useful witness

    const n_minus1 = n - 1;
    // Find t, u such that n - 1 = 2^t * u where u is odd
    var t: u64 = 0;
    var u = n_minus1;
    while ((u & 1) == 0) {
        t += 1;
        u >>= 1;
    }

    // Calculate a^u mod n
    var xx = powerModulus(a, u, n);

    var i: u64 = 0;
    while (i < t) : (i += 1) {
        const yy = multiplyModulus(xx, xx, n);
        // If yy == 1 and xx != 1 and xx != n-1, then n is composite
        if (yy == 1 and xx != 1 and xx != n_minus1) {
            return true; // a is a witness to n's compositeness
        }
        xx = yy;
    }

    // Return true if a IS a witness (xx != 1), false otherwise
    return xx != 1;
}

// Uses the Miller-Rabin primality test (deterministic version for u64)
fn isPrime(n: u64) bool {
    if (n <= 1) return false;
    if (n <= 3) return true; // 2 and 3 are prime
    if (n % 2 == 0 or n % 3 == 0) return false; // Handle divisors 2 and 3

    // Small primes often used as bases for Miller-Rabin
    // For a deterministic test for u64, we need more bases.
    // These are sufficient for numbers up to 2^64.
    // See https://math.stackexchange.com/questions/241313/miller-rabin-primality-test-with-large-numbers
    const primes: []const u64 = &.{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37 };

    // Check if n is one of these small primes directly
    for (primes) |prime| {
        if (n == prime) return true;
    }

    for (primes) |prime| {
        // Skip bases >= n
        if (prime >= n) break;

        if (isWitness(prime, n)) {
            return false; // Found a witness, n is composite
        }
    }

    return true; // No witness found among the tested bases, likely prime
}

// Calculate the Legendre symbol (a/p)
fn legendreSymbol(a: u64, p: u64) i64 {
    if (p < 3 or !isPrime(p)) {
        // Legendre symbol is defined for odd primes p
        std.log.warn("legendreSymbol called with non-odd-prime p={}\n", .{p});
        return 0; // Or choose another indicator
    }

    const ls = powerModulus(a, (p - 1) / 2, p);

    if (ls == p - 1) {
        return -1; // Corresponds to quadratic non-residue
    } else if (ls == 1) {
        return 1; // Corresponds to quadratic residue
    } else {
        // ls should be 0 if a % p == 0
        return 0; // Corresponds to a divisible by p
    }
}

// Represents an element in the field F(p^2), x + y*sqrt(w2)
// where w2 is a quadratic non-residue mod p.
const Fp2 = struct {
    x: u64,
    y: u64,
};

// Multiply two elements in F(p^2)
fn multiplyFp2(a: Fp2, b: Fp2, prime: u64, w2: u64) Fp2 {
    const axbx = multiplyModulus(a.x, b.x, prime);
    const ayby = multiplyModulus(a.y, b.y, prime);
    const aybyw2 = multiplyModulus(ayby, w2, prime);

    // Calculate real part: (a.x*b.x + a.y*b.y*w2) % prime
    const real_part: u64 = @intCast((@as(u128, axbx) + @as(u128, aybyw2)) % prime);

    const axby = multiplyModulus(a.x, b.y, prime);
    const aybx = multiplyModulus(a.y, b.x, prime);

    // Calculate imaginary part: (a.x*b.y + a.y*b.x) % prime
    const imag_part: u64 = @intCast((@as(u128, axby) + @as(u128, aybx)) % prime);

    return .{
        .x = real_part,
        .y = imag_part,
    };
}

// Calculate base^power in F(p^2) using exponentiation by squaring
fn powerFp2(base_param: Fp2, power_param: u64, prime: u64, w2: u64) Fp2 {
    // Identity element in F(p^2) is 1 + 0*sqrt(w2)
    var result: Fp2 = .{ .x = 1, .y = 0 };
    if (power_param == 0) return result;

    // Reduce base components modulo prime initially
    var base: Fp2 = .{
        .x = base_param.x % prime,
        .y = base_param.y % prime,
    };
    var power = power_param;

    while (power > 0) {
        if ((power & 1) == 1) {
            result = multiplyFp2(result, base, prime, w2);
        }
        base = multiplyFp2(base, base, prime, w2);
        power >>= 1;
    }
    return result;
}
