// https://rosettacode.org/wiki/Concurrent_computing
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    var lock: std.Thread.Mutex = .{};

    const thread1 = try std.Thread.spawn(.{}, worker, .{ "Enjoy", &lock, random });
    const thread2 = try std.Thread.spawn(.{}, worker, .{ "Rosetta", &lock, random });
    const thread3 = try std.Thread.spawn(.{}, worker, .{ "Code", &lock, random });

    thread1.join();
    thread2.join();
    thread3.join();
}

fn worker(text: []const u8, lock: *std.Thread.Mutex, random: std.Random) void {
    // random sleep interval so that print order is independent of thread spawn order
    const interval = random.uintLessThan(u64, 500) * std.time.ns_per_ms;
    std.Thread.sleep(interval);

    // don't assume that there is a lock in the print function
    lock.lock();
    defer lock.unlock();

    std.debug.print("{s}\n", .{text});
}
