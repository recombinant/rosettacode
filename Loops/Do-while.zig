// https://rosettacode.org/wiki/Loops/Do-while
// {{works with|Zig|0.16.0}}

// Copied from rosettacode
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var a: u8 = 0;
    // no do-while in syntax, trust the optimizer to do
    // correct Loop inversion https://en.wikipedia.org/wiki/Loop_inversion
    // If the variable `alive` is independent to other variables and not in
    // diverging control flow, then the optimization is possible in general.
    var alive = true;
    while (alive == true or a % 6 != 0) {
        alive = false;
        a += 1;
        try stdout.print("{d}\n", .{a});
    }

    try stdout.flush();
}
