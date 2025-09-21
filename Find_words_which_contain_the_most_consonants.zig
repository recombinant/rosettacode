// https://rosettacode.org/wiki/Find_words_which_contain_the_most_consonants
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    const text = @embedFile("data/unixdict.txt");

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map: std.AutoArrayHashMapUnmanaged(usize, std.ArrayList([]const u8)) = .empty;
    defer {
        var it = map.iterator();
        while (it.next()) |*entry|
            entry.value_ptr.deinit(allocator);
        map.deinit(allocator);
    }

    // fill hashmap with task worthy words
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        const count = verifyConsonants(word) catch |err| {
            switch (err) {
                ConsonantError.WordTooShort,
                ConsonantError.DuplicatedConsonant,
                ConsonantError.NotLetter,
                => continue,
            }
        };
        const gop = try map.getOrPut(allocator, count);
        if (!gop.found_existing)
            gop.value_ptr.* = .empty;

        try gop.value_ptr.append(allocator, word);
    }

    // sort counts ascending
    const counts: []usize = try allocator.dupe(usize, map.keys());
    defer allocator.free(counts);
    std.mem.sortUnstable(usize, counts, {}, std.sort.asc(usize));

    // pretty print counts and words
    for (counts) |count| {
        // value is a std.ArrayList, hence .items to access slice
        const words: [][]const u8 = map.get(count).?.items;
        const s: []const u8 = if (words.len == 1) "" else "s";
        try stdout.print(" {} consonants / {} word{s}\n", .{ count, words.len, s });
        var n: u32 = 0;
        for (words) |word| {
            if (n % 8 != 0) try stdout.writeByte(' ');
            n += 1;
            try stdout.print("{s:14}", .{word});
            if (n % 8 == 0) try stdout.writeByte('\n');
        }
        if (n % 8 != 0) try stdout.writeByte('\n');
    }
    try stdout.flush();
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

    var consonants: std.StaticBitSet(26) = .initEmpty();

    for (word) |c| {
        if (!std.ascii.isAlphabetic(c))
            return ConsonantError.NotLetter;

        const c_lower = std.ascii.toLower(c);
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
