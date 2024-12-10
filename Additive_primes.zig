// https://rosettacode.org/wiki/Additive_primes
// Translated from C
const std = @import("std");

pub fn main() !void {
    const N = 500;

    const writer = std.io.getStdOut().writer();

    try writer.print("Rosetta Code: additive primes less than {}:\n", .{N});

    // Pre-calculate the prime numbers below N at comptime.
    const is_prime: std.StaticBitSet(N) = comptime blk: {
        @setEvalBranchQuota(4000);
        // An array of bool would have been simpler.
        var bitset = std.StaticBitSet(N).initEmpty();
        var it = bitset.iterator(.{ .kind = .unset });
        while (it.next()) |n|
            if (isPrime(n))
                bitset.set(n);
        break :blk bitset;
    };

    var count: usize = 0;
    var n: u16 = 2;
    var inc: u16 = 1;
    while (n < is_prime.capacity()) : ({
        n += inc;
        inc = 2;
    }) {
        if (is_prime.isSet(n) and is_prime.isSet(sumOfDecimalDigits(n))) {
            try writer.print("{d:4}", .{n});
            count += 1;
            if ((count % 10) == 0)
                try writer.writeByte('\n');
        }
    }
    try writer.print("\nThose were {} additive primes.\n", .{count});
}

fn isPrime(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 2) return false;

    inline for ([3]u3{ 2, 3, 5 }) |p| if (n % p == 0) return n == p;

    const wheel = comptime [_]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: T = 7;
    while (true)
        for (wheel) |w| {
            if (p * p > n) return true;
            if (n % p == 0) return false;
            p += w;
        };
}

fn sumOfDecimalDigits(n_: anytype) @TypeOf(n_) {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("sumOfDecimalDigits() expected unsigned integer argument, found " ++ @typeName(T));

    var n = n_;
    var sum: T = 0;
    while (n > 0) {
        sum += n % 10;
        n /= 10;
    }
    return sum;
}
