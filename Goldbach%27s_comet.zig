// https://rosettacode.org/wiki/Goldbach%27s_comet
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var goldbach = try Goldbach.init(allocator, 2_000_000);
    defer goldbach.deinit();

    std.debug.print("The first 100 Goldbach numbers:\n", .{});
    var n: u32 = 2;
    while (n < 102) : (n += 1)
        std.debug.print("{d:3}{s}", .{ try goldbach.function(2 * n), if (n % 10 == 1) "\n" else "" });

    std.debug.print("\nThe 1,000,000th Goldbach number = {}\n", .{try goldbach.function(1_000_000)});
}

const Goldbach = struct {
    primes: std.DynamicBitSet,

    fn init(allocator: std.mem.Allocator, limit: u32) !Goldbach {
        var primes = try std.DynamicBitSet.initFull(allocator, limit);
        primes.setValue(0, false);
        primes.setValue(1, false);
        var n: u32 = 2;
        const n_limit = std.math.sqrt(limit);
        while (n < n_limit) : (n += 1) {
            var k = n * n;
            while (k < limit) : (k += n)
                primes.setValue(k, false);
        }
        return .{ .primes = primes };
    }
    fn deinit(self: *Goldbach) void {
        self.primes.deinit();
    }

    fn function(self: Goldbach, number: u32) !u32 {
        if (number <= 2) return error.NumberTooSmall;
        if (number % 2 == 1) return error.NumberOdd;

        var result: u32 = 0;
        var i: u32 = 1;
        while (i <= number / 2) : (i += 1)
            if (self.primes.isSet(i) and self.primes.isSet(number - i)) {
                result += 1;
            };
        return result;
    }
};
