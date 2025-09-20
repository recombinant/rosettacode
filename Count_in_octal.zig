// https://rosettacode.org/wiki/Count_in_octal
// {{works with|Zig|0.15.1}}
// copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var i: u5 = 0;
    while (true) : (i += 1) {
        try stdout.print("{o}\n", .{i});
        if (i == std.math.maxInt(@TypeOf(i)))
            break;
    }

    try stdout.flush();
}
