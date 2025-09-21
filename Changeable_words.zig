// https://rosettacode.org/wiki/Changeable_words
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");

pub fn main() !void {
    const filename = "data/unixdict.txt";
    const data = @embedFile(filename);

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var words: std.ArrayList([]const u8) = .empty;
    defer words.deinit(allocator);

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |word|
        if (word.len > 11)
            try words.append(allocator, word);

    var n: usize = 0;
    try stdout.print("Changeable words in {s}:\n", .{filename});
    for (words.items[0 .. words.items.len - 1]) |str1|
        for (words.items[1..]) |str2|
            if (isHammingDistanceOne(str1, str2)) {
                n += 1;
                try stdout.print("{d:2}: {s:>14} -> {s}\n", .{ n, str1, str2 });
            };

    try stdout.flush();
}

/// Return true only if the Hamming distance is 1
fn isHammingDistanceOne(str1: []const u8, str2: []const u8) bool {
    if (str1.len != str2.len)
        return false; // Dissimilar lengths, no Hamming distance

    var found = false;
    for (str1, str2) |c1, c2| {
        if (c1 != c2) {
            if (found)
                return false; // Hamming distance > one
            found = true;
        }
    }
    return found; // Hamming distance is zero or one
}
