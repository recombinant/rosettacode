// https://rosettacode.org/wiki/Pangram_checker
// {{works with|Zig|0.15.1}}
const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const phrases = pangram_phrases ++ not_pangram_phrases;

    for (phrases) |phrase|
        try stdout.print(
            "\"{s}\" is {s}a pangram\n",
            .{ phrase, if (isPangram(phrase)) "" else "not " },
        );

    try stdout.flush();
}

const pangram_phrases = [_][]const u8{
    "The quick brown fox jumps over the lazy dog.",
    "Pack my box with five dozen liquor jugs.",
};

const not_pangram_phrases = [_][]const u8{
    "The qu1ck brown fox jumps over the lazy d0g.",
    "The five boxing wizards dump quickly.",
    "Heavy boxes perform waltzes and jigs.",
};

fn isPangram(s: []const u8) bool {
    if (s.len < 26)
        return false;

    var bits: u26 = 0;

    for (s) |c|
        if (std.ascii.isAlphabetic(c)) {
            bits |= @as(u26, 1) << @truncate(std.ascii.toLower(c) - 'a');
        };

    return bits == comptime std.math.maxInt(@TypeOf(bits));
}
test isPangram {
    for (pangram_phrases) |phrase|
        try testing.expect(isPangram(phrase));
    for (not_pangram_phrases) |phrase|
        try testing.expect(!isPangram(phrase));
}
test "26 bits" {
    const BitType = u26;
    try testing.expectEqual(26, @bitSizeOf(BitType));

    // All bits set.
    // Uses wraparound properties of two's complement arithmetic.
    const bits: BitType = @as(BitType, 0) -% 1;

    try testing.expectEqual(std.math.maxInt(BitType), bits);
}

/// Alternative implementation of isPangram() using std.StaticBitset
fn isPangramWithBitmap(s: []const u8) bool {
    if (s.len < 26)
        return false;

    var bits = std.StaticBitSet(26).initEmpty();

    for (s) |c|
        if (std.ascii.isAlphabetic(c))
            bits.set(std.ascii.toLower(c) - 'a');

    return bits.count() == 26;
}
test isPangramWithBitmap {
    for (pangram_phrases) |phrase|
        try testing.expect(isPangramWithBitmap(phrase));
    for (not_pangram_phrases) |phrase|
        try testing.expect(!isPangramWithBitmap(phrase));
}
