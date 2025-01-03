// https://rosettacode.org/wiki/Longest_substrings_without_repeating_characters
// Translation of C++
const std = @import("std");

pub fn main() !void {
    const examples = [_][]const u8{
        "xyzyabcybdfd", "xyzyab",            "zzzzz",
        "a",            "thisisastringtest", "",
    };

    const writer = std.io.getStdOut().writer();

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for (examples) |example| {
        try writer.print("Original string: \"{s}\"\n", .{example});
        try writer.writeAll("Longest substrings: ");
        const ls = try lswr(allocator, example);
        try writer.print("{s}\n\n", .{ls});
        allocator.free(ls);
    }
}

/// Return longest substrings without repeats.
/// Allocates memory for the result, which must be freed by the caller.
fn lswr(allocator: std.mem.Allocator, str: []const u8) ![]const []const u8 {
    var characters = std.AutoArrayHashMap(u8, void).init(allocator);
    defer characters.deinit();

    var max_length: usize = 0;
    var result = std.ArrayList([]const u8).init(allocator);
    defer result.deinit();
    for (0..str.len) |offset| {
        characters.clearRetainingCapacity();
        var len: usize = 0;
        while (offset + len < str.len) : (len += 1) {
            if (characters.contains(str[offset + len]))
                break;
            try characters.put(str[offset + len], {});
        }
        if (len > max_length) {
            result.clearAndFree();
            max_length = len;
        }
        if (len == max_length)
            try result.append(str[offset .. offset + max_length]);
    }
    return result.toOwnedSlice();
}
