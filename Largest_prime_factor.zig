// https://rosettacode.org/wiki/Largest_prime_factor
const std = @import("std");

pub fn main() !void {
    var t0 = try std.time.Timer.start();

    // const n = comptime std.math.pow(u128, 2, 64) - 59;
    // const n = comptime std.math.pow(u64, 2, 32) - 5;
    // const n = comptime std.math.pow(u128, 2, 31) - 1;
    const n = 600_851_475_143;
    const T = AutoNumberType(n);

    const factor = findLargestPrimeFactor(T, @intCast(n));
    try std.io.getStdOut().writer().print("Largest prime factor of {d} is {d}\n", .{ n, factor });
    try std.io.getStdErr().writer().print("\nprocessed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}

pub fn findLargestPrimeFactor(T: type, n_: T) T {
    if (n_ < 2)
        return 1;

    var n = n_;
    var max: T = 1;
    while (n % 2 == 0) {
        max = 2;
        n /= 2;
    }
    while (n % 3 == 0) {
        max = 3;
        n /= 3;
    }
    while (n % 5 == 0) {
        max = 5;
        n /= 5;
    }

    const inc = [8]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };
    var k: T = 7;
    var i: usize = 0;
    while (k * k <= n) {
        if (n % k == 0) {
            max = k;
            n /= k;
        } else {
            k += inc[i];
            i = (i + 1) % 8;
        }
    }
    return if (n > 1) n else max;
}

/// Refactored from Extensible_prime_generator
/// Given an upper bound, max, return the most restrictive
/// largest prime factor data type.
pub fn AutoNumberType(comptime max: u64) type {
    if (max == 0)
        @compileError("The maximum sieving size must be non-zero.");
    var bit_len = 64 - @clz(max);
    if (bit_len < 4)
        bit_len = 4;
    // Allow for (k * k > n)
    return std.meta.Int(.unsigned, bit_len + 1);
}

const testing = std.testing;

test AutoNumberType {
    try testing.expectEqual(u5, AutoNumberType(1));
    try testing.expectEqual(u5, AutoNumberType(2));
    try testing.expectEqual(u5, AutoNumberType(3));
    try testing.expectEqual(u5, AutoNumberType(4));
    try testing.expectEqual(u5, AutoNumberType(5));
    try testing.expectEqual(u5, AutoNumberType(8));
    try testing.expectEqual(u41, AutoNumberType(600851475143));
    try testing.expectEqual(u62, AutoNumberType(comptime std.math.pow(u128, 2, 61) - 1));
    try testing.expectEqual(u65, AutoNumberType(comptime std.math.pow(u128, 2, 64) - 59));
}
