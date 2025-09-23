// https://rosettacode.org/wiki/Count_how_many_vowels_and_consonants_occur_in_a_string
// {{works with|Zig|0.15.1}}
const std = @import("std");
const testing = std.testing;
const print = std.debug.print;

pub fn main() void {
    const phrase = "Now is the time for all good men to come to the aid of their country.";

    const vowel_count, const consonant_count = countLetters(phrase);
    print(
        "Vowel count = {}, consonant count= {}\n",
        .{ vowel_count, consonant_count },
    );
}

fn countLetters(letters: []const u8) struct { usize, usize } {
    var vowel_count: usize = 0;
    var consonant_count: usize = 0;
    for (letters) |c| {
        switch (getLetterType(c)) {
            .vowel => vowel_count += 1,
            .consonant => consonant_count += 1,
            .other => {},
        }
    }
    return .{ vowel_count, consonant_count };
}

test countLetters {
    const v0, const c0 = countLetters("");
    try testing.expectEqual(0, v0);
    try testing.expectEqual(0, c0);
    const v1, const c1 = countLetters("AAAA");
    try testing.expectEqual(4, v1);
    try testing.expectEqual(0, c1);
    const v2, const c2 = countLetters("XX");
    try testing.expectEqual(0, v2);
    try testing.expectEqual(2, c2);
}

const LetterType = enum {
    vowel,
    consonant,
    other,
};

fn getLetterType(c: u8) LetterType {
    if (!std.ascii.isAlphabetic(c)) return .other;
    return switch (c) {
        'a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U' => .vowel,
        else => .consonant,
    };
}

test getLetterType {
    try testing.expectEqual(LetterType.vowel, getLetterType('e'));
    try testing.expectEqual(LetterType.vowel, getLetterType('A'));
    try testing.expectEqual(LetterType.other, getLetterType(' '));
    try testing.expectEqual(LetterType.consonant, getLetterType('Z'));
}
