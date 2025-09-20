// https://rosettacode.org/wiki/Amicable_pairs
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var t0: std.time.Timer = try .start();

    try stdout.writeAll("The amicable pairs below 20,000 are:\n");
    for (1..20_000 + 1) |n| {
        const m = sumProperDivisors(n, true);
        if (m != 0 and n == sumProperDivisors(m, false))
            try stdout.print("{d} {d}\n", .{ m, n });
    }

    try stdout.writeByte('\n');
    try stdout.flush();
    std.log.info("processed in {D}", .{t0.read()});
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
