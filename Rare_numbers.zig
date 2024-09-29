// https://www.rosettacode.org/wiki/Rare_numbers
// Naïve brute force implementation  of first five rare numbers.
const std = @import("std");
const math = std.math;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var t0 = try std.time.Timer.start();

    var count: usize = 0;
    var n: u64 = 0;
    while (count < 5) : (n += 1)
        if (isRare(n)) {
            try stdout.print("{d}\n", .{n});
            count += 1;
        };
    try stdout.print("Processed in {}\n\n", .{std.fmt.fmtDuration(t0.read())});
}

fn isRare(n: u64) bool {
    const rev = reverse(n);
    if (n <= rev) return false;

    return isPerfectSquare(n + rev) and isPerfectSquare(n - rev);
}

fn reverse(n0: u64) u64 {
    var r: u64 = 0;
    var n: u64 = n0;
    while (n > 0) {
        r *= 10;
        r += n % 10;
        n /= 10;
    }
    return r;
}

/// refer https://en.wikipedia.org/wiki/Square_number
fn isPerfectSquare(n: u64) bool {
    // Too much modulo or division arithmetic is more expensive than sqrt.
    switch (n % 12) {
        0, 1, 4, 9 => {},
        else => return false,
    }

    switch (n % 4) {
        0, 1 => {},
        else => return false,
    }

    switch (n % 10) {
        0, 1, 4, 5, 6, 9 => {},
        else => return false,
    }

    switch (calcDigitalRoot(n)) {
        1, 4, 7, 9 => {},
        else => return false,
    }

    const s: u64 = math.sqrt(n);
    return s * s == n;
}

/// refer https://rosettacode.org/wiki/Digital_root
fn calcDigitalRoot(n: u64) u64 {
    if (n == 0)
        return 0;

    const d: u64 = n % 9;
    if (d != 0)
        return d;

    return 9;
}

const testing = std.testing;

test isPerfectSquare {
    try testing.expect(isPerfectSquare(1));
    try testing.expect(isPerfectSquare(4));
    try testing.expect(!isPerfectSquare(5));
    try testing.expect(isPerfectSquare(65 + 56));
    try testing.expect(isPerfectSquare(65 - 56));
    try testing.expect(!isPerfectSquare(18446744065119617024));
    try testing.expect(isPerfectSquare(18446744065119617025));
    try testing.expect(!isPerfectSquare(18446744065119617026));
}

test reverse {
    try testing.expectEqual(reverse(1), @as(u64, 1));
    try testing.expectEqual(reverse(2), @as(u64, 2));
    try testing.expectEqual(reverse(10), @as(u64, 1));
    try testing.expectEqual(reverse(123456), @as(u64, 654321));
}
