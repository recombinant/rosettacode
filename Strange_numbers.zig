// https://rosettacode.org/wiki/Strange_numbers
// zig run Strange_numbers.zig | fmt
const std = @import("std");

// // This would be the array if it were hard-coded integers.
// const next_digit = [_]u32{
//     0x7532,  0x8643,  0x97540, 0x86510, 0x97621,
//     0x87320, 0x98431, 0x95420, 0x6531,  0x7642,
// };

/// The next_digits array is calculated at comptime.
/// Pack 4 bit hex values into a 32bit integer rather than using
/// a list as per the Go and Wren examples.
const next_digit: [10]u32 = blk: {
    var possibles: [10]u32 = [1]u32{0} ** 10;
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

fn gen(p: []u8, i: usize, c: u8) void {
    p[i] = c;

    if (i == p.len - 1)
        std.io.getStdOut().writer().print("{s}\n", .{p}) catch unreachable
    else {
        var d = next_digit[c - '0'];
        while (d != 0) : (d >>= 4)
            gen(p, i + 1, '0' + @as(u8, @truncate(d & 0x0f)));
    }
}

pub fn main() !void {
    // ----------------------------------------------- task
    {
        var buf: [3]u8 = undefined;
        for ('1'..'5') |c|
            gen(&buf, 0, @truncate(c));
    }
    // -------------------------------------- extended task
    {
        var table: [10][10]u32 = [1][10]u32{[1]u32{0} ** 10} ** 10;

        for (0..10) |j| table[0][j] = 1;

        for (1..10) |i|
            for (0..10) |j| {
                var d = next_digit[j];
                while (d != 0) : (d >>= 4)
                    table[i][j] += table[i - 1][d & 0x0f];
            };

        std.io.getStdOut().writer().print("\n{d} 10-digits starting with 1\n", .{table[9][1]}) catch unreachable;
    }

    if (false) {
        // ------------------------------------------- task
        var count: usize = 0;
        var n: u16 = 100;
        while (n <= 500) : (n += 1) {
            if (isStrange(u16, n, 3)) {
                count += 1;
                const sep: u8 = if (count % 10 == 0) '\n' else ' ';
                std.debug.print("{d}{c}", .{ n, sep });
            }
        }
        if (count % 10 != 0)
            std.debug.print("\n", .{});
        std.debug.print("\n{} strange numbers\n", .{count});
    }
    if (false) {
        // ---------------------- brute force extended task
        var count: usize = 0;
        var n: u32 = 1_000_000_000;
        while (n < 2_000_000_000) : (n += 1) {
            if (isStrange(u32, n, 10))
                count += 1;
        }
        std.debug.print("\n\n{} 10 digit strange numbers starting with 1\n", .{count});
    }
}

fn isStrange(comptime T: type, n_arg: T, comptime digit_count: usize) bool {
    var n = n_arg;
    var digits: [digit_count]i8 = undefined;
    for (&digits) |*d| {
        d.* = @intCast(n % 10);
        n /= 10;
    }
    const slice0 = digits[0 .. digit_count - 1];
    const slice1 = digits[1..digit_count];
    for (slice0, slice1) |d0, d1|
        if (!isPrimeDigit(d0 - d1))
            return false;
    return true;
}

inline fn isPrimeDigit(n: i8) bool {
    switch (n) {
        -7, -5, -3, -2, 2, 3, 4, 5 => return true,
        else => return false,
    }
}
