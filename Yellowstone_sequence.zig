// https://rosettacode.org/wiki/Yellowstone_sequence
// {{works with|Zig|0.15.1}}
// {{trans|Nim}}

// https://rosettacode.org/wiki/Yellowstone_sequence#Procedure_version
const std = @import("std");

/// Caller owns returned slice memory.
fn yellowstone(allocator: std.mem.Allocator, n: u32) ![]u32 {
    std.debug.assert(n >= 3);
    var result: std.ArrayList(u32) = try .initCapacity(allocator, n);
    try result.appendSlice(allocator, &[_]u32{ 1, 2, 3 });
    var present: std.AutoArrayHashMapUnmanaged(u32, void) = .empty;
    defer present.deinit(allocator);
    for (result.items) |i|
        try present.put(allocator, i, {});

    var start: u32 = 4;
    while (result.items.len < n) {
        const len = result.items.len;
        var candidate = start;
        while (true) {
            if ((present.get(candidate) == null) and std.math.gcd(candidate, result.items[len - 1]) == 1 and std.math.gcd(candidate, result.items[len - 2]) != 1) {
                try result.append(allocator, candidate);
                try present.put(allocator, candidate, {});
                while (present.get(start) != null)
                    start += 1;
                break;
            }
            candidate += 1;
        }
    }
    return try result.toOwnedSlice(allocator);
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const result = try yellowstone(allocator, 30);
    defer allocator.free(result);

    try stdout.print("{any}\n", .{result});
    try stdout.flush();
}
