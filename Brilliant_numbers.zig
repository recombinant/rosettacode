// https://rosettacode.org/wiki/Brilliant_numbers
const std = @import("std");
const fmt = std.fmt;
const math = std.math;
const time = std.time;

const print = std.debug.print;

// --------------------------------------------------------------

pub fn main() !void {
    main1(); // Brute force
    try main2();
}

fn main1() void {
    var t0 = time.Timer.start() catch unreachable;

    print("First 100 brilliant numbers:\n", .{});
    var n: u64 = 1;
    var position: usize = 0;
    while (position < 100) : (n += 1) {
        if (isBrilliant(n)) {
            position += 1;
            const sep: u8 = if (position % 10 == 0) '\n' else ' ';
            print("{d:4}{c}", .{ n, sep });
        }
    }
    print("\n", .{});

    const stop_after = math.powi(u64, 10, 6) catch unreachable;

    var pow: u64 = 1;
    var trigger = math.powi(u64, 10, pow) catch unreachable;

    n = 1;
    position = 0;
    while (true) : (n += 1) {
        if (isBrilliant(n)) {
            position += 1;
            if (n >= trigger) {
                print("First brilliant number >= 10^{d} is {d} at position {d}\n", .{ pow, n, position });
                pow += 1;
                trigger *= 10;
                if (n > stop_after)
                    break;
            }
        }
    }
    print("\nprocessed in {}\n\n\n", .{fmt.fmtDuration(t0.read())});
}

/// Find all the prime factor(s)
/// - fail if there is only one
/// - fail if there are more than two
/// - fail if they differ in base 10 magnitudes
pub fn isBrilliant(n_: anytype) bool {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isBrilliant() requires an unsigned integer, found " ++ @typeName(T));

    if (n_ < 4)
        return false;

    var fc = FactorChecker(T).init(n_);

    var n = n_;
    while (n % 2 == 0) {
        fc.appendPrime(2) catch return false;
        n /= 2;
    }
    while (n % 3 == 0) {
        fc.appendPrime(3) catch return false;
        n /= 3;
    }
    while (n % 5 == 0) {
        fc.appendPrime(5) catch return false;
        n /= 5;
    }

    const inc = [8]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };
    var k: T = 7;
    var i: usize = 0;
    while (k * k <= n) {
        if (n % k == 0) {
            fc.appendPrime(k) catch return false;
            n /= k;
        } else {
            k += inc[i];
            i = (i + 1) % 8;
        }
    }
    if (n != 1)
        fc.appendPrime(n) catch return false;

    return fc.isBrilliant();
}

const FactorCheckerError = error{
    FactorMagnitudeOutOfRange,
    TooManyFactors,
};

fn FactorChecker(comptime T: type) type {
    return struct {
        const Self = @This();

        count: u2 = 0,
        expected_log: u16,

        fn init(n: T) Self {
            return Self{
                .expected_log = math.log10_int(n) / 2,
            };
        }
        fn appendPrime(self: *Self, n: T) !void {
            if (math.log10_int(n) != self.expected_log)
                return FactorCheckerError.FactorMagnitudeOutOfRange;
            self.count += 1;
            switch (self.count) {
                1, 2 => {},
                else => return FactorCheckerError.TooManyFactors,
            }
        }
        fn isBrilliant(self: Self) bool {
            return self.count == 2;
        }
    };
}

// --------------------------------------------------------------

const heap = std.heap;
const mem = std.mem;
const sort = std.sort;

// Probably quicker by importing primesieve using its C interface:
// https://github.com/kimwalisch/primesieve

// This sieve is good enough.
// https://rosettacode.org/wiki/Extensible_prime_generator
const PrimeGen = @import("Extensible_prime_generator_alternate.zig").PrimeGen;
const AutoSieveType = @import("Extensible_prime_generator_alternate.zig").AutoSieveType;

fn main2() !void {
    var t0 = try time.Timer.start();

    const max_prime = 1_000_000_000;
    // var maximum = math.powi(u64, 10, 12);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const primes_by_digits: []const []const u64 = try getPrimesByDigits(allocator, max_prime);
    defer {
        for (primes_by_digits) |primes| allocator.free(primes);
        allocator.free(primes_by_digits);
    }
    // --------------------------------
    print("First 100 brilliant numbers:\n", .{});
    var brilliant_numbers = std.ArrayList(u64).init(allocator);
    defer brilliant_numbers.deinit();
    for (primes_by_digits) |primes| {
        for (primes, 0..) |p1, i|
            for (primes[i..]) |p2|
                try brilliant_numbers.append(p1 * p2);
        if (brilliant_numbers.items.len >= 100)
            break;
    }
    mem.sort(u64, brilliant_numbers.items, {}, sort.asc(u64));
    for (brilliant_numbers.items[0..100], 1..) |number, i| {
        const c: u8 = if (i % 10 == 0) '\n' else ' ';
        print("{d:4}{c}", .{ number, c });
    }
    print("\n", .{});
    // --------------------------------
    // digits in the answer, not in the primes.
    for (2..14) |digits| {
        const count, const first = try getBrilliant(primes_by_digits, digits);
        print("First brilliant number >= 10^{d} is {d} at position {d}\n", .{ digits - 1, first, count });
    }
    // --------------------------------
    print("\nprocessed in {}\n\n\n", .{fmt.fmtDuration(t0.read())});
}

/// In this instance the C++ and Nim solutions are faster and
/// less intelligible having the "advantage" in their standard libraries.
///
/// This solution is good enough.
///
/// Note: `primes_by_digits` refers to the number of digits in the primes,
///       whereas `digits` refers to the number of digit wanted in the
///       result `next`.
fn getBrilliant(primes_by_digits: []const []const u64, digits: usize) !struct { u64, u64 } {
    const limit = try math.powi(u64, 10, digits - 1);
    var count: usize = 0;
    var next: u64 = math.maxInt(u64);
    for (primes_by_digits[0 .. (digits + 1) / 2]) |primes| {
        outer: for (primes, 0..) |p1, i| {
            for (primes[i..]) |p2| {
                const prod = p1 * p2;
                if (prod < limit)
                    count += 1
                else {
                    next = @min(prod, next);
                    if (p1 == p2)
                        break :outer;
                    break;
                }
            }
        }
    }
    return .{ count + 1, next };
}

/// Load all the necessary primes using a prime generator.
fn getPrimesByDigits(allocator: mem.Allocator, comptime max_prime: u64) ![]const []const u64 {
    const T = AutoSieveType(max_prime);
    var primegen = PrimeGen(T).init(allocator);
    defer primegen.deinit();

    var primes_by_digits = std.ArrayList([]u64).init(allocator);
    var primes = std.ArrayList(u64).init(allocator);
    defer primes.deinit();

    var p: u64 = 10;
    while (p < max_prime) {
        const prime = (try primegen.next()).?;
        if (prime > p) {
            try primes_by_digits.append(try primes.toOwnedSlice());
            p *= 10;
        }
        try primes.append(prime);
    }
    return primes_by_digits.toOwnedSlice();
}
