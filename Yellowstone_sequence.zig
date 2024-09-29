// https://rosettacode.org/wiki/Yellowstone_sequence

// Translation of Nim
// https://rosettacode.org/wiki/Yellowstone_sequence#Procedure_version
const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;
const assert = std.debug.assert;
const print = std.debug.print;

fn yellowstone(allocator: mem.Allocator, n: u32) ![]u32 {
    assert(n >= 3);
    var result = try std.ArrayList(u32).initCapacity(allocator, n);
    try result.appendSlice(&[_]u32{ 1, 2, 3 });
    var present = std.AutoArrayHashMap(u32, void).init(allocator);
    defer present.deinit();
    for (result.items) |i|
        try present.put(i, {});

    var start: u32 = 4;
    while (result.items.len < n) {
        const len = result.items.len;
        var candidate = start;
        while (true) {
            if ((present.get(candidate) == null) and math.gcd(candidate, result.items[len - 1]) == 1 and math.gcd(candidate, result.items[len - 2]) != 1) {
                try result.append(candidate);
                try present.put(candidate, {});
                while (present.get(start) != null)
                    start += 1;
                break;
            }
            candidate += 1;
        }
    }
    return try result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const result = try yellowstone(allocator, 30);
    defer allocator.free(result);

    print("{any}\n", .{result});
}
