// https://rosettacode.org/wiki/Triangular_numbers
const std = @import("std");
const math = std.math;
const mem = std.mem;

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    for ([_]u64{ 7140, 21408696, 26728085384, 14545501785001 }) |n| {
        try stdout.print("Roots of {}:\n", .{n});
        const lookup = comptime [_]struct { title: []const u8, f: *const fn (f64) f64 }{
            .{ .title = "triangular: ", .f = triangularRoot },
            .{ .title = "tetrahedral:", .f = tetrahedralRoot },
            .{ .title = "pentatopic: ", .f = pentatopicRoot },
        };
        for (lookup) |s|
            try stdout.print("  {s} {d:.6}\n", .{ s.title, s.f(@floatFromInt(n)) });
        try stdout.writeByte('\n');
    }
    // --------------------------------------------------------------
    try printNSimplexNumbers(stdout, allocator, 2, 30, "First 30 triangular numbers:");
    try printNSimplexNumbers(stdout, allocator, 3, 30, "First 30 tetrahedral numbers:");
    try printNSimplexNumbers(stdout, allocator, 4, 30, "First 30 pentatopic numbers:");
    try printNSimplexNumbers(stdout, allocator, 12, 30, "First 30 12-simplex numbers:");
}

/// Pretty print the first "count" terms of the "r-simplex" sequence
/// Zig print() requires the format parameter to be comptime known, so a
/// workaround is used.
fn printNSimplexNumbers(writer: anytype, allocator: mem.Allocator, r: u8, count: u8, title: []const u8) !void {
    try writer.print("{s}\n", .{title});
    var width: usize = 0;
    var terms = try std.ArrayList([]const u8).initCapacity(allocator, count);
    defer {
        while (terms.popOrNull()) |term| allocator.free(term);
        terms.deinit();
    }
    // Create terms and obtain maximum width at run-time
    for (1..count + 1) |n| {
        const term = try binomial(n + r - 1, r);
        const buffer = try std.fmt.allocPrint(allocator, "{d}", .{term});
        try terms.append(buffer);
        width = @max(width, buffer.len);
    }
    // Maximum width is now known, create buffer of that width.
    var buffer = try allocator.alloc(u8, width);
    defer allocator.free(buffer);
    for (terms.items, 1..) |term, n| {
        // use buffer to right justify each term.
        @memset(buffer, ' '); // brute force wipe
        @memcpy(buffer[buffer.len - term.len ..], term); // right justified
        try writer.writeAll(buffer);
        try writer.writeByte(if (n % 5 == 0) '\n' else ' ');
    }
    try writer.writeByte('\n');
}

fn triangularRoot(x: f64) f64 {
    return (math.sqrt(8 * x + 1) - 1) * 0.5;
}

fn tetrahedralRoot(x: f64) f64 {
    const t1 = 3 * x;
    const t2 = math.sqrt(t1 * t1 - 1 / 27);
    return math.cbrt(t1 + t2) + math.cbrt(t1 - t2) - 1;
}

fn pentatopicRoot(x: f64) f64 {
    return (math.sqrt(5 + 4 * math.sqrt(24 * x + 1)) - 3) * 0.5;
}

const BinomialError = error{
    Args, // The second argument cannot be more than the first.
};

/// from wikipedia
fn binomial(n: u64, k: u64) !u64 {
    if (k > n) return BinomialError.Args;
    if (k == 0 or n == k) return 1;
    var c: u64 = 1;
    const k_ = @min(k, n - k);
    for (0..k_) |i|
        c *= n - i;
    return c / factorial(k_);
}

fn factorial(n: u64) u64 {
    var result: u64 = 1;
    for (2..n + 1) |i|
        result *= i;
    return result;
}

test binomial {
    try std.testing.expectEqual(@as(u64, 1), try binomial(1, 1));
    try std.testing.expectEqual(@as(u64, 10), try binomial(5, 3));
    try std.testing.expectEqual(@as(u64, 12376), try binomial(17, 6));
}

test factorial {
    try std.testing.expectEqual(@as(u64, 1), factorial(1));
    try std.testing.expectEqual(@as(u64, 120), factorial(5));
    try std.testing.expectEqual(@as(u64, 479_001_600), factorial(12));
}
