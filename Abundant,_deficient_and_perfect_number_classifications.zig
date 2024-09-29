// https://rosettacode.org/wiki/Abundant,_deficient_and_perfect_number_classifications
const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var deficient: u64 = 1; // 1 is deficient by default, add it to deficient
    var perfect: u64 = 0;
    var abundant: u64 = 0;

    for (2..20_000 + 1) |n| {
        const sum = sumProperDivisors(n);
        if (sum < n)
            deficient += 1
        else if (sum == n)
            perfect += 1
        else
            abundant += 1;
    }

    try stdout.writeAll("The classification of the numbers between 1 and 20,000 is as follows :\n");
    try stdout.print("  Deficient = {d}\n", .{deficient});
    try stdout.print("  Perfect   = {d}\n", .{perfect});
    try stdout.print("  Abundant  = {d}\n", .{abundant});

    try bw.flush();
}

// From the C implementation. Less looping.
fn sumProperDivisors(number: u64) u64 {
    assert(number > 1);
    var limit = number / 2;
    var sum: u64 = 1; // 1 is in all proper division numbers
    var j: u64 = 2;
    while (j < limit) : (j += 1) {
        if (number % j != 0)
            continue;
        limit = number / j;
        sum += j;
        if (j != limit)
            sum += limit;
    }
    return sum;
}
