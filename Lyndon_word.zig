// https://rosettacode.org/wiki/Lyndon_word
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var lyndon_words: LyndonWords = try .init(allocator, 5, "01");
    defer lyndon_words.deinit();

    while (try lyndon_words.next()) |word| {
        try stdout.print("{s}\n", .{word});
        allocator.free(word);
    }

    try stdout.flush();
}

const LyndonWords = struct {
    allocator: std.mem.Allocator,
    n: usize,
    alphabet: []const u8,
    w: []const u8,

    fn init(allocator: std.mem.Allocator, n: usize, alphabet_: []const u8) !LyndonWords {
        const alphabet = try allocator.dupe(u8, alphabet_);
        std.sort.pdq(u8, alphabet, {}, std.sort.asc(u8));
        return LyndonWords{
            .allocator = allocator,
            .n = n,
            .alphabet = alphabet,
            .w = try allocator.dupe(u8, alphabet[0..1]),
        };
    }
    fn deinit(self: *LyndonWords) void {
        self.allocator.free(self.w);
        self.allocator.free(self.alphabet);
    }

    /// Allocates memory for the result, which must be freed by the caller.
    fn next(self: *LyndonWords) !?[]const u8 {
        if (self.w.len == 0)
            return null;
        const w = self.w;
        self.w = try nextLyndonWord_(self, w);
        return w;
    }

    /// Allocates memory for the result, which must be freed by the caller.
    /// https://en.wikipedia.org/wiki/Lyndon_word
    /// Duval (1988)
    fn nextLyndonWord_(self: *LyndonWords, w: []const u8) ![]const u8 {
        // 1. repeat w and truncate it to a word of length exactly n
        var a: std.ArrayList(u8) = .empty;
        defer a.deinit(self.allocator);
        while (a.items.len < self.n)
            try a.appendSlice(self.allocator, w);
        a.shrinkRetainingCapacity(self.n);

        // 2. as long as the final symbol of word is the last symbol in the
        //    sorted ordering of the alphabet, remove it, producing a shorter
        //    word.
        while (a.items.len != 0 and a.items[a.items.len - 1] == self.alphabet[self.alphabet.len - 1])
            _ = a.pop();
        if (a.items.len != 0) {
            const last_char = a.items[a.items.len - 1];
            const next_char_index = std.mem.indexOfScalar(u8, self.alphabet, last_char).?;
            const next_char = self.alphabet[next_char_index + 1];
            // 3. replace the final remaining symbol of word by its successor
            //    in the sorted ordering of the alphabet.
            _ = a.pop();
            try a.append(self.allocator, next_char);
        }
        return a.toOwnedSlice(self.allocator);
    }
};
