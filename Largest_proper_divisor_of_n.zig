// https://www.rosettacode.org/wiki/Largest_proper_divisor_of_n
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var n: u8 = 1;
    while (n < 101) : (n += 1)
        try stdout.print(
            "{d:2}{c}",
            .{
                largestProperDivisor(n),
                @as(u8, if (n % 10 == 0) '\n' else ' '),
            },
        );
}

/// Counting up to sqrt(n) requires less looping than
/// counting down from (n / 2) for n in range 1..101
fn largestProperDivisor(n: u8) u8 {
    const limit = std.math.sqrt(n) + 1;

    // Zig for() loop uses usize, so use a while() loop
    // to avoid intCast() or truncate()
    var d: @TypeOf(n) = 2;
    while (d < limit) : (d += 1)
        if (n % d == 0)
            return n / d;
    return 1;
}
