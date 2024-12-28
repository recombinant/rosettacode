// https://rosettacode.org/wiki/Find_words_whose_first_and_last_three_letters_are_equal
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (validateThreeLetters(word))
            print("{s}\n", .{word});
}

fn validateThreeLetters(word: []const u8) bool {
    return word.len > 5 and mem.eql(u8, word[0..3], word[word.len - 3 .. word.len]);
}
