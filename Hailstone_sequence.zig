// https://rosettacode.org/wiki/Hailstone_sequence
// Translation of C
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

const N: u32 = 100_000;

pub fn main() !void {
    // -------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ------------------------------------------
    var jatmax: u32 = undefined;
    var hmax: u32 = 0;
    var j: u32 = 1;
    while (j < N) : (j += 1) {
        const n = hailstone(j, null);
        if (n > hmax) {
            hmax = n;
            jatmax = j;
        }
    }

    const array = try allocator.alloc(u32, hailstone(27, null));
    defer allocator.free(array);
    const n = hailstone(27, array);

    print(
        "[ {d}, {d}, {d}, {d}, ...., {d}, {d}, {d}, {d}] len={d}\n",
        .{ array[0], array[1], array[2], array[3], array[n - 4], array[n - 3], array[n - 2], array[n - 1], n },
    );
    print("Max {d} at hailstone({d})\n", .{ hmax, jatmax });
}

fn hailstone(n: u32, array: ?[]u32) u32 {
    var value = n;
    var hs: u32 = 1;
    var idx: usize = 0;

    while (value != 1) {
        hs += 1;
        if (array) |a|
            a[idx] = value;
        idx += 1;
        value = if (value & 1 != 0) (3 * value + 1) else (value / 2);
    }
    if (array) |a|
        a[idx] = value;
    return hs;
}
