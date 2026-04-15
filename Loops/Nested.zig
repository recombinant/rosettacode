// https://rosettacode.org/wiki/Loops/Nested
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
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
