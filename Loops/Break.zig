// https://rosettacode.org/wiki/Loops/Break
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
    const stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout);
    var writer = bw.writer();
    // ----------------------------------------------------------
    while (true) {
        const n1 = random.intRangeAtMost(u8, 0, 19);
        try writer.print("{d}\n", .{n1});
        if (n1 == 10)
            break;
        const n2 = random.intRangeAtMost(u8, 0, 19);
        try writer.print("{d}\n", .{n2});
    }
    try bw.flush();
}
