// https://rosettacode.org/wiki/Two_sum
// {{works with|Zig|0.15.1}}
const std = @import("std");

fn sumsUpTo(comptime T: type, input: []const T, target_sum: T) ?struct { usize, usize } {
    if (input.len <= 1) return null;

    return result: for (input[0 .. input.len - 1], 0..) |left, left_i| {
        if (left > target_sum) break :result null;

        const offset = left_i + 1;
        for (input[offset..], offset..) |right, right_i| {
            const current_sum = left + right;
            if (current_sum < target_sum) continue;
            if (current_sum == target_sum) break :result .{ left_i, right_i };
            if (current_sum > target_sum) break;
        }
    } else null;
}

pub fn main() error{WriteFailed}!void {
    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const a = [_]u32{ 0, 2, 11, 19, 90 };
    const target_sum: u32 = 21;

    const optional_indexes = sumsUpTo(u32, &a, target_sum);
    if (optional_indexes) |indexes| {
        try stdout.print("Result: [{d}, {d}].\n", .{ indexes[0], indexes[1] });
    } else {
        try stderr.print("Numbers with sum {d} were not found!\n", .{target_sum});
    }
    try stdout.flush();
    try stderr.flush();
}
