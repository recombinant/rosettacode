// https://rosettacode.org/wiki/Padovan_sequence
// Translation of Nim
const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const print = std.debug.print;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ----------------------------------------------------------
    const seq1 = try padovan1(allocator, 20);
    defer allocator.free(seq1);
    print("First 20 terms of the Padovan sequence:\n {any}\n", .{seq1});
    // ----------------------------------------------------------
    const list1 = try padovan1(allocator, 64);
    defer allocator.free(list1);
    const list2 = try padovan2(allocator, 64);
    defer allocator.free(list2);
    print(
        "The first 64 iterative and calculated values {s}.\n\n",
        .{if (mem.eql(u64, list1, list2)) "are the same" else "differ"},
    );
    // ----------------------------------------------------------
    const seq3 = try padovan3(allocator, 10);
    defer {
        for (seq3) |s| allocator.free(s);
        allocator.free(seq3);
    }
    const str3 = try mem.join(allocator, " ", seq3);
    defer allocator.free(str3);
    print("First 10 L-system strings:\n {s}\n\n", .{str3});
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
    print("Lengths of the first 32 L-system strings:\n {any}\n", .{list3});
    print(
        "These lengths are{s}the first 32 terms of the Padovan sequence.\n",
        .{if (mem.eql(u64, list3, list1[0..list3.len])) " " else " not "},
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
fn padovan1(allocator: mem.Allocator, n: u64) ![]const u64 {
    var result = try std.ArrayList(u64).initCapacity(allocator, n);
    try result.appendNTimes(1, @min(n, 3));

    var a: u64 = 1;
    var b: u64 = 1;
    var c: u64 = 1;
    var count: usize = 3;
    while (count < n) : (count += 1) {
        const tmp = a + b;
        a = b;
        b = c;
        c = tmp;
        try result.append(c);
    }
    return result.toOwnedSlice();
}

/// the first "n" Padovan values using formula.
fn padovan2(allocator: mem.Allocator, n: u64) ![]const u64 {
    var result = try std.ArrayList(u64).initCapacity(allocator, n);
    if (n > 1) try result.append(1);
    var p: f64 = 1.0;
    var count: usize = 1;
    while (count < n) : (count += 1) {
        try result.append(@intFromFloat(p / S + 0.5));
        p *= P;
    }
    return result.toOwnedSlice();
}

/// the strings produced by the L-system.
fn padovan3(allocator: mem.Allocator, n: u64) ![][]const u8 {
    var result = try std.ArrayList([]const u8).initCapacity(allocator, n);
    var s = std.ArrayList(u8).init(allocator);
    defer s.deinit();
    try s.append('A');
    var count: usize = 0;
    while (count < n) : (count += 1) {
        var next = std.ArrayList(u8).init(allocator);
        for (s.items) |ch| try next.appendSlice(getRule(ch));
        try result.append(try s.toOwnedSlice());
        s = std.ArrayList(u8).fromOwnedSlice(allocator, try next.toOwnedSlice());
    }
    return result.toOwnedSlice();
}
