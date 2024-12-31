// https://rosettacode.org/wiki/Pick_random_element
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    const chars = [_]u8{
        'A', 'B', 'C', 'D',
        'E', 'F', 'G', 'H',
        'I', 'J', 'K', 'L',
        'M', 'N', 'O', 'P',
        'Q', 'R', 'S', 'T',
        'U', 'V', 'W', 'X',
        'Y', 'Z', '?', '!',
        '<', '>', '(', ')',
    };
    for (1..33) |i| {
        const sep: u8 = if (i % 4 == 0) '\n' else ' ';
        std.debug.print("'{c}',{c}", .{ chars[random.intRangeLessThan(usize, 0, chars.len)], sep });
    }
}
