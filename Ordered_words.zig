// https://rosettacode.org/wiki/Ordered_words
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");

    // allocator ------------------------------------------
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ordered word list ----------------------------------
    var words: std.ArrayList([]const u8) = .empty;
    defer words.deinit(allocator);

    // find ordered words of longest length ---------------
    var maxlen: usize = 0;
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        const len = word.len;
        if (len >= maxlen and isOrdered(word)) {
            if (len > maxlen) {
                maxlen = len;
                words.clearRetainingCapacity();
            }
            try words.append(allocator, word);
        }
    }

    const list = try words.toOwnedSlice(allocator);
    defer allocator.free(list);

    try printWords(list);
}

fn isOrdered(word: []const u8) bool {
    if (word.len < 2)
        return true;
    for (word[0 .. word.len - 1], word[1..word.len]) |a, b|
        if (a > b)
            return false;
    return true;
}

fn printWords(words: [][]const u8) !void {
    // buffered stdout ------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------

    var sep: []const u8 = "";
    for (words) |word| {
        try stdout.print("{s}{s}", .{ sep, word });
        sep = " ";
    }
    try stdout.writeByte('\n');

    // flush buffered stdout ------------------------------
    try stdout.flush();
}
