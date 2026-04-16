// https://rosettacode.org/wiki/Odd_words
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    var stdout = &stdout_writer.interface;

    var file: Io.File = try Io.Dir.cwd().openFile(io, "data/unixdict.txt", .{});
    defer file.close(io);

    const file_size = (try file.stat(io)).size;
    const unixdict_txt = try gpa.alloc(u8, file_size);
    defer gpa.free(unixdict_txt);

    var buffer: [4096]u8 = undefined;
    var file_reader = file.reader(io, &buffer);
    const r = &file_reader.interface;
    try r.readSliceAll(unixdict_txt);

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
    var word_set: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer word_set.deinit(gpa);
    try word_set.ensureTotalCapacity(gpa, lf_count);
    var longest_word: usize = 0;

    // fill word_set with contents of "unixdict.txt"
    var it = std.mem.splitScalar(u8, unixdict_txt, '\n');
    while (it.next()) |word| {
        if (word.len != 0) {
            try word_set.putNoClobber(gpa, word, {});
            longest_word = @max(longest_word, word.len);
        }
    }

    var odd_word_buffer = try gpa.alloc(u8, longest_word / 2);
    defer gpa.free(odd_word_buffer);

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
                try stdout.print("{s:10} {s}\n", .{ word, odd_word });
        }
    }
    try stdout.flush();
}
