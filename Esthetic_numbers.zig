// https://rosettacode.org/wiki/Esthetic_numbers
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
// https://oeis.org/A033075
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var base: u8 = 2;
    while (base <= 16) : (base += 1) {
        try stdout.print("Base {d}: {d}th to {d}th esthetic numbers:\n", .{ base, 4 * base, 6 * base });
        var n: u64 = 1;
        var c: u64 = 0;
        while (c < 6 * base) : (n += 1) {
            if (isEsthetic(n, base)) {
                c += 1;
                if (c >= 4 * base) {
                    try stdout.printInt(n, base, .lower, .{});
                    try stdout.writeByte(' ');
                }
            }
        }
        try stdout.writeByte('\n');
        try stdout.writeByte('\n');
    }

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // the following all use the obvious range limitations for the numbers in question
    try listEsths(allocator, 1000, 1010, 9999, 9898, 16, true, stdout);
    try listEsths(allocator, 1e8, 101_010_101, 13 * 1e7, 123_456_789, 9, true, stdout);
    try listEsths(allocator, 1e11, 101_010_101_010, 13 * 1e10, 123_456_789_898, 7, false, stdout);
    try listEsths(allocator, 1e14, 101_010_101_010_101, 13 * 1e13, 123_456_789_898_989, 5, false, stdout);
    try listEsths(allocator, 1e17, 101_010_101_010_101_010, 13 * 1e16, 123_456_789_898_989_898, 4, false, stdout);

    try stdout.flush();
}

inline fn uabs(a: u64, b: u64) u64 {
    return if (a > b) a - b else b - a;
}

fn isEsthetic(n_: u64, base: u64) bool {
    if (n_ == 0)
        return false;

    var n = n_;
    var i: u64 = n % base;
    n /= base;
    while (n > 0) {
        const j = n % base;
        if (uabs(i, j) != 1)
            return false;
        n /= base;
        i = j;
    }
    return true;
}

fn dfs(allocator: std.mem.Allocator, esths: *std.ArrayList(u64), n: u64, m: u64, i: u64) !void {
    if (i >= n and i <= m)
        try esths.append(allocator, i);

    if (i == 0 or i > m)
        return;

    const d = i % 10;
    const i1_ = i * 10 + d - 1;
    const i2_ = i1_ + 2;
    if (d == 0)
        try dfs(allocator, esths, n, m, i2_)
    else if (d == 9)
        try dfs(allocator, esths, n, m, i1_)
    else {
        try dfs(allocator, esths, n, m, i1_);
        try dfs(allocator, esths, n, m, i2_);
    }
}

fn listEsths(allocator: std.mem.Allocator, n: u64, n2: u64, m: u64, m2: u64, per_line: usize, write_all: bool, w: *std.Io.Writer) !void {
    var esth_list: std.ArrayList(u64) = .empty;
    for (0..10) |i|
        try dfs(allocator, &esth_list, n2, m2, i);

    const esths = try esth_list.toOwnedSlice(allocator);
    defer allocator.free(esths);

    const max_chars = comptime maxDecimalCommatized();
    var buffer1: [max_chars]u8 = undefined;
    var buffer2: [max_chars]u8 = undefined;
    var buffer3: [max_chars]u8 = undefined;

    try w.print(
        "Base 10: {s} esthetic numbers between {s} and {s}:\n",
        .{ try commatize(&buffer1, esths.len), try commatize(&buffer2, n), try commatize(&buffer3, m) },
    );
    if (write_all) {
        for (esths, 1..) |esth, i| {
            try w.print("{d} ", .{esth});
            if (i % per_line == 0)
                try w.writeByte('\n');
        }
    } else {
        for (esths[0..per_line]) |esth|
            try w.print("{d} ", .{esth});

        try w.writeAll("\n............\n");

        for (esths[esths.len - per_line ..]) |esth|
            try w.print("{d} ", .{esth});
    }
    try w.writeByte('\n');
    try w.writeByte('\n');
}

fn commatize(buffer: []u8, n: u64) ![]const u8 {
    // number as string without commas
    var buffer2: [maxDecimalChars(@TypeOf(n))]u8 = undefined;
    const size = std.fmt.printInt(&buffer2, n, 10, .lower, .{});
    const s = buffer2[0..size];
    //
    var w: std.Io.Writer = .fixed(buffer);

    // write number string as string with inserted commas
    const last = s.len - 1;
    for (s, 0..) |c, idx| {
        try w.writeByte(c);
        if (last - idx != 0 and (last - idx) % 3 == 0)
            try w.writeByte(',');
    }
    return w.buffered();
}

fn maxDecimalCommatized() usize {
    const T = u64; // @TypeOf(n) in commatize() above
    return maxDecimalChars(T) + maxDecimalCommas(T);
}

/// Return the maximum number of characters in a string representing a decimal of type T.
fn maxDecimalChars(comptime T: type) usize {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("type must be an unsigned integer.");
    const max_int: comptime_float = @floatFromInt(std.math.maxInt(T));
    return @intFromFloat(@log10(max_int) + 1);
}

/// Return the maximum number of commas in a 'commatized' string representing a decimal of type T.
fn maxDecimalCommas(comptime T: type) usize {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("type must be an unsigned integer.");
    return (maxDecimalChars(T) - 1) / 3;
}

const testing = std.testing;

test uabs {
    try testing.expectEqual(0, uabs(0, 0));
    try testing.expectEqual(1, uabs(3, 4));
    try testing.expectEqual(1, uabs(4, 3));
    try testing.expectEqual(99, uabs(1, 100));
    try testing.expectEqual(99, uabs(100, 1));
}

test isEsthetic {
    try testing.expect(isEsthetic(1, 10));
    try testing.expect(isEsthetic(10, 10));
    try testing.expect(isEsthetic(121, 10));
    try testing.expect(isEsthetic(323, 10));
    //
    try testing.expect(!isEsthetic(11, 10));
    try testing.expect(!isEsthetic(20, 10));
    try testing.expect(!isEsthetic(124, 10));
    try testing.expect(!isEsthetic(324, 10));
}

test commatize {
    var buffer: [maxDecimalCommatized()]u8 = undefined;

    try testing.expectEqualSlices(
        u8,
        "18,446,744,073,709,551,615",
        try commatize(&buffer, std.math.maxInt(u64)),
    );
}

test maxDecimalChars {
    try testing.expectEqual(1, maxDecimalChars(u1));
    try testing.expectEqual(3, maxDecimalChars(u8));
    try testing.expectEqual(5, maxDecimalChars(u16));
    try testing.expectEqual(39, maxDecimalChars(u128));
}

test maxDecimalCommas {
    try testing.expectEqual(0, maxDecimalCommas(u8));
    try testing.expectEqual(1, maxDecimalCommas(u16));
    try testing.expectEqual(12, maxDecimalCommas(u128));
}
