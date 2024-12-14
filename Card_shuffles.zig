// https://rosettacode.org/wiki/Card_shuffles
// Translation of Python
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    var deck = Deck(20).init(random);

    try writer.writeAll("Riffle shuffle\n");
    deck.reset();
    try writer.print("{any}\n", .{deck.cards});
    deck.riffleShuffle(10);
    try writer.print("{any}\n", .{deck.cards});
    try writer.writeByte('\n');

    try writer.writeAll("Riffle shuffle\n");
    deck.reset();
    try writer.print("{any}\n", .{deck.cards});
    deck.riffleShuffle(1);
    try writer.print("{any}\n", .{deck.cards});
    try writer.writeByte('\n');

    try writer.writeAll("Overhand shuffle\n");
    deck.reset();
    try writer.print("{any}\n", .{deck.cards});
    deck.overhandShuffle(10);
    try writer.print("{any}\n", .{deck.cards});
    try writer.writeByte('\n');

    try writer.writeAll("Overhand shuffle\n");
    deck.reset();
    try writer.print("{any}\n", .{deck.cards});
    deck.overhandShuffle(1);
    try writer.print("{any}\n", .{deck.cards});
    try writer.writeByte('\n');

    try writer.writeAll("Library shuffle\n");
    deck.reset();
    try writer.print("{any}\n", .{deck.cards});
    deck.shuffle();
    try writer.print("{any}\n", .{deck.cards});
    try writer.writeByte('\n');
}

fn Deck(comptime n_cards: usize) type {
    return struct {
        const Self = @This();
        cards: [n_cards]u8,
        random: std.Random,

        fn init(random: std.Random) Self {
            var deck = Self{
                .cards = undefined,
                .random = random,
            };
            deck.reset();
            return deck;
        }
        fn reset(self: *Self) void {
            for (&self.cards, 1..) |*card, i|
                card.* = @truncate(i);
        }
        fn shuffle(self: *Self) void {
            self.random.shuffle(u8, &self.cards);
        }
        fn riffleShuffle(self: *Self, flips: usize) void {
            const r = self.random;
            const Array = std.BoundedArray(u8, n_cards);
            var new_hand = Array.init(0) catch unreachable;
            new_hand.appendSlice(&self.cards) catch unreachable;

            for (flips) |_| {
                const cut_point = blk: {
                    // cut the deck at the middle +/- 10%
                    var cut_point = new_hand.len / 2;
                    // remove the following two lines for perfect cutting
                    const ten_percent = r.intRangeLessThan(usize, 0, new_hand.len / 10);
                    cut_point +%= if (r.boolean()) ten_percent else 0 -% ten_percent;

                    break :blk cut_point;
                };

                //  split the deck
                var pile1 = Array.init(0) catch unreachable;
                var pile2 = Array.init(0) catch unreachable;
                pile1.appendSlice(new_hand.constSlice()[0..cut_point]) catch unreachable;
                pile2.appendSlice(new_hand.constSlice()[cut_point..]) catch unreachable;
                new_hand.clear();
                while (pile1.len != 0 and pile2.len != 0) {
                    // allow for imperfect riffling so that more than one card
                    // can come from the same side in a row biased towards the
                    // side with more cards
                    const a = r.intRangeLessThan(usize, 0, pile1.len);
                    const b = r.intRangeLessThan(usize, 0, pile2.len);
                    switch (std.math.order(a, b)) {
                        .gt => new_hand.append(pile1.pop()) catch unreachable,
                        .eq => switch (r.boolean()) {
                            false => new_hand.append(pile1.pop()) catch unreachable,
                            true => new_hand.append(pile2.pop()) catch unreachable,
                        },
                        .lt => new_hand.append(pile2.pop()) catch unreachable,
                    }
                }
                new_hand.appendSlice(pile1.constSlice()) catch unreachable;
                new_hand.appendSlice(pile2.constSlice()) catch unreachable;
            }
            @memcpy(&self.cards, new_hand.constSlice());
        }
        fn overhandShuffle(self: *Self, passes: usize) void {
            const Array = std.BoundedArray(u8, n_cards);
            var main_hand = Array.init(0) catch unreachable;
            var other_hand = Array.init(0) catch unreachable;
            var temp = Array.init(0) catch unreachable;

            main_hand.appendSlice(&self.cards) catch unreachable;
            for (0..passes) |_| {
                other_hand.clear();
                while (main_hand.len != 0) {
                    // cut at up to 20% of the way through the deck
                    const cut_size = self.random.intRangeAtMost(usize, 1, n_cards / 5 + 1);
                    temp.clear();

                    // grab the next cut up to the end of the cards left in the main hand
                    var i: usize = 0;
                    while (i < cut_size and main_hand.len != 0) : (i += 1)
                        temp.append(main_hand.pop()) catch unreachable;
                    // add them to the cards in the other hand, sometimes to the front sometimes to the back
                    if (0 != self.random.intRangeLessThan(u8, 0, 10))
                        std.mem.swap(Array, &other_hand, &temp); // front ~90% of the time
                    other_hand.appendSlice(temp.constSlice()) catch unreachable;
                }
                // move the cards back to the main hand
                main_hand = other_hand;
            }
            @memcpy(&self.cards, main_hand.constSlice());
        }
    };
}
