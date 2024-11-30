// https://rosettacode.org/wiki/Increasing_gaps_between_consecutive_Niven_numbers
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    var t0 = try std.time.Timer.start();

    var previous: u64 = 1;
    var gap: u64 = 0;
    var sum: u64 = 0;
    var niven_index: usize = 0;
    var gap_index: usize = 1;

    print("Gap index  Gap    Niven index    Niven number\n", .{});
    var niven: u64 = 1;
    while (gap_index <= 32) : (niven += 1) {
        sum = digitSum(niven, sum);
        if (divisible(niven, sum)) {
            if (niven > previous + gap) {
                gap = niven - previous;
                print("{d:9}{d:5}{d:15}{d:16}\n", .{ gap_index, gap, niven_index, previous });
                gap_index += 1;
            }
            previous = niven;
            niven_index += 1;
        }
    }
    print("\nprocessed in {}\n", .{std.fmt.fmtDuration(t0.read())});
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
