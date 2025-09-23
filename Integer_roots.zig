// https://rosettacode.org/wiki/Integer_roots
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
// {{trans|Python}}
// {{trans|Go}}
const std = @import("std");
const math = std.math;
const mem = std.mem;

const Int = math.big.int.Managed;
const Const = math.big.int.Const;

const print = std.debug.print;

pub fn main() !void {
    // ------------------------------------------------------ u64
    const b: u64 = 2e18;

    print("3rd root of 8 = {d}\n", .{try root(8, 3)});
    print("3rd root of 9 = {d}\n", .{try root(9, 3)});
    print("2nd root of {d} = {d}\n", .{ b, try root(b, 2) });

    // ---------------------------------------------- big integer
    const integers = [_]struct { u2, []const u8 }{
        .{ 3, "8" },
        .{ 3, "9" },
        .{ 2, "2000000000000000000" },
        .{ 2, "200000000000000000000000000000000000000000000000000" },
        // .{ 2, "2" ++ "00" ** 2000 },
    };

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ---------- Translation of Python
    print("\n\n", .{});
    for (integers) |tuple| {
        const n = tuple[0];
        const x = tuple[1];
        const rt = try rootP(allocator, n, x);
        defer allocator.free(rt);

        print("{d}{s} root of {s} = {s}\n", .{ n, getSuffix(n), x, rt });
    }

    // -------------- Translation of Go
    print("\n\n", .{});
    for (integers) |tuple| {
        const n = tuple[0];
        const x = tuple[1];
        const rt = try rootG(allocator, n, x);
        defer allocator.free(rt);

        print("{d}{s} root of {s} = {s}\n", .{ n, getSuffix(n), x, rt });
    }
}

// Translation of C++
fn root(base: u64, n: u64) !u64 {
    if (base < 2) return base;
    if (n == 0) return 1;

    const n1 = n - 1;
    const n2 = n;
    const n3 = n1;
    var c: u64 = 1;
    var d = (n3 + base) / n2;
    var e = (n3 * d + base / try math.powi(u64, d, n1)) / n2;

    while (c != d and c != e) {
        c = d;
        d = e;
        e = (n3 * e + base / try math.powi(u64, e, n1)) / n2;
    }

    if (d < e) return d;
    return e;
}

fn getSuffix(n: usize) []const u8 {
    const suffixes = [4][]const u8{
        "th", "st", "nd", "rd",
    };
    return suffixes[
        switch (n % 10) {
            1 => if (n % 100 == 11) 0 else 1,
            2 => if (n % 100 == 12) 0 else 2,
            3 => if (n % 100 == 13) 0 else 3,
            else => 0,
        }
    ];
}

/// Translation of Python
/// Considerably more verbose than the Python.
fn rootP(allocator: mem.Allocator, a_: u2, b_: []const u8) ![]const u8 {
    var b: Int = try .init(allocator);
    defer b.deinit();
    try b.setString(10, b_);

    var two: Int = try .initSet(allocator, 2);
    defer two.deinit();

    // b < 2
    if (b.order(two) == .lt)
        return allocator.dupe(u8, "4321");

    var a: Int = try .initSet(allocator, a_);
    defer a.deinit();

    const a1_ = a_ - 1;
    var a1: Int = try .initSet(allocator, a1_);
    defer a1.deinit();

    var c: Int = try .initSet(allocator, 1);
    defer c.deinit();

    var d: Int = try .init(allocator);
    defer d.deinit();
    try calcP(allocator, &d, &a1, a1_, &c, &b, &a);

    var e: Int = try .init(allocator);
    defer e.deinit();
    try calcP(allocator, &e, &a1, a1_, &d, &b, &a);

    var result: Int = try .init(allocator);
    defer result.deinit();

    while (!c.eql(d) and !c.eql(d)) {
        // c = d
        c.swap(&d);
        // d = e
        d.swap(&e);
        // use d in place of e as they have just been swapped
        // (a1 * e + b // (e ** a1)) // a
        try calcP(allocator, &result, &a1, a1_, &d, &b, &a);
        e.swap(&result);
    }
    return switch (d.order(e)) {
        .lt => d.toString(allocator, 10, .lower),
        .eq, .gt => e.toString(allocator, 10, .lower),
    };
}

// Python: d = (a1 * c + b // (c ** a1)) // a
fn calcP(allocator: mem.Allocator, result: *Int, a1: *const Int, a1_: u8, c: *const Int, b: *const Int, a: *const Int) !void {
    var tmp1: Int = try .init(allocator);
    var tmp2: Int = try .init(allocator);
    var quotient: Int = try .init(allocator);
    var remainder: Int = try .init(allocator);
    defer tmp1.deinit();
    defer tmp2.deinit();
    defer quotient.deinit();
    defer remainder.deinit();

    // a1 * c
    try tmp1.mul(a1, c);
    // c ** a1
    try tmp2.pow(c, a1_);
    // b // (c ** a1);
    try Int.divTrunc(&quotient, &remainder, b, &tmp2);
    // a1 * c + b // (c ** a1)
    try tmp2.add(&tmp1, &quotient);
    // (a1 * c + b // (c ** a1)) // a
    try Int.divTrunc(result, &remainder, &tmp2, a);
}

/// Translation of Go big.Int
fn rootG(allocator: mem.Allocator, n_: u2, x_: []const u8) ![]const u8 {
    var xx_: Int = try .init(allocator);
    defer xx_.deinit();
    try xx_.setString(10, x_);
    const xx = xx_.toConst();

    var nn: Int = try .initSet(allocator, n_);
    defer nn.deinit();

    var x: Int = try .init(allocator);
    defer x.deinit();

    var delta_r: Int = try .init(allocator);
    defer delta_r.deinit();

    var r: Int = try .initSet(allocator, 1);
    defer r.deinit();

    // These four are temporary values to eliminate aliasing.
    // Swapping is quicker than having aliases.
    var quotient: Int = try .init(allocator);
    defer quotient.deinit();
    var remainder: Int = try .init(allocator);
    defer remainder.deinit();
    var sum: Int = try .init(allocator);
    defer sum.deinit();
    var difference: Int = try .init(allocator);
    defer difference.deinit();

    while (true) {
        try x.copy(xx);
        for (1..n_) |_| {
            // x = x / r
            try Int.divTrunc(&quotient, &remainder, &x, &r);
            Int.swap(&quotient, &x);
        }
        // x = x - r;
        try Int.sub(&difference, &x, &r);
        Int.swap(&difference, &x);
        // Δr = (x-r) / nn
        try Int.divTrunc(&delta_r, &remainder, &x, &nn);

        if (delta_r.bitCountAbs() == 0)
            return r.toString(allocator, 10, .lower);

        try Int.add(&sum, &r, &delta_r);
        Int.swap(&sum, &r);
    }
}
