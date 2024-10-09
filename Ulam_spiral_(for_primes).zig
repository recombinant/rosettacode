// https://rosettacode.org/wiki/Ulam_spiral_(for_primes)
// based on code from https://github.com/tiehuis/zig-rosetta
const std = @import("std");

pub fn main() void {
    ulam(9);
}

fn ulam(n_: usize) void {
    const n = if (n_ % 2 == 0) n_ + 1 else n_;

    for (0..n) |x| {
        for (0..n) |y| {
            const z = cell(y, x, n);
            if (isPrime(z))
                std.debug.print(" #", .{})
            else
                std.debug.print("  ", .{});
        }
        std.debug.print("\n", .{});
    }
}

fn cell(x_: usize, y_: usize, n_: usize) usize {
    const n: isize = @intCast(n_);
    var x: isize = @intCast(x_);
    var y: isize = @intCast(y_);

    x -= @divTrunc(n - 1, 2);
    y -= @divTrunc(n, 2);

    const l: isize = @intCast(2 * @max(@abs(x), @abs(y)));
    const d = if (y >= x) l * 3 + x + y else l - x - y;
    return @intCast((l - 1) * (l - 1) + d);
}

fn isPrime(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 2)
        return false;
    if (n % 2 == 0)
        return n == 2;
    if (n % 3 == 0)
        return n == 3;
    if (n % 5 == 0)
        return n == 5;

    const wheel = [_]T{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: u64 = 7;
    while (true) {
        for (wheel) |w| {
            if (p * p > n)
                return true;
            if (n % p == 0)
                return false;
            p += w;
        }
    }
}

const testing = std.testing;

test isPrime {
    const p61 = try std.math.powi(u64, 2, 61);
    const primes = [_]u64{
        2,     3,     5,     7,       11,
        13,    17,    19,    23,      29,
        19141, 19391, 19609, p61 - 1, p61 - 31,
    };
    const non_primes = [_]u64{
        0,     1,     4,     6,       8,       9,
        10,    12,    14,    15,      16,      18,
        19147, 19397, 19607, p61 - 3, p61 + 1,
    };

    for (primes) |n|
        try testing.expect(isPrime(n));
    for (non_primes) |n|
        try testing.expect(!isPrime(n));
}
