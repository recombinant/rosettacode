// https://rosettacode.org/wiki/Find_words_whose_first_and_last_three_letters_are_equal
// {{works with|Zig|0.15.1}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (validateThreeLetters(word))
            print("{s}\n", .{word});
}

fn validateThreeLetters(word: []const u8) bool {
    return word.len > 5 and std.mem.eql(u8, word[0..3], word[word.len - 3 .. word.len]);
}
