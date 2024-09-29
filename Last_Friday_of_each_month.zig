// https://rosettacode.org/wiki/Last_Friday_of_each_month
// Translation of Fortran

// see also:
// https://rosettacode.org/wiki/Find_the_last_Sunday_of_each_month
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

const YearError = error{
    OutOfRange,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // try getLastFridays(allocator, 1582);
    // try getLastFridays(allocator, 1701);
    // try getLastFridays(allocator, 2023);
    // try getLastFridays(allocator, 2024);
    const fridays = try getLastFridays(allocator, 2012);
    for (fridays) |friday| {
        print("{s}\n", .{friday});
        allocator.free(friday);
    }
}

/// Caller owns contents of returned array.
fn getLastFridays(allocator: mem.Allocator, year: u16) ![12][]const u8 {
    if (year < 1582) return YearError.OutOfRange; // Start of Gregorian Calender

    const febuary_days: u16 = 28 + @as(u16, @intFromBool(isLeapYear(year)));
    const days_in_month = [12]u16{ 31, febuary_days, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

    const y = year - 1;
    var k = 44 + y + y / 4 + 6 * (y / 100) + y / 400;

    var result: [12][]const u8 = undefined;

    for (days_in_month, &result, 1..) |m, *text, i| {
        k += m;
        text.* = try std.fmt.allocPrint(allocator, "{}-{d:02}-{d:2}", .{ year, i, m - (k % 7) });
    }
    return result;
}

fn isLeapYear(year: u16) bool {
    return (year % 4 == 0) and ((year % 100 != 0) or (year % 400 == 0));
}

const testing = std.testing;

test "leap year" {
    try testing.expect(!isLeapYear(1900));
    try testing.expect(isLeapYear(2000));
    try testing.expect(isLeapYear(2020));
    try testing.expect(!isLeapYear(2021));
    try testing.expect(!isLeapYear(2022));
    try testing.expect(!isLeapYear(2023));
    try testing.expect(isLeapYear(2024));
}
