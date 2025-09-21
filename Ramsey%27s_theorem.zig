// https://rosettacode.org/wiki/Ramsey%27s_theorem
// {{works with|Zig|0.15.1}}
// {{trans|C}}
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

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (0..17) |i| {
        for (0..17) |j|
            try stdout.print("{c} ", .{@intFromEnum(a[i][j])});
        try stdout.writeByte('\n');
    }

    for (0..17) |i| {
        idx[0] = i;
        if (try findGroup(.one, i + 1, 17, 1, stdout) or try findGroup(.zero, i + 1, 17, 1, stdout)) {
            try stdout.writeAll("no good\n");
            try stdout.flush();
            return;
        }
    }

    try stdout.writeAll("all good\n");
    try stdout.flush();
}

fn findGroup(kind: Kind, min_n: usize, max_n: usize, depth: usize, w: *std.Io.Writer) !bool {
    if (depth == 4) {
        try w.print("totally {s}connected group:", .{if (kind != .zero) "" else "un"});
        for (idx) |value| {
            try w.print(" {d}", .{value});
        }
        try w.writeByte('\n');
        try w.flush();
        return true;
    }

    for (min_n..max_n) |i| {
        var n: usize = 0;

        while (n < depth) : (n += 1)
            if (a[idx[n]][i] != kind)
                break;

        if (n == depth) {
            idx[n] = i;
            if (try findGroup(kind, 1, max_n, depth + 1, w))
                return true;
        }
    }
    return false;
}
