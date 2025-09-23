// https://rosettacode.org/wiki/Own_digits_power_sum
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");
const print = std.debug.print;

const MAX_DIGITS = 9;

fn digitsFromNumber(output: []u4, n_: u64) []const u4 {
    var n = n_;
    var idx: u64 = 0;
    while (n != 0) : (idx += 1) {
        output[idx] = @intCast(n % 10);
        n /= 10;
    }
    return output[0..idx];
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
                var digit_buffer: [MAX_DIGITS]u4 = undefined;
                sum = 0;
                const digits = digitsFromNumber(&digit_buffer, i);
                for (digits) |digit|
                    sum += powers[digit];
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
