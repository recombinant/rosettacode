// https://rosettacode.org/wiki/Thue-Morse
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var thue_morse: ThueMorseSequence = .init(gpa);
    for (0..7) |index| {
        const s = try thue_morse.next();
        try stdout.print("{d}: {s}\n", .{ index, s });
        gpa.free(s);
    }

    try stdout.flush();
}
const ThueMorseSequence = struct {
    allocator: Allocator,
    index: u64,

    fn init(allocator: Allocator) ThueMorseSequence {
        return ThueMorseSequence{
            .allocator = allocator,
            .index = 0,
        };
    }
    /// Caller owns returned memory slice.
    fn next(self: *ThueMorseSequence) ![]const u8 {
        const len = std.math.shl(usize, 1, self.index);
        const result = try self.allocator.alloc(u8, len);
        for (result, 0..) |*digit, n|
            digit.* = @popCount(n) % 2 + '0';
        self.index += 1;
        return result;
    }
};
