// https://rosettacode.org/wiki/Ulam_numbers
// {{works with|Zig|0.16.0}}
// {{trans|C}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var t0: Io.Timestamp = .now(io, .real);

    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // --------------------------------------------------------------
    var n: u64 = 1;
    while (n <= 100_000) : (n *= 10) {
        try stdout.print("Ulam({}) = {}\n", .{ n, try ulam(gpa, n) });
        try stdout.flush();
    }

    // --------------------------------------------------------------
    std.log.info("Elapsed time: {f}", .{t0.untilNow(io, .real)});
}

fn ulam(allocator: Allocator, n: u64) !u64 {
    if (n <= 2)
        return n;
    var ulams: std.ArrayListUnmanaged(u64) = try .initCapacity(allocator, n);
    defer ulams.deinit(allocator);
    try ulams.append(allocator, 1);
    try ulams.append(allocator, 2);

    var sieve: std.ArrayListUnmanaged(u64) = .empty;
    defer sieve.deinit(allocator);
    try sieve.append(allocator, 1);
    try sieve.append(allocator, 1);

    var u: u64 = 2;
    while (ulams.items.len < n) {
        const sieve_length = u + ulams.items[ulams.items.len - 2];
        if (sieve_length > sieve.items.len) {
            const len0 = sieve.items.len;
            try sieve.resize(allocator, @intFromFloat(@as(f32, @floatFromInt(sieve_length)) * std.math.phi));
            @memset(sieve.items[len0..sieve.items.len], 0);
        }
        for (0..ulams.items.len - 1) |i|
            sieve.items[u + ulams.items[i] - 1] += 1;

        if (std.mem.indexOfScalar(u64, sieve.items[u..sieve_length], 1)) |i| {
            u += i + 1;
            try ulams.append(allocator, u);
        }
    }
    return ulams.items[n - 1];
}
