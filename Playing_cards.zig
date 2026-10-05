// https://rosettacode.org/wiki/Playing_cards
// {{works with|Zig|0.17.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var deck: Deck = .init();

    try stdout.writeAll("New deck:\n");
    try deck.show(stdout);

    try stdout.writeAll("\nShuffled deck:\n");
    deck.shuffle(random);
    try deck.show(stdout);

    try stdout.writeAll("\nDeal 4 hands of 5 cards each\n");
    for (0..4) |_| {
        var sep: []const u8 = "";
        for (0..5) |_| {
            try stdout.print("{s}{?f} ", .{ sep, deck.deal() });
            sep = " ";
        }
        try stdout.writeByte('\n');
    }

    try stdout.print("\nLeft in deck {} cards:\n", .{deck.cards.len - deck.cards_dealt});
    try deck.show(stdout);

    try stdout.flush();
}

const Card = struct {
    const Suit = enum { @"♠", @"♣", @"♦", @"♥" };
    const Pip = enum { A, @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", J, Q, K };

    suit: Suit,
    pip: Pip,

    pub fn format(self: Card, w: *Io.Writer) Io.Writer.Error!void {
        return try w.print("{s}{s}", .{ @tagName(self.pip), @tagName(self.suit) });
    }
};

const Deck = struct {
    const suit_len = @typeInfo(Card.Suit).@"enum".field_names.len;
    const pip_len = @typeInfo(Card.Pip).@"enum".field_names.len;
    const pack_len = suit_len * pip_len;

    cards: [pack_len]Card,
    cards_dealt: u16,

    fn init() Deck {
        var deck: Deck = .{
            .cards = undefined,
            .cards_dealt = 0,
        };
        inline for (@typeInfo(Card.Suit).@"enum".field_values) |suit_value| {
            inline for (@typeInfo(Card.Pip).@"enum".field_values) |pip_value|
                deck.cards[suit_value * pip_len + pip_value] = Card{
                    .suit = @fromBackingInt(suit_value),
                    .pip = @fromBackingInt(pip_value),
                };
        }
        return deck;
    }

    fn show(deck: *const Deck, w: *Io.Writer) !void {
        var sep: []const u8 = "";
        for (deck.cards[deck.cards_dealt..]) |card| {
            try w.print("{s}{f}", .{ sep, card });
            sep = " ";
        }
        try w.writeByte('\n');
    }

    fn deal(deck: *Deck) ?Card {
        if (deck.cards_dealt == deck.cards.len)
            return null;
        const card = deck.cards[deck.cards_dealt];
        deck.cards_dealt += 1;
        return card;
    }

    fn shuffle(deck: *Deck, random: std.Random) void {
        random.shuffle(Card, &deck.cards);
        deck.cards_dealt = 0;
    }
};
