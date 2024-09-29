// https://rosettacode.org/wiki/Words_from_neighbour_ones
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

const WordSet = std.StringArrayHashMap(void);

pub fn main() !void {
    const LIMIT: usize = 9;

    const text = @embedFile("data/unixdict.txt");
    // ---------------------------------------------------- Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    const max_capacity: usize = blk: {
        var word_count: usize = 0;
        var it = mem.splitScalar(u8, text, '\n');
        while (it.next()) |word| {
            if (word.len >= LIMIT) word_count += 1;
        }
        break :blk word_count;
    };
    var word_set = WordSet.init(allocator);
    try word_set.ensureTotalCapacity(max_capacity);
    defer word_set.deinit();

    // Create set of words of task appropriate length from unixdict.txt
    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        if (word.len < LIMIT)
            continue;
        try word_set.putNoClobber(word, {});
    }

    // For a set of new words created by task.
    var new_word_set = WordSet.init(allocator);
    defer {
        for (new_word_set.keys()) |word|
            allocator.free(word);
        new_word_set.deinit();
    }

    var new_word: [LIMIT]u8 = undefined;

    // Complete the set of new words as specified by the task.
    const words = word_set.keys();
    for (0..words.len - LIMIT) |i| {
        for (0..new_word.len) |j|
            new_word[j] = words[i + j][j];

        if (word_set.get(&new_word) != null and new_word_set.get(&new_word) == null)
            try new_word_set.putNoClobber(try allocator.dupe(u8, &new_word), {});
    }

    // Pretty print.
    const wpr = 8; // words per row
    var n: u32 = 0;
    for (new_word_set.keys()) |word| {
        if (n % wpr != 0) print(" ", .{});
        n += 1;

        print("{s:9}", .{word});

        if (n % wpr == 0) print("\n", .{});
    }
    if (n % wpr != 0) print("\n", .{});
}
