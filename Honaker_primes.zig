// https://rosettacode.org/wiki/Honaker_primes
// {{works with|Zig|0.15.1}}
const std = @import("std");

// https://rosettacode.org/wiki/Extensible_prime_generator
const PrimeGen = @import("sieve.zig").PrimeGen;

pub fn main() !void {
    var t0: std.time.Timer = try .start();

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var it: HonakerPrimeIterator = .init(allocator);
    defer it.deinit();

    const task1 = 50;
    const task2 = 10_000;
    var count: usize = 0;

    while (true) {
        const hp = try it.next(); // Honaker prime
        count += 1;

        if (count == 1)
            try stdout.print("The first {} Honaker primes:\n", .{task1});
        if (count <= task1) {
            const sep: u8 = if (count % 5 == 0) '\n' else ' ';
            try stdout.print("({d:3}, {d:4}){c}", .{ hp.index, hp.prime, sep });
        } else if (count == task2) {
            try stdout.print(
                "\n\nThe {d}th Honaker prime: ({}, {})\n",
                .{ task2, hp.index, hp.prime },
            );
            break;
        }
    }
    try stdout.writeByte('\n');
    try stdout.flush();

    std.log.info("processed in {D}", .{t0.read()});
}

fn sumDigits(n_: u64) u64 {
    var sum: u64 = 0;
    var n = n_;
    while (n != 0) {
        sum += n % 10;
        n /= 10;
    }
    return sum;
}

/// Honaker prime iterator
const HonakerPrimeIterator = struct {
    primegen: PrimeGen(u64),
    index: u64 = 1,

    fn init(allocator: std.mem.Allocator) HonakerPrimeIterator {
        return HonakerPrimeIterator{
            .primegen = .init(allocator),
        };
    }
    fn deinit(self: *HonakerPrimeIterator) void {
        self.primegen.deinit();
    }

    fn next(self: *HonakerPrimeIterator) !struct { index: u64, prime: u64 } {
        while (try self.primegen.next()) |p| : (self.index += 1) {
            if (sumDigits(p) == sumDigits(self.index)) {
                return .{
                    .index = self.index,
                    .prime = p,
                };
            }
        }
        unreachable;
    }
};
