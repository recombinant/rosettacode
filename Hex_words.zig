// https://rosettacode.org/wiki/Hex_words
const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const testing = std.testing;

const Result = struct { word: []const u8, value: u64, root: u64 };

fn lessThanRoot(_: void, r1: Result, r2: Result) bool {
    return r1.root < r2.root;
}

fn greaterThanValue(_: void, r1: Result, r2: Result) bool {
    return r1.value > r2.value;
}

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ------------------------------------------ read text
    const f = try std.fs.cwd().openFile("data/unixdict.txt", .{});
    const text = try f.readToEndAlloc(allocator, math.maxInt(usize));
    defer allocator.free(text);
    // ----------------------------------------------------
    var results = std.ArrayList(Result).init(allocator);
    var results_distinct = std.ArrayList(Result).init(allocator);
    defer results.deinit();
    defer results_distinct.deinit();

    var it = mem.splitScalar(u8, text, '\n');
    outer: while (it.next()) |word| {
        if (word.len < 4) continue;

        var letter_count: u16 = 0;
        var letter_bits = std.StaticBitSet(6).initEmpty();
        for (word) |letter|
            switch (letter) {
                'a'...'f' => {
                    letter_count += 1;
                    letter_bits.set(letter - 'a');
                },
                else => continue :outer,
            };

        const value = try std.fmt.parseInt(u32, word, 16);
        const root = digitalRoot(value);

        const result = Result{ .word = word, .value = value, .root = root };
        try results.append(result);

        if (letter_bits.count() >= 4)
            try results_distinct.append(result);
    }

    sort.heap(Result, results.items, {}, lessThanRoot);
    sort.heap(Result, results_distinct.items, {}, greaterThanValue);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d} hex words in unixdict.txt with 4 or more letters:\n\n", .{results.items.len});
    for (results.items) |result|
        try stdout.print("{s: <6} -> {d: >8} -> {d}\n", .{ result.word, result.value, result.root });
    try stdout.writeByte('\n');
    try stdout.writeByte('\n');
    try stdout.print("{d} hex words in unixdict.txt with 4 or more distinct letters:\n\n", .{results_distinct.items.len});
    for (results_distinct.items) |result|
        try stdout.print("{s: <6} -> {d: >8} -> {d}\n", .{ result.word, result.value, result.root });
}

// https://rosettacode.org/wiki/Digital_root
fn digitalRoot(value: u64) u64 {
    var n = value;
    var d: u64 = 0;
    while (true) {
        while (n > 0) {
            d += n % 10;
            n /= 10;
        }
        if (d > 9) {
            n = d;
            d = 0;
        } else break;
    }
    return d;
}

test "digital root" {
    try testing.expectEqual(1, digitalRoot(1));
    try testing.expectEqual(5, digitalRoot(14));
    try testing.expectEqual(1, digitalRoot(55));
    try testing.expectEqual(6, digitalRoot(267));
    try testing.expectEqual(1, digitalRoot(8_128));
    try testing.expectEqual(6, digitalRoot(39_390));
    try testing.expectEqual(3, digitalRoot(588_225));
    try testing.expectEqual(9, digitalRoot(627_615));
    try testing.expectEqual(9, digitalRoot(393_900_588_225));
}
