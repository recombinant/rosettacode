// https://rosettacode.org/wiki/Loops/Break
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
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
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
