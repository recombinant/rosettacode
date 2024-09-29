// https://rosettacode.org/wiki/Find_words_which_contain_the_most_consonants
const std = @import("std");
const ascii = std.ascii;
const mem = std.mem;
const sort = std.sort;
const print = std.debug.print;

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = std.AutoArrayHashMap(usize, std.ArrayList([]const u8)).init(allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry|
            entry.value_ptr.deinit();
        map.deinit();
    }

    // fill hashmap with task worthy words
    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        const count = verifyConsonants(word) catch |err| {
            switch (err) {
                ConsonantError.WordTooShort,
                ConsonantError.DuplicatedConsonant,
                ConsonantError.NotLetter,
                => continue,
            }
        };
        const gop = try map.getOrPut(count);
        if (!gop.found_existing)
            gop.value_ptr.* = std.ArrayList([]const u8).init(allocator);

        try gop.value_ptr.append(word);
    }

    // sort counts ascending
    const counts: []usize = try allocator.dupe(usize, map.keys());
    defer allocator.free(counts);
    sort.insertion(usize, counts, {}, sort.asc(usize));

    // pretty print counts and words
    for (counts) |count| {
        // value is a std.ArrayList, hence .items to access slice
        const words: [][]const u8 = map.get(count).?.items;
        const s: []const u8 = if (words.len == 1) "" else "s";
        print(" {} consonants / {} word{s}\n", .{ count, words.len, s });
        var n: u32 = 0;
        for (words) |word| {
            if (n % 8 != 0) print(" ", .{});
            n += 1;
            print("{s:14}", .{word});
            if (n % 8 == 0) print("\n", .{});
        }
        if (n % 8 != 0) print("\n", .{});
    }
}

const Vowel = enum { a, e, i, o, u };

const ConsonantError = error{
    WordTooShort,
    DuplicatedConsonant,
    NotLetter,
};

fn verifyConsonants(word: []const u8) ConsonantError!usize {
    if (word.len <= 10)
        return ConsonantError.WordTooShort;

    var consonants = std.StaticBitSet(26).initEmpty();

    for (word) |c| {
        if (!ascii.isAlphabetic(c))
            return ConsonantError.NotLetter;

        const c_lower = ascii.toLower(c);
        switch (c) {
            'a', 'e', 'i', 'o', 'u' => continue, // ignore vowels
            else => {},
        }
        const idx = c_lower - 'a';
        if (consonants.isSet(idx))
            return ConsonantError.DuplicatedConsonant;
        consonants.set(idx);
    }
    return consonants.count();
}
