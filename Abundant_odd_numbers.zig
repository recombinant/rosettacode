// https://www.rosettacode.org/wiki/Abundant_odd_numbers
// based on C
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var n: u64 = 1;
    var rank: u64 = 0;
    while (rank < 25) : (n += 2)
        if (n < sumProperDivisors(n)) {
            rank += 1;
            try stdout.print("{d}: {d}\n", .{ rank, n });
        };

    while (rank < 1_000) : (n += 2) {
        if (n < sumProperDivisors(n))
            rank += 1;
    }

    try stdout.print("\nThe one thousandth abundant odd number is: {d}\n", .{n});

    n = 1_000_000_001;
    while (true) : (n += 2)
        if (n < sumProperDivisors(n))
            break;
    try stdout.print("\nThe first abundant odd number above one billion is: {d}\n", .{n});
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
