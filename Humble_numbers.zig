// https://rosettacode.org/wiki/Humble_numbers
// Translation of C
const std = @import("std");
const print = std.debug.print;

fn isHumble(i: u32) bool {
    if (i <= 1) return true;
    if (i % 2 == 0) return isHumble(i / 2);
    if (i % 3 == 0) return isHumble(i / 3);
    if (i % 5 == 0) return isHumble(i / 5);
    if (i % 7 == 0) return isHumble(i / 7);
    return false;
}

/// Simple slow brute force
pub fn main() void {
    const limit = std.math.maxInt(u32);
    var humble = std.mem.zeroes([16]usize);

    var n: u32 = 1;
    var count: usize = 0;
    while (n != limit) : (n +%= 1)
        if (isHumble(n)) {
            const len = std.math.log10_int(n);
            humble[len] += 1;
            if (count < 50)
                print("{d} ", .{n});
            count += 1;
        };
    print("\n\n", .{});

    print("Of the first {d} humble numbers:\n", .{count});
    for (1..10) |num|
        print("{d:5} have {d} digits\n", .{ humble[num], num });
}
