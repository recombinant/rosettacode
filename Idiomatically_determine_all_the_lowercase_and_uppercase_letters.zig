// https://rosettacode.org/wiki/Idiomatically_determine_all_the_lowercase_and_uppercase_letters
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
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
