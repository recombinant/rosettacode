// https://rosettacode.org/wiki/Anagrams
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // ------------------------ hash map for anagram lookup
    // string vs list of words
    var anagrams: std.StringHashMapUnmanaged(std.ArrayList([]const u8)) = .empty;
    defer {
        var it = anagrams.iterator();
        while (it.next()) |anagram| {
            allocator.free(anagram.key_ptr.*);
            anagram.value_ptr.deinit(allocator);
        }
        anagrams.deinit(allocator);
    }

    // fill anagram lookup --------------------------------
    // lexicographically sort each word's letters to act as a key into
    // the 'anagrams' lookup
    // e.g. 'aeln' : ['elan', 'lane', 'lean', 'lena', 'neal']
    {
        var it = std.mem.splitSequence(u8, text, "\n");
        while (it.next()) |word| {
            const key = try allocator.dupe(u8, word);
            std.mem.sortUnstable(u8, key, {}, std.sort.asc(u8));

            const gop = try anagrams.getOrPut(allocator, key);
            if (gop.found_existing)
                allocator.free(key)
            else
                gop.value_ptr.* = .empty;

            try gop.value_ptr.append(allocator, word);
        }
    }

    {
        var most_words_keys: std.ArrayList([]const u8) = .empty;
        defer most_words_keys.deinit(allocator);

        var max_length: usize = 0;
        var it = anagrams.iterator();
        while (it.next()) |kv| {
            const len = kv.value_ptr.items.len;
            if (len >= max_length) {
                if (len > max_length) {
                    max_length = len;
                    most_words_keys.clearRetainingCapacity();
                }
                try most_words_keys.append(allocator, kv.key_ptr.*);
            }
        }

        for (most_words_keys.items) |key| {
            if (anagrams.get(key)) |list| {
                try stdout.print("{s}", .{key});

                for (list.items) |word|
                    try stdout.print(" {s}", .{word});

                try stdout.writeByte('\n');
            }
        }
    }

    // ------------------------------
    try stdout.flush();
}
