// https://rosettacode.org/wiki/Anadromes
const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const print = std.debug.print;

pub fn main() !void {
    // Assume lexicographically sorted for ordered printout.
    const text = @embedFile("data/words.txt");
    const word_cutoff = 6;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Insertion order is preserved.
    var word_set = std.StringArrayHashMap(void).init(allocator);
    defer word_set.deinit();

    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        if (word.len > word_cutoff and !isPalindrome(word))
            try word_set.put(word, {});
    }

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    print("Anadrome pairs with more than {} letters are:\n", .{word_cutoff});
    for (word_set.keys()) |word| {
        buffer.clearRetainingCapacity();
        try buffer.appendSlice(word);
        mem.reverse(u8, buffer.items);

        if (word_set.get(buffer.items) != null and mem.order(u8, word, buffer.items) == .lt)
            print("{s} -> {s}\n", .{ word, buffer.items });
    }
}

fn isPalindrome(s: []const u8) bool {
    var i: usize = 0;
    const end = s.len / 2;
    while (i < end) : (i += 1)
        if (s[i] != s[s.len - i - 1]) return false;

    return true;
}

test isPalindrome {
    try testing.expect(isPalindrome("abccba"));
    try testing.expect(isPalindrome("abcdcba"));
    try testing.expect(!isPalindrome("abcdecba"));
}
