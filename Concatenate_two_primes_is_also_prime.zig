// https://rosettacode.org/wiki/Concatenate_two_primes_is_also_prime
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    const limit = 100;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var primes: std.ArrayList(u32) = .empty;
    defer primes.deinit(allocator);
    var results: std.ArrayList(u32) = .empty;
    defer results.deinit(allocator);

    for (0..limit) |i| {
        const p: u32 = @intCast(i);
        if (isPrime(p))
            try primes.append(allocator, p);
    }

    var factor: u32 = 1;
    var minimum: u32 = 0;
    for (primes.items) |p| {
        for (primes.items) |q| {
            if (q < factor or q > minimum) {
                minimum = std.math.pow(u32, 10, std.math.log10_int(@as(u32, q)));
                factor = minimum * 10;
            }
            const pq = (p * factor) + q;
            if (isPrime(pq))
                try results.append(allocator, pq);
        }
    }
    std.mem.sortUnstable(u32, results.items, {}, std.sort.asc(u32));

    var count: usize = 0;
    try stdout.print("Two primes under {d} concatenated together to form another prime:\n", .{limit});
    for (results.items, 0..) |result, i| {
        if (i > 0 and result == results.items[i - 1])
            continue;
        try stdout.print("{d:6} ", .{result});
        count += 1;
        if (count % 10 == 0)
            try stdout.writeByte('\n');
    }
    try stdout.print("\n\nFound {d} such concatenated primes.\n", .{count});

    try stdout.flush();
}

fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u32 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}
