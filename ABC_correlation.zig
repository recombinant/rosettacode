// https://rosettacode.org/wiki/ABC_correlation

// Assuming only lower case ASCII letters ('a' to 'z' inclusive)
// other ASCII characters encountered will be ignored.
// Must contain at least one of each 'a', 'b' & 'c'
fn isAbcWord(word: []const u8) bool {
    var a: usize = 0;
    var b: usize = 0;
    var c: usize = 0;
    for (word) |char|
        switch (char) {
            'a' => a += 1,
            'b' => b += 1,
            'c' => c += 1,
            else => {},
        };
    return a != 0 and a == b and a == c;
}

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    const words = "aluminium abc internet adb cda blank black mercury venus earth mars jupiter saturn uranus neptune pluto";
    var it1 = std.mem.tokenizeScalar(u8, words, ' ');
    while (it1.next()) |word|
        if (isAbcWord(word))
            try writer.print("{s} is an \"abc\" word\n", .{word});

    const data = @embedFile("data/unixdict.txt");
    var count: usize = 0;
    var it2 = std.mem.tokenizeScalar(u8, data, '\n');
    while (it2.next()) |word|
        if (isAbcWord(word)) {
            count += 1;
        };
    try writer.print("\nThere are {} abc words in unixdict.txt\n", .{count});
}

test isAbcWord {
    try testing.expect(!isAbcWord("")); // no 'a', 'b' or 'c'
    try testing.expect(!isAbcWord("a")); // no 'b' or 'c'
    try testing.expect(!isAbcWord("aa"));
    try testing.expect(!isAbcWord("aaa"));
    try testing.expect(!isAbcWord("def"));
    try testing.expect(isAbcWord("abc"));
    try testing.expect(isAbcWord("zabcz"));
    try testing.expect(isAbcWord("DaEbFcGcHbIaJ"));
    try testing.expect(isAbcWord("AbacC"));
}

const std = @import("std");
const testing = std.testing;
