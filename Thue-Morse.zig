// https://rosettacode.org/wiki/Thue-Morse
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var thue_morse: ThueMorseSequence = .init(allocator);
    for (0..7) |index| {
        const s = try thue_morse.next();
        try stdout.print("{d}: {s}\n", .{ index, s });
        allocator.free(s);
    }

    try stdout.flush();
}
const ThueMorseSequence = struct {
    allocator: std.mem.Allocator,
    index: u64,

    fn init(allocator: std.mem.Allocator) ThueMorseSequence {
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
