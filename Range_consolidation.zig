// https://rosettacode.org/wiki/Range_consolidation
const std = @import("std");
const mem = std.mem;
const sort = std.sort;
const testing = std.testing;
const print = std.debug.print;

pub fn main() void {
    var test1 = [_]Range{.{ .lo = 1.1, .hi = 2.2 }};
    var test2 = [_]Range{ .{ .lo = 6.1, .hi = 7.2 }, .{ .lo = 7.2, .hi = 8.3 } };
    var test3 = [_]Range{ .{ .lo = 4, .hi = 3 }, .{ .lo = 2, .hi = 1 } };
    var test4 = [_]Range{ .{ .lo = 4, .hi = 3 }, .{ .lo = 2, .hi = 1 }, .{ .lo = -1, .hi = -2 }, .{ .lo = 3.9, .hi = 10 } };
    var test5 = [_]Range{ .{ .lo = 1, .hi = 3 }, .{ .lo = -6, .hi = -1 }, .{ .lo = -4, .hi = -5 }, .{ .lo = 8, .hi = 2 }, .{ .lo = -6, .hi = -6 } };
    testConsolidateRanges(&test1);
    testConsolidateRanges(&test2);
    testConsolidateRanges(&test3);
    testConsolidateRanges(&test4);
    testConsolidateRanges(&test5);
}

const Range = struct {
    const Self = @This();
    lo: f64,
    hi: f64,

    fn normalize(self: *Self) void {
        if (self.hi < self.lo)
            mem.swap(f64, &self.lo, &self.hi);
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt; // autofix
        _ = options; // autofix
        try writer.print("[{d}, {d}]", .{ self.lo, self.hi });
    }
};

fn ascRanges(_: void, r1: Range, r2: Range) bool {
    if (r1.lo < r2.lo) return true;
    if (r1.lo > r2.lo) return false;
    if (r1.hi < r2.hi) return true;
    if (r1.hi > r2.hi) return false;
    return false;
}

fn normalizeRanges(ranges: []Range) void {
    for (ranges) |*r|
        r.normalize();
    sort.insertion(Range, ranges, {}, ascRanges);
}

// Consolidates an array of ranges in-place.
fn consolidateRanges(ranges: []Range) []Range {
    normalizeRanges(ranges);
    var out_index: usize = 0;
    var i: usize = 0;
    while (i < ranges.len) {
        var j = i + 1;
        while (j < ranges.len and ranges[j].lo <= ranges[i].hi) : (j += 1) {
            if (ranges[i].hi < ranges[j].hi)
                ranges[i].hi = ranges[j].hi;
        }
        ranges[out_index] = ranges[i];
        out_index += 1;
        i = j;
    }
    return ranges[0..out_index];
}

fn printRanges(ranges: []Range) void {
    if (ranges.len == 0)
        return;
    print("{}", .{ranges[0]});
    for (ranges[1..]) |r|
        print(", {}", .{r});
}

fn testConsolidateRanges(ranges: []Range) void {
    printRanges(ranges);
    print(" -> ", .{});
    const consolidated = consolidateRanges(ranges);
    printRanges(consolidated);
    print("\n", .{});
}

test "range normalization" {
    var range_test1 = Range{ .lo = 1.1, .hi = 2.2 };
    var range_test2 = Range{ .lo = 2.2, .hi = 1.1 };
    const range_expected1 = range_test1;
    const range_expected2 = range_expected1;

    range_test1.normalize();
    range_test2.normalize();

    try testing.expectEqual(range_expected1, range_test1);
    try testing.expectEqual(range_expected2, range_test2);
}
