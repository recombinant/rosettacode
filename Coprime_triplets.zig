// https://rosettacode.org/wiki/Coprime_triplets
// {{works with|Zig|0.15.1}}
// {{trans|Nim}}
const std = @import("std");
const gcd = std.math.gcd;
const indexOfScalar = std.mem.indexOfScalar;
const print = std.debug.print;

pub fn main() !void {
    const T: type = u8;
    const limit: T = 50;

    var buffer: [limit]T = undefined;
    var list: std.ArrayList(T) = .initBuffer(&buffer);
    try list.appendSliceBounded(&[2]T{ 1, 2 });

    while (true) {
        var n: T = 3;
        const prev2 = list.items[list.items.len - 2];
        const prev1 = list.items[list.items.len - 1];
        while (indexOfScalar(T, list.items, n) != null or gcd(n, prev2) != 1 or gcd(n, prev1) != 1)
            n += 1;
        if (n > limit)
            break;
        try list.appendBounded(n);
    }
    // Pretty print
    print("Coprime triplets under {}:\n", .{limit});
    for (list.items, 1..) |n, i|
        print("{d:2}{c}", .{ n, @as(u8, if (i % 10 == 0) '\n' else ' ') });
    if (list.items.len % 10 != 0)
        print("\n", .{});

    print("\nFound {} terms.", .{list.items.len});
}
