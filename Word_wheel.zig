// https://rosettacode.org/wiki/Word_wheel
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");
const WordSet = std.StringArrayHashMapUnmanaged(void);

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");
    // --------------------------------------------------------------
    var t0: std.time.Timer = try .start();
    // ---------------------------------------------------- Allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();
    // --------------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------
    var word_set = try populateWordSet(allocator, text);
    defer word_set.deinit(allocator);
    // --------------------------------------------------------------
    try task1(allocator, word_set, stdout);
    try stdout.flush();
    try task2(allocator, word_set, stdout);
    try stdout.flush();
    // --------------------------------------------------------------
    std.log.info("processed in {D}", .{t0.read()});
}

/// Primary task
fn task1(allocator: std.mem.Allocator, word_set: WordSet, w: *std.Io.Writer) !void {
    var found: std.ArrayList([]const u8) = .empty;
    defer found.deinit(allocator);

    const letters = [9]u8{ 'd', 'e', 'e', 'g', 'k', 'l', 'n', 'o', 'w' };
    var letters_buffer: std.ArrayList(u8) = .empty;
    defer letters_buffer.deinit(allocator);

    for (word_set.keys()) |word| {
        if (std.mem.indexOfScalar(u8, word, 'k') != null) {
            letters_buffer.clearRetainingCapacity();
            try letters_buffer.appendSlice(allocator, &letters);
            for (word) |c| {
                const idx = std.mem.indexOfScalar(u8, letters_buffer.items, c);
                if (idx) |i|
                    _ = letters_buffer.swapRemove(i)
                else
                    break;
            } else {
                try found.append(allocator, word);
            }
        }
    }

    try w.print("The following {} words are the solutions to the puzzle:\n", .{found.items.len});
    for (found.items) |word|
        try w.print(" {s}\n", .{word});
}

/// Optional Extra task
fn task2(allocator: std.mem.Allocator, word_set: WordSet, w: *std.Io.Writer) !void {
    var distinct_letters9: std.AutoArrayHashMapUnmanaged(u8, void) = .empty;
    defer distinct_letters9.deinit(allocator);
    var letter_list9: std.ArrayList(u8) = try .initCapacity(allocator, 9);
    defer letter_list9.deinit(allocator);

    // speed up
    var accel9: std.ArrayList(u8) = try .initCapacity(allocator, 9);
    defer accel9.deinit(allocator);
    //
    var most_found: u16 = 0;
    var most_words9: std.ArrayList([]const u8) = .empty;
    var most_letters: std.ArrayList(u8) = .empty;
    defer most_words9.deinit(allocator);
    defer most_letters.deinit(allocator);

    const words9 = try populateWords9(allocator, word_set);
    defer allocator.free(words9);
    for (words9) |word9| {
        distinct_letters9.clearRetainingCapacity();
        for (word9) |letter|
            try distinct_letters9.put(allocator, letter, {});

        // speed up
        accel9.clearRetainingCapacity();
        try accel9.appendSlice(allocator, distinct_letters9.keys());
        const accel9items = accel9.items;
        //
        for (distinct_letters9.keys()) |central_letter| {
            var found: @TypeOf(most_found) = 0;

            next_word: for (word_set.keys()) |word| {
                // speed up
                if (std.mem.indexOfNone(u8, word, accel9items) != null)
                    continue;
                //
                if (std.mem.indexOfScalar(u8, word, central_letter) != null) {
                    letter_list9.clearRetainingCapacity();
                    try letter_list9.appendSlice(allocator, word9);

                    for (word) |c| {
                        const idx = std.mem.indexOfScalar(u8, letter_list9.items, c);
                        if (idx) |i|
                            _ = letter_list9.swapRemove(i)
                        else
                            continue :next_word;
                    }
                    found += 1;
                }
            }

            if (found > most_found) {
                most_found = found;
                most_words9.clearRetainingCapacity();
                most_letters.clearRetainingCapacity();
                try most_words9.append(allocator, word9);
                try most_letters.append(allocator, central_letter);
            } else if (found == most_found) {
                try most_words9.append(allocator, word9);
                try most_letters.append(allocator, central_letter);
            }
        }
    }

    try w.print("\nMost words found = {d}\n", .{most_found});
    try w.writeAll("Nine letter words producing this total:\n");
    for (most_words9.items, most_letters.items) |word, letter| {
        try w.print(" \"{s}\" with central letter '{c}'\n", .{ word, letter });
    }
    try w.writeByte('\n');
}

/// Set of words in `text` with between 3 and 9 letters inclusive.
fn populateWordSet(allocator: std.mem.Allocator, text: []const u8) !WordSet {
    // pre-compute capacity
    var word_count: usize = 0;
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        if (word.len >= 3 and word.len <= 9)
            word_count += 1;
    }

    var word_set: WordSet = .empty;
    try word_set.ensureTotalCapacity(allocator, word_count);

    // populate set
    it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (word.len >= 3 and word.len <= 9)
            try word_set.putNoClobber(allocator, word, {});

    return word_set;
}

/// List of 9 letter words in `word_set`
fn populateWords9(allocator: std.mem.Allocator, word_set: WordSet) ![]const []const u8 {
    // pre-compute capacity
    var word_count: usize = 0;
    for (word_set.keys()) |word| {
        if (word.len == 9)
            word_count += 1;
    }

    var word_list: std.ArrayList([]const u8) = try .initCapacity(allocator, word_count);
    for (word_set.keys()) |word|
        if (word.len == 9)
            try word_list.append(allocator, word);

    const words = try word_list.toOwnedSlice(allocator);
    std.mem.sortUnstable([]const u8, words, {}, compareStrings);

    return words;
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}
