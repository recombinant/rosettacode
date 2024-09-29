// https://rosettacode.org/wiki/Odd_words
const std = @import("std");
const File = std.fs.File;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var word_set = std.StringHashMap(void).init(allocator);
    defer {
        var it = word_set.keyIterator();
        while (it.next()) |key| allocator.free(key.*);
        word_set.deinit();
    }
    try word_set.ensureTotalCapacity(26_000);

    var file: File = try std.fs.cwd().openFile("data/unixdict.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var max_len: usize = 0;
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |word| {
        if (word.len > 4) {
            const m = try allocator.dupe(u8, word);
            try word_set.putNoClobber(m, {});
            max_len = @max(max_len, word.len / 2 + 1);
        }
    }

    var odd_word_set = std.StringHashMap(void).init(allocator);
    defer {
        var it = odd_word_set.keyIterator();
        while (it.next()) |key| allocator.free(key.*);
        odd_word_set.deinit();
    }

    var even_word_set = std.StringHashMap(void).init(allocator);
    defer {
        var it = even_word_set.keyIterator();
        while (it.next()) |key| allocator.free(key.*);
        even_word_set.deinit();
    }

    var buffer1 = try allocator.alloc(u8, max_len);
    var buffer2 = try allocator.alloc(u8, max_len);
    defer allocator.free(buffer1);
    defer allocator.free(buffer2);

    var it = word_set.keyIterator();
    while (it.next()) |word| {
        if (word.len > 8) {
            var end: usize = undefined;
            for (word.*, 0..) |letter, i| {
                end = i / 2;
                if (i & 1 == 0) {
                    buffer1[end] = letter;
                } else {
                    buffer2[end] = letter;
                }
            }
            const odd_word = buffer1[0 .. end + 1];
            if (word_set.contains(odd_word)) {
                if (!odd_word_set.contains(odd_word))
                    try odd_word_set.putNoClobber(try allocator.dupe(u8, odd_word), {});
            }
            const even_word = buffer2[0 .. end + 1];
            if (word_set.contains(even_word)) {
                if (!even_word_set.contains(even_word))
                    try even_word_set.putNoClobber(try allocator.dupe(u8, even_word), {});
            }
        }
    }
    it = odd_word_set.keyIterator();
    while (it.next()) |word|
        try std.io.getStdOut().writer().print("{s}\n", .{word.*});
}
