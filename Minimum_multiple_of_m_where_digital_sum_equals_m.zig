// https://rosettacode.org/wiki/Minimum_multiple_of_m_where_digital_sum_equals_m
// OEIS A131382
const std = @import("std");

fn sumDigits(n_: u64) u64 {
    var n = n_;
    var sum: u64 = 0;
    while (n != 0) {
        sum += n % 10;
        n /= 10;
    }
    return sum;
}

fn a131382(n: u64) u64 {
    var m: u64 = 1;
    while (n != sumDigits(m * n)) : (m += 1) {}
    return m;
}

pub fn main() !void {
    var t0 = try std.time.Timer.start();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = bw.writer();

    var n: u64 = 1;
    while (n <= 70) : (n += 1) {
        try writer.print("{d:9}", .{a131382(n)});
        if (n % 10 == 0) {
            try writer.writeByte('\n');
            try bw.flush();
        }
    }
    try bw.flush();

    std.log.info("processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}
