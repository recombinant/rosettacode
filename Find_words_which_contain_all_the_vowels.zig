// https://rosettacode.org/wiki/Find_words_which_contain_all_the_vowels
const std = @import("std");
const mem = std.mem;
const meta = std.meta;
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (verifyVowels(word))
            print("{s}\n", .{word});
}

const Vowel = enum { a, e, i, o, u };

fn verifyVowels(word: []const u8) bool {
    if (word.len <= 10)
        return false;

    var vowels = comptime mem.zeroes([meta.fields(Vowel).len]bool);

    for (word) |c| {
        const idx: usize = @intFromEnum(switch (c) {
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

    inline for (meta.fields(Vowel)) |f|
        if (!vowels[f.value])
            return false;

    return true;
}
