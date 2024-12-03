// https://rosettacode.org/wiki/Isograms_and_heterograms

//! This task has been designed to limit the number of dynamic (heap)
//! allocations by performing lowercase string conversions just
//! before comparison or print and not keeping a lowercase copy
//! of any strings.
const std = @import("std");

pub fn main() !void {
    const data = @embedFile("data/unixdict.txt");
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var isogram_pairs_list = std.ArrayList(IsogramPair).init(allocator);
    defer isogram_pairs_list.deinit();

    var it = std.mem.tokenizeScalar(u8, data, '\n');
    outer: while (it.next()) |word| {
        std.debug.assert(word.len != 0);
        for (word) |c|
            if (!std.ascii.isAlphabetic(c))
                continue :outer;
        if (IsogramPair.init(word)) |isogram_pair|
            try isogram_pairs_list.append(isogram_pair);
    }
    const isogram_pairs = try isogram_pairs_list.toOwnedSlice();
    defer allocator.free(isogram_pairs);
    // The pairs are already in lexicographical order as they
    // came out of the dictionary. So use a stable sort to sort
    // by:
    // - decreasing n
    // - decreasing word length
    std.mem.sort(IsogramPair, isogram_pairs, {}, IsogramPair.descending);

    // for lowercase word, known max length is 22 in unixdict.txt
    var buffer: [22]u8 = undefined;

    const writer = std.io.getStdOut().writer();
    try writer.writeAll("n-isograms with n > 1:\n");

    var index: usize = 0;
    for (isogram_pairs) |isogram_pair| {
        if (isogram_pair.n > 1) {
            const text = lowerString(&buffer, isogram_pair.word);
            try writer.writeByte(' ');
            try writer.writeAll(text);
            try writer.writeByte('\n');
            index += 1;
        } else {
            break; // 1-isograms start at index
        }
    }
    const @"1-isograms" = isogram_pairs[index..];
    try writer.writeByte('\n');
    try writer.writeAll("Heterograms with more than 10 letters:\n");

    for (@"1-isograms") |isogram_pair| {
        std.debug.assert(isogram_pair.n == 1);
        if (isogram_pair.word.len > 10) {
            try writer.writeByte(' ');
            const text = lowerString(&buffer, isogram_pair.word);
            try writer.writeAll(text);
            try writer.writeByte('\n');
        }
    }
}

/// Adapted from std.ascii.lowerString knowing that all
/// characters are alphabetic.
fn lowerString(output: []u8, ascii_string: []const u8) []u8 {
    std.debug.assert(output.len >= ascii_string.len);
    for (ascii_string, 0..) |c, i| {
        output[i] = c | 0x20;
    }
    return output[0..ascii_string.len];
}

const IsogramPair = struct {
    n: usize,
    word: []const u8, // alphabetic, mixed case

    /// null means that `word` it is not an isogram.
    fn init(word: []const u8) ?IsogramPair {
        var letters = std.mem.zeroes([26]u5);
        for (word) |c|
            letters[(c | 0x20) - 'a'] += 1;
        var max_n: u5 = 0;
        for (letters) |n| {
            if (n != 0) {
                if (max_n == 0)
                    max_n = n
                else if (max_n != n)
                    return null;
            }
        }
        // Stores mixed case eliminating an extra alloc/free.
        // Can be converted to lowercase for print.
        return IsogramPair{ .n = max_n, .word = word };
    }

    /// 1. decreasing order of n
    /// 2. decreasing order of word length
    /// 3. skip step 3 (already ascending lexicographic order)
    fn descending(_: void, a: IsogramPair, b: IsogramPair) bool {
        return switch (std.math.order(a.n, b.n)) {
            .gt => true,
            .lt => false,
            .eq => switch (std.math.order(a.word.len, b.word.len)) {
                .gt => true,
                .eq, .lt => false,
            },
        };
    }
};

const testing = std.testing;
test "ascii case conversion" {
    try testing.expectEqual('A' | 0x20, 'a');
    try testing.expectEqual('a' | 0x20, 'a');
}

test lowerString {
    var buffer: [16]u8 = undefined;
    const string = "HelloWorld";
    const actual = lowerString(&buffer, string);
    try testing.expectEqualSlices(u8, "helloworld", actual);
}
