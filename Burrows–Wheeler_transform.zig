// https://rosettacode.org/wiki/Burrows%E2%80%93Wheeler_transform
// https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform
// This code follows the wikipedia example and explanation,
// it is not a translation of the wikipedia Python Sample.
const std = @import("std");

pub fn main() !void {
    const stx = std.ascii.control_code.stx;
    const etx = std.ascii.control_code.etx;

    const strings = [_][]const u8{
        "banana",
        "appellee",
        "dogwood",
        "TO BE OR NOT TO BE OR WANT TO BE OR NOT?",
        "SIX.MIXED.PIXIES.SIFT.SIXTY.PIXIE.DUST.BOXES",
        "\x02ABC\x03",
    };
    const writer = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for (strings) |s| {
        try printString(s, stx, etx, writer);
        try writer.writeByte('\n');

        try writer.writeAll(" --> ");
        if (try bwt(allocator, s, stx, etx)) |t| {
            defer allocator.free(t);
            try printString(t, stx, etx, writer);
            try writer.writeAll("\n --> ");

            const r = try ibwt(allocator, t, stx, etx);
            defer allocator.free(r);
            try printString(r, stx, etx, writer);
            try writer.writeByte('\n');
        }
        try writer.writeByte('\n');
    }
}

/// Allocates memory for the result, which must be freed by the caller.
fn bwt(allocator: std.mem.Allocator, s_: []const u8, stx: u8, etx: u8) !?[]const u8 {
    if (std.mem.indexOfAny(u8, s_, &[2]u8{ stx, etx }) != null) {
        std.log.err("string can't contain STX or ETX", .{});
        return null;
    }
    const s = blk: {
        var a = try std.ArrayList(u8).initCapacity(allocator, s_.len + 2);
        try a.append(stx);
        try a.appendSlice(s_);
        try a.append(etx);
        break :blk try a.toOwnedSlice();
    };
    defer allocator.free(s);

    // create a table...
    const table = try allocator.alloc([]const u8, s.len);
    defer allocator.free(table);

    // where rows are all possible rotations of s
    const tmp = try allocator.dupe(u8, s);
    for (table) |*row| {
        row.* = try allocator.dupe(u8, tmp);
        std.mem.rotate(u8, tmp, 1);
    }
    allocator.free(tmp);
    defer for (table) |row|
        allocator.free(row);

    std.mem.sort([]const u8, table, [2]u8{ stx, etx }, lessThan);

    // last column of table
    const last_column = try allocator.alloc(u8, s.len);
    for (last_column, table) |*dest, source|
        dest.* = source[source.len - 1];
    return last_column;
}

fn ibwt(allocator: std.mem.Allocator, r: []const u8, stx: u8, etx: u8) ![]const u8 {
    // create an empty table
    const table = try allocator.alloc([]u8, r.len);
    defer allocator.free(table);
    for (table) |*row| {
        row.* = try allocator.alloc(u8, r.len);
        @memset(row.*, 0);
    }
    defer for (table) |row|
        allocator.free(row);

    for (1..r.len + 1) |i| {
        for (table, r) |*row, c|
            row.*[r.len - i] = c;
        std.mem.sort([]const u8, table, [2]u8{ stx, etx }, lessThan);
    }

    for (table) |row|
        if (row[row.len - 1] == etx) {
            std.debug.assert(std.mem.indexOfScalar(u8, row, stx) == 0);
            std.debug.assert(std.mem.lastIndexOfScalar(u8, row, etx) == row.len - 1);
            return try allocator.dupe(u8, row[1 .. row.len - 1]);
        };
    unreachable;
}

/// Allocates memory for the result, which must be freed by the caller.
fn printString(s: []const u8, comptime stx: u8, comptime etx: u8, writer: anytype) !void {
    for (s) |c| {
        const out = switch (c) {
            stx => if (std.ascii.isPrint(c)) c else '^',
            etx => if (std.ascii.isPrint(c)) c else '$',
            else => if (std.ascii.isPrint(c)) c else '?',
        };
        try writer.writeByte(out);
    }
}

/// Callback function for std.mem.sort of array of strings.
fn lessThan(context: [2]u8, lhs: []const u8, rhs: []const u8) bool {
    const stx, const etx = context;
    for (lhs, rhs) |c1, c2| {
        if (c1 == etx)
            return false;
        if (c2 == etx)
            return true;
        if (c1 == stx)
            return false;
        if (c2 == stx)
            return true;
        // case sensitive lexicographical comparison
        switch (std.math.order(c1, c2)) {
            .lt => return true,
            .gt => return false,
            .eq => {},
        }
    }
    return false;
}
