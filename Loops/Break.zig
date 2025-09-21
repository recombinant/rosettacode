// https://rosettacode.org/wiki/Loops/Break
// {{works with|Zig|0.15.1}}
const std = @import("std");

const print = std.debug.print;

pub fn main() !void {
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    while (true) {
        const n1 = random.intRangeAtMost(u8, 0, 19);
        try stdout.print("{d}\n", .{n1});
        if (n1 == 10)
            break;
        const n2 = random.intRangeAtMost(u8, 0, 19);
        try stdout.print("{d}\n", .{n2});
    }

    try stdout.flush();
}
