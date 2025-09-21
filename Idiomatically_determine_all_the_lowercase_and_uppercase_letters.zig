// https://rosettacode.org/wiki/Idiomatically_determine_all_the_lowercase_and_ccase_letters
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

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

    try stdout.flush();
}
