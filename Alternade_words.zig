// https://rosettacode.org/wiki/Alternade_words
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const filename = "data/unixdict.txt";
    const text = @embedFile(filename);

    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------- set of words
    var words: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer words.deinit(allocator);
    {
        try words.ensureTotalCapacity(allocator, std.mem.count(u8, text, "\n") + 1);

        var it = std.mem.splitSequence(u8, text, "\n");
        while (it.next()) |word|
            try words.put(allocator, word, {});
    }
    // ----------------------------------------------------
    var count: u32 = 0;

    var w1: std.ArrayList(u8) = .empty;
    var w2: std.ArrayList(u8) = .empty;
    defer w1.deinit(allocator);
    defer w2.deinit(allocator);

    try stdout.print("\"{s}\" contains the following alternades of length 6 or more:\n", .{filename});

    for (words.keys()) |word| {
        if (word.len < 6)
            continue;
        w1.clearRetainingCapacity();
        w2.clearRetainingCapacity();
        for (word, 0..) |c, i|
            if (i % 2 == 0)
                try w1.append(allocator, c)
            else
                try w2.append(allocator, c);

        if (words.get(w1.items) != null and words.get(w2.items) != null) {
            count += 1;
            try stdout.print("{d:2}: {s:<8} -> {s:<4} {s:<4}\n", .{ count, word, w1.items, w2.items });
        }
    }

    try stdout.flush();
}
