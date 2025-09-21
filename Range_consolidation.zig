// https://rosettacode.org/wiki/Range_consolidation
// {{works with|Zig|0.15.1}}
const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var test1 = [_]Range{.{ .lo = 1.1, .hi = 2.2 }};
    var test2 = [_]Range{ .{ .lo = 6.1, .hi = 7.2 }, .{ .lo = 7.2, .hi = 8.3 } };
    var test3 = [_]Range{ .{ .lo = 4, .hi = 3 }, .{ .lo = 2, .hi = 1 } };
    var test4 = [_]Range{ .{ .lo = 4, .hi = 3 }, .{ .lo = 2, .hi = 1 }, .{ .lo = -1, .hi = -2 }, .{ .lo = 3.9, .hi = 10 } };
    var test5 = [_]Range{ .{ .lo = 1, .hi = 3 }, .{ .lo = -6, .hi = -1 }, .{ .lo = -4, .hi = -5 }, .{ .lo = 8, .hi = 2 }, .{ .lo = -6, .hi = -6 } };
    try testConsolidateRanges(&test1, stdout);
    try testConsolidateRanges(&test2, stdout);
    try testConsolidateRanges(&test3, stdout);
    try testConsolidateRanges(&test4, stdout);
    try testConsolidateRanges(&test5, stdout);
}

const Range = struct {
    const Self = @This();
    lo: f64,
    hi: f64,

    fn normalize(self: *Self) void {
        if (self.hi < self.lo)
            std.mem.swap(f64, &self.lo, &self.hi);
    }

    pub fn format(
        self: Self,
        w: *std.Io.Writer,
    ) !void {
        try w.print("[{d}, {d}]", .{ self.lo, self.hi });
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
    std.mem.sortUnstable(Range, ranges, {}, ascRanges);
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

fn printRanges(ranges: []Range, w: *std.Io.Writer) !void {
    if (ranges.len == 0)
        return;
    try w.print("{f}", .{ranges[0]});
    for (ranges[1..]) |r|
        try w.print(", {f}", .{r});
}

fn testConsolidateRanges(ranges: []Range, w: *std.Io.Writer) !void {
    try printRanges(ranges, w);
    try w.writeAll(" -> ");
    const consolidated = consolidateRanges(ranges);
    try printRanges(consolidated, w);
    try w.writeByte('\n');
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
