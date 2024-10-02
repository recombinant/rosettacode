// https://rosettacode.org/wiki/Munchausen_numbers
const std = @import("std");
const math = std.math;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const limit = 5_000; // the upper bound of the search

    var number: u16 = 1;
    while (number <= limit) : (number += 1)
        if (isMunchausen(number))
            try stdout.print("{d} (munchausen)\n", .{number});
}

/// If the sum is equal to the number itself then the number will
/// be a Munchausen number.
fn isMunchausen(n_: anytype) bool {
    const T = @TypeOf(n_);

    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("type must be an unsigned integer.");

    var sum: T = 0;
    // loop through each digit in n_
    // e.g. for 1000 we get 0, 0, 0, 1.
    var n = n_;
    while (n != 0) {
        const digit = n % 10;
        n /= 10;

        // There may be integer overflow.
        // If there is integer overflow then n_ is
        // not a Munchausen number.

        // Find the sum of the digits raised to themselves.
        const pow = math.powi(T, digit, digit) catch |err|
            switch (err) {
            error.Overflow => return false,
            error.Underflow => unreachable,
        };

        const ov = @addWithOverflow(sum, pow);
        if (ov[1] != 0)
            return false;

        // sum = sum + digit**digit
        sum = ov[0];
    }
    return sum == n_;
}
