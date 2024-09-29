// https://rosettacode.org/wiki/Odd_words
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var file: std.fs.File = try std.fs.cwd().openFile("data/unixdict.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const unixdict_txt = try allocator.alloc(u8, file_size);
    defer allocator.free(unixdict_txt);

    try file.reader().readNoEof(unixdict_txt);

    // Need capacity for HashMap.
    // Number of words in text is equivalent to number of linefeed characters.
    // (+1 should the file not end with linefeed).
    const lf_count = blk: {
        var count: usize = 1;
        for (unixdict_txt) |ch| {
            if (ch == '\n') count += 1;
        }
        break :blk count;
    };

    // StringArrayHashMap as insertion order is maintained.
    var word_set = std.StringArrayHashMap(void).init(allocator);
    defer word_set.deinit();
    try word_set.ensureTotalCapacity(lf_count);
    var longest_word: usize = 0;

    // fill word_set with contents of "unixdict.txt"
    var it = mem.splitScalar(u8, unixdict_txt, '\n');
    while (it.next()) |word| {
        if (word.len != 0) {
            try word_set.putNoClobber(word, {});
            longest_word = @max(longest_word, word.len);
        }
    }

    var odd_word_buffer = try allocator.alloc(u8, longest_word / 2);
    defer allocator.free(odd_word_buffer);

    for (word_set.keys()) |word| {
        if (word.len > 8) {
            var end: usize = undefined;
            for (word, 0..) |letter, i| {
                if (i & 1 == 0) {
                    end = i / 2;
                    odd_word_buffer[end] = letter;
                }
            }
            const odd_word = odd_word_buffer[0 .. end + 1];
            if (word_set.contains(odd_word))
                try std.io.getStdOut().writer().print("{s:10} {s}\n", .{ word, odd_word });
        }
    }
}
