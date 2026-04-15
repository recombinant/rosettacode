// https://rosettacode.org/wiki/Anagrams
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;

    const text = @embedFile("data/unixdict.txt");
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // ------------------------ hash map for anagram lookup
    // string vs list of words
    var anagrams: std.StringHashMapUnmanaged(std.ArrayList([]const u8)) = .empty;
    defer {
        var it = anagrams.iterator();
        while (it.next()) |anagram| {
            gpa.free(anagram.key_ptr.*);
            anagram.value_ptr.deinit(gpa);
        }
        anagrams.deinit(gpa);
    }

    // fill anagram lookup --------------------------------
    // lexicographically sort each word's letters to act as a key into
    // the 'anagrams' lookup
    // e.g. 'aeln' : ['elan', 'lane', 'lean', 'lena', 'neal']
    {
        var it = std.mem.splitSequence(u8, text, "\n");
        while (it.next()) |word| {
            const key = try gpa.dupe(u8, word);
            std.mem.sortUnstable(u8, key, {}, std.sort.asc(u8));

            const gop = try anagrams.getOrPut(gpa, key);
            if (gop.found_existing)
                gpa.free(key)
            else
                gop.value_ptr.* = .empty;

            try gop.value_ptr.append(gpa, word);
        }
    }

    {
        var most_words_keys: std.ArrayList([]const u8) = .empty;
        defer most_words_keys.deinit(gpa);

        var max_length: usize = 0;
        var it = anagrams.iterator();
        while (it.next()) |kv| {
            const len = kv.value_ptr.items.len;
            if (len >= max_length) {
                if (len > max_length) {
                    max_length = len;
                    most_words_keys.clearRetainingCapacity();
                }
                try most_words_keys.append(gpa, kv.key_ptr.*);
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
