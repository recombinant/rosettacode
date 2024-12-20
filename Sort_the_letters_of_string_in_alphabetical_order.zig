// https://rosettacode.org/wiki/Sort_the_letters_of_string_in_alphabetical_order
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var s1 = "The quick brown fox jumps over the lazy dog, apparently".*;
    const result1 = sort(&s1);
    try writer.print("«««{s}»»»\n\n", .{result1});

    var s2 = "Now is the time for all good men to come to the aid of their country.".*;
    const result2 = sort(&s2);
    try writer.print("«««{s}»»»\n", .{result2});
}

/// Primitive in-place bubble sort of a slice of u8.
/// Returns sorted slice without whitespace or control
/// characters.
fn sort(s: []u8) []u8 {
    var swapped = true;
    while (swapped) {
        swapped = false;
        for (s[0 .. s.len - 1], s[1..]) |*a, *b|
            if (a.* > b.*) {
                std.mem.swap(u8, a, b);
                swapped = true;
            };
    }
    var idx0: usize = 0;
    while (idx0 < s.len and s[idx0] <= 0x20)
        idx0 += 1;

    var idx1 = idx0;
    while (idx1 < s.len and s[idx1] < 0x7f)
        idx1 += 1;

    return s[idx0..idx1];
}
