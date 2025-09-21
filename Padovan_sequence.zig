// https://rosettacode.org/wiki/Padovan_sequence
// {{works with|Zig|0.15.1}}
// {{trans|Nim}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ----------------------------------------------------------
    const seq1 = try padovan1(allocator, 20);
    defer allocator.free(seq1);
    std.debug.print("First 20 terms of the Padovan sequence:\n {any}\n", .{seq1});
    // ----------------------------------------------------------
    const list1 = try padovan1(allocator, 64);
    defer allocator.free(list1);
    const list2 = try padovan2(allocator, 64);
    defer allocator.free(list2);
    std.debug.print(
        "The first 64 iterative and calculated values {s}.\n\n",
        .{if (std.mem.eql(u64, list1, list2)) "are the same" else "differ"},
    );
    // ----------------------------------------------------------
    const seq3 = try padovan3(allocator, 10);
    defer {
        for (seq3) |s| allocator.free(s);
        allocator.free(seq3);
    }
    const str3 = try std.mem.join(allocator, " ", seq3);
    defer allocator.free(str3);
    std.debug.print("First 10 L-system strings:\n {s}\n\n", .{str3});
    // ----------------------------------------------------------
    const list3 = blk: {
        const seq4 = try padovan3(allocator, 32);
        defer {
            for (seq4) |s| allocator.free(s);
            allocator.free(seq4);
        }
        const list3 = try allocator.alloc(u64, seq4.len);
        for (seq4, list3) |s, *n| n.* = s.len;
        break :blk list3;
    };
    defer allocator.free(list3);
    std.debug.print("Lengths of the first 32 L-system strings:\n {any}\n", .{list3});
    std.debug.print(
        "These lengths are{s}the first 32 terms of the Padovan sequence.\n",
        .{if (std.mem.eql(u64, list3, list1[0..list3.len])) " " else " not "},
    );
}

const P = 1.324717957244746025960908854;
const S = 1.0453567932525329623;

fn getRule(ch: u8) []const u8 {
    return switch (ch) {
        'A' => "B",
        'B' => "C",
        'C' => "AB",
        else => unreachable,
    };
}

// the first "n" Padovan values using recurrence relation
fn padovan1(allocator: std.mem.Allocator, n: u64) ![]const u64 {
    var result: std.ArrayList(u64) = try .initCapacity(allocator, n);
    try result.appendNTimes(allocator, 1, @min(n, 3));

    var a: u64 = 1;
    var b: u64 = 1;
    var c: u64 = 1;
    var count: usize = 3;
    while (count < n) : (count += 1) {
        const tmp = a + b;
        a = b;
        b = c;
        c = tmp;
        try result.append(allocator, c);
    }
    return result.toOwnedSlice(allocator);
}

/// the first "n" Padovan values using formula.
fn padovan2(allocator: std.mem.Allocator, n: u64) ![]const u64 {
    var result: std.ArrayList(u64) = try .initCapacity(allocator, n);
    if (n > 1) try result.append(allocator, 1);
    var p: f64 = 1.0;
    var count: usize = 1;
    while (count < n) : (count += 1) {
        try result.append(allocator, @intFromFloat(p / S + 0.5));
        p *= P;
    }
    return result.toOwnedSlice(allocator);
}

/// the strings produced by the L-system.
fn padovan3(allocator: std.mem.Allocator, n: u64) ![][]const u8 {
    var result: std.ArrayList([]const u8) = try .initCapacity(allocator, n);
    var s: std.ArrayList(u8) = .empty;
    defer s.deinit(allocator);
    try s.append(allocator, 'A');
    var count: usize = 0;
    while (count < n) : (count += 1) {
        var next: std.ArrayList(u8) = .empty;
        for (s.items) |ch| try next.appendSlice(allocator, getRule(ch));
        try result.append(allocator, try s.toOwnedSlice(allocator));
        s = .fromOwnedSlice(try next.toOwnedSlice(allocator));
    }
    return result.toOwnedSlice(allocator);
}
