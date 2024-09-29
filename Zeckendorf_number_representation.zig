// https://rosettacode.org/wiki/Zeckendorf_number_representation
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var z = try Zeckendorf1.init(allocator);
    defer z.deinit();

    for (0..21) |i| {
        const n = try z.zeckendorf(@intCast(i));
        defer z.allocator.free(n);
        try stdout.print("{d:2} {s: >8}\n", .{ i, n });
    }

    for (0..21) |i| {
        const n = Zeckendorf2.zeckendorf(@intCast(i));
        try stdout.print("{d:2} {b: >8}\n", .{ i, n });
    }
}

const Zeckendorf2 = struct {
    fn zeckendorf(number: u32) u64 {
        const result = zr(1, 1, number, 0);
        return result.set;
    }

    fn zr(fib0: u32, fib1: u32, n: u32, bit: usize) struct { remaining: u32, set: u64 } {
        if (fib1 > n) {
            return .{ .remaining = n, .set = 0 };
        }
        var result = zr(fib1, fib0 + fib1, n, bit + 1);
        if (fib1 <= result.remaining) {
            result.set |= @as(u64, 1) << @intCast(bit);
            result.remaining -= fib1;
        }
        return result;
    }
};

const Zeckendorf1 = struct {
    fib: std.ArrayList(u32),
    allocator: mem.Allocator,

    fn init(allocator: mem.Allocator) !Zeckendorf1 {
        var fib = std.ArrayList(u32).init(allocator);
        try fib.insert(0, 1);
        try fib.insert(0, 2);
        return Zeckendorf1{
            .fib = fib,
            .allocator = allocator,
        };
    }
    fn deinit(self: *Zeckendorf1) void {
        self.fib.deinit();
    }

    // Caller owns returned memory slice.
    fn zeckendorf(self: *Zeckendorf1, number: u32) ![]const u8 {
        while (self.fib.items[0] < number)
            try self.fib.insert(0, self.fib.items[0] + self.fib.items[1]);

        var result = std.ArrayList(u8).init(self.allocator);
        const writer = result.writer();
        var n = number;
        for (self.fib.items) |f| {
            if (f <= n) {
                try writer.writeByte('1');
                n -= f;
            } else {
                try writer.writeByte('0');
            }
        }
        if (result.items[0] == '0')
            _ = result.orderedRemove(0);
        return result.toOwnedSlice();
    }
};
