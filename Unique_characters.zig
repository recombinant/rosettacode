// https://rosettacode.org/wiki/Unique_characters
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const strings = [_][]const u8{ "133252abcdeeffd", "a6789798st", "yxcdfgxcyz" };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var letter_counts: [256]LetterCount = @splat(.zero);

    for (strings) |s|
        for (s) |c|
            letter_counts[c].increment();

    // Printable ASCII characters only.
    var c: u8 = ' ';
    while (c < 127) : (c += 1)
        if (letter_counts[c] == .one) try stdout.writeByte(c);
    try stdout.writeByte('\n');

    try stdout.flush();
}

const LetterCount = enum {
    zero,
    one,
    many,

    fn increment(self: *LetterCount) void {
        switch (self.*) {
            .zero => self.* = .one,
            .one => self.* = .many,
            .many => {},
        }
    }
};
