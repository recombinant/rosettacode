// https://rosettacode.org/wiki/A%2BB
// {{works with|Zig|0.15.1}}
// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdin_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdout = &stdout_writer.interface;
    const stdin = &stdin_reader.interface;
    // for the stdin input text
    var buffer1: [1024]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buffer1);
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
