// https://rosettacode.org/wiki/De_Polignac_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const pows2: [20]u64 = comptime calcPows(20);

    var dp1000: u64 = undefined;
    var dp10000: u64 = undefined;

    var dp_array: [50]u64 = undefined;
    dp_array[0] = 1;
    var dp_count: usize = 1;

    var n: u64 = 3;
    var count: usize = 1;
    next_n: while (count < 10_000) : (n += 2) {
        for (pows2) |pow| {
            if (pow > n) break;
            if (isPrime(n - pow)) continue :next_n;
        }
        count += 1;
        if (count <= dp_array.len) {
            dp_array[dp_count] = n;
            dp_count += 1;
        } else if (count == 1_000)
            dp1000 = n
        else if (count == 10_000)
            dp10000 = n;
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("First 50 De Polignac numbers:\n");
    for (dp_array, 1..) |dp, i| {
        try stdout.print("{d:5} ", .{dp});
        if (i % 10 == 0)
            try stdout.writeByte('\n');
    }
    try stdout.writeByte('\n');
    try stdout.print("One thousandth: {d:6}\n", .{dp1000});
    try stdout.print("Ten thousandth: {d:6}\n", .{dp10000});
    try stdout.flush();
}

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u64 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}

fn calcPows(comptime n: u16) [n]u64 {
    var pows2: [n]u64 = undefined;
    inline for (&pows2, 0..) |*p, i|
        p.* = 1 << i;
    return pows2;
}
