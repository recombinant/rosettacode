// https://rosettacode.org/wiki/Ramsey%27s_theorem
// Translation of C
const std = @import("std");

const Kind = enum(u8) {
    zero = '0',
    one = '1',
    two = '-',
};

var a: [17][17]Kind = undefined;
var idx: [4]usize = undefined;

pub fn main() !void {
    for (0..17) |i|
        for (0..17) |j| {
            a[i][j] = if (i == j) Kind.two else Kind.zero;
        };

    var k: usize = 1;
    while (k <= 8) : (k <<= 1)
        for (0..17) |i| {
            const j = (i + k) % 17;
            a[i][j] = Kind.one;
            a[j][i] = Kind.one;
        };

    const stdout = std.io.getStdOut().writer();

    for (0..17) |i| {
        for (0..17) |j|
            try stdout.print("{c} ", .{@intFromEnum(a[i][j])});
        try stdout.writeByte('\n');
    }

    for (0..17) |i| {
        idx[0] = i;
        if (try findGroup(.one, i + 1, 17, 1) or try findGroup(.zero, i + 1, 17, 1)) {
            try stdout.writeAll("no good\n");
            return;
        }
    }

    try stdout.writeAll("all good\n");
}

fn findGroup(kind: Kind, min_n: usize, max_n: usize, depth: usize) !bool {
    const stdout = std.io.getStdOut().writer();

    if (depth == 4) {
        try stdout.print("totally {s}connected group:", .{if (kind != .zero) "" else "un"});
        for (idx) |value| {
            try stdout.print(" {d}", .{value});
        }
        try stdout.writeByte('\n');
        return true;
    }

    for (min_n..max_n) |i| {
        var n: usize = 0;

        while (n < depth) : (n += 1)
            if (a[idx[n]][i] != kind)
                break;

        if (n == depth) {
            idx[n] = i;
            if (try findGroup(kind, 1, max_n, depth + 1))
                return true;
        }
    }

    return false;
}
