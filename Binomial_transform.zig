// https://rosettacode.org/wiki/Binomial_transform
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

const S = [20]i64;

pub fn main() void {
    const names = [_][]const u8{
        "Catalan",
        "Prime flip-flop",
        "Fibonacci",
        "Padovan",
    };
    const sequences = [names.len]S{
        S{ 1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796, 58786, 208012, 742900, 2674440, 9694845, 35357670, 129644790, 477638700, 1767263190 },
        S{ 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0 },
        S{ 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181 },
        S{ 1, 0, 0, 1, 0, 1, 1, 1, 2, 2, 3, 4, 5, 7, 9, 12, 16, 21, 28, 37 },
    };

    var fwd: S = undefined;
    var res: S = undefined;

    for (names, sequences) |name, sequence| {
        printSequence(name, &sequence);

        btForward(&fwd, &sequence);
        printSequence("Forward binomial transform", &fwd);

        btInverse(&res, &sequence);
        printSequence("Inverse binomial transform", &res);

        btInverse(&res, &fwd);
        printSequence("Round trip", &res);

        btSelfInverting(&fwd, &sequence);
        printSequence("Self-inverting", &fwd);

        btSelfInverting(&res, &fwd);
        printSequence("Re-inverted", &res);

        print("\n", .{});
    }
}

fn printSequence(name: []const u8, slice: []const i64) void {
    print("{s}:\n", .{name});
    for (slice, 0..) |n, i| {
        if (i != 0) print(" ", .{});
        print("{}", .{n});
    }
    print("\n", .{});
}

fn btForward(output: []i64, sequence: []const i64) void {
    assert(output.len == sequence.len);
    @memset(output, 0);
    for (output, 0..) |*b, n|
        for (sequence[0 .. n + 1], 0..) |a, k| {
            b.* += binomial(n, k) * a;
        };
}

fn btInverse(output: []i64, sequence: []const i64) void {
    assert(output.len == sequence.len);
    @memset(output, 0);
    for (output, 0..) |*b, n| {
        var sign: i64 = if (n & 1 != 0) -1 else 1;
        for (sequence[0 .. n + 1], 0..) |a, k| {
            b.* += binomial(n, k) * a * sign;
            sign = -sign;
        }
    }
}

fn btSelfInverting(result: []i64, sequence: []const i64) void {
    assert(result.len == sequence.len);
    @memset(result, 0);
    for (result, 0..) |*b, n| {
        var sign: i64 = 1;
        for (sequence[0 .. n + 1], 0..) |a, k| {
            b.* += binomial(n, k) * a * sign;
            sign = -sign;
        }
    }
}

// This are calculated at comptime.
const factorials: [21]u64 = [2]u64{ 1, 1 } ++ calcFactorials(19);

fn calcFactorials(comptime n: usize) [n]u64 {
    var result: [n]u64 = undefined; // Array of factorial 2...
    var fact: u64 = 1;

    for (&result, 2..) |*ptr, i| {
        fact *= i;
        ptr.* = fact;
    }
    return result;
}

fn factorial(n: u64) u64 {
    if (n >= factorials.len) unreachable; // too big for u64
    return factorials[n];
}

/// Return i64 for convenient use within btXXXX() functions
fn binomial(n: u64, k: u64) i64 {
    return @intCast(factorial(n) / (factorial(n - k) * factorial(k)));
}

const testing = std.testing;

test factorial {
    try testing.expectEqual(1, factorial(0));
    try testing.expectEqual(1, factorial(1));
    try testing.expectEqual(2, factorial(2));
    try testing.expectEqual(6, factorial(3));
    try testing.expectEqual(24, factorial(4));
    try testing.expectEqual(120, factorial(5));
    try testing.expectEqual(720, factorial(6));
    try testing.expectEqual(5040, factorial(7));
    try testing.expectEqual(40320, factorial(8));
    try testing.expectEqual(362880, factorial(9));
    try testing.expectEqual(3628800, factorial(10));
}

test binomial {
    try testing.expectEqual(1, binomial(0, 0));

    try testing.expectEqual(1, binomial(1, 0));
    try testing.expectEqual(1, binomial(1, 1));

    try testing.expectEqual(1, binomial(2, 0));
    try testing.expectEqual(2, binomial(2, 1));
    try testing.expectEqual(1, binomial(2, 2));

    try testing.expectEqual(1, binomial(3, 0));
    try testing.expectEqual(3, binomial(3, 1));
    try testing.expectEqual(3, binomial(3, 2));
    try testing.expectEqual(1, binomial(3, 3));

    try testing.expectEqual(1, binomial(4, 0));
    try testing.expectEqual(4, binomial(4, 1));
    try testing.expectEqual(6, binomial(4, 2));
    try testing.expectEqual(4, binomial(4, 3));
    try testing.expectEqual(1, binomial(4, 4));
}

test "run against Fibonacci sequence" {
    const fibonacci_sequence = S{ 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181 };

    var fwd: S = undefined;
    var res: S = undefined;

    // Compare against results from C sample.
    btForward(&fwd, &fibonacci_sequence);
    try testing.expectEqualSlices(i64, &S{ 0, 1, 3, 8, 21, 55, 144, 377, 987, 2584, 6765, 17711, 46368, 121393, 317811, 832040, 2178309, 5702887, 14930352, 39088169 }, &fwd);

    btInverse(&res, &fibonacci_sequence);
    try testing.expectEqualSlices(i64, &S{ 0, 1, -1, 2, -3, 5, -8, 13, -21, 34, -55, 89, -144, 233, -377, 610, -987, 1597, -2584, 4181 }, &res);

    btInverse(&res, &fwd);
    try testing.expectEqualSlices(i64, &S{ 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181 }, &res);

    btSelfInverting(&fwd, &fibonacci_sequence);
    try testing.expectEqualSlices(i64, &S{ 0, -1, -1, -2, -3, -5, -8, -13, -21, -34, -55, -89, -144, -233, -377, -610, -987, -1597, -2584, -4181 }, &fwd);

    btSelfInverting(&res, &fwd);
    try testing.expectEqualSlices(i64, &S{ 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181 }, &res);
}
