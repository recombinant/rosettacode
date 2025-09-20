// https://rosettacode.org/wiki/ABC_incremental_counts
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Assumes all lower case ASCII.
    const filenames: [2][]const u8 = .{ "data/unixdict.txt", "data/words_alpha.txt" };
    const text_array: [2][]const u8 = .{ @embedFile(filenames[0]), @embedFile(filenames[1]) };
    const min_counts_array: [2][]const usize = .{ &[_]usize{ 1, 1, 2 }, &[_]usize{ 2, 2, 3 } };
    const letters_array: [3][]const u8 = .{ "abc", "the", "cio" };

    for (filenames, text_array, min_counts_array) |filename, text, min_counts| {
        try stdout.print("Using {s}:\n\n", .{filename});

        for (letters_array, min_counts) |letters, min_count| {
            try stdout.writeAll("Letters: [");
            var separator: []const u8 = "";
            for (letters) |c| {
                try stdout.print("{s}{c}", .{ separator, c });
                separator = ", ";
            }
            try stdout.print("] --- Minimum count {d}\n", .{min_count});

            const result = try abcIncrementalCounts(allocator, text, letters, min_count);
            defer allocator.free(result);

            if (result.len == 0)
                try stdout.writeAll("--- no words ---\n")
            else {
                for (result) |word|
                    try stdout.print("{s}\n", .{word});
            }
            try stdout.writeByte('\n');
        }
    }
    try stdout.writeAll("\n--- le fin ---\n");

    try stdout.flush();
}

fn abcIncrementalCounts(allocator: std.mem.Allocator, text: []const u8, letters: []const u8, min_count: usize) ![][]const u8 {
    if (text.len == 0 or letters.len == 0)
        return allocator.alloc([]const u8, 0);

    var result: std.ArrayList([]const u8) = .empty;

    const counts = try allocator.alloc(usize, letters.len);
    defer allocator.free(counts);

    var it = std.mem.tokenizeScalar(u8, text, '\n');
    next_word: while (it.next()) |word| {
        if (word.len < letters.len) continue;

        @memset(counts, 0);

        for (letters, counts) |c, *count| {
            count.* = std.mem.count(u8, word, &[1]u8{c});
            if (count.* < min_count)
                continue :next_word;
        }
        for (counts) |count|
            if (count == 0)
                continue :next_word;

        if (counts.len > 1) {
            std.mem.sortUnstable(usize, counts, {}, std.sort.asc(usize));
            var value1 = counts[0];
            for (counts[1..]) |value2| {
                if (value1 + 1 != value2)
                    continue :next_word;
                value1 = value2;
            }
        }
        try result.append(allocator, word);
    }
    return try result.toOwnedSlice(allocator);
}
