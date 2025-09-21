// https://rosettacode.org/wiki/Number_names
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for ([_]i64{ 12, 1048576, 9e18, -2, 0 }) |n| {
        const text = try spellInteger(allocator, n);
        defer allocator.free(text);
        try stdout.print("{s}\n", .{text});
    }

    try stdout.flush();
}

const negative = "negative ";

pub const small = [20][]const u8{
    "zero",     "one",      "two",      "three",   "four",    "five",
    "six",      "seven",    "eight",    "nine",    "ten",     "eleven",
    "twelve",   "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
    "eighteen", "nineteen",
};
pub const tens = [10][]const u8{
    "",      "",      "twenty",  "thirty", "forty",
    "fifty", "sixty", "seventy", "eighty", "ninety",
};

pub const hundred = " hundred";

pub const millions = [_][]const u8{
    "",          " thousand",    " million",     " billion",
    " trillion", " quadrillion", " quintillion",
};

const WordTypeTag = enum {
    negative,
    separator,
    small,
    tens,
    hundred,
    millions,
};

pub const WordType = union(WordTypeTag) {
    negative: void,
    separator: u8,
    small: usize,
    tens: usize,
    hundred: void,
    millions: usize,

    /// Stringize array of tokens `words`.
    pub fn spellCardinal(allocator: std.mem.Allocator, words: []const WordType) ![]u8 {
        const len = WordType.getLength(words);

        var result: std.ArrayList(u8) = try .initCapacity(allocator, len);
        for (words) |word_type| {
            switch (word_type) {
                .negative => try result.appendSlice(allocator, negative),
                .separator => |c| try result.append(allocator, c),
                .small => |index| try result.appendSlice(allocator, small[index]),
                .tens => |index| try result.appendSlice(allocator, tens[index]),
                .hundred => try result.appendSlice(allocator, hundred),
                .millions => |index| try result.appendSlice(allocator, millions[index]),
            }
        }
        return result.toOwnedSlice(allocator);
    }

    /// Get the length array of tokens `words` when stringized.
    pub fn getLength(words: []const WordType) usize {
        var len: usize = 0;
        for (words) |word_type| {
            len += switch (word_type) {
                .negative => negative.len,
                .separator => 1,
                .small => |index| small[index].len,
                .tens => |index| tens[index].len,
                .hundred => hundred.len,
                .millions => |index| millions[index].len,
            };
        }
        return len;
    }
};

/// Supports integers in range math.minInt(i64) to math.maxInt(i64)
/// (which is a greater range than the Go solution - by one)
/// Caller owns returned slice memory.
fn spellInteger(allocator: std.mem.Allocator, n_: i64) ![]const u8 {
    const words = try parseInteger(allocator, n_);
    defer allocator.free(words);

    return WordType.spellCardinal(allocator, words);
}

/// This function is also imported by Spelling_of_ordinal_numbers.zig
pub fn parseInteger(allocator: std.mem.Allocator, n_: i64) ![]const WordType {
    var t: std.ArrayList(WordType) = .empty;
    if (n_ < 0)
        try t.append(allocator, WordType.negative);

    var n: u64 = if (n_ >= 0) @as(u64, @bitCast(n_)) else if (n_ != std.math.minInt(i64)) @as(u64, @bitCast(-n_)) else comptime (std.math.maxInt(u64) >> 1) + 1;

    switch (n) {
        0...19 => try t.append(allocator, WordType{ .small = n }),
        20...99 => {
            try t.append(allocator, WordType{ .tens = n / 10 });
            const s = n % 10;
            if (s > 0) {
                try t.append(allocator, WordType{ .separator = '-' });
                try t.append(allocator, WordType{ .small = s });
            }
        },
        100...999 => {
            try t.append(allocator, WordType{ .small = n / 100 });
            try t.append(allocator, WordType{ .hundred = {} });
            const s = n % 100;
            if (s > 0) {
                try t.append(allocator, WordType{ .separator = ' ' });
                const text = try parseInteger(allocator, @intCast(s));
                defer allocator.free(text);
                try t.appendSlice(allocator, text);
            }
        },
        else => {
            // work right-to-left
            var sx: std.ArrayList(WordType) = .empty;
            // defer sx.deinit(); // toOwnedSlice()

            var i: usize = 0;
            while (n != 0) : (i += 1) {
                const p = n % 1000;
                n /= 1000;
                if (p != 0) {
                    const text1 = try parseInteger(allocator, @intCast(p));
                    defer allocator.free(text1);

                    var ix: std.ArrayList(WordType) = .empty;
                    // defer ix.deinit(); // swapped with empty ArrayList

                    try ix.appendSlice(allocator, text1);
                    if (millions[i].len != 0)
                        try ix.append(allocator, WordType{ .millions = i });
                    if (sx.items.len != 0) {
                        try ix.append(allocator, WordType{ .separator = ' ' });
                        const text2 = try sx.toOwnedSlice(allocator);
                        defer allocator.free(text2);

                        try ix.appendSlice(allocator, text2);
                    }
                    // sx is empty ie. sx.items.len == 0
                    // ix contains text
                    std.mem.swap(std.ArrayList(WordType), &sx, &ix);
                }
            }
            const words = try sx.toOwnedSlice(allocator);
            defer allocator.free(words);

            try t.appendSlice(allocator, words); // t may already contain "negative "
        },
    }
    return t.toOwnedSlice(allocator);
}
