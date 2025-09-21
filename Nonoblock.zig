// https://rosettacode.org/wiki/Nonoblock
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try writeBlock(allocator, "21", 5, stdout);
    try writeBlock(allocator, "", 5, stdout);
    try writeBlock(allocator, "8", 10, stdout);
    try writeBlock(allocator, "2323", 15, stdout);
    try writeBlock(allocator, "23", 5, stdout);

    try stdout.flush();
}

fn writeBlock(allocator: std.mem.Allocator, data: []const u8, len: usize, w: *std.Io.Writer) !void {
    const a = try allocator.dupe(u8, data);
    defer allocator.free(a);

    var alloc_writer: std.Io.Writer.Allocating = .init(allocator);
    var start: bool = false;
    for (a) |c| {
        if (start)
            try alloc_writer.writer.writeByte(' ')
        else
            start = true;
        try alloc_writer.writer.writeByte(c);
    }
    try w.print("\nblocks [{s}], cells {d}\n", .{ alloc_writer.written(), len });
    alloc_writer.deinit();

    var sum_bytes: usize = 0;
    for (a) |ch|
        sum_bytes += ch - '0';

    if (len - sum_bytes <= 0) {
        try w.writeAll("No solution\n");
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
            try w.writeByte(ch);
        }
        try w.writeByte('\n');
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
    var result: std.ArrayList([]u8) = .empty;
    for (1..num_zeros + 2 - ones.len) |x| {
        const skip_one = ones[1..];
        const seq = try genSequence(allocator, skip_one, num_zeros - x);
        defer {
            for (seq) |s| allocator.free(s);
            allocator.free(seq);
        }
        for (seq) |tail| {
            var s: std.ArrayList(u8) = .empty;
            try s.appendNTimes(allocator, '0', x);
            try s.appendSlice(allocator, ones[0]);
            try s.appendSlice(allocator, tail);
            try result.append(allocator, try s.toOwnedSlice(allocator));
        }
    }
    return result.toOwnedSlice(allocator);
}
