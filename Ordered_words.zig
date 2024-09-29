// https://rosettacode.org/wiki/Ordered_words
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    const text = @embedFile("data/unixdict.txt");

    // allocator ------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ordered word list ----------------------------------
    var words = std.ArrayList([]const u8).init(allocator);
    defer words.deinit();

    // find ordered words of longest length ---------------
    var maxlen: usize = 0;
    var it = mem.splitScalar(u8, text, '\n');
    while (it.next()) |word| {
        const len = word.len;
        if (len >= maxlen and isOrdered(word)) {
            if (len > maxlen) {
                maxlen = len;
                words.clearRetainingCapacity();
            }
            try words.append(word);
        }
    }

    const list = try words.toOwnedSlice();
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
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    // ----------------------------------------------------

    var sep: []const u8 = "";
    for (words) |word| {
        try stdout.print("{s}{s}", .{ sep, word });
        sep = " ";
    }
    try stdout.writeByte('\n');

    // flush buffered stdout ------------------------------
    try bw.flush();
}
