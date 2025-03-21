// https://rosettacode.org/wiki/ABC_words
pub fn main() void {
    const text = @embedFile("data/unixdict.txt"); // no uppercase

    var count: usize = 0;
    var it = mem.splitScalar(u8, text, '\n');

    skip: while (it.next()) |word| {
        var last_index: usize = 0;
        for ("abc") |letter| {
            if (mem.indexOfScalar(u8, word, letter)) |index|
                if (index >= last_index) {
                    last_index = index;
                    continue;
                };
            continue :skip;
        }
        count += 1;
        const sep: u8 = if (count % 5 == 0) '\n' else ' ';
        print("{d:3} {s:<14}{c}", .{ count, word, sep });
    }
}

const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
