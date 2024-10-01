// https://rosettacode.org/wiki/Evaluate_binomial_coefficients
const std = @import("std");
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;

const Rational = math.big.Rational;
const Int = math.big.int.Managed;

const assert = std.debug.assert;

pub fn main() !void {
    try example1();
    try example2();
    try example3();
}

// --------------------------------------------------------------

pub fn example1() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var b1 = try binomialCoeff1(allocator, 5, 3);
    var b2 = try binomialCoeff1(allocator, 40, 19);
    var b3 = try binomialCoeff1(allocator, 67, 31);
    defer b1.deinit();
    defer b2.deinit();
    defer b3.deinit();

    const stdout = io.getStdOut().writer();
    try stdout.print("Example 1 (rational numbers)\n", .{});
    try stdout.print("{d}\n", .{b1});
    try stdout.print("{d}\n", .{b2});
    try stdout.print("{d}\n\n", .{b3});
}

/// Using rational numbers.
fn binomialCoeff1(allocator: mem.Allocator, n: usize, k: usize) !Int {
    var result = try Rational.init(allocator);
    var factor = try Rational.init(allocator);
    var temp = try Rational.init(allocator);
    defer result.deinit();
    defer factor.deinit();
    defer temp.deinit();

    try result.setInt(1);

    for (1..k + 1) |i| {
        try factor.setRatio(n - i + 1, i);
        // avoid alias inefficiency when multiplying
        try temp.copyRatio(result.p, result.q);
        try result.mul(temp, factor);
        assert(try result.q.to(usize) == 1);
    }
    return result.p.clone();
}

// --------------------------------------------------------------

pub fn example2() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var r1 = try binomialCoeff2(allocator, 5, 3);
    var r2 = try binomialCoeff2(allocator, 40, 19);
    var r3 = try binomialCoeff2(allocator, 67, 31);
    defer r1.deinit();
    defer r2.deinit();
    defer r3.deinit();

    const stdout = io.getStdOut().writer();
    try stdout.print("Example 2 (big integers)\n", .{});
    try stdout.print("{d}\n", .{r1});
    try stdout.print("{d}\n", .{r2});
    try stdout.print("{d}\n\n", .{r3});
}

/// Using big integers.
fn binomialCoeff2(allocator: mem.Allocator, n: usize, k: usize) !Int {
    var result = try Int.initSet(allocator, 1);
    var temp = try Int.init(allocator);
    var numerator = try Int.init(allocator);
    var denominator = try Int.init(allocator);
    var rem = try Int.init(allocator);
    defer temp.deinit();
    defer numerator.deinit();
    defer denominator.deinit();
    defer rem.deinit();

    for (1..k + 1) |i| {
        try numerator.set(n - i + 1);
        try denominator.set(i);
        try temp.mul(&result, &numerator);
        try result.divTrunc(&rem, &temp, &denominator);
        assert(rem.eqlZero());
    }
    return result;
}

// --------------------------------------------------------------

fn example3() !void {
    const stdout = io.getStdOut().writer();
    try stdout.print("Example 3 (translation of C)\n", .{});
    try stdout.print("{d}\n", .{try binomialCoeff(u16, 5, 3)});
    try stdout.print("{d}\n", .{try binomialCoeff(u64, 40, 19)});
    try stdout.print("{d}\n\n", .{try binomialCoeff(u128, 67, 31)});
}

const BinomialCoeffError = error{
    KgtN, // k > n
    Overflow,
};

/// Translation of C
fn binomialCoeff(comptime T: type, n_: T, k_: T) BinomialCoeffError!T {
    var n = n_;
    var k = k_;
    if (k == 0) return 1;
    if (k == 1) return n;
    if (k == n) return 1;
    if (k > n) return BinomialCoeffError.KgtN;
    if (k > n / 2) k = n - k; // symmetry
    var r: T = 1;
    var d: T = 1;
    while (d <= k) : (d += 1) {
        if (r >= math.maxInt(T) / n) { // Possible overflow?
            var g = math.gcd(n, d);
            const nr = n / g;
            var dr = d / g; // reduced numerator / denominator
            g = math.gcd(r, dr);
            r /= g;
            dr /= g;
            if (r >= math.maxInt(T) / nr)
                return BinomialCoeffError.Overflow; // Unavoidable overflow
            r *= nr;
            r /= dr;
            n -= 1;
        } else {
            r *= n;
            r /= d;
            n -= 1;
        }
    }
    return r;
}
