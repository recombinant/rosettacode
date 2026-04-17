// https://rosettacode.org/wiki/Sum_and_product_of_an_array
// {{works with|Zig|0.16.0}}

// Copied from rosettacode
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const numbers = [_]u8{ 1, 2, 3, 4, 5 };
    var sum: u8 = 0;
    var product: u8 = 1;
    for (numbers) |number| {
        product *= number;
        sum += number;
    }
    try stdout.print("{} {}\n", .{ product, sum });

    try stdout.flush();
}
