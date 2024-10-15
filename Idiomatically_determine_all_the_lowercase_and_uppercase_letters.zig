// https://rosettacode.org/wiki/Idiomatically_determine_all_the_lowercase_and_ccase_letters
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var c: u8 = undefined;

    try stdout.writeAll("Upper case: ");
    c = 'A';
    while (c <= 'Z') : (c += 1)
        try stdout.writeByte(c);
    try stdout.writeByte('\n');

    try stdout.writeAll("Lower case: ");
    c = 'a';
    while (c <= 'z') : (c += 1)
        try stdout.writeByte(c);
    try stdout.writeByte('\n');
}
