// https://rosettacode.org/wiki/Radical_of_an_integer
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------- task 1
    try stdout.writeAll("The radicals of 1 to 50 are:\n");
    var i: u64 = 1;
    while (i <= 50) : (i += 1) {
        const radical = calcRadical(i);
        try stdout.print("{d:4}", .{radical});
        if (i % 10 == 0)
            try stdout.writeByte('\n');
    }
    try stdout.flush();

    // --------------------------------------------------- task 2
    try stdout.writeByte('\n');
    try stdout.print("The radical of {d:6} is: {d:6}\n", .{ 99999, calcRadical(99999) });
    try stdout.print("The radical of {d:6} is: {d:6}\n", .{ 499999, calcRadical(499999) });
    try stdout.print("The radical of {d:6} is: {d:6}\n", .{ 999999, calcRadical(999999) });
    try stdout.flush();

    // --------------------------------------------------- task 3
    try stdout.writeAll("\nDistribution of radicals up to 1,000,000:\n");

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const primes: []u64 = try getPrimes(allocator, 1_000_000);
    defer allocator.free(primes);

    var radical_count: [8]usize = undefined;
    @memset(&radical_count, 0);
    radical_count[1] = 1; // radical regarded as 1 by convention
    i = 2;
    while (i <= 1_000_000) : (i += 1) {
        const count = countRadicalPrimeCount(i, primes);
        radical_count[count] += 1;
    }
    for (radical_count, 0..) |count, idx|
        try stdout.print("{d}: {d}\n", .{ idx, count });
    try stdout.flush();

    // ----------------------------------------------- bonus task
    try stdout.writeAll("\nUp to 1,000,000:\n");
    i = 2;
    var prime_count: usize = 0;
    var prime_power_count: usize = 0;
    while (i <= 1_000_000) : (i += 1)
        switch (getPrimeRadicalType(i, primes)) {
            .prime => prime_count += 1,
            .prime_power => prime_power_count += 1,
            .neither => {},
        };
    try stdout.print("Primes: {d:5}\n", .{prime_count});
    try stdout.print("Powers: {d:5}\n", .{prime_power_count});
    try stdout.print("Plus 1: {d:5}\n", .{1});
    try stdout.print("Total:  {d:5}\n", .{prime_count + prime_power_count + 1});
    try stdout.flush();
}

/// The radical of n is the product of the distinct prime factors of n.
fn calcRadical(n_: u64) u64 {
    var n = n_;
    var radical: u64 = 1;
    var i: u64 = 2;
    while (n > 1) : (i += 1)
        if (n % i == 0) {
            radical *= i;
            while (n % i == 0) : (n /= i) {}
        };
    return radical;
}

/// Count of distinct prime factors of n.
fn countRadicalPrimeCount(n_: u64, primes: []const u64) usize {
    var n = n_;
    var i: u64 = 0;
    var count: usize = 0;
    while (n > 1) : (i += 1) {
        const p = primes[i];
        if (n % p == 0) {
            count += 1;
            while (n % p == 0) : (n /= p) {}
        }
    }
    return count;
}

const RadicalType = enum { prime, prime_power, neither };

/// Radicals that are prime numbers or powers of prime numbers.
fn getPrimeRadicalType(n_: u64, primes: []const u64) RadicalType {
    var n = n_;
    var i: u64 = 0;
    var result: RadicalType = .neither;
    var found = false;
    while (n > 1) : (i += 1) {
        const p = primes[i];
        if (n % p == 0) {
            if (found)
                return .neither;
            found = true;
            n /= p;
            result = .prime;
            if (n % p == 0) {
                n /= p;
                result = .prime_power;
                while (n % p == 0) : (n /= p) {}
            }
        }
    }
    return result;
}

/// Returns an array of prime numbers.
/// Allocates memory for the result, which must be freed by the caller.
fn getPrimes(allocator: std.mem.Allocator, comptime limit: usize) ![]u64 {
    const sieve = createSieve(limit);
    // count primes in the sieve
    const prime_count = blk: {
        var count: usize = 0;
        for (sieve) |is_prime| {
            count += @intFromBool(is_prime);
        }
        break :blk count;
    };
    // create and return an array of primes
    var primes = try allocator.alloc(u64, prime_count);
    var i: usize = 0;
    for (sieve, 0..) |is_prime, n|
        if (is_prime) {
            primes[i] = @intCast(n);
            i += 1;
        };
    return primes;
}

/// Sieve of Eratosthenes returning an array of bool. Simple.
/// true means prime, false means composite.
fn createSieve(comptime limit: usize) [limit + 1]bool {
    var sieve: [limit + 1]bool = undefined;
    @memset(&sieve, true);
    sieve[0] = false;
    sieve[1] = false;

    var i: usize = 4;
    while (i < limit) : (i += 2)
        sieve[i] = false;

    i = 3;
    while (i * i <= limit) : (i += 2) {
        var j = i * i;
        while (j <= limit) : (j += i)
            sieve[j] = false;
    }
    return sieve;
}
