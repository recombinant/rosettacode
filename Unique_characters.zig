// https://rosettacode.org/wiki/Unique_characters
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const strings = [_][]const u8{ "133252abcdeeffd", "a6789798st", "yxcdfgxcyz" };

    var letter_counts = [1]LetterCount{.zero} ** 256;

    for (strings) |s|
        for (s) |c|
            letter_counts[c].increment();

    // Printable ASCII characters only.
    var c: u8 = ' ';
    while (c < 127) : (c += 1)
        if (letter_counts[c] == .one) print("{c}", .{c});
    print("\n", .{});
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
