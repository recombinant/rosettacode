// https://rosettacode.org/wiki/Find_words_which_contains_more_than_3_e_vowels
// {{works with|Zig|0.15.1}}
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (contains3E(word))
            print("{s}\n", .{word});
}

fn contains3E(word: []const u8) bool {
    if (word.len < 3)
        return false;

    var count: u16 = 0;

    for (word) |c| {
        switch (c) {
            'a', 'i', 'o', 'u', 'A', 'I', 'O', 'U' => return false,
            'e', 'E' => count += 1,
            else => continue,
        }
    }
    return count > 3;
}
