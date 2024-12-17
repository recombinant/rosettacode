// https://rosettacode.org/wiki/Zsigmondy_numbers
// Translation of C
const std = @import("std");

pub fn main() !void {
    const a_list = [10]u8{ 2, 3, 4, 5, 6, 7, 3, 5, 7, 7 };
    const b_list = [10]u8{ 1, 1, 1, 1, 1, 1, 2, 3, 3, 5 };

    const terms = 20;

    const writer = std.io.getStdOut().writer();

    for (a_list, b_list) |a, b|
        try printZsigmondy(a, b, terms, writer);
}

fn printZsigmondy(a: u64, b: u64, terms: u8, writer: anytype) !void {
    try writer.print("Zsigmondy(n, {d}, {d}) - first {d} terms:\n", .{ a, b, terms });
    var n: u8 = 1;
    while (n <= terms) : (n += 1)
        try writer.print("{d} ", .{try calcZsigmondy(n, a, b)});
    try writer.writeByteNTimes('\n', 2);
}

fn calcZsigmondy(n: u8, a: u64, b: u64) !u64 {
    const dn = try std.math.powi(u64, a, n) - try std.math.powi(u64, b, n);

    var maxdiv: u64 = 0;
    var d: u64 = 1;
    while (d * d <= dn) : (d += 1) {
        if (dn % d != 0)
            continue;
        if (try allCoprime(a, b, d, n))
            maxdiv = if (d > maxdiv) d else maxdiv;

        const dnd = dn / d;
        if (try allCoprime(a, b, dnd, n))
            maxdiv = if (dnd > maxdiv) dnd else maxdiv;
    }
    return maxdiv;
}

fn allCoprime(a: u64, b: u64, d: u64, n: u8) !bool {
    var m: u8 = 1;
    while (m < n) : (m += 1) {
        const dm: u64 = try std.math.powi(u64, a, m) - try std.math.powi(u64, b, m);
        if (std.math.gcd(dm, d) != 1)
            return false;
    }
    return true;
}
