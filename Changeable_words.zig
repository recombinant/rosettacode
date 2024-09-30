// https://rosettacode.org/wiki/Changeable_words
// Translation of Wren
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    const filename = "data/unixdict.txt";
    const data = @embedFile(filename);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var words = std.ArrayList([]const u8).init(allocator);
    defer words.deinit();

    var it = mem.splitScalar(u8, data, '\n');
    while (it.next()) |word|
        if (word.len > 11)
            try words.append(word);

    var n: usize = 0;
    print("Changeable words in {s}:\n", .{filename});
    for (words.items[0 .. words.items.len - 1]) |str1|
        for (words.items[1..]) |str2|
            if (isHammingDistanceOne(str1, str2)) {
                n += 1;
                print("{d:2}: {s:>14} -> {s}\n", .{ n, str1, str2 });
            };
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
