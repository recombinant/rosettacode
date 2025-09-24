// https://rosettacode.org/wiki/Verify_distribution_uniformity/Naive
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var cnt: u32 = 10;
    while (cnt <= 1000000) : (cnt *= 10) {
        try stdout.print("Count = {}: ", .{cnt});
        try stdout.writeAll(if (try check(allocator, random, rand5_7, 7, cnt, 0.03, stdout)) "flat\n" else "NOT flat\n");
    }

    try stdout.flush();
}

fn rand5(random: std.Random) u4 {
    return random.intRangeAtMost(u4, 1, 5);
}

fn rand5_7(random: std.Random) u4 {
    var r: u5 = undefined;
    while (true) {
        r = @as(u5, rand5(random)) * 5 + rand5(random);
        if (r < 27)
            break;
    }
    return @intCast(r / 3 - 1);
}

/// Assumes gen() returns a value from 1 to n.
/// `delta` is relative
fn check(allocator: std.mem.Allocator, random: std.Random, gen: *const fn (std.Random) u4, n: usize, cnt: usize, delta: f64, writer: *std.Io.Writer) !bool {
    var bins = try allocator.alloc(f64, n);
    defer allocator.free(bins);
    @memset(bins, 0);

    var i: usize = cnt;
    while (i != 0) {
        i -= 1;
        bins[gen(random) - 1] += 1;
    }

    i = 0;
    while (i < n) : (i += 1) {
        const ratio: f64 = bins[i] * @as(f64, @floatFromInt(n)) / @as(f64, @floatFromInt(cnt)) - 1;
        if (ratio > -delta and ratio < delta)
            continue;

        try writer.print(
            "bin {d} out of range: {d} ({d:.2}% vs {d}%), ",
            .{ i + 1, bins[i], ratio * 100, delta * 100 },
        );
        break;
    }
    return (i == n);
}
