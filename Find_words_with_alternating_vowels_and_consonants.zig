// https://rosettacode.org/wiki/Find_words_with_alternating_vowels_and_consonants
// {{works with|Zig|0.15.1}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    var it = std.mem.splitScalar(u8, text, '\n');

    var count: u32 = 0;
    while (it.next()) |word|
        if (isAlternating(word)) {
            if (count % 7 != 0) print(" ", .{});
            count += 1;

            print("{s:14}", .{word});

            if (count % 7 == 0) print("\n", .{});
        };
    if (count % 7 != 0) print("\n", .{});
}

fn isVowel(c: u8) bool {
    return switch (c) {
        'a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U' => true,
        else => false,
    };
}

fn isAlternating(word: []const u8) bool {
    if (word.len <= 9)
        return false;

    for (word[0 .. word.len - 1], word[1..]) |c1, c2|
        if (isVowel(c1) == isVowel(c2))
            return false;

    return true;
}
