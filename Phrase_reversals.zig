// https://www.rosettacode.org/wiki/Phrase_reversals
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const sentence = "rosetta code phrase reversal";

    var reversed1: [sentence.len]u8 = sentence.*;
    mem.reverse(u8, &reversed1);

    var reversed2: [sentence.len]u8 = sentence.*;
    reverseWordLetters(&reversed2);

    var reversed3: [sentence.len]u8 = sentence.*;
    mem.reverse(u8, &reversed3);
    reverseWordLetters(&reversed3);

    try stdout.print("{s}\n", .{sentence});
    try stdout.print("{s}\n", .{reversed1});
    try stdout.print("{s}\n", .{reversed2});
    try stdout.print("{s}\n", .{reversed3});
}

/// Given a sentence
/// - find the words
/// - reverse the letters in each of those words
fn reverseWordLetters(sentence: []u8) void {
    var start_index: usize = 0;
    while (mem.indexOfScalarPos(u8, sentence, start_index, ' ')) |end_index| {
        mem.reverse(u8, sentence[start_index..end_index]);
        start_index = end_index + 1;
    }
    mem.reverse(u8, sentence[start_index..]); // final word
}
