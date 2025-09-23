// https://rosettacode.org/wiki/Loops/Do-while
// {{works with|Zig|0.15.1}}

// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
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
