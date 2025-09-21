// https://rosettacode.org/wiki/Increasing_gaps_between_consecutive_Niven_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var t0: std.time.Timer = try .start();

    var previous: u64 = 1;
    var gap: u64 = 0;
    var sum: u64 = 0;
    var niven_index: usize = 0;
    var gap_index: usize = 1;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("Gap index  Gap    Niven index    Niven number\n");
    var niven: u64 = 1;
    while (gap_index <= 32) : (niven += 1) {
        sum = digitSum(niven, sum);
        if (divisible(niven, sum)) {
            if (niven > previous + gap) {
                gap = niven - previous;
                try stdout.print("{d:9}{d:5}{d:15}{d:16}\n", .{ gap_index, gap, niven_index, previous });
                try stdout.flush();
                gap_index += 1;
            }
            previous = niven;
            niven_index += 1;
        }
    }

    std.log.info("processed in {D}", .{t0.read()});
}

// Returns the sum of the digits of n given the
// sum of the digits of n - 1
fn digitSum(n_: u64, sum_: u64) u64 {
    var n = n_;
    var sum = sum_ + 1;
    while (n > 0 and n % 10 == 0) {
        sum -= 9;
        n /= 10;
    }
    return sum;
}

fn divisible(n: u64, d: u64) bool {
    if (d & 1 == 0 and n & 1 == 1)
        return false;
    return n % d == 0;
}
