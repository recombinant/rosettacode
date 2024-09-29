// https://rosettacode.org/wiki/Chinese_remainder_theorem
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() void {
    const n = [_]usize{ 3, 5, 7 };
    const a = [_]usize{ 2, 3, 2 };

    print("{}\n", .{chineseRemainder(n[0..], a[0..])});
}

fn mulInv(a_: usize, b_: usize) usize {
    if (b_ == 1)
        return 1;

    var x0: isize = 0;
    var x1: isize = 1;

    var a: isize = @intCast(a_);
    var b: isize = @intCast(b_);
    const b0 = b;

    while (a > 1) {
        const q = @divTrunc(a, b);
        var t = b;
        b = @mod(a, b);
        a = t;
        t = x0;
        x0 = x1 - q * x0;
        x1 = t;
    }

    if (x1 < 0)
        x1 += b0;

    return @intCast(x1);
}

fn chineseRemainder(n: []const usize, a: []const usize) usize {
    assert(n.len == a.len);

    var s: usize = 0;
    var p: usize = 1;

    for (n) |e|
        p *= e;

    for (n, 0..) |_, i| {
        const q = p / n[i];
        s += a[i] * mulInv(q, n[i]) * q;
    }
    return s % p;
}
