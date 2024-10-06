// https://rosettacode.org/wiki/Factorions
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    // cache factorials from 0 to 11
    var factorial: [12]usize = undefined;
    factorial[0] = 1;
    for (1..factorial.len) |n|
        factorial[n] = factorial[n - 1] * n;

    for (9..12 + 1) |base| {
        print("The factorions for base {d} are:\n", .{base});
        for (1..1_500_000) |i| {
            var n: usize = i;

            var sum: usize = 0;
            while (n >= base) {
                sum += factorial[n % base];
                n /= base;
            }
            sum += factorial[n];

            if (sum == i)
                printNumber(i, @intCast(base));
        }
        print("\n", .{});
    }
}

fn printNumber(n: usize, base: u8) void {
    if (base != 10) {
        var buffer: [10]u8 = undefined;
        const converted = std.fmt.bufPrintIntToSlice(&buffer, n, base, .lower, .{});
        print("  {s} (decimal {})\n", .{ converted, n });
    } else {
        print("  {}\n", .{n});
    }
}
