// https://rosettacode.org/wiki/Range_extraction
// Translation of Go
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();

    const rf = try getRangeFormat(allocator, u8, &[_]u8{
        0,  1,  2,  4,  6,  7,  8,  11, 12, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        25, 27, 28, 29, 30, 31, 32, 33, 35, 36,
        37, 38, 39,
    });
    defer allocator.free(rf);

    try writer.print("range format: {s}\n", .{rf});
}

/// Allocates memory for the result, which must be freed by the caller.
fn getRangeFormat(allocator: std.mem.Allocator, T: type, slice: []const T) ![]const u8 {
    if (@typeInfo(T) != .int)
        @compileError("getRangeFormat() expected integer argument, found " ++ @typeName(T));

    if (slice.len == 0)
        return allocator.alloc(u8, 0);

    // Maximum buffer size depends on T and log10_int needs unsigned argument.
    const U = std.meta.Int(.unsigned, @typeInfo(T).int.bits);
    var buffer: [@as(u16, std.math.log10_int(@as(U, std.math.maxInt(U))) * 2) + 5]u8 = undefined;

    var s = std.io.fixedBufferStream(&buffer);
    const sw = s.writer();

    var parts = std.ArrayList([]const u8).init(allocator);
    defer {
        for (parts.items) |text| allocator.free(text);
        parts.deinit();
    }
    var n1: usize = 0;
    while (true) {
        var n2 = n1 + 1;
        while (n2 < slice.len and slice[n2] == slice[n2 - 1] + 1)
            n2 += 1;
        s.reset();
        try sw.print("{}", .{slice[n1]});
        if (n2 == n1 + 2)
            try sw.print(",{}", .{slice[n2 - 1]})
        else if (n2 > n1 + 2)
            try sw.print("-{}", .{slice[n2 - 1]});
        try parts.append(try allocator.dupe(u8, s.getWritten()));
        if (n2 == slice.len)
            break;
        if (slice[n2] == slice[n2 - 1]) return error.RepeatedValue;
        if (slice[n2] < slice[n2 - 1]) return error.OutOfOrder;
        n1 = n2;
    }
    return std.mem.join(allocator, ",", parts.items);
}

const testing = std.testing;
test getRangeFormat {
    const list1 = [_]u8{
        25, 27, 28, 29, 30, 30, 31, 32, 33, 35,
    };
    try testing.expectError(error.RepeatedValue, getRangeFormat(testing.allocator, u8, &list1));

    const list2 = [_]u8{
        25, 27, 28, 29, 31, 30, 32, 33, 35, 36,
    };
    try testing.expectError(error.OutOfOrder, getRangeFormat(testing.allocator, u8, &list2));

    const list3 = [_]u8{};
    const result3 = try getRangeFormat(testing.allocator, u8, &list3);
    try testing.expectEqual(0, result3.len);
    testing.allocator.free(result3);

    const list4 = [_]u8{42};
    const result4 = try getRangeFormat(testing.allocator, u8, &list4);
    try testing.expectEqualSlices(u8, "42", result4);
    testing.allocator.free(result4);

    const list5 = [_]u8{ 42, 44 };
    const result5 = try getRangeFormat(testing.allocator, u8, &list5);
    try testing.expectEqualSlices(u8, "42,44", result5);
    testing.allocator.free(result5);

    const list6 = [_]u8{ 42, 43, 44 };
    const result6 = try getRangeFormat(testing.allocator, u8, &list6);
    try testing.expectEqualSlices(u8, "42-44", result6);
    testing.allocator.free(result6);

    const list7 = [_]i8{
        -6, -3, -2, -1, 0,  1,  3,  4,  5,  7,
        8,  9,  10, 11, 14, 15, 17, 18, 19, 20,
    };
    const result7 = try getRangeFormat(testing.allocator, i8, &list7);
    try testing.expectEqualSlices(u8, "-6,-3-1,3-5,7-11,14,15,17-20", result7);
    testing.allocator.free(result7);

    const list8 = [_]i32{ std.math.minInt(i32), std.math.minInt(i32) + 1, std.math.minInt(i32) + 2 };
    const result8 = try getRangeFormat(testing.allocator, i32, &list8);
    try testing.expectEqualSlices(u8, "-2147483648--2147483646", result8);
    testing.allocator.free(result8);

    const list9 = [_]i64{ std.math.minInt(i64), std.math.minInt(i64) + 2 };
    const result9 = try getRangeFormat(testing.allocator, i64, &list9);
    try testing.expectEqualSlices(u8, "-9223372036854775808,-9223372036854775806", result9);
    testing.allocator.free(result9);
}
