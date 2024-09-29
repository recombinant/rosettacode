// https://rosettacode.org/wiki/Cuban_primes
// Translation of Wren
const std = @import("std");
const mem = std.mem;
const time = std.time;
const print = std.debug.print;

pub fn main() !void {
    var t0 = try time.Timer.start();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------

    var primes = std.ArrayList(u64).init(allocator);
    try primes.appendSlice(&.{ 3, 5 });
    defer primes.deinit();
    const cutoff = 200;
    var cubans = std.ArrayList(u64).init(allocator);
    defer cubans.deinit();
    const big_one = 100_000;
    var big_cuban: u64 = undefined;
    var c: u64 = 0;
    var show_each = true;
    var u: u64 = 0;
    var v: u64 = 1;

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
                        try primes.append(z);
                }
                try primes.append(v);
                try cubans.append(v);
                if (c == cutoff) show_each = false;
            }
            if (c == big_one) {
                big_cuban = v;
                break;
            }
        }
    }
    const duration = t0.read();

    print("The first {d} cuban primes are:\n", .{cutoff});
    for (cubans.items[0..cutoff], 0..) |item, i| {
        if (i % 10 == 0 and i != 0) print("\n", .{}); // 10 per line say
        print("{d:10} ", .{item});
    }
    if (cutoff % 10 != 0) print("\n", .{});

    print("\nThe 100,000th cuban prime is: {d}\n", .{big_cuban});

    print("Processed in: {}\n", .{std.fmt.fmtDuration(duration)});
}
