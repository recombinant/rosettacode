// https://rosettacode.org/wiki/Semordnilap
// {{works with|Zig|0.15.1}}
const std = @import("std");
const print = std.debug.print;

const unixdict = @embedFile("data/unixdict.txt");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var word_count: usize = 0; // for word_lookup capacity
    {
        var it = std.mem.tokenizeScalar(u8, unixdict, '\n');
        while (it.next()) |_|
            word_count += 1;
    }
    // 'word' vs 'seen'
    var word_lookup: std.StringArrayHashMapUnmanaged(bool) = .empty;
    defer word_lookup.deinit(allocator);
    {
        try word_lookup.ensureUnusedCapacity(allocator, word_count);
        var it = std.mem.tokenizeScalar(u8, unixdict, '\n');
        while (it.next()) |word|
            _ = try word_lookup.getOrPutValue(allocator, word, true);
    }
    var palindromes: std.ArrayList([2][]const u8) = .empty;
    // palindromes.toOwnedSlice() obviates the need for palindromes.deinit();
    {
        // iterate all words in the dictionary
        var it = word_lookup.iterator();
        while (it.next()) |entry1| {
            // true if it has not been seen
            if (entry1.value_ptr.*) {
                // mark seen
                entry1.value_ptr.* = false;
                // reverse word to create palindrome
                const word = try allocator.dupe(u8, entry1.key_ptr.*);
                defer allocator.free(word);
                std.mem.reverse(u8, word);
                // is there the palindrome in lookup?
                const optional_entry2 = word_lookup.getEntry(word);
                if (optional_entry2) |entry2| {
                    // true if palindrome has not been seen
                    if (entry2.value_ptr.*) {
                        // mark palindrome seen
                        entry2.value_ptr.* = false;
                        try palindromes.append(allocator, .{ entry1.key_ptr.*, entry2.key_ptr.* });
                    }
                }
            }
        }
    }
    var pairs = try palindromes.toOwnedSlice(allocator);
    defer allocator.free(pairs);
    print("There are {d} unique semordnilap pairs in the dictionary.\n\n", .{pairs.len});

    // stable sort by length, shortest first.
    std.mem.sort([2][]const u8, pairs, {}, pairLengthCompare);

    // show the last five
    for (pairs[pairs.len - 5 ..]) |pair|
        print("{s} {s}\n", .{ pair[0], pair[1] });
}

/// Compare lengths of the first element in each palindrome pair.
fn pairLengthCompare(context: void, a: [2][]const u8, b: [2][]const u8) bool {
    _ = context;
    return a[0].len < b[0].len;
}
