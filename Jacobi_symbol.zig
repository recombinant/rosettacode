// https://rosettacode.org/wiki/Jacobi_symbol
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

fn jacobi(a_: u32, n_: u32) i32 {
    var a = a_;
    var n = n_;
    if (a >= n)
        a %= n;
    var result: i32 = 1;
    while (a != 0) {
        while (a & 1 == 0) {
            a >>= 1;
            if ((n & 7) == 3 or (n & 7) == 5)
                result = -result;
        }
        std.mem.swap(u32, &a, &n);
        if ((a & 3) == 3 and (n & 3) == 3)
            result = -result;
        a %= n;
    }
    if (n == 1)
        return result;
    return 0;
}

fn printTable(kmax: u32, nmax: u32, w: *std.Io.Writer) !void {
    try w.writeAll("n\\k|");
    var k: u32 = 0;
    while (k <= kmax) : (k += 1)
        try w.print("{d:3}", .{k});
    try w.writeAll("\n----");
    k = 0;
    while (k <= kmax) : (k += 1)
        try w.writeAll("---");
    try w.writeByte('\n');
    var n: u32 = 1;
    while (n <= nmax) : (n += 2) {
        try w.print("{d:2} |", .{n});
        k = 0;
        while (k <= kmax) : (k += 1) {
            // at Zig 0.14
            // signed print alway has a leading + or -
            // unsigned for non-negative numbers
            const j = jacobi(k, n);
            const fmt = "{d:3}";
            if (j < 0)
                try w.print(fmt, .{j})
            else
                try w.print(fmt, .{@as(u32, @bitCast(j))});
        }
        try w.writeByte('\n');
    }
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try printTable(20, 21, stdout);

    try stdout.flush();
}
