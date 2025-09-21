// https://rosettacode.org/wiki/Card_shuffles
// {{works with|Zig|0.15.1}}
// {{trans|Python}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    var deck: Deck(20) = .init(random);

    try stdout.writeAll("Riffle shuffle\n");
    deck.reset();
    try stdout.print("{any}\n", .{deck.cards});
    deck.riffleShuffle(10);
    try stdout.print("{any}\n", .{deck.cards});
    try stdout.writeByte('\n');

    try stdout.writeAll("Riffle shuffle\n");
    deck.reset();
    try stdout.print("{any}\n", .{deck.cards});
    deck.riffleShuffle(1);
    try stdout.print("{any}\n", .{deck.cards});
    try stdout.writeByte('\n');

    try stdout.writeAll("Overhand shuffle\n");
    deck.reset();
    try stdout.print("{any}\n", .{deck.cards});
    deck.overhandShuffle(10);
    try stdout.print("{any}\n", .{deck.cards});
    try stdout.writeByte('\n');

    try stdout.writeAll("Overhand shuffle\n");
    deck.reset();
    try stdout.print("{any}\n", .{deck.cards});
    deck.overhandShuffle(1);
    try stdout.print("{any}\n", .{deck.cards});
    try stdout.writeByte('\n');

    try stdout.writeAll("Library shuffle\n");
    deck.reset();
    try stdout.print("{any}\n", .{deck.cards});
    deck.shuffle();
    try stdout.print("{any}\n", .{deck.cards});
    try stdout.writeByte('\n');

    try stdout.flush();
}

fn Deck(comptime n_cards: usize) type {
    return struct {
        const Self = @This();
        cards: [n_cards]u8,
        random: std.Random,

        fn init(random: std.Random) Self {
            var deck: Self = .{
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
            var buffer_new_hand: [n_cards]u8 = undefined;
            var new_hand: std.ArrayList(u8) = .initBuffer(&buffer_new_hand);
            new_hand.appendSliceBounded(&self.cards) catch unreachable;

            for (0..flips) |_| {
                const cut_point = blk: {
                    // cut the deck at the middle +/- 10%
                    var cut_point = new_hand.items.len / 2;
                    // remove the following two lines for perfect cutting
                    const ten_percent = r.intRangeLessThan(usize, 0, new_hand.items.len / 10);
                    cut_point +%= if (r.boolean()) ten_percent else 0 -% ten_percent;

                    break :blk cut_point;
                };

                //  split the deck
                var buffer_pile1: [n_cards]u8 = undefined;
                var buffer_pile2: [n_cards]u8 = undefined;
                var pile1: std.ArrayList(u8) = .initBuffer(&buffer_pile1);
                var pile2: std.ArrayList(u8) = .initBuffer(&buffer_pile2);
                pile1.appendSliceBounded(new_hand.items[0..cut_point]) catch unreachable;
                pile2.appendSliceBounded(new_hand.items[cut_point..]) catch unreachable;
                new_hand.clearRetainingCapacity();
                while (pile1.items.len != 0 and pile2.items.len != 0) {
                    // allow for imperfect riffling so that more than one card
                    // can come from the same side in a row biased towards the
                    // side with more cards
                    const a = r.intRangeLessThan(usize, 0, pile1.items.len);
                    const b = r.intRangeLessThan(usize, 0, pile2.items.len);
                    switch (std.math.order(a, b)) {
                        .gt => new_hand.appendBounded(pile1.pop().?) catch unreachable,
                        .eq => switch (r.boolean()) {
                            false => new_hand.appendBounded(pile1.pop().?) catch unreachable,
                            true => new_hand.appendBounded(pile2.pop().?) catch unreachable,
                        },
                        .lt => new_hand.appendBounded(pile2.pop().?) catch unreachable,
                    }
                }
                new_hand.appendSliceBounded(pile1.items) catch unreachable;
                new_hand.appendSliceBounded(pile2.items) catch unreachable;
            }
            @memcpy(&self.cards, new_hand.items);
        }
        fn overhandShuffle(self: *Self, passes: usize) void {
            var buffer_main: [n_cards]u8 = undefined;
            var buffer_other: [n_cards]u8 = undefined;
            var buffer_temp: [n_cards]u8 = undefined;
            var main_hand: std.ArrayList(u8) = .initBuffer(&buffer_main);
            var other_hand: std.ArrayList(u8) = .initBuffer(&buffer_other);
            var temp: std.ArrayList(u8) = .initBuffer(&buffer_temp);

            main_hand.appendSliceBounded(&self.cards) catch unreachable;
            for (0..passes) |_| {
                other_hand.clearRetainingCapacity();
                while (main_hand.items.len != 0) {
                    // cut at up to 20% of the way through the deck
                    const cut_size = self.random.intRangeAtMost(usize, 1, n_cards / 5 + 1);
                    temp.clearRetainingCapacity();

                    // grab the next cut up to the end of the cards left in the main hand
                    var i: usize = 0;
                    while (i < cut_size and main_hand.items.len != 0) : (i += 1)
                        temp.appendBounded(main_hand.pop().?) catch unreachable;
                    // add them to the cards in the other hand, sometimes to the front sometimes to the back
                    if (0 != self.random.intRangeLessThan(u8, 0, 10))
                        std.mem.swap(std.ArrayList(u8), &other_hand, &temp); // front ~90% of the time
                    other_hand.appendSliceBounded(temp.items) catch unreachable;
                }
                // move the cards back to the main hand
                main_hand = other_hand;
            }
            @memcpy(&self.cards, main_hand.items);
        }
    };
}
