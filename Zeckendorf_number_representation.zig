// https://rosettacode.org/wiki/Zeckendorf_number_representation
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var z = try Zeckendorf1.init(allocator);
    defer z.deinit();

    for (0..21) |i| {
        const n = try z.zeckendorf(@intCast(i));
        defer z.allocator.free(n);
        try stdout.print("{d:2} {s: >8}\n", .{ i, n });
        try stdout.flush();
    }

    for (0..21) |i| {
        const n = Zeckendorf2.zeckendorf(@intCast(i));
        try stdout.print("{d:2} {b: >8}\n", .{ i, n });
        try stdout.flush();
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
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !Zeckendorf1 {
        var fib: std.ArrayList(u32) = .empty;
        try fib.insert(allocator, 0, 1);
        try fib.insert(allocator, 0, 2);
        return Zeckendorf1{
            .fib = fib,
            .allocator = allocator,
        };
    }
    fn deinit(self: *Zeckendorf1) void {
        self.fib.deinit(self.allocator);
    }

    // Caller owns returned memory slice.
    fn zeckendorf(self: *Zeckendorf1, number: u32) ![]const u8 {
        while (self.fib.items[0] < number)
            try self.fib.insert(self.allocator, 0, self.fib.items[0] + self.fib.items[1]);

        var a: std.Io.Writer.Allocating = .init(self.allocator);
        var n = number;
        for (self.fib.items) |f| {
            if (f <= n) {
                try a.writer.writeByte('1');
                n -= f;
            } else {
                try a.writer.writeByte('0');
            }
        }
        var result = a.toArrayList();
        if (result.items[0] == '0')
            _ = result.orderedRemove(0);
        return result.toOwnedSlice(self.allocator);
    }
};
