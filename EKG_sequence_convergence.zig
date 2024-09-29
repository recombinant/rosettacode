// https://rosettacode.org/wiki/EKG_sequence_convergence
// Translation of Go
const std = @import("std");
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() void {
    const limit = 100;
    const starts = [5]u16{ 2, 5, 7, 9, 10 };
    var ekg: [5][limit]u16 = undefined;

    for (starts, 0..) |start, s| {
        ekg[s][0] = 1;
        ekg[s][1] = start;
        for (2..limit) |n| {
            var i: u16 = 2;
            while (true) : (i += 1) {
                // a potential sequence member cannot already have been used
                // and must have a factor in common with previous member
                if ((mem.indexOfScalar(u16, ekg[s][0..n], i) == null) and math.gcd(ekg[s][n - 1], i) > 1) {
                    ekg[s][n] = i;
                    break;
                }
            }
        }
        print("EKG({d:2}): [", .{start});
        print("{d}", .{ekg[s][0]});
        for (1..30) |i| print(" {d}", .{ekg[s][i]});
        print("]\n", .{});
    }

    for (2..limit) |i| {
        if (ekg[1][i] == ekg[2][i] and areSame(ekg[1][0..i], ekg[2][0..i])) {
            print("\nEKG(5) and EKG(7) converge at term {d}\n", .{i + 1});
            return;
        }
    }
    print("\nEKG5(5) and EKG(7) do not converge within {d} terms\n", .{limit});
}

fn areSame(s: []u16, t: []u16) bool {
    assert(s.len == t.len);

    sort.insertion(u16, s, {}, sort.asc(u16));
    sort.insertion(u16, t, {}, sort.asc(u16));

    return mem.eql(u16, s, t);
}
