// https://rosettacode.org/wiki/Sparkline_in_unicode
// {{works with|Zig|0.15.1}}
const std = @import("std");

fn writeSparkline(numbers: []const f64, max: f64, min: f64, w: *std.Io.Writer) !void {
    const bars = [_][]const u8{ "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" };
    const range = max - min;
    if (range == 0)
        _ = try w.splatBytes(bars[bars.len / 2 - 1], numbers.len)
    else {
        for (numbers) |n|
            try w.writeAll(bars[@min(bars.len - 1, @as(usize, @intFromFloat((n - min) / range * bars.len)))]);
    }
}

pub fn main() !void {
    const input1 = "1 2 3 4 5 6 7 8 7 6 5 4 3 2 1";
    const input2 = "1.5, 0.5 3.5, 2.5 5.5, 4.5 7.5, 6.5";
    const input3 = "0, 1, 19, 20";
    const input4 = "0, 999, 4000, 4999, 7000, 7999";

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([_][]const u8{ input1, input2, input3, input4 }) |input| {
        std.debug.assert(input.len != 0); // more code required?

        var numbers_list: std.ArrayList(f64) = .empty;
        defer numbers_list.deinit(allocator);
        // parse, min, max and append to number list
        var min: f64 = std.math.floatMax(f64);
        var max: f64 = -min;
        var it = std.mem.tokenizeAny(u8, input, " ,");
        while (it.next()) |number_string| {
            const number = try std.fmt.parseFloat(f64, number_string);
            max = @max(max, number);
            min = @min(min, number);
            try numbers_list.append(allocator, number);
        }
        // write numbers and statistics
        try stdout.writeAll("Numbers:");
        for (numbers_list.items) |number|
            try stdout.print(" {d}", .{number});
        try stdout.print("\n min: {d}\n max: {d}\n", .{ min, max });
        //
        try writeSparkline(numbers_list.items, max, min, stdout);
        //
        _ = try stdout.splatByte('\n', 2);
    }

    try stdout.flush();
}

const testing = std.testing;
test writeSparkline {
    var buffer: [64]u8 = undefined;
    var w: std.Io.Writer = .fixed(&buffer);

    // array of repeated number
    const numbers1 = [_]f64{ 42, 42, 42, 42, 42, 42, 42 };
    try writeSparkline(&numbers1, 42, 42, &w);
    try std.testing.expectEqualSlices(u8, "▄▄▄▄▄▄▄", w.buffered());

    // array of length one
    _ = w.consumeAll();
    const numbers2 = [_]f64{42};
    try writeSparkline(&numbers2, 42, 42, &w);
    try std.testing.expectEqualSlices(u8, "▄", w.buffered());
}
