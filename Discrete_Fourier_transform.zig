// https://rosettacode.org/wiki/Discrete_Fourier_transform
// Translated from Wren
const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const math = std.math;
const complex = math.complex;

const Float = f64;
const FloatFmt = "{d:.2}";
const Complex = complex.Complex(Float);

pub fn main() !void {
    // Allocator ------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // stdout ---------------------------------------------
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Sequence -------------------------------------------
    const sequence = [_]Float{ 2, 3, 5, 7, 11 };
    const x = try allocator.alloc(Complex, sequence.len);
    defer allocator.free(x);
    for (sequence, x) |i, *xx|
        xx.* = Complex{ .re = i, .im = 0 };
    try printComplexSlice(allocator, stdout, x, "\nOriginal sequence:");

    // DFT ------------------------------------------------
    const y = try dft(allocator, x);
    defer allocator.free(y);
    try printComplexSlice(allocator, stdout, y, "\nAfter applying the Discrete Fourier Transform:");

    // IDFT -----------------------------------------------
    const inv = try idft(allocator, y);
    defer allocator.free(inv);
    try printComplexSlice(allocator, stdout, inv, "\nAfter applying the Inverse Discrete Fourier Transform to the above transform:");

    // stdout ---------------------------------------------
    try stdout.writeByte('\n');
    try bw.flush();
}

/// Caller owns returned memory
fn dft(allocator: mem.Allocator, x: []Complex) ![]Complex {
    const N = x.len;
    const zero = Complex{ .re = 0, .im = 0 };
    const Nf: Float = @floatFromInt(N);

    const y = try allocator.alloc(Complex, N);

    for (y, 0..) |*yy, k| {
        yy.* = zero;
        for (x, 0..) |xx, n| {
            const kf: Float = @floatFromInt(k);
            const nf: Float = @floatFromInt(n);
            const t = Complex{ .re = 0, .im = -2 * math.pi * kf * nf / Nf };
            // x[n] = x[n] +  y[k] * exp(t)
            yy.* = yy.*.add(xx.mul(complex.exp(t)));
        }
    }
    return y;
}

/// Caller owns returned memory
fn idft(allocator: mem.Allocator, y: []Complex) ![]Complex {
    const N = y.len;
    const zero = Complex{ .re = 0, .im = 0 };
    const Nf: Float = @floatFromInt(N);

    const x = try allocator.alloc(Complex, N);

    for (x, 0..) |*xx, n| {
        xx.* = zero;
        for (y, 0..) |yy, k| {
            const kf: Float = @floatFromInt(k);
            const nf: Float = @floatFromInt(n);
            const t = Complex{ .re = 0, .im = 2 * math.pi * kf * nf / Nf };
            // x[n] = x[n] +  y[k] * exp(t)
            xx.* = xx.*.add(yy.mul(complex.exp(t)));
        }
        // x[n] = x[n] / N
        xx.* = xx.*.div(Complex{ .re = Nf, .im = 0 });
        // clean x[n] to remove very small imaginary values
        if (math.approxEqAbs(Float, 0, xx.im, 1e-14)) xx.* = Complex{ .re = xx.*.re, .im = 0 };
    }
    return x;
}

/// Print title followed by complex numbers
fn printComplexSlice(allocator: mem.Allocator, writer: anytype, sequence: []const Complex, title: []const u8) !void {
    try writer.writeAll(title);
    var sep: []const u8 = " ";
    for (sequence) |c| {
        try writer.writeAll(sep);
        try printComplex(allocator, writer, c);
        sep = ", ";
    }
}

/// Print complex number. Omit imaginary component if zero.
fn printComplex(allocator: mem.Allocator, writer: anytype, c: Complex) !void {
    const format = "(" ++ FloatFmt ++ ", " ++ FloatFmt ++ "i)"; // comptime evaluated

    const s = if (c.im == 0)
        try fmt.allocPrint(allocator, FloatFmt, .{c.re})
    else
        try fmt.allocPrint(allocator, format, .{ c.re, c.im });

    try writer.print("{s}", .{s});
    allocator.free(s);
}
