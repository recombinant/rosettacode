// https://rosettacode.org/wiki/Word_wheel
// Translation of Wren
const std = @import("std");
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const print = std.debug.print;

const WordSet = std.StringArrayHashMap(void);

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");
    // ---------------------------------------------------- Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();
    // --------------------------------------------------------------
    var word_set = try populateWordSet(allocator, text);
    defer word_set.deinit();
    // --------------------------------------------------------------
    try task1(allocator, word_set);
    try task2(allocator, word_set);
}

/// Primary task
fn task1(allocator: mem.Allocator, word_set: WordSet) !void {
    var found = std.ArrayList([]const u8).init(allocator);
    defer found.deinit();

    const letters = [9]u8{ 'd', 'e', 'e', 'g', 'k', 'l', 'n', 'o', 'w' };
    var letters_buffer = std.ArrayList(u8).init(allocator);
    defer letters_buffer.deinit();

    for (word_set.keys()) |word| {
        if (mem.indexOfScalar(u8, word, 'k') != null) {
            letters_buffer.clearRetainingCapacity();
            try letters_buffer.appendSlice(&letters);
            for (word) |c| {
                const idx = mem.indexOfScalar(u8, letters_buffer.items, c);
                if (idx) |i|
                    _ = letters_buffer.swapRemove(i)
                else
                    break;
            } else {
                try found.append(word);
            }
        }
    }

    print("The following {} words are the solutions to the puzzle:\n", .{found.items.len});
    for (found.items) |word|
        print(" {s}\n", .{word});
}

/// Optional Extra task
fn task2(allocator: mem.Allocator, word_set: WordSet) !void {
    var distinct_letters9 = std.AutoArrayHashMap(u8, void).init(allocator);
    defer distinct_letters9.deinit();
    var letter_list9 = try std.ArrayList(u8).initCapacity(allocator, 9);
    defer letter_list9.deinit();

    // // speed up
    // // Zig 0.13dev over twice as fast
    // var accel9 = try std.ArrayList(u8).initCapacity(allocator, 9);

    // defer accel9.deinit();

    var most_found: u16 = 0;
    var most_words9 = std.ArrayList([]const u8).init(allocator);
    var most_letters = std.ArrayList(u8).init(allocator);
    defer most_words9.deinit();
    defer most_letters.deinit();

    const words9 = try populateWords9(allocator, word_set);
    defer allocator.free(words9);
    for (words9) |word9| {
        distinct_letters9.clearRetainingCapacity();
        for (word9) |letter|
            try distinct_letters9.put(letter, {});

        // // speed up
        // accel9.clearRetainingCapacity();
        // try accel9.appendSlice(distinct_letters9.keys());
        // const accel9items = accel9.items;

        for (distinct_letters9.keys()) |central_letter| {
            var found: @TypeOf(most_found) = 0;

            next_word: for (word_set.keys()) |word| {
                // // speed up
                // if (mem.indexOfNone(u8, word, accel9items) != null)
                //     continue;
                if (mem.indexOfScalar(u8, word, central_letter) != null) {
                    letter_list9.clearRetainingCapacity();
                    try letter_list9.appendSlice(word9);

                    for (word) |c| {
                        const idx = mem.indexOfScalar(u8, letter_list9.items, c);
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
                try most_words9.append(word9);
                try most_letters.append(central_letter);
            } else if (found == most_found) {
                try most_words9.append(word9);
                try most_letters.append(central_letter);
            }
        }
    }

    print("\nMost words found = {d}\n", .{most_found});
    print("Nine letter words producing this total:\n", .{});
    for (most_words9.items, most_letters.items) |word, letter| {
        print(" \"{s}\" with central letter '{c}'\n", .{ word, letter });
    }
}

/// Set of words in `text` with between 3 and 9 letters inclusive.
fn populateWordSet(allocator: mem.Allocator, text: []const u8) !WordSet {
    // pre-compute capacity
    var word_count: usize = 0;
    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        if (word.len >= 3 and word.len <= 9)
            word_count += 1;
    }

    var word_set = WordSet.init(allocator);
    try word_set.ensureTotalCapacity(word_count);

    // populate set
    it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word|
        if (word.len >= 3 and word.len <= 9)
            try word_set.putNoClobber(word, {});

    return word_set;
}

/// List of 9 letter words in `word_set`
fn populateWords9(allocator: mem.Allocator, word_set: WordSet) ![]const []const u8 {
    // pre-compute capacity
    var word_count: usize = 0;
    for (word_set.keys()) |word| {
        if (word.len == 9)
            word_count += 1;
    }

    var word_list = try std.ArrayList([]const u8).initCapacity(allocator, word_count);
    for (word_set.keys()) |word|
        if (word.len == 9)
            try word_list.append(word);

    const words = try word_list.toOwnedSlice();
    mem.sort([]const u8, words, {}, compareStrings);

    return words;
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return mem.order(u8, lhs, rhs).compare(math.CompareOperator.lt);
}
