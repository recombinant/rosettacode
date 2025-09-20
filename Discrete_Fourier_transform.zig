// https://rosettacode.org/wiki/Discrete_Fourier_transform
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");

const Float = f64;
const Complex = std.math.complex.Complex(Float);

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // ------------------------------------------- sequence
    const sequence = [_]Float{ 2, 3, 5, 7, 11 };
    const x = try allocator.alloc(Complex, sequence.len);
    defer allocator.free(x);
    for (sequence, x) |i, *xx|
        xx.* = Complex{ .re = i, .im = 0 };
    try printComplexSlice(x, "\nOriginal sequence:", stdout);

    // ------------------------------------------------ DFT
    const y = try dft(allocator, x);
    defer allocator.free(y);
    try printComplexSlice(y, "\nAfter applying the Discrete Fourier Transform:", stdout);

    // ----------------------------------------------- IDFT
    const inv = try idft(allocator, y);
    defer allocator.free(inv);
    try printComplexSlice(inv, "\nAfter applying the Inverse Discrete Fourier Transform to the above transform:", stdout);

    // --------------------------------------------- stdout
    try stdout.flush();
}

/// Caller owns returned memory
fn dft(allocator: std.mem.Allocator, x: []Complex) ![]Complex {
    const N = x.len;
    const zero = Complex{ .re = 0, .im = 0 };
    const Nf: Float = @floatFromInt(N);

    const y = try allocator.alloc(Complex, N);

    for (y, 0..) |*yy, k| {
        yy.* = zero;
        for (x, 0..) |xx, n| {
            const kf: Float = @floatFromInt(k);
            const nf: Float = @floatFromInt(n);
            const t = Complex{ .re = 0, .im = -2 * std.math.pi * kf * nf / Nf };
            // x[n] = x[n] + y[k] * exp(t)
            yy.* = yy.*.add(xx.mul(std.math.complex.exp(t)));
        }
    }
    return y;
}

/// Caller owns returned memory
fn idft(allocator: std.mem.Allocator, y: []Complex) ![]Complex {
    const N = y.len;
    const zero = Complex{ .re = 0, .im = 0 };
    const Nf: Float = @floatFromInt(N);

    const x = try allocator.alloc(Complex, N);

    for (x, 0..) |*xx, n| {
        xx.* = zero;
        for (y, 0..) |yy, k| {
            const kf: Float = @floatFromInt(k);
            const nf: Float = @floatFromInt(n);
            const t = Complex{ .re = 0, .im = 2 * std.math.pi * kf * nf / Nf };
            // x[n] = x[n] + y[k] * exp(t)
            xx.* = xx.*.add(yy.mul(std.math.complex.exp(t)));
        }
        // x[n] = x[n] / N
        xx.* = xx.*.div(Complex{ .re = Nf, .im = 0 });
        // clean x[n] to remove very small imaginary values
        if (std.math.approxEqAbs(Float, 0, xx.im, 1e-14)) xx.* = Complex{ .re = xx.*.re, .im = 0 };
    }
    return x;
}

/// Print title followed by complex numbers
fn printComplexSlice(sequence: []const Complex, title: []const u8, w: *std.Io.Writer) !void {
    try w.writeAll(title);
    var sep: []const u8 = " ";
    for (sequence) |c| {
        try w.writeAll(sep);
        try printComplex(c, w);
        sep = ", ";
    }
}

/// Print complex number. Omit imaginary component if zero.
fn printComplex(c: Complex, w: *std.Io.Writer) !void {
    const options: std.fmt.Number = .{ .precision = 2 };

    if (c.im == 0)
        try w.printFloat(c.re, options)
    else {
        try w.writeByte('(');
        try w.printFloat(c.re, options);
        try w.writeAll(", ");
        try w.printFloat(c.im, options);
        try w.writeAll("i)");
    }
}
