// https://rosettacode.org/wiki/Own_digits_power_sum
// Translation of C
const std = @import("std");
const print = std.debug.print;

const MAX_DIGITS = 9;

var digits: [MAX_DIGITS]u4 = undefined;

fn getDigits(i_: u64) void {
    var i = i_;
    var ix: u64 = 0;
    while (i > 0) : (ix += 1) {
        digits[ix] = @intCast(i % 10);
        i /= 10;
    }
}

pub fn main() !void {
    var powers = [10]u64{ 0, 1, 4, 9, 16, 25, 36, 49, 64, 81 };
    print("Own digits power sums for N = 3 to 9 inclusive:\n", .{});
    var n: u64 = 3;
    while (n < 10) : (n += 1) {
        for (powers[2..], 2..) |*p, d| p.* *= d;
        var i = try std.math.powi(u64, 10, n - 1);
        const max = i * 10;
        var last_digit: u4 = 0;
        var sum: u64 = undefined;
        while (i < max) {
            if (last_digit == 0) {
                getDigits(i);
                sum = 0;
                for (0..n) |d| {
                    const dp = digits[d];
                    sum += powers[dp];
                }
            } else if (last_digit == 1)
                sum += 1
            else
                sum += powers[last_digit] - powers[last_digit - 1];

            if (sum == i) {
                print("{d}\n", .{i});
                if (last_digit == 0) print("{d}\n", .{i + 1});
                i += 10 - last_digit;
                last_digit = 0;
            } else if (sum > i) {
                i += 10 - last_digit;
                last_digit = 0;
            } else if (last_digit < 9) {
                i += 1;
                last_digit += 1;
            } else {
                i += 1;
                last_digit = 0;
            }
        }
    }
}
