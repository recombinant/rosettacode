// https://rosettacode.org/wiki/Count_occurrences_of_a_substring
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() void {
    print("{d}\n", .{mem.count(u8, "the three truths", "th")});
    print("{d}\n", .{mem.count(u8, "abababababa", "abab")});
    print("{d}\n", .{mem.count(u8, "abaabba*bbaba*bbab", "a*b")});
}
