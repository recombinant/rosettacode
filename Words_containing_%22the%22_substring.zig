// https://rosettacode.org/wiki/Words_containing_%22the%22_substring
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt"); // no uppercase

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var it = std.mem.splitScalar(u8, text, '\n');

    while (it.next()) |word|
        if (word.len > 11)
            if (std.mem.indexOf(u8, word, "the")) |_|
                try stdout.print("{s}\n", .{word});

    try stdout.flush();
}
