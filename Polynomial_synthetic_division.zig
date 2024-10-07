// https://rosettacode.org/wiki/Polynomial_synthetic_division
// Translation of: Go
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const Rational = std.math.big.Rational;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const N = try createPolynomial(allocator, i16, &[_]i16{ 1, -12, 0, -42 });
    defer destroyPolynomial(allocator, N);

    const D = try createPolynomial(allocator, i16, &[_]i16{ 1, -3 });
    defer destroyPolynomial(allocator, D);

    // https://en.wikipedia.org/wiki/Synthetic_division#Python_implementation
    const Q, const R = try extendedSyntheticDivision(allocator, N, D);
    defer {
        destroyPolynomial(allocator, Q);
        destroyPolynomial(allocator, R);
    }

    const stdout = io.getStdOut().writer();

    try printPolynomial(stdout, N);
    try stdout.writeAll(" div ");
    try printPolynomial(stdout, D);
    try stdout.writeAll(" = ");

    try printPolynomial(stdout, Q);
    try stdout.writeAll(" remainder ");
    try printPolynomial(stdout, R);
    try stdout.writeByte('\n');
}

fn printPolynomial(writer: anytype, rationals: []Rational) !void {
    try writer.writeAll("[");

    var buffer: [256]u8 = undefined;
    var fba = heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var started = false;
    for (rationals) |r| {
        fba.reset();
        if (started) try writer.writeByte(' ') else started = true;
        try writer.print("{s}/{s}", .{
            try r.p.toString(allocator, 10, .lower),
            try r.q.toString(allocator, 10, .lower),
        });
    }
    try writer.writeAll("]");
}

/// Fast polynomial division by using Expanded Synthetic Division.
/// Also works with non-monic polynomials.
///
/// Dividend and divisor are both polynomials, which are here simply lists of coefficients.
/// e.g.: x**2 + 3*x + 5 will be represented as [1, 3, 5]
///
/// Returns {quotient, remainder}. Caller owns returned slices' memory.
fn extendedSyntheticDivision(allocator: mem.Allocator, dividend: []const Rational, divisor: []const Rational) !struct { []Rational, []Rational } {
    const out = try dupePolynomial(allocator, dividend);
    defer allocator.free(out); // Rational contents are moved for return

    const normalizer = divisor[0];

    var i: usize = 0;
    while (i < dividend.len - divisor.len + 1) : (i += 1) {
        // For general polynomial division (when polynomials are non-monic),
        // we need to normalize by dividing the coefficient with the divisor's first coefficient
        try out[i].div(out[i], normalizer);

        const coef = out[i];
        if (!coef.p.eqlZero()) { // Useless to multiply if coef is 0
            var tmp = try Rational.init(allocator);
            defer tmp.deinit();
            // In synthetic division, we always skip the first coefficient of the divisor,
            // because it is only used to normalize the dividend coefficients
            for (1..divisor.len) |j| {
                try tmp.copyRatio(divisor[j].p, divisor[j].q);
                tmp.negate(); // -divisor[j]
                try tmp.mul(tmp, coef); // -divisor[j] * coef
                //  out[i + j] += -divisor[j] * coef
                try out[i + j].add(out[i + j], tmp);
            }
        }
    }
    // The resulting out contains both the quotient and the remainder,
    // the remainder being the size of the divisor (the remainder
    // has necessarily the same degree as the divisor since it is
    // what we couldn't divide from the dividend), so we compute the index
    // where this separation is, and return the quotient and remainder.
    const separator = out.len - (divisor.len - 1);
    const quotient = try allocator.dupe(Rational, out[0..separator]);
    const remainder = try allocator.dupe(Rational, out[separator..]);
    return .{ quotient, remainder };
}

/// Caller owns returned slice memory.
fn createPolynomial(allocator: mem.Allocator, T: type, array: []const T) ![]Rational {
    if (@typeInfo(T) != .int)
        @compileError("createPolynomial requires an integer, found " ++ @typeName(T));

    const result = try allocator.alloc(Rational, array.len);
    for (result, array) |*rat, n| {
        rat.* = try Rational.init(allocator);
        try rat.setInt(n);
    }
    return result;
}

fn dupePolynomial(allocator: mem.Allocator, rationals: []const Rational) ![]Rational {
    const result = try allocator.alloc(Rational, rationals.len);
    for (result, rationals) |*dest, source| {
        dest.* = try Rational.init(allocator);
        try dest.copyRatio(source.p, source.q);
    }
    return result;
}

fn destroyPolynomial(allocator: mem.Allocator, rationals: []Rational) void {
    for (rationals) |*r|
        r.deinit();

    allocator.free(rationals);
}
