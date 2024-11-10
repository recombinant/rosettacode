// https://rosettacode.org/wiki/Loops/Nested
const std = @import("std");
const mem = std.mem;

const print = std.debug.print;

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    var a: [10][10]u8 = undefined;

    for (&a) |*row|
        for (row) |*cell| {
            cell.* = random.intRangeAtMost(u8, 1, 20);
        };

    outer: for (a) |row| {
        for (row) |cell| {
            print("{d} ", .{cell});
            if (cell == 20)
                break :outer;
        }
        print("\n", .{});
    }
    print("\n", .{});
}
