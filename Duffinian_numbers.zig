// https://rosettacode.org/wiki/Duffinian_numbers
// Copied from C++
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
    const writer = std.io.getStdOut().writer();
    try writer.writeAll("First 50 Duffinian numbers:\n");
    {
        var count: usize = 0;
        var n: u16 = 1;
        while (count < 50) : (n += 1) {
            if (isDuffinian(n)) {
                count += 1;
                const sep: u8 = if (count % 10 == 0) '\n' else ' ';
                try writer.print("{d:3}{c}", .{ n, sep });
            }
        }
    }
    try writer.writeAll("\nFirst 50 Duffinian triplets:\n");
    {
        var count: usize = 0;
        var n: u32 = 1;
        var m: u32 = 0;
        while (count < 50) : (n += 1) {
            m = if (isDuffinian(n)) m + 1 else 0;
            if (m == 3) {
                count += 1;
                var buffer: [80]u8 = undefined;
                var fbs = std.io.fixedBufferStream(&buffer);
                try fbs.writer().print("({d}, {d}, {d})", .{ n - 2, n - 1, n });
                const sep: u8 = if (count % 3 == 0) '\n' else ' ';
                try writer.print("{s:<24}{c}", .{ fbs.getWritten(), sep });
            }
        }
    }
    try writer.writeByte('\n');
}
