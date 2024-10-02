// https://rosettacode.org/wiki/Deal_cards_for_FreeCell
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const io = std.io;
const mem = std.mem;

const RndGen = @import("Linear_congruential_generator.zig").Microsoft;

pub fn main() !void {
    const stdout = io.getStdOut().writer();

    for ([_]u16{ 1, 617 }) |n| {
        // TODO: _ = arena.reset(.retain_capacity);
        try stdout.print("Game #{}\n", .{n});

        const rnd = RndGen.init(n);
        try printFreeCell(stdout, rnd);
        try stdout.writeByte('\n');
    }
}

fn printFreeCell( // TODO: allocator: mem.Allocator,
    out: anytype,
    rnd_: anytype,
) !void {
    var rnd = rnd_;

    const suits = [4][]const u8{ "♧", "♢", "♡", "♤" };
    const ranks = [13][]const u8{
        "A", "2", "3", "4", "5",
        "6", "7", "8", "9", "10",
        "J", "Q", "K",
    };

    const suits_len: usize = comptime blk: {
        var len: usize = 0;
        for (suits) |suit| len += suit.len;
        break :blk len;
    };
    const ranks_len: usize = comptime blk: {
        var len: usize = 0;
        for (ranks) |rank| len += rank.len;
        break :blk len;
    };

    // suit, rank and slices + 4 bytes missed
    var buffer: [(suits_len * 13) + (ranks_len * 4) + @sizeOf([]u8) * 52 + 4]u8 = undefined;
    var fbs = heap.FixedBufferAllocator.init(&buffer);
    const allocator = fbs.allocator();

    // var la = heap.LoggingAllocator(.debug, .debug).init(fbs.allocator());
    // const allocator = la.allocator();

    var deck = try std.ArrayList([]u8).initCapacity(allocator, 52);
    for (ranks) |rank|
        for (suits) |suit| {
            const buf = try fmt.allocPrint(allocator, "{s}{s}", .{ rank, suit });
            try deck.append(buf);
        };

    while (deck.items.len != 0) {
        for (0..8) |_| {
            if (deck.items.len == 0)
                break; // linefeed

            const n = rnd.random().int(u16) % deck.items.len;
            const card = deck.swapRemove(n);
            try out.print("{s} ", .{card});
        }
        try out.writeByte('\n');
    }
}
