// https://rosettacode.org/wiki/Call_a_foreign-language_function
// {{works with|Zig|0.16.0}}
// # zig run Call_a_foreign-language_function.zig -lc
// copied from rosettacode
const std = @import("std");
const Io = std.Io;
const c = @cImport({
    @cInclude("stdlib.h"); // `free`
    @cInclude("string.h"); // `strdup`
});

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var buffer: [64]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_writer.interface;

    const string = "Hello World!";
    const copy = c.strdup(string);
    defer c.free(copy);

    try stdout.print("{s}\n", .{copy});

    try stdout.flush();
}
