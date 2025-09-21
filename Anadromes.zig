// https://rosettacode.org/wiki/Anadromes
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // Assume lexicographically sorted for ordered printout.
    const text = @embedFile("data/words.txt");
    const word_cutoff = 6;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Insertion order is preserved.
    var word_set: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer word_set.deinit(allocator);

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        if (word.len > word_cutoff and !isPalindrome(word))
            try word_set.put(allocator, word, {});
    }

    var buffer: std.ArrayList(u8) = .empty;
    defer buffer.deinit(allocator);

    try stdout.print("Anadrome pairs with more than {} letters are:\n", .{word_cutoff});
    for (word_set.keys()) |word| {
        buffer.clearRetainingCapacity();
        try buffer.appendSlice(allocator, word);
        std.mem.reverse(u8, buffer.items);

        if (word_set.get(buffer.items) != null and std.mem.order(u8, word, buffer.items) == .lt)
            try stdout.print("{s} -> {s}\n", .{ word, buffer.items });
    }

    try stdout.flush();
}

fn isPalindrome(s: []const u8) bool {
    var i: usize = 0;
    const end = s.len / 2;
    while (i < end) : (i += 1)
        if (s[i] != s[s.len - i - 1]) return false;

    return true;
}

const testing = std.testing;

test isPalindrome {
    try testing.expect(isPalindrome("abccba"));
    try testing.expect(isPalindrome("abcdcba"));
    try testing.expect(!isPalindrome("abcdecba"));
}
