// https://rosettacode.org/wiki/Markov_chain_text_generator
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    const text = @embedFile("data/alice_oz.txt");

    const result = try markov(allocator, random, text, 3, 300);
    defer allocator.free(result);
    std.debug.print("{s}\n", .{result});
}

fn markov(allocator: std.mem.Allocator, random: std.Random, text: []const u8, key_size: usize, output_size: usize) ![]const u8 {
    if (key_size < 1)
        return error.KeySizeInvalid;
    // -------------------------------------------- words in text
    const words = blk: {
        var words_list: std.ArrayList([]const u8) = .empty;
        var it = std.mem.tokenizeAny(u8, text, "\r\n\t ");
        while (it.next()) |word|
            try words_list.append(allocator, word);
        break :blk try words_list.toOwnedSlice(allocator);
    };
    defer allocator.free(words);
    if (words.len < key_size or words.len < output_size)
        return error.OutputSizeOutOfRange;
    // --------------------------------- prefix/suffix dictionary
    var dict: std.StringArrayHashMapUnmanaged(std.ArrayList([]const u8)) = .empty;
    defer {
        var it = dict.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.items) |s|
                allocator.free(s);
            entry.value_ptr.deinit(allocator);
        }
        dict.deinit(allocator);
    }
    for (0..words.len - key_size) |i| {
        const key = try std.mem.join(allocator, " ", words[i .. i + key_size]);
        const suffix: []const u8 = if (i + key_size < words.len) words[i + key_size] else "";
        var gop = try dict.getOrPut(allocator, key);
        if (gop.found_existing)
            allocator.free(key)
        else
            gop.value_ptr.* = .empty;
        try gop.value_ptr.append(allocator, try allocator.dupe(u8, suffix));
    }
    // ----------------------------------------------------------
    var output: std.ArrayList([]const u8) = .empty;
    defer output.deinit(allocator);
    var prefix = dict.keys()[random.uintLessThan(usize, dict.keys().len)];
    var it = std.mem.tokenizeScalar(u8, prefix, ' ');
    while (it.next()) |word|
        try output.append(allocator, word);

    prefix = try allocator.dupe(u8, prefix); // free'd/alloc'd in while() loop
    defer allocator.free(prefix);

    var n: usize = 0;
    while (true) {
        const suffixes = dict.get(prefix).?;
        if (suffixes.items.len == 0)
            break
        else {
            const next_word = suffixes.items[random.uintLessThan(usize, suffixes.items.len)];
            try output.append(allocator, next_word);
        }
        if (output.items.len >= output_size)
            break;
        n += 1;
        allocator.free(prefix);
        prefix = try std.mem.join(allocator, " ", output.items[n .. n + key_size]);
    }
    return try std.mem.join(allocator, " ", output.items[0..output_size]);
}
