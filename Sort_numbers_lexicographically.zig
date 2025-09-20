// https://rosettacode.org/wiki/Sort_numbers_lexicographically
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const numbers: [5]i16 = .{ 0, 5, 13, 21, -22 };
    try stdout.print("In lexicographical order:\n\n", .{});

    for (numbers) |num| {
        // Create the ordered values in LexOrder
        const ordered: LexOrder(i16) = try .init(allocator, num);
        defer ordered.deinit();

        try stdout.print("{d}: [", .{num});

        for (ordered.numbers) |n|
            try stdout.print("{d} ", .{n});

        try stdout.writeAll("]\n");
    }

    try stdout.flush();
}

/// A struct is used to limit scope of the type 'T' to the
/// 'Pair' struct and 'cmp' function.
fn LexOrder(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        numbers: []T,

        const Pair = struct { n: T, s: []const u8 };

        pub fn init(allocator: std.mem.Allocator, num: T) !Self {
            var array: std.ArrayList(Pair) = .empty;
            defer array.deinit(allocator); // not necessary after toOwnedSlice()

            const lo: T, const hi: T = if (num < 1) .{ num, 1 } else .{ 1, num };

            var i = lo;
            while (i <= hi) : (i += 1) {
                const s = try std.fmt.allocPrint(allocator, "{d}", .{i});
                const pair = Pair{ .n = i, .s = s };
                try array.append(allocator, pair);
            }
            const pairs = try array.toOwnedSlice(allocator);
            defer {
                for (pairs) |p| allocator.free(p.s);
                allocator.free(pairs);
            }

            // Lexicographically sort on "pair.s" strings
            std.mem.sortUnstable(Pair, pairs, {}, cmpPairs);

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
            std.debug.assert(p1.n != p2.n);
            const s1 = p1.s;
            const s2 = p2.s;
            const len = @min(s1.len, s2.len);
            std.debug.assert(len != 0);

            for (s1[0..len], s2[0..len]) |a, b|
                if (a > b)
                    return false
                else if (a < b)
                    return true;

            std.debug.assert(s1.len != s2.len);
            return s1.len < s2.len;
        }
    };
}
