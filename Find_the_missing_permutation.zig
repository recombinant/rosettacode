// https://rosettacode.org/wiki/Find_the_missing_permutation
// Translation of C
const std = @import("std");
const print = std.debug.print;

const N = 4;
const perms = [_]*const [N]u8{
    "ABCD", "CABD", "ACDB", "DACB", "BCDA", "ACBD", "ADCB", "CDAB",
    "DABC", "BCAD", "CADB", "CDBA", "CBAD", "ABDC", "ADBC", "BDCA",
    "DCBA", "BACD", "BADC", "BDAC", "CBDA", "DBCA", "DCAB",
};

pub fn main() void {
    const n: u32 = blk: {
        var n: u32 = 1;
        var i: u32 = 1;
        while (i < N) : (i += 1) n *= i; // n = (N-1)!, # of occurrence
        break :blk n;
    };

    var miss: [N]u8 = undefined;

    for (0..N) |i| {
        var cnt: [N]u16 = undefined;
        @memset(&cnt, 0);

        // count how many times each letter occur at position i
        for (perms) |perm|
            cnt[perm[i] - 'A'] += 1;

        // letter not occurring (N-1)! times is the missing one
        var j: u8 = 0;
        while (j < N and cnt[j] == n) j += 1;

        miss[i] = j + 'A';
    }
    print("Missing: {s}\n", .{miss});
}
