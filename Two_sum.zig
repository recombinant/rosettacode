// https://rosettacode.org/wiki/Two_sum
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

const std = @import("std");

pub fn main() std.fs.File.WriteError!void {
    const stdout = std.io.getStdOut();
    const stdout_w = stdout.writer();

    const stderr = std.io.getStdErr();
    const stderr_w = stderr.writer();

    const a = [_]u32{ 0, 2, 11, 19, 90 };
    const target_sum: u32 = 21;

    const optional_indexes = sumsUpTo(u32, &a, target_sum);
    if (optional_indexes) |indexes| {
        try stdout_w.print("Result: [{d}, {d}].\n", .{ indexes[0], indexes[1] });
    } else {
        try stderr_w.print("Numbers with sum {d} were not found!\n", .{target_sum});
    }
}
