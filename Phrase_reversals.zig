// https://www.rosettacode.org/wiki/Phrase_reversals
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const sentence = "rosetta code phrase reversal";

    var reversed1: [sentence.len]u8 = sentence.*;
    std.mem.reverse(u8, &reversed1);

    var reversed2: [sentence.len]u8 = sentence.*;
    reverseWordLetters(&reversed2);

    var reversed3: [sentence.len]u8 = sentence.*;
    std.mem.reverse(u8, &reversed3);
    reverseWordLetters(&reversed3);

    try stdout.print("{s}\n", .{sentence});
    try stdout.print("{s}\n", .{reversed1});
    try stdout.print("{s}\n", .{reversed2});
    try stdout.print("{s}\n", .{reversed3});

    try stdout.flush();
}

/// Given a sentence
/// - find the words
/// - reverse the letters in each of those words
fn reverseWordLetters(sentence: []u8) void {
    var start_index: usize = 0;
    while (std.mem.indexOfScalarPos(u8, sentence, start_index, ' ')) |end_index| {
        std.mem.reverse(u8, sentence[start_index..end_index]);
        start_index = end_index + 1;
    }
    std.mem.reverse(u8, sentence[start_index..]); // final word
}
