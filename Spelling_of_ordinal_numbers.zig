// https://rosettacode.org/wiki/Spelling_of_ordinal_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

const number_names = @import("Number_names.zig");
const WordType = number_names.WordType;
const parseInteger = number_names.parseInteger;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([_]i64{ 1, 2, 3, 4, 5, 11, 65, 100, 101, 272, 23456, 8_007_006_005_004_003 }) |n| {
        const text = try spellOrdinal(allocator, n);
        defer allocator.free(text);
        print("{s}\n", .{text});
    }
}

const irregular_ordinals = [20]?[]const u8{
    null,    "first", "second",  "third",  null,
    "fifth", null,    null,      "eighth", "ninth",
    null,    null,    "twelfth", null,     null,
    null,    null,    null,      null,     null,
};

/// Refer spellInteger() in Number_names.zig for documentation.
/// Caller owns returned slice memory.
fn spellOrdinal(allocator: std.mem.Allocator, n: i64) ![]u8 {
    const words = try parseInteger(allocator, n);
    defer allocator.free(words);
    assert(words.len != 0);

    const last_word = words.len - 1;

    const text = try WordType.spellCardinal(allocator, words[0..last_word]);

    // Allow for extra 3 bytes i.e. replacing 'twenty' with 'twentieth' or 'two' with 'second'
    var result: std.ArrayList(u8) = try .initCapacity(allocator, WordType.getLength(words) + 3);
    try result.appendSlice(allocator, text);

    allocator.free(text);

    switch (words[last_word]) {
        .negative => unreachable,
        .separator => unreachable,
        .small => |index| {
            if (irregular_ordinals[index]) |ordinal|
                try result.appendSlice(allocator, ordinal)
            else {
                try result.appendSlice(allocator, number_names.small[index]);
                try result.appendSlice(allocator, "th");
            }
        },
        .tens => |index| {
            const tens = number_names.tens[index];
            assert(tens.len != 0);
            assert(tens[tens.len - 1] == 'y');
            try result.appendSlice(allocator, tens[0 .. tens.len - 1]);
            try result.appendSlice(allocator, "ieth");
        },
        .hundred => {
            try result.appendSlice(allocator, number_names.hundred);
            try result.appendSlice(allocator, "th");
        },
        .millions => |index| {
            const millions = number_names.millions[index];
            assert(millions.len != 0);
            try result.appendSlice(allocator, millions);
            try result.appendSlice(allocator, "th");
        },
    }
    return result.toOwnedSlice(allocator);
}
