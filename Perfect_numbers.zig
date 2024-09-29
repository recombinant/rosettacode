// https://rosettacode.org/wiki/Perfect_numbers
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const math = std.math;
const print = std.debug.print;

pub fn main() void {
    var n: usize = 2;
    while (n < 10_000) : (n += 1)
        if (isPerfect(n))
            print("{}\n", .{n});
}

fn isPerfect(n: usize) bool {
    const max = math.sqrt(n) + 1;

    var tot: usize = 1;
    var i: usize = 2;
    while (i < max) : (i += 1)
        if ((n % i) == 0) {
            tot += i;
            const q = n / i;
            if (q > i)
                tot += q;
        };
    return tot == n;
}
