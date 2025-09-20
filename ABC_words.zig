// https://rosettacode.org/wiki/ABC_words
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() void {
    const text = @embedFile("data/unixdict.txt"); // no uppercase

    var count: usize = 0;
    var it = std.mem.splitScalar(u8, text, '\n');

    skip: while (it.next()) |word| {
        var last_index: usize = 0;
        for ("abc") |letter| {
            if (std.mem.indexOfScalar(u8, word, letter)) |index|
                if (index >= last_index) {
                    last_index = index;
                    continue;
                };
            continue :skip;
        }
        count += 1;
        const sep: u8 = if (count % 5 == 0) '\n' else ' ';
        std.debug.print("{d:3} {s:<14}{c}", .{ count, word, sep });
    }
}
