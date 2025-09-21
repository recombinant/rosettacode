// https://rosettacode.org/wiki/Loops/Continue
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (1..11) |i| {
        try stdout.print("{}", .{i});
        if (i % 5 == 0) {
            try stdout.writeByte('\n');
            continue;
        }
        try stdout.writeAll(", ");
    }
    try stdout.flush();
}
