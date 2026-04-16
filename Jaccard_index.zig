// https://rosettacode.org/wiki/Jaccard_index
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

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

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // ----------------------------------------------- Data
    var a: JSet = try .init(gpa, 'a', &[_]JType{});
    var b: JSet = try .init(gpa, 'b', &[_]JType{ 1, 2, 3, 4, 5 });
    var c: JSet = try .init(gpa, 'c', &[_]JType{ 1, 3, 5, 7, 9 });
    var d: JSet = try .init(gpa, 'd', &[_]JType{ 2, 4, 6, 8, 10 });
    var e: JSet = try .init(gpa, 'e', &[_]JType{ 2, 3, 5, 7 });
    var f: JSet = try .init(gpa, 'f', &[_]JType{8});
    defer for ([_]*JSet{ &a, &b, &c, &d, &e, &f }) |set| set.deinit(gpa);
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

    fn init(allocator: Allocator, id: u8, array: []const JType) !JSet {
        var set: std.AutoArrayHashMapUnmanaged(JType, void) = .empty;
        for (array) |n|
            try set.put(allocator, n, {});
        std.debug.assert(set.count() == array.len);
        return JSet{
            .id = id,
            .set = set,
        };
    }
    fn deinit(self: *JSet, allocator: Allocator) void {
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
