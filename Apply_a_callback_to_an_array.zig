// https://rosettacode.org/wiki/Apply_a_callback_to_an_array
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const array = [_]u8{ 1, 2, 3, 4, 42 };
    apply(u8, &array, printArray);
}

fn apply(comptime T: type, array: []const T, callback: fn (T, usize) void) void {
    for (array, 0..) |e, i| {
        callback(e, i);
    }
}

fn printArray(e: u8, i: usize) void {
    print("array[{}] = {}\n", .{ i, e });
}
