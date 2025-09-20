// https://rosettacode.org/wiki/Cuban_primes
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");

pub fn main() !void {
    var t0: std.time.Timer = try .start();
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------

    var primes: std.ArrayList(u64) = .empty;
    defer primes.deinit(allocator);
    try primes.appendSlice(allocator, &.{ 3, 5 });
    const cutoff = 200;
    var cubans: std.ArrayList(u64) = .empty;
    defer cubans.deinit(allocator);
    const big_one = 100_000;
    var big_cuban: u64 = undefined;
    var c: u64 = 0;
    var show_each = true;
    var u: u64 = 0;
    var v: u64 = 1;

    std.log.info("Calculating the first {d} cuban primes and the {d}th cuban prime...", .{ cutoff, big_one });
    for (1..(1 << 20)) |_| {
        var found = false;
        u += 6;
        v += u;
        const mx: u64 = @intFromFloat(@floor(@sqrt(@as(f64, @floatFromInt(v)))));
        for (primes.items) |item| {
            if (item > mx) break;
            if (v % item == 0) {
                found = true;
                break;
            }
        }
        if (!found) {
            c += 1;
            if (show_each) {
                var z = primes.items[primes.items.len - 1];
                while (z <= v - 2) {
                    z += 2;
                    var found_prime = false;
                    for (primes.items) |item| {
                        if (item > mx) break;
                        if (z % item == 0) {
                            found_prime = true;
                            break;
                        }
                    }
                    if (!found_prime)
                        try primes.append(allocator, z);
                }
                try primes.append(allocator, v);
                try cubans.append(allocator, v);
                if (c == cutoff) show_each = false;
            }
            if (c == big_one) {
                big_cuban = v;
                break;
            }
        }
    }
    std.log.info("calculated in: {D}", .{t0.read()});

    try stdout.print("The first {d} cuban primes are:\n", .{cutoff});
    for (cubans.items[0..cutoff], 0..) |item, i| {
        if (i % 10 == 0 and i != 0) try stdout.writeByte('\n'); // 10 per line say
        try stdout.print("{d:10} ", .{item});
    }
    if (cutoff % 10 != 0) try stdout.writeByte('\n');

    try stdout.print("\nThe 100,000th cuban prime is: {d}\n\n", .{big_cuban});
    try stdout.flush();
}
