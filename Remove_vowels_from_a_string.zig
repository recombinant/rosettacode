// https://rosettacode.org/wiki/Remove_vowels_from_a_string
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() void {
    const string = "Zig Programming Language";
    var buffer: [string.len]u8 = undefined;

    print("{s}\n", .{removeVowelsFromString(&buffer, string)});
}

pub fn removeVowelsFromString(output: []u8, ascii_string: []const u8) []u8 {
    assert(output.len >= ascii_string.len);

    var i: usize = 0;
    for (ascii_string) |c| {
        switch (c) {
            'A', 'E', 'I', 'O', 'U', 'a', 'e', 'i', 'o', 'u' => continue,
            else => {
                output[i] = c;
                i += 1;
            },
        }
    }
    return output[0..i];
}
