// https://rosettacode.org/wiki/Duffinian_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

fn isDuffinian(n_: anytype) bool {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isDuffinian() expected unsigned integer argument, found " ++ @typeName(T));

    if (n_ == 2)
        return false;
    var n = n_;
    var total: T = 1;
    var power: T = 2;
    while (n & 1 == 0) : ({
        power <<= 1;
        n >>= 1;
    }) {
        total += power;
    }
    var p: T = 3;
    while (p * p <= n) : (p += 2) {
        var sum: T = 1;
        power = p;
        while (n % p == 0) : ({
            power *= p;
            n /= p;
        }) {
            sum += power;
        }
        total *= sum;
    }
    if (n_ == n)
        return false;
    if (n > 1)
        total *= n + 1;
    return std.math.gcd(total, n_) == 1;
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("First 50 Duffinian numbers:\n");
    {
        var count: usize = 0;
        var n: u16 = 1;
        while (count < 50) : (n += 1) {
            if (isDuffinian(n)) {
                count += 1;
                const sep: u8 = if (count % 10 == 0) '\n' else ' ';
                try stdout.print("{d:3}{c}", .{ n, sep });
            }
        }
    }
    try stdout.writeAll("\nFirst 50 Duffinian triplets:\n");
    {
        var count: usize = 0;
        var n: u32 = 1;
        var m: u32 = 0;
        while (count < 50) : (n += 1) {
            m = if (isDuffinian(n)) m + 1 else 0;
            if (m == 3) {
                count += 1;
                var buffer: [80]u8 = undefined;
                var bw: std.Io.Writer = .fixed(&buffer);
                try bw.print("({d}, {d}, {d})", .{ n - 2, n - 1, n });
                const sep: u8 = if (count % 3 == 0) '\n' else ' ';
                try stdout.print("{s:<24}{c}", .{ bw.buffered(), sep });
            }
        }
    }
    try stdout.writeByte('\n');

    try stdout.flush();
}
