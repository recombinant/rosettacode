// https://rosettacode.org/wiki/Digit_fifth_powers
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    var sum: u64 = 0;
    var i: u64 = 2; // ignore 1
    // up to but not including 6 digits
    while (i < 1e6) : (i += 1)
        if (i == sum5(i)) {
            try writer.print("{}\n", .{i});
            sum += i;
        };
    try writer.print("Sum of all the numbers that can be written as the sum of fifth powers of their digits = {}\n", .{sum});
}

fn sum5(n_: u64) u64 {
    const cached = comptime blk: {
        var pow5: [10]u64 = undefined;
        for (&pow5, 0..) |*p, i|
            p.* = std.math.pow(u64, i, 5);
        break :blk pow5;
    };
    var sum: u64 = 0;
    var n = n_;
    while (n != 0) {
        sum += cached[n % 10];
        n /= 10;
    }
    return sum;
}
