// https://rosettacode.org/wiki/Ordered_words
// {{works with|Zig|0.16.0}}
const std = @import("std");

const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    const text = @embedFile("data/unixdict.txt");

    // ordered word list ----------------------------------
    var words: std.ArrayList([]const u8) = .empty;
    defer words.deinit(gpa);

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
            try words.append(gpa, word);
        }
    }

    const list = try words.toOwnedSlice(gpa);
    defer gpa.free(list);

    try printWords(list, io);
}

fn isOrdered(word: []const u8) bool {
    if (word.len < 2)
        return true;
    for (word[0 .. word.len - 1], word[1..word.len]) |a, b|
        if (a > b)
            return false;
    return true;
}

fn printWords(words: [][]const u8, io: Io) !void {
    // buffered stdout ------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
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
