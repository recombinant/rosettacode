// https://rosettacode.org/wiki/Coprimes
const std = @import("std");
const math = std.math;
const print = std.debug.print;

pub fn main() void {
    const Pair = struct { u32, u32 };
    const pairs = [_]Pair{
        .{ 21, 15 }, .{ 17, 23 }, .{ 36, 12 },
        .{ 18, 29 }, .{ 60, 15 },
    };

    for (pairs) |pair| {
        const x, const y = pair;
        const not: []const u8 = if (isComprimePair(x, y)) "" else " not";
        print("{any} are{s} coprimes\n", .{ pair, not });
    }
}

fn isComprimePair(x: u32, y: u32) bool {
    return math.gcd(x, y) == 1;
}
