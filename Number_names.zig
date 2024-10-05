// https://rosettacode.org/wiki/Number_names
// Translation of: Go
const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;

const print = std.debug.print;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([_]i64{ 12, 1048576, 9e18, -2, 0 }) |n| {
        const text = try spellInteger(allocator, n);
        defer allocator.free(text);
        print("{s}\n", .{text});
    }
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
    pub fn spellCardinal(allocator: mem.Allocator, words: []const WordType) ![]u8 {
        const len = WordType.getLength(words);

        var result = try std.ArrayList(u8).initCapacity(allocator, len);
        for (words) |word_type| {
            switch (word_type) {
                .negative => try result.appendSlice(negative),
                .separator => |c| try result.append(c),
                .small => |index| try result.appendSlice(small[index]),
                .tens => |index| try result.appendSlice(tens[index]),
                .hundred => try result.appendSlice(hundred),
                .millions => |index| try result.appendSlice(millions[index]),
            }
        }
        return result.toOwnedSlice();
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
fn spellInteger(allocator: mem.Allocator, n_: i64) ![]const u8 {
    const words = try parseInteger(allocator, n_);
    defer allocator.free(words);

    return WordType.spellCardinal(allocator, words);
}

/// This function is also imported by Spelling_of_ordinal_numbers.zig
pub fn parseInteger(allocator: mem.Allocator, n_: i64) ![]const WordType {
    var t = std.ArrayList(WordType).init(allocator);
    if (n_ < 0)
        try t.append(WordType.negative);

    var n: u64 = if (n_ >= 0) @as(u64, @bitCast(n_)) else if (n_ != math.minInt(i64)) @as(u64, @bitCast(-n_)) else comptime (math.maxInt(u64) >> 1) + 1;

    switch (n) {
        0...19 => try t.append(WordType{ .small = n }),
        20...99 => {
            try t.append(WordType{ .tens = n / 10 });
            const s = n % 10;
            if (s > 0) {
                try t.append(WordType{ .separator = '-' });
                try t.append(WordType{ .small = s });
            }
        },
        100...999 => {
            try t.append(WordType{ .small = n / 100 });
            try t.append(WordType{ .hundred = {} });
            const s = n % 100;
            if (s > 0) {
                try t.append(WordType{ .separator = ' ' });
                const text = try parseInteger(allocator, @intCast(s));
                defer allocator.free(text);
                try t.appendSlice(text);
            }
        },
        else => {
            // work right-to-left
            var sx = std.ArrayList(WordType).init(allocator);
            // defer sx.deinit(); // toOwnedSlice()

            var i: usize = 0;
            while (n != 0) : (i += 1) {
                const p = n % 1000;
                n /= 1000;
                if (p != 0) {
                    const text1 = try parseInteger(allocator, @intCast(p));
                    defer allocator.free(text1);

                    var ix = std.ArrayList(WordType).init(allocator);
                    // defer ix.deinit(); // swapped with empty ArrayList

                    try ix.appendSlice(text1);
                    if (millions[i].len != 0)
                        try ix.append(WordType{ .millions = i });
                    if (sx.items.len != 0) {
                        try ix.append(WordType{ .separator = ' ' });
                        const text2 = try sx.toOwnedSlice();
                        defer allocator.free(text2);

                        try ix.appendSlice(text2);
                    }
                    // sx is empty ie. sx.items.len == 0
                    // ix contains text
                    mem.swap(std.ArrayList(WordType), &sx, &ix);
                }
            }
            const words = try sx.toOwnedSlice();
            defer allocator.free(words);

            try t.appendSlice(words); // t may already contain "negative "
        },
    }
    return t.toOwnedSlice();
}
