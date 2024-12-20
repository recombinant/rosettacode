// https://rosettacode.org/wiki/Letter_frequency
const std = @import("std");
const ascii = std.ascii;
const mem = std.mem;
const print = std.debug.print;

pub fn main() void {
    const text = @embedFile("data/unixdict.txt");

    const f = frequency(text);

    for (f, 'a'..) |freq, letter|
        print("'{c}': {d}\n", .{ @as(u8, @truncate(letter)), freq });
}

fn frequency(text: []const u8) [26]usize {
    var result = mem.zeroes([26]usize);
    for (text) |c| {
        switch (c) {
            'a'...'z' => result[c - 'a'] += 1,
            'A'...'Z' => result[c - 'A'] += 1,
            else => {},
        }
    }
    return result;
}
