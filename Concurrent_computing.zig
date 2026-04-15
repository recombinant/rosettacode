// https://rosettacode.org/wiki/Concurrent_computing
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var lock: Io.Mutex = .init;

    const thread1 = try std.Thread.spawn(.{}, worker, .{ io, "Enjoy", &lock, random });
    const thread2 = try std.Thread.spawn(.{}, worker, .{ io, "Rosetta", &lock, random });
    const thread3 = try std.Thread.spawn(.{}, worker, .{ io, "Code", &lock, random });

    thread1.join();
    thread2.join();
    thread3.join();
}

fn worker(io: Io, text: []const u8, lock: *Io.Mutex, random: std.Random) !void {
    // random sleep interval so that print order is independent of thread spawn order
    const interval = random.intRangeAtMost(i64, 0, 500);
    const duration = Io.Duration.fromMilliseconds(interval);
    try Io.sleep(io, duration, .real);

    // don't assume that there is a lock in the print function
    try lock.lock(io);
    defer lock.unlock(io);

    std.debug.print("{s}\n", .{text});
}
