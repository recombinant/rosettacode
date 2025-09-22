// https://rosettacode.org/wiki/Minimum_multiple_of_m_where_digital_sum_equals_m
// {{works with|Zig|0.15.1}}
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
    var t0: std.time.Timer = try .start();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var n: u64 = 1;
    while (n <= 70) : (n += 1) {
        try stdout.print("{d:9}", .{a131382(n)});
        if (n % 10 == 0) {
            try stdout.writeByte('\n');
            try stdout.flush();
        }
    }
    try stdout.writeByte('\n');
    try stdout.flush();

    std.log.info("processed in {D}", .{t0.read()});
}
