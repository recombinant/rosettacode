// https://rosettacode.org/wiki/Upside-down_numbers
// Translated from Wren
const std = @import("std");
const math = std.math;
const mem = std.mem;
const testing = std.testing;

const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var it = try UpsideDownIterator.init(allocator);
    defer it.deinit();

    print("First fifty upside-downs:\n", .{});
    while (true) {
        const count, const number = try it.next();
        if (count <= 50)
            print("{d:5}{s}", .{ number, if (count % 10 == 0) "\n" else "" })
        else if (count == 500)
            print("\nFive hundredth: {}\n", .{number})
        else if (count == 5_000)
            print("\nFive thousandth: {}\n", .{number})
        else if (count == 50_000)
            print("\nFifty thousandth: {}\n", .{number})
        else if (count == 500_000)
            print("\nFive hundred thousandth: {}\n", .{number})
        else if (count == 5_000_000)
            print("\nFive millionth: {}\n", .{number})
        else if (count > 5_000_000)
            break;
    }
}

/// Generate upside-down numbers (OEIS A299539)
const UpsideDownIterator = struct {
    const wrappings = [_][2]u64{
        .{ 1, 9 }, .{ 2, 8 }, .{ 3, 7 }, .{ 4, 6 }, .{ 5, 5 },
        .{ 6, 4 }, .{ 7, 3 }, .{ 8, 2 }, .{ 9, 1 },
    };

    allocator: mem.Allocator,
    evens: std.ArrayList(u64),
    odds: std.ArrayList(u64),
    tmp: std.ArrayList(u64),

    odd_index: usize = 0,
    even_index: usize = 0,

    ndigits: usize = 1,
    pow: u64 = 100,

    count: usize = 0,

    fn init(allocator: mem.Allocator) !UpsideDownIterator {
        var odds = std.ArrayList(u64).init(allocator);
        try odds.append(5);
        var evens = std.ArrayList(u64).init(allocator);
        try evens.appendSlice(&[_]u64{ 19, 28, 37, 46, 55, 64, 73, 82, 91 });

        return .{
            .allocator = allocator,
            .evens = evens,
            .odds = odds,
            .tmp = std.ArrayList(u64).init(allocator),
        };
    }
    fn deinit(self: *UpsideDownIterator) void {
        self.evens.deinit();
        self.odds.deinit();
        self.tmp.deinit();
    }

    fn next(self: *UpsideDownIterator) !struct { usize, u64 } {
        while (true)
            if (self.ndigits % 2 == 1) {
                if (self.odd_index < self.odds.items.len) {
                    const result = self.odds.items[self.odd_index];
                    self.odd_index += 1;
                    self.count += 1;
                    return .{ self.count, result };
                } else {
                    // build next odds, but switch to evens
                    self.tmp.clearRetainingCapacity();
                    for (wrappings) |w| {
                        const hi, const lo = w;
                        for (self.odds.items) |i|
                            try self.tmp.append(hi * self.pow + i * 10 + lo);
                    }
                    mem.swap(std.ArrayList(u64), &self.odds, &self.tmp);

                    self.ndigits += 1;
                    self.pow *= 10;
                    self.odd_index = 0;
                }
            } else {
                if (self.even_index < self.evens.items.len) {
                    const result = self.evens.items[self.even_index];
                    self.even_index += 1;
                    self.count += 1;
                    return .{ self.count, result };
                } else {
                    // build next evens, but switch to odds
                    self.tmp.clearRetainingCapacity();
                    for (wrappings) |w| {
                        const hi, const lo = w;
                        for (self.evens.items) |i|
                            try self.tmp.append(hi * self.pow + 10 * i + lo);
                    }
                    mem.swap(std.ArrayList(u64), &self.evens, &self.tmp);

                    self.ndigits += 1;
                    self.pow *= 10;
                    self.even_index = 0;
                }
            };
    }
};
