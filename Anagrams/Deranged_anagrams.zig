// https://rosettacode.org/wiki/Anagrams/Deranged_anagrams
const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;
const sort = std.sort;

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");

    // allocator ------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // anagram table --------------------------------------
    const Anagrams = std.ArrayList([]const u8);
    const AnagramTable = std.StringHashMap(Anagrams);

    var anagram_table = AnagramTable.init(allocator);
    defer {
        var it = anagram_table.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit();
        }
        anagram_table.deinit();
    }

    // Populate anagram table -----------------------------
    {
        var it = mem.splitScalar(u8, text, '\n');
        while (it.next()) |word| {
            const key = try allocator.dupe(u8, word);
            // word letters are sorted to create key
            sort.insertion(u8, key, {}, sort.asc(u8));

            const gop = try anagram_table.getOrPut(key);
            if (gop.found_existing)
                allocator.free(key)
            else
                gop.value_ptr.* = Anagrams.init(allocator);

            try gop.value_ptr.append(word);
        }
    }

    // Eliminate solo words -------------------------------
    {
        var remove_keys = Anagrams.init(allocator);
        defer remove_keys.deinit();

        // Find the keys to delete.
        var it = anagram_table.iterator();
        while (it.next()) |kv| {
            const len = kv.value_ptr.items.len;
            if (len < 2)
                try remove_keys.append(kv.key_ptr.*);
        }

        // Remove the key/value pairs where there is only one word.
        for (remove_keys.items) |key| {
            const kv = anagram_table.getEntry(key) orelse unreachable;
            const array_list = kv.value_ptr.*; // Copy before remove() overwrites.
            assert(mem.eql(u8, kv.key_ptr.*, key));
            const b = anagram_table.remove(key);
            assert(b);
            array_list.deinit();
            allocator.free(key);
        }
    }

    const Pairs = std.ArrayList([2][]const u8);
    var deranged_pairs = Pairs.init(allocator);
    defer deranged_pairs.deinit();

    // Find deranged anagrams -----------------------------
    {
        var max_word_length: usize = 0;
        var it = anagram_table.valueIterator();
        while (it.next()) |anagrams| {
            const wlen = anagrams.items[0].len; // word length
            if (wlen >= max_word_length) {
                const words: [][]const u8 = anagrams.items;
                const n = words.len;
                for (words[0 .. n - 1], words[1..n]) |a, b|
                    if (isDeranged(a, b)) {
                        if (wlen > max_word_length) {
                            max_word_length = wlen;
                            deranged_pairs.clearRetainingCapacity();
                        }
                        try deranged_pairs.append(.{ a, b });
                    };
            }
        }
    }

    // Output deranged pairs to unbuffered stdout ---------
    const writer = std.io.getStdOut().writer();
    for (deranged_pairs.items) |pair|
        try writer.print("{s} {s}\n", .{ pair[0], pair[1] });
}

fn isDeranged(a: []const u8, b: []const u8) bool {
    for (a, b) |ch_a, ch_b|
        if (ch_a == ch_b)
            return false;
    return true;
}
