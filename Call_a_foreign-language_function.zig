// https://rosettacode.org/wiki/Call_a_foreign-language_function
// {{works with|Zig|0.15.1}}
// zig run Call_a_foreign-language_function.zig -lc
// copied from rosettacode
const std = @import("std");
const c = @cImport({
    @cInclude("stdlib.h"); // `free`
    @cInclude("string.h"); // `strdup`
});

pub fn main() !void {
    var buffer: [64]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    const string = "Hello World!";
    const copy = c.strdup(string);
    defer c.free(copy);

    try stdout.print("{s}\n", .{copy});

    try stdout.flush();
}
