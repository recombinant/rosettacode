// https://rosettacode.org/wiki/Combinations_and_permutations
const std = @import("std");
const Number = f64;

fn perm(n: Number, k: Number) Number {
    var result: Number = 1;
    var i: Number = 0;
    while (i < k) : (i += 1)
        result *= n - i;

    return result;
}

fn comb(n: Number, k: Number) Number {
    return perm(n, k) / perm(k, k);
}

pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    const p: Number = 12;
    const c: Number = 60;

    var j: Number = 1;
    while (j < p) : (j += 1)
        try stdout.print("P({d},{d}) = {d}\n", .{ p, j, @floor(perm(p, j)) });

    var k: Number = 10;
    while (k < c) : (k += 10)
        try stdout.print("C({d},{d}) = {d}\n", .{ c, k, @floor(comb(c, k)) });
}
