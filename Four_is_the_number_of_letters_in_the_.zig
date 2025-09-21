// https://rosettacode.org/wiki/Four_is_the_number_of_letters_in_the_...
// {{works with|Zig|0.15.1}}
// {{trans|C++}}

// Differs from the C++ inasmuch as the C++ implementation uses std::string
// (with associated allocation) whereas the Zig implementation uses
// Tagged Unions and comptime strings thus avoiding the extra allocation
// for each word, hyphen and comma.
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    {
        const n: usize = 201;
        const words = try getSentence(allocator, n);
        defer allocator.free(words);

        // const s = try stringifySentence(allocator, words);
        // defer allocator.free(s);
        // std.log.info("\"{s}\"", .{s});

        try stdout.print("Number of letters in first {} numbers in the sequence:\n", .{words.len});
        for (words, 0..) |word, i| {
            if (i != 0)
                try stdout.writeByte(if (i % 25 == 0) '\n' else ' ');
            try stdout.print("{d:2}", .{word.countLetters()});
        }
        try stdout.writeByte('\n');
        try stdout.print("Sentence length: {} characters\n\n", .{calcSentenceLength(words)});
        try stdout.flush();
    }
    {
        var n: usize = 1_000;
        while (n <= 10_000_000) : (n *= 10) {
            const words = try getSentence(allocator, n);
            defer allocator.free(words);
            const word = try words[n - 1].asString(allocator);
            defer allocator.free(word);
            try stdout.print("The {}th word is '{s}' and has {} letters. ", .{ n, word, words[n - 1].countLetters() });
            try stdout.print("Sentence length: {} characters\n", .{calcSentenceLength(words)});
        }
        try stdout.flush();
    }
}

const Sentence = []const Word;

/// Allocates memory for the result, which must be freed by the caller.
fn getSentence(allocator: std.mem.Allocator, count: usize) !Sentence {
    const words = [_][]const u8{
        "Four",    "is",   "the",      "number", "of",
        "letters", "in",   "the",      "first",  "word",
        "of",      "this", "sentence",
    };
    var result: std.ArrayList(Word) = .empty;
    defer result.deinit(allocator);

    if (count != 0) {
        // up to and including the first comma
        for (words, 1..) |letters, i| {
            if (i != words.len)
                try result.append(allocator, Word{ .word = letters })
            else
                try result.append(allocator, Word{ .word_comma = letters });
        }
        var n: usize = result.items.len;

        var word_index: usize = 1;
        while (count > n) : (word_index += 1) {
            n += try appendNumberName(&result, allocator, result.items[word_index].countLetters(), false);
            try result.append(allocator, .{ .word = "in" });
            try result.append(allocator, .{ .word = "the" });
            n += 2;
            n += try appendNumberName(&result, allocator, word_index + 1, true);
            const last = result.pop().?;
            switch (last) {
                .word => |word| try result.append(allocator, .{ .word_comma = word }),
                .word_hyphen => |pair| try result.append(allocator, .{ .word_hyphen_comma = pair }),
                else => unreachable,
            }
        }
    }
    return result.toOwnedSlice(allocator);
}
/// Sentence length includes all words, space and punctuation.
/// - hyphen words have a hyphen in the middle
/// - comma words have a trailing comma
/// - hyphen_comma words have a hyphen in the middle and a trailing comma
/// all words have a trailing space (except the last)
fn calcSentenceLength(words: Sentence) usize {
    var len: usize = 0;
    for (words) |word|
        len += switch (word) {
            .word => |letters| letters.len + 1,
            .word_hyphen => |pair| pair[0].len + pair[1].len + 2,
            .word_hyphen_comma => |pair| pair[0].len + pair[1].len + 3,
            .word_comma => |letters| letters.len + 2,
        };
    if (len != 0)
        len -= 1; // no trailing space
    return len;
}
/// Allocates memory for the result, which must be freed by the caller.
fn stringifySentence(allocator: std.mem.Allocator, words: Sentence) ![]const u8 {
    const sentence_length = calcSentenceLength(words);
    //
    var result: std.ArrayList(u8) = try .initCapacity(allocator, sentence_length);
    for (words, 0..) |word, i| {
        if (i != 0)
            try result.append(' ');
        switch (word) {
            .word => |letters| try result.appendSlice(letters),
            .word_hyphen => |pair| {
                try result.appendSlice(pair[0]);
                try result.append('-');
                try result.appendSlice(pair[1]);
            },
            .word_hyphen_comma => |pair| {
                try result.appendSlice(pair[0]);
                try result.append('-');
                try result.appendSlice(pair[1]);
                try result.append(',');
            },
            .word_comma => |letters| {
                try result.appendSlice(letters);
                try result.append(',');
            },
        }
    }
    return result.toOwnedSlice();
}

const WordTag = enum {
    word,
    word_hyphen,
    word_hyphen_comma,
    word_comma,
};
/// Some words are just words, some words have have hyphen in the middle,
/// other words have a trailing comma and a few words have both the hyphen
/// and a comma.
/// A tagged union eliminates allocator operations on strings to insert
/// a hyphen or add a comma.
const Word = union(WordTag) {
    word: []const u8,
    word_hyphen: [2][]const u8,
    word_hyphen_comma: [2][]const u8,
    word_comma: []const u8,

    fn countLetters(self: Word) usize {
        return switch (self) {
            .word, .word_comma => |letters| letters.len,
            .word_hyphen, .word_hyphen_comma => |pair| pair[0].len + pair[1].len,
        };
    }
    /// The word itself as a string.
    /// Allocates memory for the result, which must be freed by the caller.
    fn asString(self: Word, allocator: std.mem.Allocator) ![]const u8 {
        switch (self) {
            .word, .word_comma => |letters| {
                return try allocator.dupe(u8, letters);
            },
            .word_hyphen, .word_hyphen_comma => |pair| {
                // hyphen, but no comma
                return try std.mem.join(allocator, "", &[3][]const u8{ pair[0], "-", pair[1] });
            },
        }
    }
};

const NumberName = struct {
    cardinal: []const u8,
    ordinal: []const u8,

    fn init(cardinal: []const u8, ordinal: []const u8) NumberName {
        return .{ .cardinal = cardinal, .ordinal = ordinal };
    }
    fn getName(n: NumberName, ordinal: bool) []const u8 {
        return if (ordinal) n.ordinal else n.cardinal;
    }
};

const NamedNumber = struct {
    cardinal: []const u8,
    ordinal: []const u8,
    number: u64,

    fn init(cardinal: []const u8, ordinal: []const u8, number: u64) NamedNumber {
        return .{
            .cardinal = cardinal,
            .ordinal = ordinal,
            .number = number,
        };
    }
    fn getName(n: NamedNumber, ordinal: bool) []const u8 {
        return if (ordinal) n.ordinal else n.cardinal;
    }
};

fn getNamedNumber(n: u64) NamedNumber {
    const named_numbers = comptime [_]NamedNumber{
        .init("hundred", "hundredth", 100),
        .init("thousand", "thousandth", 1_000),
        .init("million", "millionth", 1_000_000),
        .init("billion", "biliionth", 1_000_000_000),
        .init("trillion", "trillionth", 1_000_000_000_000),
        .init("quadrillion", "quadrillionth", 1_000_000_000_000_000),
        .init("quintillion", "quintillionth", 1_000_000_000_000_000_000),
    };
    const names_len = named_numbers.len;
    var i: usize = 0;
    while (i + 1 < names_len) : (i += 1) {
        if (n < named_numbers[i + 1].number)
            return named_numbers[i];
    }
    return named_numbers[names_len - 1];
}

/// Recursive. Returns a count of the words added.
fn appendNumberName(result: *std.ArrayList(Word), allocator: std.mem.Allocator, n: usize, ordinal: bool) !usize {
    const small = comptime [_]NumberName{
        .init("zero", "zeroth"),         .init("one", "first"),           .init("two", "second"),
        .init("three", "third"),         .init("four", "fourth"),         .init("five", "fifth"),
        .init("six", "sixth"),           .init("seven", "seventh"),       .init("eight", "eighth"),
        .init("nine", "ninth"),          .init("ten", "tenth"),           .init("eleven", "eleventh"),
        .init("twelve", "twelfth"),      .init("thirteen", "thirteenth"), .init("fourteen", "fourteenth"),
        .init("fifteen", "fifteenth"),   .init("sixteen", "sixteenth"),   .init("seventeen", "seventeenth"),
        .init("eighteen", "eighteenth"), .init("nineteen", "nineteenth"),
    };
    const tens = comptime [_]NumberName{
        .init("twenty", "twentieth"), .init("thirty", "thirtieth"),
        .init("forty", "fortieth"),   .init("fifty", "fiftieth"),
        .init("sixty", "sixtieth"),   .init("seventy", "seventieth"),
        .init("eighty", "eightieth"), .init("ninety", "ninetieth"),
    };
    var count: usize = 0;
    if (n < 20) {
        try result.append(allocator, Word{ .word = small[n].getName(ordinal) });
        count = 1;
    } else if (n < 100) {
        if (n % 10 == 0) {
            try result.append(allocator, Word{ .word = tens[n / 10 - 2].getName(ordinal) });
        } else {
            const word1 = tens[n / 10 - 2].getName(false);
            const word2 = small[n % 10].getName(ordinal);
            try result.append(allocator, Word{ .word_hyphen = .{ word1, word2 } });
        }
        count = 1;
    } else {
        const num: NamedNumber = getNamedNumber(n);
        const p = num.number;
        count += try appendNumberName(result, allocator, n / p, false);
        if (n % p == 0) {
            try result.append(allocator, Word{ .word = num.getName(ordinal) });
            count += 1;
        } else {
            try result.append(allocator, Word{ .word = num.getName(false) });
            count += 1;
            count += try appendNumberName(result, allocator, n % p, ordinal);
        }
    }
    return count;
}

const testing = std.testing;

test getSentence {
    const words0 = try getSentence(testing.allocator, 0);
    defer testing.allocator.free(words0);
    try testing.expectEqual(0, words0.len);

    const words1 = try getSentence(testing.allocator, 1);
    defer testing.allocator.free(words1);
    try testing.expectEqual(13, words1.len);

    const words200 = try getSentence(testing.allocator, 200);
    defer testing.allocator.free(words200);
    try testing.expectEqual(201, words200.len);

    const words201 = try getSentence(testing.allocator, 201);
    defer testing.allocator.free(words201);
    try testing.expectEqual(201, words201.len);

    const words202 = try getSentence(testing.allocator, 202);
    defer testing.allocator.free(words202);
    try testing.expect(words202.len > 201);
}
