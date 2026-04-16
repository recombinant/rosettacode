// https://rosettacode.org/wiki/Words_from_neighbour_ones
// {{works with|Zig|0.16.0}}
const std = @import("std");

const Allocator = std.mem.Allocator;
const Io = std.Io;

const WordSet = std.StringArrayHashMapUnmanaged(void);

const LIMIT: usize = 9;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    const text = @embedFile("data/unixdict.txt");

    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------
    const max_capacity: usize = blk: {
        var word_count: usize = 0;
        var it = std.mem.splitScalar(u8, text, '\n');
        while (it.next()) |word| {
            if (word.len >= LIMIT) word_count += 1;
        }
        break :blk word_count;
    };
    var word_set: WordSet = .empty;
    try word_set.ensureTotalCapacity(gpa, max_capacity);
    defer word_set.deinit(gpa);

    // Create set of words of task appropriate length from unixdict.txt
    // Insertion order into the set is preserved.
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        if (word.len < LIMIT)
            continue;
        try word_set.putNoClobber(gpa, word, {});
    }

    // For a set of new words created by task.
    var new_word_set: WordSet = .empty;
    defer {
        for (new_word_set.keys()) |word|
            gpa.free(word);
        new_word_set.deinit(gpa);
    }

    var new_word: [LIMIT]u8 = undefined;

    // Complete the set of new words as specified by the task.
    const words = word_set.keys();
    for (0..words.len - LIMIT) |i| {
        for (0..new_word.len) |j|
            new_word[j] = words[i + j][j];

        if (word_set.get(&new_word) != null and new_word_set.get(&new_word) == null)
            try new_word_set.putNoClobber(gpa, try gpa.dupe(u8, &new_word), {});
    }

    // Pretty print.
    const wpr = 8; // words per row
    var n: u32 = 0;
    for (new_word_set.keys()) |word| {
        if (n % wpr != 0) try stdout.print(" ", .{});
        n += 1;

        try stdout.print("{s:9}", .{word});

        if (n % wpr == 0) try stdout.writeByte('\n');
    }
    if (n % wpr != 0) try stdout.writeByte('\n');

    try stdout.flush();
}
