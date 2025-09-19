// https://rosettacode.org/wiki/Odd_words
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var word_set = std.StringHashMap(void).init(allocator);
    defer {
        var it = word_set.keyIterator();
        while (it.next()) |key| allocator.free(key.*);
        word_set.deinit();
    }

    var file: std.fs.File = try std.fs.cwd().openFile("data/unixdict.txt", .{});
    defer file.close();

    var buffer1: [4096]u8 = undefined;
    var file_reader = file.reader(&buffer1);
    var r = &file_reader.interface;

    // assume words are <= 64 bytes in length
    var buffer2: [64]u8 = undefined;
    var w = std.Io.Writer.fixed(&buffer2);

    // ---------------------------------------------------
    // count the words for `word_set` capacity
    const count = try getWordCount(r, &w);
    // with the exact count no realloc will be necessary
    try word_set.ensureTotalCapacity(count);
    std.debug.print("dictionary usable word count = {}\n", .{count});

    try file_reader.seekTo(0); // rewind
    _ = w.consumeAll(); // reset `w` writer
    // ---------------------------------------------------
    var max_len: usize = 0; // for buffer allocation
    // put the words into `word_set`
    while (0 != try r.streamDelimiterEnding(&w, '\n')) : (_ = w.consumeAll()) {
        const word = w.buffered();
        // consume the '\n' (or catch eof)
        _ = r.takeByte() catch |err| switch (err) {
            error.EndOfStream => {},
            else => |e| return e,
        };

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

    var buffer3 = try allocator.alloc(u8, max_len);
    defer allocator.free(buffer3);

    var it1 = word_set.keyIterator();
    while (it1.next()) |word| {
        if (word.len > 8) {
            var len: usize = 0;
            var it2 = std.mem.window(u8, word.*, 1, 2);
            while (it2.next()) |letter| : (len += 1)
                buffer3[len] = letter[0];

            const odd_word = buffer3[0..len];
            if (word_set.contains(odd_word)) {
                if (!odd_word_set.contains(odd_word))
                    try odd_word_set.putNoClobber(try allocator.dupe(u8, odd_word), {});
            }
        }
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    it1 = odd_word_set.keyIterator();
    while (it1.next()) |word|
        try stdout.print("{s}\n", .{word.*});

    try stdout.flush();
}

// Count all the words with a length greater than 4
// (minimum length for a odd word).
fn getWordCount(r: *std.Io.Reader, w: *std.Io.Writer) !u32 {
    var count: u32 = 1;
    while (0 != try r.streamDelimiterEnding(w, '\n')) : (_ = w.consumeAll()) {
        // consume the '\n' (or catch eof)
        _ = r.takeByte() catch |err| switch (err) {
            error.EndOfStream => {},
            else => |e| return e,
        };
        const word = w.buffered();
        if (word.len > 4)
            count += 1;
    }
    return count;
}
