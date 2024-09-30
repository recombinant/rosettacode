// https://rosettacode.org/wiki/Jaccard_index
const std = @import("std");
const heap = std.heap;
const io = std.io;
const mem = std.mem;

const assert = std.debug.assert;

const JaccardIndex = struct { i: usize, u: usize };
const JType = u16;

/// J(A, B) = |A ∩ B|/|A ∪ B|
fn jaccardIndex(a: *const JSet, b: *const JSet) !JaccardIndex {
    if (a.count() == 0 and b.count() == 0) return .{ .i = 1, .u = 1 };

    var intersect_count: usize = 0;
    var union_count = b.count();
    for (a.values()) |ai| {
        if (b.contains(ai)) intersect_count += 1 else union_count += 1;
    }
    // Rationalize rational number.
    if (intersect_count == 0) union_count = 1;
    if (intersect_count == union_count) {
        intersect_count = 1;
        union_count = 1;
    }
    if (intersect_count != 0 and union_count % intersect_count == 0) {
        union_count /= intersect_count;
        intersect_count = 1;
    }
    // Return the Jaccard Index as a rational number.
    return .{ .i = intersect_count, .u = union_count };
}

pub fn main() !void {
    const stdout = io.getStdOut().writer();
    // ------------------------------------------ Allocator
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------- Data
    var a = try JSet.init(allocator, 'a', &[_]JType{});
    var b = try JSet.init(allocator, 'b', &[_]JType{ 1, 2, 3, 4, 5 });
    var c = try JSet.init(allocator, 'c', &[_]JType{ 1, 3, 5, 7, 9 });
    var d = try JSet.init(allocator, 'd', &[_]JType{ 2, 4, 6, 8, 10 });
    var e = try JSet.init(allocator, 'e', &[_]JType{ 2, 3, 5, 7 });
    var f = try JSet.init(allocator, 'f', &[_]JType{8});
    defer for ([_]*JSet{ &a, &b, &c, &d, &e, &f }) |set| set.deinit();
    // -------------------------------- Print original data
    const isets = [_]JSet{ a, b, c, d, e, f };
    for (isets) |se|
        try stdout.print("{c} = {any}\n", .{ se.id, se.values() });
    try stdout.writeByte('\n');
    // ----------------------------- Print table of results
    // header
    try stdout.writeAll(" ");
    for (isets) |se| try stdout.print("    {c}", .{se.id});
    try stdout.writeByte('\n');
    // Jaccard index table
    for (isets) |se1| {
        try stdout.print("{c}:", .{se1.id});
        for (isets) |se2| {
            const j: JaccardIndex = try jaccardIndex(&se1, &se2);
            try stdout.print("  {d}/{d}", .{ j.i, j.u });
        }
        try stdout.writeByte('\n');
    }
}

/// Façade over AutoArrayHashMap to provide a set.
const JSet = struct {
    id: u8,
    set: std.AutoArrayHashMap(JType, void),

    fn init(allocator: mem.Allocator, id: u8, array: []const JType) !JSet {
        var set = std.AutoArrayHashMap(JType, void).init(allocator);
        for (array) |n|
            try set.put(n, {});
        assert(set.count() == array.len);
        return JSet{
            .id = id,
            .set = set,
        };
    }
    fn deinit(self: *JSet) void {
        self.set.deinit();
    }
    fn values(self: *const JSet) []const JType {
        return self.set.keys();
    }
    fn count(self: *const JSet) usize {
        return self.set.count();
    }
    fn contains(self: *const JSet, item: JType) bool {
        return self.set.contains(item);
    }
};
