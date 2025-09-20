// https://rosettacode.org/wiki/Count_in_factors
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

fn Primes(comptime T: type) type {
    return struct {
        const Self = @This();

        primes: std.ArrayList(T),
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) !Self {
            var primes: std.ArrayList(T) = try .initCapacity(allocator, 2);
            try primes.append(allocator, 2);
            try primes.append(allocator, 3);
            return Self{
                .primes = primes,
                .allocator = allocator,
            };
        }
        fn deinit(self: *Self) void {
            self.primes.deinit(self.allocator);
        }

        fn getPrime(self: *Self, idx: usize) !T {
            if (idx >= self.primes.items.len) {
                try self.primes.ensureTotalCapacity(self.allocator, idx + 1);

                var last = self.primes.items[self.primes.items.len - 1];
                while (idx >= self.primes.items.len) {
                    last += 2;
                    for (self.primes.items) |p| {
                        if (p * p > last) {
                            try self.primes.append(self.allocator, last);
                            break;
                        }
                        if (last % p == 0)
                            break;
                    }
                }
            }
            return self.primes.items[idx];
        }
    };
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const T = u12; // Change type to crudely adjust stopping point
    // If this asserts then refactor the first for() loop below
    std.debug.assert(@sizeOf(T) < @sizeOf(usize));

    var primes = try Primes(T).init(allocator);
    defer primes.deinit();

    for (1..std.math.maxInt(T) + 1) |x| {
        try stdout.print("{d} = ", .{x});

        var sep: []const u8 = ""; // separator
        var n: T = @intCast(x); // remainder
        var i: T = 0;
        while (true) : (i += 1) {
            const p = try primes.getPrime(i);
            while (n % p == 0) {
                n /= p;
                try stdout.print("{s}{d}", .{ sep, p });
                sep = " x ";
            }
            const ov = @mulWithOverflow(p, p);
            if (ov[1] != 0) break;
            if (n <= ov[0]) break;
        }
        if (n > 1 or sep.len == 0)
            try stdout.print("{s}{d}", .{ sep, n });
        try stdout.writeByte('\n');
    }
    try stdout.flush();
}

const testing = std.testing;

test "Primes" {
    const T = u8;
    var p = try Primes(T).init(testing.allocator);
    defer p.deinit();

    try testing.expectEqual(2, try p.getPrime(0));
    try testing.expectEqual(3, try p.getPrime(1));
    try testing.expectEqual(5, try p.getPrime(2));
    try testing.expectEqual(7, try p.getPrime(3));
    try testing.expectEqual(11, try p.getPrime(4));
    try testing.expectEqual(97, try p.getPrime(24));
}
