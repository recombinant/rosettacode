// https://rosettacode.org/wiki/Word_frequency
// {{works with|Zig|0.16.0}}
const std = @import("std");

const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    const n_most_common = 10;

    const text_mixed = @embedFile("data/Les Misérables from Project Gutenberg.txt");
    const text = try std.ascii.allocLowerString(gpa, text_mixed);
    defer gpa.free(text);

    var map: std.StringArrayHashMapUnmanaged(u32) = .empty;
    defer map.deinit(gpa);

    var word_it: WordIterator = .init(text);
    while (word_it.next()) |word| {
        const gop = try map.getOrPut(gpa, word);
        if (gop.found_existing)
            gop.value_ptr.* += 1
        else
            gop.value_ptr.* = 0;
    }

    const counts = try gpa.alloc(u32, map.values().len);
    defer gpa.free(counts);
    @memcpy(counts, map.values());
    std.mem.sortUnstable(u32, counts, {}, std.sort.desc(u32));

    const n = @min(n_most_common, counts.len);
    if (n == 0) return;

    const KV = struct {
        const Self = @This();

        key: []const u8,
        value: u32,

        fn greaterThanFn(_: void, lhs: Self, rhs: Self) bool {
            return lhs.value > rhs.value;
        }
    };

    var most_common: std.ArrayList(KV) = .empty;
    defer most_common.deinit(gpa);

    const limit = counts[n - 1];
    var kv_it = map.iterator();
    while (kv_it.next()) |entry| {
        if (entry.value_ptr.* >= limit)
            try most_common.append(gpa, KV{ .key = entry.key_ptr.*, .value = entry.value_ptr.* });
    }

    std.mem.sortUnstable(KV, most_common.items, {}, KV.greaterThanFn);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (most_common.items, 1..) |kv, i|
        try stdout.print("{d:2}) {s}: {d}\n", .{ i, kv.key, kv.value });

    try stdout.flush();
}

// As there is no regex in the Zig Standard Library (as of Zig 0.12)
const WordIterator = struct {
    text: []const u8,
    start: usize = 0,
    end: usize = 0,

    fn init(text: []const u8) WordIterator {
        return WordIterator{ .text = text };
    }

    fn next(self: *WordIterator) ?[]const u8 {
        if (self.start >= self.text.len)
            return null;

        self.start = self.end;
        while (self.start < self.text.len and !std.ascii.isLower(self.text[self.start]))
            self.start += 1;
        self.end = self.start + 1;
        if (self.start >= self.text.len)
            return null;

        while (self.end < self.text.len and std.ascii.isLower(self.text[self.end]))
            self.end += 1;
        return self.text[self.start..self.end];
    }
};

const testing = std.testing;

test "WordIterator0" {
    const text = "";

    var it: WordIterator = .init(text);
    try testing.expectEqual(null, it.next());
}

test "WordIterator1" {
    const text = "hello";

    var it: WordIterator = .init(text);
    try testing.expectEqualStrings("hello", it.next().?);
    try testing.expectEqual(null, it.next());
}

test "WordIterator2" {
    const text = "hello world ";

    var it: WordIterator = .init(text);
    try testing.expectEqualStrings("hello", it.next().?);
    try testing.expectEqualStrings("world", it.next().?);
    try testing.expectEqual(null, it.next());
}

test "WordIterator3" {
    const text = " hello world ";

    var it: WordIterator = .init(text);
    try testing.expectEqualStrings("hello", it.next().?);
    try testing.expectEqualStrings("world", it.next().?);
    try testing.expectEqual(null, it.next());
}

test "WordIterator4" {
    const text = "1234";

    var it: WordIterator = .init(text);
    try testing.expectEqual(null, it.next());
}
