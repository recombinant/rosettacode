// https://rosettacode.org/wiki/Longest_substrings_without_repeating_characters
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

pub fn main() !void {
    const examples = [_][]const u8{
        "xyzyabcybdfd", "xyzyab",            "zzzzz",
        "a",            "thisisastringtest", "",
    };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for (examples) |example| {
        try stdout.print("Original string: \"{s}\"\n", .{example});
        const ls = try lswr(allocator, example);
        if (ls.len == 0)
            try stdout.writeAll("Empty string - no substrings\n\n")
        else {
            try stdout.print("Longest substrings ({d}):\n", .{ls.len});
            for (ls) |s|
                try stdout.print("  {s}\n", .{s});
            try stdout.writeByte('\n');
        }
        allocator.free(ls);
    }
    try stdout.flush();
}

/// Return longest substrings without repeats.
/// Allocates memory for the result, which must be freed by the caller.
fn lswr(allocator: std.mem.Allocator, str: []const u8) ![]const []const u8 {
    var characters: std.AutoArrayHashMapUnmanaged(u8, void) = .empty;
    defer characters.deinit(allocator);

    var max_length: usize = 0;
    var substring_set: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer substring_set.deinit(allocator);

    for (0..str.len) |offset| {
        characters.clearRetainingCapacity();
        var len: usize = 0;
        while (offset + len < str.len) : (len += 1) {
            if (characters.contains(str[offset + len]))
                break;
            try characters.put(allocator, str[offset + len], {});
        }
        if (len > max_length) {
            substring_set.clearRetainingCapacity();
            max_length = len;
        }
        if (len == max_length)
            try substring_set.put(allocator, str[offset .. offset + max_length], {});
    }

    const result = try allocator.alloc([]const u8, substring_set.count());
    for (substring_set.keys(), result) |substring, *s|
        s.* = substring;

    return result;
}
