// https://rosettacode.org/wiki/Sort_numbers_lexicographically
// Translated from C
const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const numbers: [5]i16 = .{ 0, 5, 13, 21, -22 };
    try stdout.print("In lexicographical order:\n\n", .{});

    for (numbers) |num| {
        // Create the ordered values in LexOrder
        const ordered = try LexOrder(i16).init(allocator, num);
        defer ordered.deinit();

        try stdout.print("{d}: [", .{num});

        for (ordered.numbers) |n|
            try stdout.print("{d} ", .{n});

        try stdout.writeAll("]\n");
    }

    try bw.flush();
}

/// A struct is used to limit scope of the type 'T' to the
/// 'Pair' struct and 'cmp' function.
fn LexOrder(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: mem.Allocator,
        numbers: []T,

        const Pair = struct { n: T, s: []const u8 };

        pub fn init(allocator: mem.Allocator, num: T) !Self {
            var array = std.ArrayList(Pair).init(allocator);
            defer array.deinit(); // not necessary after toOwnedSlice()

            const lo: T, const hi: T = if (num < 1) .{ num, 1 } else .{ 1, num };

            var i = lo;
            while (i <= hi) : (i += 1) {
                const s = try std.fmt.allocPrint(allocator, "{d}", .{i});
                const pair = Pair{ .n = i, .s = s };
                try array.append(pair);
            }
            const pairs = try array.toOwnedSlice();
            defer {
                for (pairs) |p| allocator.free(p.s);
                allocator.free(pairs);
            }

            // Lexicographically sort on "pair.s" strings
            mem.sort(Pair, pairs, {}, cmpPairs);

            // Retrieve the numbers from the sorted pairs.
            const numbers = try allocator.alloc(T, pairs.len);
            for (numbers, pairs) |*n, p|
                n.* = p.n;

            return Self{
                .allocator = allocator,
                .numbers = numbers,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.numbers);
        }

        fn cmpPairs(_: void, p1: Pair, p2: Pair) bool {
            assert(p1.n != p2.n);
            const s1 = p1.s;
            const s2 = p2.s;
            const len = @min(s1.len, s2.len);
            assert(len != 0);

            for (s1[0..len], s2[0..len]) |a, b|
                if (a > b)
                    return false
                else if (a < b)
                    return true;

            assert(s1.len != s2.len);
            return s1.len < s2.len;
        }
    };
}
