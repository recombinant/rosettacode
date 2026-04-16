// https://rosettacode.org/wiki/A%2BB
// {{works with|Zig|0.16.0}}
// Copied from rosettacode
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdin_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    var stdin_reader = Io.File.stdin().reader(io, &stdin_buffer);
    const stdout = &stdout_writer.interface;
    const stdin = &stdin_reader.interface;
    // for the stdin input text
    var buffer1: [1024]u8 = undefined;
    var w: Io.Writer = .fixed(&buffer1);
    // for the tokenized input
    var buffer2: [2][]const u8 = undefined;
    var values: std.ArrayList([]const u8) = .initBuffer(&buffer2);
    // ----------------------------------------------------
    try stdout.writeAll("Enter two numbers: ");
    try stdout.flush();

    _ = try stdin.streamDelimiter(&w, '\n');
    const text = std.mem.trimEnd(u8, w.buffered(), "\r");

    var it = std.mem.tokenizeScalar(u8, text, ' ');
    while (it.next()) |value|
        try values.appendBounded(value);

    const a = try std.fmt.parseInt(u64, values.items[0], 10);
    const b = try std.fmt.parseInt(u64, values.items[1], 10);

    try stdout.print("Sum = {d}\n", .{a + b});
    // ----------------------------------------------------
    try stdout.flush();
}
