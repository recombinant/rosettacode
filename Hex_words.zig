// https://rosettacode.org/wiki/Hex_words
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Result = struct { word: []const u8, value: u64, root: u64 };

fn lessThanRoot(_: void, r1: Result, r2: Result) bool {
    return r1.root < r2.root;
}

fn greaterThanValue(_: void, r1: Result, r2: Result) bool {
    return r1.value > r2.value;
}

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    // ------------------------------------------ read text
    const f = try Io.Dir.cwd().openFile(io, "data/unixdict.txt", .{});

    var buffer: [4096]u8 = undefined;
    var file_reader = f.reader(io, &buffer);
    const r = &file_reader.interface;
    const text = try r.allocRemaining(gpa, .unlimited);
    defer gpa.free(text);

    f.close(io);

    // ----------------------------------------------------
    var results: std.ArrayList(Result) = .empty;
    var results_distinct: std.ArrayList(Result) = .empty;
    defer results.deinit(gpa);
    defer results_distinct.deinit(gpa);

    var it = std.mem.splitScalar(u8, text, '\n');
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
        try results.append(gpa, result);

        if (letter_bits.count() >= 4)
            try results_distinct.append(gpa, result);
    }

    std.mem.sortUnstable(Result, results.items, {}, lessThanRoot);
    std.mem.sortUnstable(Result, results_distinct.items, {}, greaterThanValue);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("{d} hex words in unixdict.txt with 4 or more letters:\n\n", .{results.items.len});
    for (results.items) |result|
        try stdout.print("{s: <6} -> {d: >8} -> {d}\n", .{ result.word, result.value, result.root });
    try stdout.writeByte('\n');
    try stdout.writeByte('\n');
    try stdout.print("{d} hex words in unixdict.txt with 4 or more distinct letters:\n\n", .{results_distinct.items.len});
    for (results_distinct.items) |result|
        try stdout.print("{s: <6} -> {d: >8} -> {d}\n", .{ result.word, result.value, result.root });

    try stdout.flush();
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

const testing = std.testing;

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
