// https://rosettacode.org/wiki/Permutations_by_swapping
// {{works with|Zig|0.15.1}}
// Zig makes use of wraparound addition.
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    var it: JohnsonTrotterIterator(4, u8) = .init([4]u8{ 11, 22, 33, 44 });
    var count: usize = 0;
    while (it.next()) |values| {
        count += 1;
        print("{d:2}: ", .{count});
        // print the value and also (for reference) the direction
        for (values, it.directed_integers) |v, directed_integer|
            switch (directed_integer.direction) {
                .left => print("<{} ", .{v}),
                .right => print("{}> ", .{v}),
            };
        print("\n", .{});
    }
}

fn JohnsonTrotterIterator(comptime n: usize, T: type) type {
    return struct {
        const Self = @This();
        const Direction = enum(usize) {
            right = 1,
            left = @bitCast(@as(isize, -1)), // for wraparound addition
        };
        const DirectedInteger = struct {
            position: usize, // these are the directed integers
            direction: Direction, // -1 or 1
        };

        first_pass: bool,
        values: [n]T, // the values to be permuted
        directed_integers: [n]DirectedInteger,

        fn init(values: [n]T) Self {
            return Self{
                .first_pass = true,
                .values = values,
                .directed_integers = comptime blk: {
                    var array: [n]DirectedInteger = undefined;
                    for (&array, 0..) |*di, i|
                        di.* = .{ .position = i, .direction = .left };
                    break :blk array;
                },
            };
        }
        fn next(self: *Self) ?[n]T {
            // on first pass don't increment, just return as is
            if (self.first_pass)
                self.first_pass = false
            else {
                if (!self.increment())
                    return null;
            }
            return self.values;
        }
        // Index of a directed integer (and that facing).
        const IndexPair = struct { usize, usize };
        /// Returns null if a mobile integer cannot be found.
        fn indexOfLargestMobileInteger(self: *const Self) ?IndexPair {
            var result: ?IndexPair = null;
            var largest: usize = 0; // zero will never be the largest
            // Brute force search.
            for (self.directed_integers, 0..) |di, i|
                if (di.position > largest) {
                    const j: usize = i +% @intFromEnum(di.direction);
                    if (j < n and self.directed_integers[j].position < di.position)
                        if (di.position > largest) {
                            largest = di.position;
                            result = IndexPair{ i, j };
                        };
                };
            return result;
        }
        /// Implement Johnson-Trotter algorithm.
        /// Returns false when complete, i.e. when no mobile integer exists.
        fn increment(self: *Self) bool {
            const indexes = self.indexOfLargestMobileInteger() orelse return false;
            //
            const i, const j = indexes;
            const mobile_integer = self.directed_integers[i];
            // swap mobile_integer and the adjacent directed integer it is looking at
            std.mem.swap(T, &self.values[i], &self.values[j]);
            std.mem.swap(DirectedInteger, &self.directed_integers[i], &self.directed_integers[j]);
            // reverse direction of all directed integers .gt. mobile integer
            // (necessary only if mobile integer is not also the largest integer)
            if (mobile_integer.position != comptime n - 1)
                for (&self.directed_integers) |*directed_integer|
                    if (directed_integer.position > mobile_integer.position) {
                        directed_integer.direction = switch (directed_integer.direction) {
                            .left => .right,
                            .right => .left,
                        };
                    };
            return true;
        }
    };
}
