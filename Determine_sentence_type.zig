// https://rosettacode.org/wiki/Determine_sentence_type
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() void {
    const paragraph = "hi there, how are you today? I'd like to present to you the washing machine 9001. You have been nominated to win one of these! Just make sure you don't break it";
    const fmt = "{s:<52} ==> {c}\n";
    var pos0: usize = 0;
    while (std.mem.indexOfAnyPos(u8, paragraph, pos0, "?!.")) |pos1| {
        const ch: u8 = switch (paragraph[pos1]) {
            '?' => 'Q',
            '!' => 'E',
            '.' => 'S',
            else => unreachable,
        };
        const sentence = std.mem.trimStart(u8, paragraph[pos0 .. pos1 + 1], " ");
        std.debug.print(fmt, .{ sentence, ch });
        pos0 = pos1 + 1;
    }
    if (pos0 != paragraph.len) {
        const ch: u8 = 'N';
        const sentence = std.mem.trimStart(u8, paragraph[pos0..paragraph.len], " ");
        std.debug.print(fmt, .{ sentence, ch });
    }
}
