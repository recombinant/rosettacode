// https://rosettacode.org/wiki/Lah_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");
const testing = std.testing;

pub fn main() anyerror!void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("unsigned Lah numbers: L(n, k):\n");
    try stdout.writeAll("n/k ");
    for (0..13) |i| {
        try stdout.print("{d:10} ", .{i});
    }
    try stdout.writeAll("\n");
    for (0..13) |row| {
        try stdout.print("{d:3}", .{row});
        for (0..row + 1) |i| {
            const l = lah(u64, row, i);
            try stdout.print("{d:11}", .{l});
        }
        try stdout.writeAll("\n");
    }

    // Maximum value of a Lah number for n = 100
    var max: u2048 = 0; // Experimentation shows that u1043 would be sufficient.
    const n: @TypeOf(max) = 100;
    var k: @TypeOf(max) = 0;
    while (k <= n) : (k += 1) {
        const l = lah(@TypeOf(max), 100, k);
        if (l > max) max = l;
    }
    try stdout.print("\nmaximum Lah number for n = 100: {d}\n", .{max});

    try stdout.flush();
}

fn factorial(comptime T: type, n: T) T {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("T must be an unsigned int type");
    var res: T = 1;
    if (n == 0)
        return res;

    var i: T = 2;
    while (i <= n) : (i += 1) res *= i;

    return res;
}

fn lah(comptime T: type, n: T, k: T) T {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("T must be an unsigned int type");
    if (k == 1) return factorial(T, n);
    if (k == n) return 1;
    if (k > n) return 0;
    if (k < 1 or n < 1) return 0;
    return (factorial(T, n) * factorial(T, n - 1)) / (factorial(T, k) * factorial(T, k - 1)) / factorial(T, n - k);
}

test "factorial" {
    try testing.expectEqual(factorial(u8, 5), 120);
    try testing.expectEqual(factorial(u128, 22), 1124000727777607680000);
}

test "Lah numbers" {
    try testing.expectEqual(lah(u16, 4, 3), 12);
    try testing.expectEqual(lah(u32, 6, 2), 1800);
    try testing.expectEqual(lah(u1043, 100, 10), 44519005448993144810881324947684737529186447692709328597242209638906324913313742508392928375354932241404408343800007105650554669129521241784320000000000000000000000);
}
