// https://rosettacode.org/wiki/Amb
// {{works with|Zig|0.15.1}}
// {{trans|Go}}

// Translation of the alternative solution. Zig does not have
// garbage collection or reference counting, so all memory
// allocation/free activity must be implemented explicitly.
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const a1 = [_][]const u8{ "the", "that", "a" };
    const a2 = [_][]const u8{ "frog", "elephant", "thing" };
    const a3 = [_][]const u8{ "walked", "treaded", "grows" };
    const a4 = [_][]const u8{ "slowly", "quickly" };

    const wordset = [_][]const []const u8{
        a1[0..a1.len],
        a2[0..a2.len],
        a3[0..a3.len],
        a4[0..a4.len],
    };

    if (try amb(allocator, wordset[0..wordset.len], try allocator.alloc([]const u8, 0))) |result| {
        for (result) |s|
            try stdout.print("{s} ", .{s});
        try stdout.writeByte('\n');
        allocator.free(result);
    } else {
        try stdout.writeAll("No amb found\n");
    }
    try stdout.flush();
}

// Recursive function.
// This function owns `array_in` slice memory. Caller owns returned slice memory.
fn amb(allocator: std.mem.Allocator, wordsets: []const []const []const u8, array_in: [][]const u8) !?[][]const u8 {
    if (wordsets.len == 0)
        return array_in;

    defer allocator.free(array_in);

    const len = array_in.len;
    var s: []const u8 = if (len != 0) array_in[len - 1] else undefined;

    var array_out = try allocator.alloc([]const u8, len + 1);
    defer allocator.free(array_out); // `array_out` is freed in this function.
    @memcpy(array_out[0..len], array_in);

    for (wordsets[0]) |word| {
        array_out[len] = word;
        if (len != 0 and s[s.len - 1] != word[0])
            continue;

        // Duplicate `array_out` so the the callee amb() can free it.
        const returned_slice = try allocator.dupe([]const u8, array_out);
        if (try amb(allocator, wordsets[1..wordsets.len], returned_slice)) |result|
            return result;
    }
    return null;
}
