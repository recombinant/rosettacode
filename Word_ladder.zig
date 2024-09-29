// https://www.rosettacode.org/wiki/Word_ladder
// from Go
const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const unixdict = @embedFile("data/unixdict.txt");

const WordArray = std.ArrayList([]const u8);

pub fn main() !void {
    //
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    //
    const word_count = blk: {
        var word_count: usize = 0;
        var it = mem.tokenizeScalar(u8, unixdict, '\n');
        while (it.next()) |_|
            word_count += 1;
        break :blk word_count;
    };
    var word_array = try WordArray.initCapacity(allocator, word_count);

    var it = mem.tokenizeScalar(u8, unixdict, '\n');
    while (it.next()) |word|
        try word_array.append(word);

    const words = try word_array.toOwnedSlice();
    defer allocator.free(words);

    const pairs = [_]struct { a: []const u8, b: []const u8 }{
        .{ .a = "boy", .b = "man" },
        .{ .a = "girl", .b = "lady" },
        .{ .a = "john", .b = "jane" },
        .{ .a = "alien", .b = "drool" },
        .{ .a = "child", .b = "adult" },
    };
    for (pairs) |pair|
        try wordLadder(allocator, words, pair.a, pair.b);
}

fn wordLadder(allocator: mem.Allocator, words: []const []const u8, a: []const u8, b: []const u8) !void {
    const stdout = std.io.getStdOut().writer();

    var possible = WordArray.init(allocator);
    defer possible.deinit();
    for (words) |word|
        if (word.len == a.len)
            try possible.append(word);

    var todo = std.ArrayList(WordArray).init(allocator);
    defer {
        for (todo.items) |array|
            array.deinit();
        todo.deinit();
    }
    {
        var temp = WordArray.init(allocator);
        try temp.append(a);
        try todo.append(temp);
    }

    while (todo.items.len > 0) {
        var current: WordArray = todo.orderedRemove(0);
        defer current.deinit();

        var next = WordArray.init(allocator);
        defer next.deinit();
        for (possible.items) |word|
            if (oneAway(word, current.items[current.items.len - 1]))
                try next.append(word);

        if (contains(next.items, b)) {
            try current.append(b);
            const result = try mem.join(allocator, " -> ", current.items);
            defer allocator.free(result);
            try stdout.print("{s}\n", .{result});
            return;
        }

        var i = possible.items.len;
        while (i != 0) {
            i -= 1;
            if (contains(next.items, possible.items[i]))
                _ = possible.orderedRemove(i);
        }

        for (next.items) |word| {
            var temp = try current.clone();
            try temp.append(word);
            try todo.append(temp);
        }
    }
    try stdout.print("{s} into {s} cannot be done.\n", .{ a, b });
}

fn contains(words: []const []const u8, string: []const u8) bool {
    for (words) |word|
        if (mem.eql(u8, word, string))
            return true;
    return false;
}

fn oneAway(a: []const u8, b: []const u8) bool {
    var sum: usize = 0;
    if (a.len == b.len)
        for (a, b) |ch1, ch2|
            if (ch1 != ch2) {
                sum += 1;
            };
    return sum == 1;
}

test "one away" {
    try testing.expect(oneAway("bat", "cat"));
    try testing.expect(oneAway("bat", "but"));
    try testing.expect(oneAway("bat", "bar"));
    try testing.expect(!oneAway("cat", "bar"));
    try testing.expect(!oneAway("tub", "but"));
}

test "contains" {
    const slice = &[_][]const u8{ "alice", "bob", "charlie" };

    try testing.expect(contains(slice, "alice"));
    try testing.expect(contains(slice, "bob"));
    try testing.expect(contains(slice, "charlie"));
    try testing.expect(!contains(slice, "bo"));
    try testing.expect(!contains(slice, "eve"));
}
