// https://rosettacode.org/wiki/Playfair_cipher
// {{works with|Zig|0.15.1}}
// {{trans|Nim}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const key = "playfair example";
    const text = "Hide the gold...in the TREESTUMP!!!";

    var pf: Playfair = try .init(allocator, key, .use_ji_merge);

    const pairs = try pf.encode(text);
    defer allocator.free(pairs);

    // print encoded pairs here as they will be mutated in pf.decode()
    try stdout.print("Encoded message:", .{});
    try printPairs(pairs, stdout);
    try stdout.writeByte('\n');

    pf.decode(pairs);

    try stdout.print("Decoded message:", .{});
    try printPairs(pairs, stdout);
    try stdout.writeByte('\n');

    try stdout.flush();
}

const PlayfairJIQ = enum {
    use_ji_merge,
    use_q_removal,
};

const Point = struct { x: u4, y: u4 };
const Pair = struct { u8, u8 };

fn makePairsFromText(allocator: std.mem.Allocator, text: []const u8) ![]Pair {
    std.debug.assert(text.len % 2 == 0);
    const pairs = try allocator.alloc(Pair, text.len / 2);
    for (pairs, 0..) |*pair, i| {
        pair[0] = text[i * 2];
        pair[1] = text[i * 2 + 1];
    }
    return pairs;
}

fn printPairs(pairs: []const Pair, w: *std.Io.Writer) !void {
    for (pairs) |pair|
        try w.print(" {c}{c}", .{ pair[0], pair[1] });
}

const Playfair = struct {
    allocator: std.mem.Allocator,
    jiq: PlayfairJIQ,
    table: [5][5]u8,
    positions: [26]Point,

    // replacement characters
    const repl1: u8 = 'X';
    const repl2: u8 = 'Z';

    fn init(allocator: std.mem.Allocator, key: []const u8, jiq: PlayfairJIQ) !Playfair {
        var playfair: Playfair = .{
            .allocator = allocator,
            .jiq = jiq,
            .table = undefined,
            .positions = undefined,
        };

        const table_chars = try playfair.getTableChars(key);
        std.debug.assert(table_chars.len == 25);

        // Create the table and positions lookup.
        for (0..5) |row|
            for (0..5) |col| {
                const c = table_chars[row * 5 + col];
                playfair.table[row][col] = c;
                playfair.positions[c - 'A'] = .{
                    .x = @truncate(col),
                    .y = @truncate(row),
                };
            };
        return playfair;
    }

    /// Get the 25 characters for the Polybius square.
    fn getTableChars(self: *const Playfair, key: []const u8) ![25]u8 {
        var array: std.ArrayList(u8) = try .initCapacity(self.allocator, key.len + 26);
        try array.appendSlice(self.allocator, key);
        try array.appendSlice(self.allocator, "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        const raw_table_text = try array.toOwnedSlice(self.allocator);
        defer self.allocator.free(raw_table_text);

        // Assumes input consists only of upper case A-Z
        // Either remove Q or replace J with I to give 25 letters.
        // Remove trailing duplicate letters.
        var bits: u26 = 0;
        // 25 character array for creating Polybius table
        var table_text: [25]u8 = undefined;
        var n: usize = 0;
        for (raw_table_text) |c| {
            if (std.ascii.isAlphabetic(c)) {
                var next_char = std.ascii.toUpper(c);
                switch (self.jiq) {
                    .use_q_removal => if (next_char == 'Q') {
                        continue;
                    },
                    .use_ji_merge => if (next_char == 'J') {
                        next_char = 'I';
                    },
                }
                const bit = @as(u26, 1) << @intCast(next_char - 'A');
                if (bits & bit == 0) {
                    bits |= bit;
                    table_text[n] = next_char;
                    n += 1;
                }
            }
        }
        std.debug.assert(n == 25);
        return table_text;
    }

    /// Takes plain text for messages and produces text for encryption.
    /// Remove anything the is not a letter.
    /// Convert all letters to upper case.
    /// Perform ''Q' removal or I'/'J' substitution dependent on variable `jiq`
    /// The caller owns the returned slice.
    fn getCleanText(self: *const Playfair, plain_text: []const u8) ![]u8 {
        var clean_text: std.ArrayList(u8) = .empty;
        var prev_char: ?u8 = null;
        for (plain_text) |c| {
            if (std.ascii.isAlphabetic(c)) {
                var next_char = std.ascii.toUpper(c);
                switch (self.jiq) {
                    .use_q_removal => if (next_char == 'Q') {
                        continue;
                    },
                    .use_ji_merge => if (next_char == 'J') {
                        next_char = 'I';
                    },
                }
                const len = clean_text.items.len;
                if (prev_char == null or next_char != prev_char.? or len % 2 == 0)
                    try clean_text.append(self.allocator, next_char)
                else if (prev_char != repl1)
                    try clean_text.append(self.allocator, repl1)
                else
                    try clean_text.append(self.allocator, repl2);

                prev_char = next_char;
            }
        }
        const len = clean_text.items.len;
        if (len % 2 != 0) {
            if (clean_text.items[len - 1] != repl1)
                try clean_text.append(self.allocator, repl1)
            else
                try clean_text.append(self.allocator, repl2);
        }
        return try clean_text.toOwnedSlice(self.allocator);
    }

    /// Caller owns returned slice.
    fn encode(self: *const Playfair, plain_text: []const u8) ![]Pair {
        const clean_text = try self.getCleanText(plain_text);
        defer self.allocator.free(clean_text);

        const pairs = try makePairsFromText(self.allocator, clean_text);
        self.codec(pairs, 1);
        return pairs;
    }

    /// Modify pairs in place.
    fn decode(self: *Playfair, pairs: []Pair) void {
        self.codec(pairs, 4);
    }

    /// Modify pairs in place.
    fn codec(self: *const Playfair, pairs: []Pair, direction: u4) void {
        for (pairs) |*pair| {
            const a = pair[0];
            const b = pair[1];

            var row1 = self.positions[a - 'A'].y;
            var row2 = self.positions[b - 'A'].y;
            var col1 = self.positions[a - 'A'].x;
            var col2 = self.positions[b - 'A'].x;

            if (row1 == row2) {
                col1 = (col1 + direction) % 5;
                col2 = (col2 + direction) % 5;
            } else if (col1 == col2) {
                row1 = (row1 + direction) % 5;
                row2 = (row2 + direction) % 5;
            } else {
                std.mem.swap(u4, &col1, &col2);
            }

            pair[0] = self.table[row1][col1];
            pair[1] = self.table[row2][col2];
        }
    }
};

const testing = std.testing;

test "playfair cypher prepareText() use_ji_merge" {
    // this is how the key is used in creating the polybius square
    const key = "playfair example";
    const expected = "PLAYFIREXMBCDGHKNOQSTUVWZ";

    const pf = Playfair{
        .allocator = testing.allocator,
        .jiq = .use_ji_merge,
        .table = undefined,
        .positions = undefined,
    };

    const actual: [25]u8 = try pf.getTableChars(key);

    try testing.expectEqual(25, actual.len);
    try testing.expectEqualStrings(expected[0..expected.len], actual[0..actual.len]);
}

// For testGetCleanText()
const data1 = [_][2][]const u8{
    .{ "", "" },
    .{ " ", "" },
    .{ "   ", "" },
    .{ " abc ", "ABCX" },
    .{ " abcdxx ", "ABCDXZ" },
    .{ " abcxx ", "ABCXXZ" },
    .{ "ABC", "ABCX" },
    .{ "abc?!.def", "ABCDEF" },
    .{ "ABCDEFABCDEF", "ABCDEFABCDEF" },
    .{ "AABBCCDDEEFF", "AXBXCXDXEXFX" },
    .{ "zxyyxz!!", "ZXYXXZ" },
    .{ "zxyxxz!!", "ZXYXXZ" },
};

fn testGetCleanText(s: []const u8, expected: []const u8, jiq: PlayfairJIQ) !void {
    const pf = Playfair{
        .allocator = testing.allocator,
        .jiq = jiq,
        .table = undefined,
        .positions = undefined,
    };

    const text = try pf.getCleanText(s);
    defer testing.allocator.free(text);

    try testing.expectEqualStrings(expected, text);
}

test "playfair cypher getCleanText() use_ji_merge" {
    const data2 = [_][2][]const u8{
        .{ "jJ", "IX" },
        .{ "Jj", "IX" },
        .{ "Jjj", "IXIX" },
        .{ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "ABCDEFGHIXKLMNOPQRSTUVWXYZ" },
        .{ "abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIXKLMNOPQRSTUVWXYZ" },
    };
    for (data1 ++ data2) |line| {
        const s, const expected = line;
        try testGetCleanText(s, expected, .use_ji_merge);
    }
}

test "playfair cypher getCleanText() use_q_removal" {
    const data2 = [_][2][]const u8{
        .{ "qQ", "" },
        .{ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "ABCDEFGHIJKLMNOPRSTUVWXYZX" },
        .{ "abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPRSTUVWXYZX" },
    };
    for (data1 ++ data2) |line| {
        const s, const expected = line;
        try testGetCleanText(s, expected, .use_q_removal);
    }
}

test makePairsFromText {
    const text = "ABCDEF";
    const expected = &[3]Pair{ .{ 'A', 'B' }, .{ 'C', 'D' }, .{ 'E', 'F' } };

    const pairs = try makePairsFromText(testing.allocator, text);
    defer testing.allocator.free(pairs);

    try testing.expectEqualSlices(Pair, expected, pairs);
}
