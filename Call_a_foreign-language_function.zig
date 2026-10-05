// https://rosettacode.org/wiki/Call_a_foreign-language_function
// {{works with|Zig|0.17.0}}
// # zig run Call_a_foreign-language_function.zig -lc
// copied from rosettacode
const std = @import("std");
const Io = std.Io;

// // With Zig 0.16.0 and earlier there was an easy way for
// // simple imports of C header files.
// const c = @cImport({
//     @cInclude("stdlib.h"); // `free`
//     @cInclude("string.h"); // `strdup`
//     @cInclude("stdio.h"); // `printf`
// });

// Zig 0.17.0 and later requires manual function prototypes as below,
// and/or a build.zig with addTranslateC machinery.
extern fn strdup(_Src: [*c]const u8) [*c]u8;
extern fn free(_Memory: ?*anyopaque) void;
extern fn printf(noalias _Format: [*c]const u8, ...) c_int;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var buffer: [64]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_writer.interface;

    const string = "Hello World!";
    const copy = strdup(string);
    defer free(copy);

    _ = printf("%s\n%s\n", string, copy);

    try stdout.print("{s}\n{s}\n", .{ string, copy });

    try stdout.flush();
}
