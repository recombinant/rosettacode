// https://rosettacode.org/wiki/War_card_game
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const SUITS: []const []const u8 = &.{ "♣", "♦", "♥", "♠" };
const FACES: []const []const u8 = &.{ "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A" };

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var file: Io.File = .stdout();

    try war(io, gpa, &file);
}

fn war(io: Io, allocator: Allocator, file: *Io.File) !void {
    // Create and shuffle deck
    var deck: ArrayList(usize) = .empty;
    defer deck.deinit(allocator);

    try deck.ensureTotalCapacityPrecise(allocator, 52);
    for (0..52) |i|
        try deck.append(allocator, i);

    // Shuffle deck
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();
    random.shuffle(usize, deck.items);

    // Deal cards to players (reversing order to match original implementation)
    var hand1: ArrayList(usize) = .empty;
    defer hand1.deinit(allocator);
    var hand2: ArrayList(usize) = .empty;
    defer hand2.deinit(allocator);

    try hand1.ensureTotalCapacityPrecise(allocator, 52);
    try hand2.ensureTotalCapacityPrecise(allocator, 52);

    for (0..26) |i| {
        try hand1.append(allocator, deck.items[2 * i]);
        try hand2.append(allocator, deck.items[2 * i + 1]);
    }

    // Reverse hands
    std.mem.reverse(usize, hand1.items);
    std.mem.reverse(usize, hand2.items);

    // Create cards lookup
    var cards: [52]Card = undefined;
    for (0..52) |i|
        cards[i] = Card.new(i);

    while (hand1.items.len > 0 and hand2.items.len > 0) {
        const card1 = hand1.orderedRemove(0);
        const card2 = hand2.orderedRemove(0);

        var played1: ArrayList(usize) = .empty;
        defer played1.deinit(allocator);
        var played2: ArrayList(usize) = .empty;
        defer played2.deinit(allocator);

        try played1.append(allocator, card1);
        try played2.append(allocator, card2);
        var num_played: usize = 2;

        var current_card1 = card1;
        var current_card2 = card2;

        var buffer: [1024]u8 = undefined;
        var fbw: Io.Writer = .fixed(buffer[0..]); // fixed buffer writer

        while (true) {
            _ = fbw.consumeAll();
            try fbw.print("{s}\t{s}\t", .{ cards[current_card1].getDisplaySlice(), cards[current_card2].getDisplaySlice() });
            try file.writeStreamingAll(io, fbw.buffered());

            if (cards[current_card1].rank > cards[current_card2].rank) {
                try hand1.appendSlice(allocator, played1.items);
                try hand1.appendSlice(allocator, played2.items);

                _ = fbw.consumeAll();
                try fbw.print("Player 1 takes the {} cards. Now has {}.\n", .{ num_played, hand1.items.len });
                try file.writeStreamingAll(io, fbw.buffered());

                break;
            } else if (cards[current_card1].rank < cards[current_card2].rank) {
                try hand2.appendSlice(allocator, played2.items);
                try hand2.appendSlice(allocator, played1.items);

                _ = fbw.consumeAll();
                try fbw.print("Player 2 takes the {} cards. Now has {}.\n", .{ num_played, hand2.items.len });
                try file.writeStreamingAll(io, fbw.buffered());

                break;
            } else {
                try file.writeStreamingAll(io, "War!\n");

                if (hand1.items.len < 2) {
                    try file.writeStreamingAll(io, "Player 1 has insufficient cards left.\n");
                    try hand2.appendSlice(allocator, played2.items);
                    try hand2.appendSlice(allocator, played1.items);
                    try hand2.appendSlice(allocator, hand1.items);
                    hand1.clearRetainingCapacity();
                    break;
                }

                if (hand2.items.len < 2) {
                    try file.writeStreamingAll(io, "Player 2 has insufficient cards left.\n");
                    try hand1.appendSlice(allocator, played1.items);
                    try hand1.appendSlice(allocator, played2.items);
                    try hand1.appendSlice(allocator, hand2.items);
                    hand2.clearRetainingCapacity();
                    break;
                }

                const fd_card1 = hand1.orderedRemove(0); // face down card
                current_card1 = hand1.orderedRemove(0); // face up card
                try played1.append(allocator, fd_card1);
                try played1.append(allocator, current_card1);

                const fd_card2 = hand2.orderedRemove(0); // face down card
                current_card2 = hand2.orderedRemove(0); // face up card
                try played2.append(allocator, fd_card2);
                try played2.append(allocator, current_card2);

                num_played += 4;
                try file.writeStreamingAll(io, "? \t? \tFace down cards.\n");
            }
        }
    }

    if (hand1.items.len == 52)
        try file.writeStreamingAll(io, "Player 1 wins the game!\n")
    else
        try file.writeStreamingAll(io, "Player 2 wins the game!\n");
}

const Card = struct {
    display: [4]u8,
    rank: usize,

    fn new(index: usize) Card {
        const face = FACES[index % 13];
        const suit = SUITS[index / 13];

        var display: [4]u8 = undefined;
        // Copy face (1 byte)
        display[0] = face[0];
        // Copy suit (3 bytes for Unicode suit symbols)
        @memcpy(display[1 .. suit.len + 1], suit[0..]);

        return Card{
            .display = display,
            .rank = index % 13,
        };
    }

    fn getDisplaySlice(self: *const Card) []const u8 {
        return self.display[0..];
    }
};
