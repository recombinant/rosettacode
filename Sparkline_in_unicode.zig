// https://rosettacode.org/wiki/Sparkline_in_unicode
const std = @import("std");

fn writeSparkline(numbers: []const f64, max: f64, min: f64, writer: anytype) !void {
    const bars = [_][]const u8{ "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" };
    const range = max - min;
    if (range == 0)
        try writer.writeBytesNTimes(bars[bars.len / 2 - 1], numbers.len)
    else {
        for (numbers) |n|
            try writer.writeAll(bars[@min(bars.len - 1, @as(usize, @intFromFloat((n - min) / range * bars.len)))]);
    }
}

pub fn main() !void {
    const input1 = "1 2 3 4 5 6 7 8 7 6 5 4 3 2 1";
    const input2 = "1.5, 0.5 3.5, 2.5 5.5, 4.5 7.5, 6.5";
    const input3 = "0, 1, 19, 20";
    const input4 = "0, 999, 4000, 4999, 7000, 7999";

    const writer = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([_][]const u8{ input1, input2, input3, input4 }) |input| {
        std.debug.assert(input.len != 0); // more code required?

        var numbers_list = std.ArrayList(f64).init(allocator);
        defer numbers_list.deinit();
        // parse, min, max and append to number list
        var min: f64 = std.math.floatMax(f64);
        var max: f64 = -min;
        var it = std.mem.tokenizeAny(u8, input, " ,");
        while (it.next()) |number_string| {
            const number = try std.fmt.parseFloat(f64, number_string);
            max = @max(max, number);
            min = @min(min, number);
            try numbers_list.append(number);
        }
        // write numbers and statistics
        try writer.writeAll("Numbers:");
        for (numbers_list.items) |number|
            try writer.print(" {d}", .{number});
        try writer.print("\n min: {d}\n max: {d}\n", .{ min, max });
        //
        try writeSparkline(numbers_list.items, max, min, writer);
        //
        try writer.writeByteNTimes('\n', 2);
    }
}

const testing = std.testing;
test writeSparkline {
    var buffer: [64]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    const writer = stream.writer();

    // array of repeated number
    const numbers1 = [_]f64{ 42, 42, 42, 42, 42, 42, 42 };
    try writeSparkline(&numbers1, 42, 42, writer);
    try std.testing.expectEqualSlices(u8, "▄▄▄▄▄▄▄", stream.getWritten());

    // array of length one
    stream.reset();
    const numbers2 = [_]f64{42};
    try writeSparkline(&numbers2, 42, 42, writer);
    try std.testing.expectEqualSlices(u8, "▄", stream.getWritten());
}
