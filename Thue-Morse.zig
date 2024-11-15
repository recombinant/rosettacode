// https://rosettacode.org/wiki/Thue-Morse
const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;

const print = std.debug.print;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var thue_morse = ThueMorseSequence.init(allocator);
    for (0..7) |index| {
        const s = try thue_morse.next();
        print("{d}: {s}\n", .{ index, s });
        allocator.free(s);
    }
}
const ThueMorseSequence = struct {
    allocator: mem.Allocator,
    index: u64,

    fn init(allocator: mem.Allocator) ThueMorseSequence {
        return ThueMorseSequence{
            .allocator = allocator,
            .index = 0,
        };
    }
    /// Caller owns returned memory slice.
    fn next(self: *ThueMorseSequence) ![]const u8 {
        const len = math.shl(usize, 1, self.index);
        const result = try self.allocator.alloc(u8, len);
        for (result, 0..) |*digit, n|
            digit.* = @popCount(n) % 2 + '0';
        self.index += 1;
        return result;
    }
};
