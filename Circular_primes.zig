// https://rosettacode.org/wiki/Circular_primes
// {{works with|Zig|0.15.1}}

// Copied from rosettacode
const std = @import("std");

// todo: second task not implemented

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var candidates: std.PriorityQueue(u32, void, orderU32) = .init(allocator, {});
    defer candidates.deinit();

    try stdout.writeAll("The circular primes are:\n");
    try stdout.print("{:10}" ** 4, .{ 2, 3, 5, 7 });

    var c: u32 = 4;
    try candidates.add(0);
    while (true) {
        const n = candidates.remove();
        if (n > 1_000_000)
            break;
        if (n > 10 and circular(n)) {
            try stdout.print("{:10}", .{n});
            c += 1;
            if (c % 10 == 0)
                try stdout.writeByte('\n');
        }
        try candidates.add(10 * n + 1);
        try candidates.add(10 * n + 3);
        try candidates.add(10 * n + 7);
        try candidates.add(10 * n + 9);
    }
    try stdout.writeByte('\n');

    try stdout.flush();
}

fn orderU32(_: void, a: u32, b: u32) std.math.Order {
    return std.math.order(a, b);
}

fn circular(n0: u32) bool {
    if (!isPrime(n0))
        return false
    else {
        var n = n0;
        var d: u32 = @intFromFloat(@log10(@as(f32, @floatFromInt(n))));
        return while (d > 0) : (d -= 1) {
            n = rotate(n);
            if (n < n0 or !isPrime(n))
                break false;
        } else true;
    }
}

fn rotate(n: u32) u32 {
    if (n == 0)
        return 0
    else {
        // const d = math.log(u32, 10, n);
        const d: u32 = @intFromFloat(@log10(@as(f32, @floatFromInt(n)))); // digit count - 1
        const m = std.math.pow(u32, 10, d);
        return (n % m) * 10 + n / m;
    }
}

/// 2, 3, 5 prime test.
fn isPrime(n: u32) bool {
    if (n < 2)
        return false;

    inline for ([3]u3{ 2, 3, 5 }) |p| {
        if (n % p == 0)
            return n == p;
    }

    const wheel235 = [_]u3{ 6, 4, 2, 4, 2, 4, 6, 2 };

    var i: u32 = 1;
    var f: u32 = 7;
    return while (f * f <= n) {
        if (n % f == 0)
            break false;
        f += wheel235[i];
        i = (i + 1) & 0x07;
    } else true;
}
