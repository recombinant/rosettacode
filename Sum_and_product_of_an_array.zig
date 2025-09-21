// https://rosettacode.org/wiki/Sum_and_product_of_an_array
// {{works with|Zig|0.15.1}}

// Copied from rosettacode
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
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
