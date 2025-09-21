// https://www.rosettacode.org/wiki/Largest_proper_divisor_of_n
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var n: u8 = 1;
    while (n < 101) : (n += 1)
        try stdout.print(
            "{d:2}{c}",
            .{
                largestProperDivisor(n),
                @as(u8, if (n % 10 == 0) '\n' else ' '),
            },
        );

    try stdout.flush();
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
