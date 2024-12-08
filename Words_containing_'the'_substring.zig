// https://rosettacode.org/wiki/Words_containing_%22the%22_substring
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (word.len > 11 and std.mem.indexOf(u8, word, "the") != null)
            print("{s}\n", .{word});
}
