// https://rosettacode.org/wiki/Find_words_which_contain_all_the_vowels
// {{works with|Zig|0.17.0}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (verifyVowels(word))
            print("{s}\n", .{word});
}

const Vowel = enum { a, e, i, o, u };

fn verifyVowels(word: []const u8) bool {
    if (word.len <= 10)
        return false;

    const field_values = @typeInfo(Vowel).@"enum".field_values;
    var vowels: [field_values.len]bool = @splat(false);

    for (word) |c| {
        const idx = @backingInt(switch (c) {
            'a', 'A' => Vowel.a,
            'e', 'E' => Vowel.e,
            'i', 'I' => Vowel.i,
            'o', 'O' => Vowel.o,
            'u', 'U' => Vowel.u,
            else => continue,
        });
        if (vowels[idx])
            return false;
        vowels[idx] = true;
    }

    inline for (field_values) |value|
        if (!vowels[value])
            return false;

    return true;
}
