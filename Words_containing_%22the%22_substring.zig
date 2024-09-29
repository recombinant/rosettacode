// https://rosettacode.org/wiki/Words_containing_%22the%22_substring
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt"); // no uppercase

    var it = mem.splitScalar(u8, text, '\n');

    while (it.next()) |word|
        if (word.len > 11)
            if (mem.indexOf(u8, word, "the")) |_|
                print("{s}\n", .{word});
}
