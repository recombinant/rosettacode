// https://www.rosettacode.org/wiki/Determine_if_a_string_is_numeric
const std = @import("std");
const testing = std.testing;

fn isNumeric(s: []const u8) bool {
    _ = std.fmt.parseFloat(f64, s) catch return false;
    return true;
}

test "test numeric" {
    try testing.expect(isNumeric("0"));
    try testing.expect(isNumeric("-0"));
    try testing.expect(isNumeric("+0"));
    try testing.expect(isNumeric("1"));
    try testing.expect(isNumeric("-1"));
    try testing.expect(isNumeric("1e5"));
    try testing.expect(isNumeric("2e05"));
    try testing.expect(isNumeric("3e-5"));
    try testing.expect(isNumeric("4e-05"));
    try testing.expect(isNumeric("NaN"));
    try testing.expect(isNumeric("-NaN"));
    try testing.expect(isNumeric("nan"));
    try testing.expect(isNumeric("inf"));
    try testing.expect(isNumeric("Inf"));
    try testing.expect(isNumeric("-Inf"));
    try testing.expect(isNumeric("INF"));
    try testing.expect(isNumeric("infinity"));
    try testing.expect(isNumeric("Infinity"));
    //
    try testing.expect(!isNumeric("- 1.5"));
    try testing.expect(!isNumeric(""));
    try testing.expect(!isNumeric(" "));
    try testing.expect(!isNumeric("rose"));
}
