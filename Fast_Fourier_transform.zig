// https://rosettacode.org/wiki/Fast_Fourier_transform
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const sequence = [_]f64{ 1, 1, 1, 1, 0, 0, 0, 0 };
    // Ensure array size is power of 2, padding with zeroes if necessary.
    const n = std.math.shl(usize, 1, std.math.log2_int_ceil(u8, sequence.len));
    var buf = try allocator.alloc(Complex64, n);
    defer allocator.free(buf);
    if (n != sequence.len)
        for (buf) |*c| {
            c.* = comptime .init(0, 0);
        };

    for (sequence, buf[0..sequence.len]) |r, *c| {
        c.*.re = r;
        c.*.im = 0;
    }

    try show(stdout, "Data: ", buf);
    const result = try fftV2(allocator, buf);
    defer allocator.free(result);
    try show(stdout, "FFT : ", result);

    // from https://rosettacode.org/wiki/Fast_Fourier_transform#C
    try show(stdout, "Data: ", buf);
    try fft(allocator, buf);
    try show(stdout, "FFT : ", buf);

    try stdout.flush();
}

const Complex64 = std.math.Complex(f64);

fn fft_(buf: []Complex64, out: []Complex64, n: usize, step: usize) void {
    if (step < n) {
        fft_(out, buf, n, step * 2);
        fft_(out[step..], buf[step..], n, step * 2);

        const theta_n: Complex64 = .init(0, -std.math.pi / @as(f64, @floatFromInt(n)));

        var i: usize = 0;
        while (i < n) : (i += 2 * step) {
            // cplx t = cexp(-I * PI * i / n) * out[i + step];
            const theta = theta_n.mul(.init(@floatFromInt(i), 0));
            const t: Complex64 = std.math.complex.exp(theta).mul(out[i + step]);
            buf[i / 2] = out[i].add(t);
            buf[(i + n) / 2] = out[i].sub(t);
        }
    }
}

fn fft(allocator: std.mem.Allocator, buf: []Complex64) !void {
    const n = buf.len;
    const out = try allocator.dupe(Complex64, buf);
    defer allocator.free(out);
    fft_(buf, out, n, 1);
}

// More allocation. Would be better if Zig could dynamically allocate on the stack.
// https://www.geeksforgeeks.org/fast-fourier-transformation-poynomial-multiplication/
fn fftV2(allocator: std.mem.Allocator, a: []Complex64) ![]Complex64 {
    const n = a.len;

    if (n == 1) return allocator.dupe(Complex64, a[0..1]);

    const theta_n: f64 = -2 * std.math.pi / @as(f64, @floatFromInt(n));

    var w = try allocator.alloc(Complex64, n);
    for (w, 0..) |*c, i| {
        const theta = theta_n * @as(f64, @floatFromInt(i));
        c.* = std.math.complex.exp(Complex64.init(0, theta));
    }
    defer allocator.free(w);

    const half_n = n / 2;

    // Could reduce to a single a allocation and split to two slices.
    const a_even = try allocator.alloc(Complex64, half_n);
    const a_odd = try allocator.alloc(Complex64, half_n);
    for (a_even, a_odd, 0..) |*even, *odd, i| {
        even.* = a[i * 2];
        odd.* = a[i * 2 + 1];
    }
    defer allocator.free(a_even);
    defer allocator.free(a_odd);

    const y_even = try fftV2(allocator, a_even);
    const y_odd = try fftV2(allocator, a_odd);
    defer allocator.free(y_even);
    defer allocator.free(y_odd);

    var y = try allocator.alloc(Complex64, n);
    for (y[0..half_n], y[half_n..], 0..) |*y1, *y2, i| {
        const t = w[i].mul(y_odd[i]);
        const u = y_even[i];
        y1.* = u.add(t);
        y2.* = u.sub(t);
    }
    return y;
}

fn show(writer: anytype, s: []const u8, a: []Complex64) !void {
    try writer.writeAll(s);
    for (a) |c| {
        if (c.im == 0)
            try writer.print("{d:.3} ", .{c.re})
        else
            try writer.print("({d:.3}, {d:.3}) ", .{ c.re, c.im });
    }
    try writer.writeByte('\n');
}
