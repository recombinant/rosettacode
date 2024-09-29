// https://rosettacode.org/wiki/Amicable_pairs
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var t0 = try std.time.Timer.start();

    try stdout.writeAll("The amicable pairs below 20,000 are:\n");
    for (1..20_000 + 1) |n| {
        const m = sumProperDivisors(n, true);
        if (m != 0 and n == sumProperDivisors(m, false))
            try stdout.print("{d} {d}\n", .{ m, n });
    }

    try stdout.writeByte('\n');
    try stdout.print("Processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}

// Adapted from:
// https://rosettacode.org/wiki/Abundant,_deficient_and_perfect_number_classifications#C
// Less looping.
fn sumProperDivisors(number: u64, check_over: bool) u64 {
    if (number < 2) return 0;
    var limit = number / 2;
    var sum: u64 = 1; // 1 is in all proper division numbers
    const offset = number % 2;
    var j: u64 = 2 + offset;
    while (j < limit) : (j += 1 + offset) {
        if (number % j != 0)
            continue;
        limit = number / j;
        sum += j;
        if (j != limit)
            sum += limit;
        if (check_over and sum >= number)
            return 0;
    }
    return sum;
}
