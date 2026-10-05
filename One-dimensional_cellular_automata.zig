// https://rosettacode.org/wiki/One-dimensional_cellular_automata
// {{works with|Zig|0.17.0}}
// {{trans|C}}
const std = @import("std");
const Io = std.Io;

const trans: [8:0]u8 = "___#_##_".*;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    var c: [21]u8 = "_###_##_#_#_#_#__#__\n".*;
    var b: [c.len]u8 = "____________________\n".*;
    while (true) {
        try stdout.print("{s}", .{c[1..]});
        if (!evolve(&c, &b))
            break;
    }

    try stdout.flush();
}

fn evolve(cell: []u8, backup: []u8) bool {
    var diff = false;
    for (1..cell.len - 3) |i| {
        // use left, self, right as binary number bits for table index
        const left = v(cell, i - 1);
        const self = v(cell, i);
        const right = v(cell, i + 1);
        backup[i] = trans[left * 4 + self * 2 + right];
        diff = diff or (backup[i] != cell[i]);
    }
    @memcpy(cell, backup);

    return diff;
}

inline fn v(cell: []const u8, idx: usize) usize {
    return @intFromBool(cell[idx] != '_');
}
