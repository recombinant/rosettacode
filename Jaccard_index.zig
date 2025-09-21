// https://rosettacode.org/wiki/Jaccard_index
// {{works with|Zig|0.15.1}}
const std = @import("std");

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
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------------ Allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------- Data
    var a: JSet = try .init(allocator, 'a', &[_]JType{});
    var b: JSet = try .init(allocator, 'b', &[_]JType{ 1, 2, 3, 4, 5 });
    var c: JSet = try .init(allocator, 'c', &[_]JType{ 1, 3, 5, 7, 9 });
    var d: JSet = try .init(allocator, 'd', &[_]JType{ 2, 4, 6, 8, 10 });
    var e: JSet = try .init(allocator, 'e', &[_]JType{ 2, 3, 5, 7 });
    var f: JSet = try .init(allocator, 'f', &[_]JType{8});
    defer for ([_]*JSet{ &a, &b, &c, &d, &e, &f }) |set| set.deinit(allocator);
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
    try stdout.flush();
}

/// Façade over AutoArrayHashMap to provide a set.
const JSet = struct {
    id: u8,
    set: std.AutoArrayHashMapUnmanaged(JType, void),

    fn init(allocator: std.mem.Allocator, id: u8, array: []const JType) !JSet {
        var set: std.AutoArrayHashMapUnmanaged(JType, void) = .empty;
        for (array) |n|
            try set.put(allocator, n, {});
        std.debug.assert(set.count() == array.len);
        return JSet{
            .id = id,
            .set = set,
        };
    }
    fn deinit(self: *JSet, allocator: std.mem.Allocator) void {
        self.set.deinit(allocator);
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
