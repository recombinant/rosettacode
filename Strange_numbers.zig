// https://rosettacode.org/wiki/Strange_numbers
// {{works with|Zig|0.15.1}}

// zig run Strange_numbers.zig | fmt
const std = @import("std");

// // This would be the array if it were hard-coded integers.
// const next_digit = [_]u32{
//     0x7532,  0x8643,  0x97540, 0x86510, 0x97621,
//     0x87320, 0x98431, 0x95420, 0x6531,  0x7642,
// };

/// The next_digits array is calculated at comptime.
/// Pack 4 bit hex values into a 32bit integer rather than using
/// a list as per the Go and Wren solutions.
const next_digit: [10]u32 = blk: {
    var possibles: [10]u32 = @splat(0);
    const diffs = [_]i32{ -7, -5, -3, -2, 2, 3, 5, 7 };
    for (0..possibles.len) |i| {
        var factor: i32 = 1;
        for (diffs) |d| {
            const sum = @as(i32, @intCast(i)) + d;
            if (sum >= 0 and sum < 10) {
                possibles[i] += @intCast(sum * factor);
                factor *= 0x10;
            }
        }
    }
    break :blk possibles;
};

fn gen(p: []u8, i: usize, c: u8, w: *std.Io.Writer) void {
    p[i] = c;

    if (i == p.len - 1)
        w.print("{s}\n", .{p}) catch @panic("write failed")
    else {
        var d = next_digit[c - '0'];
        while (d != 0) : (d >>= 4)
            gen(p, i + 1, '0' + @as(u8, @truncate(d & 0x0f)), w);
    }
}

pub fn main() void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------- task
    {
        var buf: [3]u8 = undefined;
        for ('1'..'5') |c|
            gen(&buf, 0, @truncate(c), stdout);
        stdout.flush() catch @panic("flush failed");
    }
    // -------------------------------------- extended task
    {
        var table: [10][10]u32 = @splat(@splat(0));

        for (0..10) |j| table[0][j] = 1;

        for (1..10) |i|
            for (0..10) |j| {
                var d = next_digit[j];
                while (d != 0) : (d >>= 4)
                    table[i][j] += table[i - 1][d & 0x0f];
            };

        stdout.print("\n{d} 10-digits starting with 1\n\n", .{table[9][1]}) catch @panic("write failed");
        stdout.flush() catch @panic("flush failed");
    }
}
