// https://rosettacode.org/wiki/Nonoblock
// Translation of Go
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();

    try writeBlock(allocator, "21", 5, writer);
    try writeBlock(allocator, "", 5, writer);
    try writeBlock(allocator, "8", 10, writer);
    try writeBlock(allocator, "2323", 15, writer);
    try writeBlock(allocator, "23", 5, writer);
}

fn writeBlock(allocator: std.mem.Allocator, data: []const u8, len: usize, writer: anytype) !void {
    const a = try allocator.dupe(u8, data);
    defer allocator.free(a);

    var sum_bytes: usize = 0;
    for (a) |ch|
        sum_bytes += ch - '0';
    try writer.print("\nblocks {c}, cells {d}\n", .{ a, len });
    if (len - sum_bytes <= 0) {
        try writer.writeAll("No solution\n");
        return;
    }
    const prep = try allocator.alloc([]u8, a.len);
    for (a, prep) |ch, *p| {
        p.* = try allocator.alloc(u8, ch - '0');
        @memset(p.*, '1');
    }
    defer {
        for (prep) |*p| allocator.free(p.*);
        allocator.free(prep);
    }
    const seq = try genSequence(allocator, prep, len - sum_bytes + 1);
    defer {
        for (seq) |s| allocator.free(s);
        allocator.free(seq);
    }
    for (seq) |r| {
        for (r[1..]) |cell| {
            const ch: u8 = if (cell == '1') '#' else '.';
            try writer.writeByte(ch);
        }
        try writer.writeByte('\n');
    }
}

fn genSequence(allocator: std.mem.Allocator, ones: []const []const u8, num_zeros: usize) ![]const []const u8 {
    if (ones.len == 0) {
        const s = try allocator.alloc(u8, num_zeros);
        @memset(s, '0');
        const result = try allocator.alloc([]u8, 1);
        result[0] = s;
        return result;
    }
    var result = std.ArrayList([]u8).init(allocator);
    for (1..num_zeros + 2 - ones.len) |x| {
        const skip_one = ones[1..];
        const seq = try genSequence(allocator, skip_one, num_zeros - x);
        defer {
            for (seq) |s| allocator.free(s);
            allocator.free(seq);
        }
        for (seq) |tail| {
            var s = std.ArrayList(u8).init(allocator);
            try s.appendNTimes('0', x);
            try s.appendSlice(ones[0]);
            try s.appendSlice(tail);
            try result.append(try s.toOwnedSlice());
        }
    }
    return result.toOwnedSlice();
}
