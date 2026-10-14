// https://rosettacode.org/wiki/Prime_triplets
// {{works with|Zig|0.17.0}}

const std = @import("std");
const Io = std.Io;

// Using wrapper around cpp primesieve from https://github.com/kimwalisch/primesieve/
const primesieve = @import("primesieve");

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var t0: Io.Timestamp = .now(io, .real);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const limit = 5500;
    var triplet_generator: PrimeTripletGenerator = .init(limit);
    defer triplet_generator.deinit();

    try stdout.writeAll("Primesieve prime triplets:\n");
    var count: usize = 0;
    while (triplet_generator.next()) |triplet| {
        count += 1;
        try stdout.print("{d:4}, {d:4}, {d:4}\n", .{ triplet[0], triplet[1], triplet[2] });
    }
    try stdout.print("\n{d} triplets less than {d}\n\n", .{ count, limit });
    try stdout.flush();

    std.log.info("processed in {f}", .{t0.untilNow(io, .real)});
}

const PrimeTripletGeneratorError = error{PrimeSieveError};

const PrimeTripletGenerator = struct {
    stop: u64,
    it: primesieve.Iterator,
    prime1: u64,
    prime2: u64,

    fn init(stop: u64) PrimeTripletGenerator {
        var it: primesieve.Iterator = .init();

        var primes: [2]u64 = undefined;
        for (&primes) |*prime|
            prime.* = it.next().?;

        return PrimeTripletGenerator{
            .stop = stop,
            .it = it,
            .prime1 = primes[0],
            .prime2 = primes[1],
        };
    }
    fn deinit(self: *PrimeTripletGenerator) void {
        self.it.deinit();
    }
    fn next(self: *PrimeTripletGenerator) ?[3]u64 {
        while (true) {
            const prime = self.it.next().?;
            if (prime >= self.stop)
                return null;
            const prime0 = self.prime1;
            self.prime1 = self.prime2;
            self.prime2 = prime;
            if ((self.prime1 - prime0) == 2 and (prime - prime0) == 6)
                return .{ prime0, self.prime1, prime };
        }
    }
};
