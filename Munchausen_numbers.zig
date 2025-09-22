// https://rosettacode.org/wiki/Munchausen_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const limit = 5_000; // the upper bound of the search

    var number: u16 = 1;
    while (number <= limit) : (number += 1)
        if (isMunchausen(number))
            try stdout.print("{d} (munchausen)\n", .{number});

    try stdout.flush();
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
        const pow = std.math.powi(T, digit, digit) catch |err|
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
