// https://rosettacode.org/wiki/Anagrams
const std = @import("std");
const mem = std.mem;
const sort = std.sort;
const print = std.debug.print;

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");

    // allocator ------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // hash map for anagram lookup ------------------------
    // string vs list of words
    var anagrams = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    defer {
        var it = anagrams.iterator();
        while (it.next()) |anagram| {
            allocator.free(anagram.key_ptr.*);
            anagram.value_ptr.deinit();
        }
        anagrams.deinit();
    }

    // fill anagram lookup --------------------------------
    // lexicographically sort each word's letters to act as a key into
    // the 'anagrams' lookup
    // e.g. 'aeln' : ['elan', 'lane', 'lean', 'lena', 'neal']
    {
        var it = mem.splitSequence(u8, text, "\n");
        while (it.next()) |word| {
            const key = try allocator.dupe(u8, word);
            sort.insertion(u8, key, {}, sort.asc(u8));

            const gop = try anagrams.getOrPut(key);
            if (gop.found_existing)
                allocator.free(key)
            else
                gop.value_ptr.* = std.ArrayList([]const u8).init(allocator);

            try gop.value_ptr.append(word);
        }
    }

    {
        var most_words_keys = std.ArrayList([]const u8).init(allocator);
        defer most_words_keys.deinit();

        var max_length: usize = 0;
        var it = anagrams.iterator();
        while (it.next()) |kv| {
            const len = kv.value_ptr.items.len;
            if (len >= max_length) {
                if (len > max_length) {
                    max_length = len;
                    most_words_keys.clearRetainingCapacity();
                }
                try most_words_keys.append(kv.key_ptr.*);
            }
        }

        for (most_words_keys.items) |key| {
            if (anagrams.get(key)) |list| {
                print("{s} ", .{key});
                try printWords(list.items);
            }
        }
    }
}

fn printWords(words: []const []const u8) !void {
    // buffered stdout ------------------------------------
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    // ----------------------------------------------------

    var sep: []const u8 = "";
    for (words) |word| {
        try stdout.print("{s}{s}", .{ sep, word });
        sep = " ";
    }
    try stdout.writeByte('\n');

    // flush buffered stdout ------------------------------
    try bw.flush();
}
