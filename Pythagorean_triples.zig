// https://rosettacode.org/wiki/Pythagorean_triples
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    var limit: usize = 10;
    while (limit <= 100_000_000) : (limit *= 10) {
        const c = countTriples(3, 4, 5, limit);
        print("Up to {d:9}: {d:10} triples, {d:8} primitives.\n", .{ limit, c.total, c.primitives });
    }
}

const TripleCount = struct {
    primitives: usize,
    total: usize,
};

fn countTriples(x: usize, y: usize, z: usize, limit: usize) TripleCount {
    var count = TripleCount{
        .primitives = 0,
        .total = 0,
    };

    var a = x;
    var b = y;
    var c = z;

    while (true) {
        const p = a + b + c;
        if (p > limit)
            break;

        count.primitives += 1;
        count.total += limit / p;

        var i: usize = a -% 2 *% b +% 2 *% c;
        var j: usize = 2 *% a -% b +% 2 *% c;
        var k: usize = j -% b +% c;

        const c1 = countTriples(i, j, k, limit);
        count.primitives += c1.primitives;
        count.total += c1.total;

        i += 4 * b;
        j += 2 * b;
        k += 4 * b;

        const c2 = countTriples(i, j, k, limit);
        count.primitives += c2.primitives;
        count.total += c2.total;

        c = k - 4 * a;
        b = j - 4 * a;
        a = i - 2 * a;
    }
    return count;
}
