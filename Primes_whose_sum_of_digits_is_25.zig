// https://rosettacode.org/wiki/Primes_whose_sum_of_digits_is_25
// {{works with|Zig|0.15.1}}

const std = @import("std");

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    if (n % 3 == 0) return n == 3;
    var d: u64 = 5;
    while (d * d <= n) {
        if (n % d == 0) return false;
        d += 2;
        if (n % d == 0) return false;
        d += 4;
    }
    return true;
}

fn digitSum(n_: u64) u16 {
    var n = n_; // parameters are immutable, copy to var
    var sum: u16 = 0;
    while (n != 0) {
        sum += @truncate(n % 10);
        n /= 10;
    }
    return sum;
}

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var result: std.ArrayList(u64) = .empty;
    defer result.deinit(allocator);

    {
        var n: u64 = 3;
        while (n <= 5000) : (n += 2)
            if (digitSum(n) == 25 and isPrime(n))
                try result.append(allocator, n);
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (result.items, 0..) |n, i|
        _ = try stdout.print("{d:4}{s}", .{ n, if ((i + 1) % 6 == 0) "\n" else " " });

    try stdout.flush();
}
