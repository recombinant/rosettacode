// https://rosettacode.org/wiki/Eisenstein_primes
// Translated from Nim
// TODO: requires a plot - maybe popen gnuplot
const std = @import("std");
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const Complex = math.Complex;

const Eisenstein = struct {
    const omega = Complex(f64){ .re = -0.5, .im = math.sqrt(@as(f64, 3)) * 0.5 };

    a: i64,
    b: i64,
    n: Complex(f64),

    fn init(a: i64, b: i64) Eisenstein {
        const na = Complex(f64){ .re = @floatFromInt(a), .im = 0 };
        const nb = Complex(f64){ .re = @floatFromInt(b), .im = 0 };
        return Eisenstein{ .a = a, .b = b, .n = na.add(nb.mul(omega)) };
    }
    fn re(e: Eisenstein) f64 {
        return e.n.re;
    }
    fn im(e: Eisenstein) f64 {
        return e.n.im;
    }
    fn norm(e: Eisenstein) u64 {
        return @intCast(e.a * e.a - e.a * e.b + e.b * e.b);
    }
    fn isPrimeE(e: Eisenstein) bool {
        if (e.a == 0 or e.b == 0 or e.a == e.b) {
            const c = @max(@abs(e.a), @abs(e.b));
            return isPrimeN(c) and c % 3 == 2;
        } else {
            return isPrimeN(e.norm());
        }
    }

    pub fn format(e: Eisenstein, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt; // autofix
        _ = options; // autofix

        const sign: u8, const imag = if (e.n.im >= 0) .{ '+', e.n.im } else .{ '-', -e.n.im };

        try writer.print("{d:7.4} {c} {d:6.4}i", .{ e.n.re, sign, imag });
    }
};

fn lessThan(_: void, e1: Eisenstein, e2: Eisenstein) bool {
    return switch (math.order(e1.norm(), e2.norm())) {
        .lt => true,
        .gt => false,
        .eq => switch (math.order(e1.im(), e2.im())) {
            .lt => true,
            .gt => false,
            .eq => e1.re() < e2.re(),
        },
    };
}

fn isPrimeN(n: u64) bool {
    if (n < 2) return false;
    if (n & 1 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var k: u64 = 5;
    var delta: u64 = 2;
    while (k * k <= n) {
        if (n % k == 0) return false;
        k += delta;
        delta = 6 - delta;
    }
    return true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Find Eisenstein primes.
    var eprimes_list = std.ArrayList(Eisenstein).init(allocator);
    var a: i64 = -100;
    while (a < 100 + 1) : (a += 1) {
        var b: i64 = -100;
        while (b < 100 + 1) : (b += 1) {
            const e = Eisenstein.init(a, b);
            if (e.isPrimeE())
                try eprimes_list.append(e);
        }
    }

    const eprimes = try eprimes_list.toOwnedSlice();
    defer allocator.free(eprimes);
    sort.insertion(Eisenstein, eprimes, {}, lessThan);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Display first 100 Eisenstein primes to terminal.
    try stdout.writeAll("First 100 Eisenstein primes nearest zero:\n");
    for (0..100) |i| {
        try stdout.print("{}", .{eprimes[i]});
        try stdout.print("{s}", .{if (i % 4 == 3) "\n" else "  "});
    }

    try bw.flush();
}

fn isPrimeAlternative(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;

    var d: u64 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}

test "primes" {
    for (0..1001) |i| {
        try std.testing.expectEqual(isPrimeN(i), isPrimeAlternative(i));
    }
}
