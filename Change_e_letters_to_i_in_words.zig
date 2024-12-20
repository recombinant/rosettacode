// https://rosettacode.org/wiki/Change_e_letters_to_i_in_words
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
const WordList = std.ArrayList([]const u8);
const WordSet = std.StringArrayHashMap(void);

pub fn main() !void {
    // No uppercase in this.
    const text = @embedFile("data/unixdict.txt");

    // ---------------------------------------------------- Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------

    const e_max_len, const e_words, var i_word_set = try populateWords(allocator, text);
    defer i_word_set.deinit();
    defer allocator.free(e_words);

    var i_word_buffer = try allocator.alloc(u8, e_max_len);
    defer allocator.free(i_word_buffer);

    for (e_words) |e_word| {
        const i_word = i_word_buffer[0..e_word.len];
        @memcpy(i_word, e_word);
        for (i_word) |*c| {
            if (c.* == 'e')
                c.* = 'i';
        }
        if (i_word_set.get(i_word) != null)
            print("{s} -> {s}\n", .{ e_word, i_word });
    }
}

fn populateWords(allocator: mem.Allocator, text: []const u8) !struct { usize, []const []const u8, WordSet } {
    var word_list_e = WordList.init(allocator);
    var word_set_i = WordSet.init(allocator);
    var longest_e: usize = 0;

    // populate list and set, find length of longest e word
    var it = mem.splitScalar(u8, text, '\n');
    next_word: while (it.next()) |word| {
        if (word.len <= 5)
            continue;
        var found_i = false;
        for (word) |c| {
            switch (c) {
                'e' => {
                    if (word.len > longest_e) longest_e = word.len;
                    try word_list_e.append(word);
                    continue :next_word;
                },
                'i' => found_i = true,
                else => {},
            }
            if (found_i)
                try word_set_i.put(word, {});
        }
    }
    return .{ longest_e, try word_list_e.toOwnedSlice(), word_set_i };
}
