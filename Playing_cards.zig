// https://rosettacode.org/wiki/Playing_cards
const std = @import("std");

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    const stdout = std.io.getStdOut().writer();

    var deck = Deck.init();

    try stdout.writeAll("New deck:\n");
    try deck.show(stdout);

    try stdout.writeAll("\nShuffled deck:\n");
    deck.shuffle(random);
    try deck.show(stdout);

    try stdout.writeAll("\nDeal 4 hands of 5 cards each\n");
    for (0..4) |_| {
        var sep: []const u8 = "";
        for (0..5) |_| {
            try stdout.print("{s}{?} ", .{ sep, deck.deal() });
            sep = " ";
        }
        try stdout.writeByte('\n');
    }

    try stdout.print("\nLeft in deck {} cards:\n", .{deck.cards.len - deck.cards_dealt});
    try deck.show(stdout);
}

const Card = struct {
    const Suit = enum { @"♠", @"♣", @"♦", @"♥" };
    const Pip = enum { A, @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", J, Q, K };

    suit: Suit,
    pip: Pip,

    pub fn format(self: Card, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt; // unused
        _ = options; // unused
        return try writer.print("{s}{s}", .{ @tagName(self.pip), @tagName(self.suit) });
    }
};

const Deck = struct {
    const suit_len = std.meta.fields(Card.Suit).len;
    const pip_len = std.meta.fields(Card.Pip).len;
    const pack_len = suit_len * pip_len;

    cards: [pack_len]Card,
    cards_dealt: u16,

    fn init() Deck {
        var deck = Deck{
            .cards = undefined,
            .cards_dealt = 0,
        };
        inline for (std.meta.fields(Card.Suit)) |suit_field| {
            inline for (std.meta.fields(Card.Pip)) |pip_field|
                deck.cards[suit_field.value * pip_len + pip_field.value] = Card{
                    .suit = @enumFromInt(suit_field.value),
                    .pip = @enumFromInt(pip_field.value),
                };
        }
        return deck;
    }

    fn show(deck: *const Deck, writer: anytype) !void {
        var sep: []const u8 = "";
        for (deck.cards[deck.cards_dealt..]) |card| {
            try writer.print("{s}{}", .{ sep, card });
            sep = " ";
        }
        try writer.writeByte('\n');
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
