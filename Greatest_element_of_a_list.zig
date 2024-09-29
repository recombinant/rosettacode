// https://rosettacode.org/wiki/Greatest_element_of_a_list
const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const array0 = [_]i64{};
    try stdout.print("{?d}\n", .{max(i64, &array0)});
    const array1 = [_]u16{1};
    try stdout.print("{?d}\n", .{max(u16, &array1)});
    const array2 = [_]f32{ 0.0, 1.2, 3.1415, -5 };
    try stdout.print("{?d}\n", .{max(f32, &array2)});
}

fn max(comptime T: type, values: []const T) ?T {
    if (values.len == 0) return null;
    var result = values[0];
    for (values[1..]) |value|
        result = @max(result, value);
    return result;
}

test max {
    const array0 = [_]i64{};
    try testing.expectEqual(null, max(i64, &array0));

    const array1 = [_]u16{1};
    try testing.expectEqual(@as(u16, 1), max(u16, &array1).?);

    const array2 = [_]f32{ 0.0, 1.2, 3.1415, -5 };
    try testing.expectEqual(@as(f32, 3.1415), max(f32, &array2).?);
}
