// https://www.rosettacode.org/wiki/Abundant_odd_numbers
// {{works with|Zig|0.15.1}}
// based on C
pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var n: u64 = 1;
    var rank: u64 = 0;
    while (rank < 25) : (n += 2)
        if (n < sumProperDivisors(n)) {
            rank += 1;
            try stdout.print("{d}: {d}\n", .{ rank, n });
            try stdout.flush();
        };

    while (rank < 1_000) : (n += 2) {
        if (n < sumProperDivisors(n))
            rank += 1;
    }

    try stdout.print("\nThe one thousandth abundant odd number is: {d}\n", .{n});
    try stdout.flush();

    n = 1_000_000_001;
    while (true) : (n += 2)
        if (n < sumProperDivisors(n))
            break;
    try stdout.print("\nThe first abundant odd number above one billion is: {d}\n", .{n});
    try stdout.flush();
}

// The following function is for odd numbers ONLY
fn sumProperDivisors(n: u64) u64 {
    assert(n % 2 == 1);
    var sum: u64 = 1;
    var i: u64 = 3;
    while (i < math.sqrt(n) + 1) : (i += 2) {
        if (n % i == 0) {
            const j = n / i;
            sum += i + if (i == j) 0 else j;
        }
    }
    return sum;
}

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
