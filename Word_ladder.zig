// https://www.rosettacode.org/wiki/Word_ladder
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

const WordArray = std.ArrayList([]const u8);

const unixdict = @embedFile("data/unixdict.txt");

pub fn main() !void {
    //
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    //
    const word_count = blk: {
        var word_count: usize = 0;
        var it = std.mem.tokenizeScalar(u8, unixdict, '\n');
        while (it.next()) |_|
            word_count += 1;
        break :blk word_count;
    };
    var word_array: WordArray = try .initCapacity(allocator, word_count);

    var it = std.mem.tokenizeScalar(u8, unixdict, '\n');
    while (it.next()) |word|
        try word_array.append(allocator, word);

    const words = try word_array.toOwnedSlice(allocator);
    defer allocator.free(words);

    const pairs = [_]struct { a: []const u8, b: []const u8 }{
        .{ .a = "boy", .b = "man" },
        .{ .a = "girl", .b = "lady" },
        .{ .a = "john", .b = "jane" },
        .{ .a = "alien", .b = "drool" },
        .{ .a = "child", .b = "adult" },
    };
    for (pairs) |pair|
        try wordLadder(allocator, words, pair.a, pair.b, stdout);
    try stdout.flush();
}

fn wordLadder(allocator: std.mem.Allocator, words: []const []const u8, a: []const u8, b: []const u8, w: *std.Io.Writer) !void {
    var possible: WordArray = .empty;
    defer possible.deinit(allocator);
    for (words) |word|
        if (word.len == a.len)
            try possible.append(allocator, word);

    var todo: std.ArrayList(WordArray) = .empty;
    defer {
        for (todo.items) |*array|
            array.deinit(allocator);
        todo.deinit(allocator);
    }
    {
        var temp: WordArray = .empty;
        try temp.append(allocator, a);
        try todo.append(allocator, temp);
    }

    while (todo.items.len > 0) {
        var current: WordArray = todo.orderedRemove(0);
        defer current.deinit(allocator);

        var next: WordArray = .empty;
        defer next.deinit(allocator);
        for (possible.items) |word|
            if (oneAway(word, current.items[current.items.len - 1]))
                try next.append(allocator, word);

        if (contains(next.items, b)) {
            try current.append(allocator, b);
            const result = try std.mem.join(allocator, " → ", current.items);
            defer allocator.free(result);
            try w.print("{s}\n\n", .{result});
            return;
        }

        var i = possible.items.len;
        while (i != 0) {
            i -= 1;
            if (contains(next.items, possible.items[i]))
                _ = possible.orderedRemove(i);
        }

        for (next.items) |word| {
            var temp = try current.clone(allocator);
            try temp.append(allocator, word);
            try todo.append(allocator, temp);
        }
    }
    try w.print("{s} into {s} cannot be done.\n\n", .{ a, b });
}

fn contains(words: []const []const u8, string: []const u8) bool {
    for (words) |word|
        if (std.mem.eql(u8, word, string))
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

const testing = std.testing;

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
