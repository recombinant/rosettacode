// https://rosettacode.org/wiki/Deal_cards_for_FreeCell
// {{works with|Zig|0.15.1}}
const std = @import("std");
const RndGen = @import("Linear_congruential_generator.zig").Microsoft.lcg;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for ([_]u16{ 1, 617 }) |n| {
        try stdout.print("Game #{}\n", .{n});

        const rnd: RndGen = .init(n);
        try printFreeCell(rnd, stdout);
        try stdout.writeByte('\n');
    }
    try stdout.flush();
}

fn printFreeCell(rnd_: anytype, w: *std.Io.Writer) !void {
    var rnd = rnd_;

    const suits = [4][]const u8{ "♧", "♢", "♡", "♤" };
    const ranks = [13][]const u8{
        "A", "2", "3", "4", "5",
        "6", "7", "8", "9", "10",
        "J", "Q", "K",
    };
    const pack_len = suits.len * ranks.len;

    // (utf-8 length for suits + max length of rank (ie. 10)) * pack length
    var buffer: [(suits[0].len + 2) * 52]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buffer);
    const allocator = fba.allocator();

    var deck_buffer: [pack_len][]const u8 = undefined;
    var deck: std.ArrayList([]const u8) = .initBuffer(&deck_buffer);
    for (ranks) |rank|
        for (suits) |suit| {
            const buf = try std.fmt.allocPrint(allocator, "{s}{s}", .{ rank, suit });
            try deck.appendBounded(buf);
        };

    while (deck.items.len != 0) {
        for (0..8) |_| {
            if (deck.items.len == 0)
                break; // linefeed

            const n = rnd.random().int(u16) % deck.items.len;
            const card = deck.swapRemove(n);
            try w.print("{s} ", .{card});
        }
        try w.writeByte('\n');
    }
}
