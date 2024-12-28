// https://rosettacode.org/wiki/Meissel%E2%80%93Mertens_constant
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const prime_reciprocals = try listPrimeReciprocals(allocator, 100_000_000);
    defer allocator.free(prime_reciprocals);

    const euler: f64 = 0.577_215_664_901_532_861;
    var sum: f64 = 0.0;
    for (prime_reciprocals) |reciprocal|
        sum += reciprocal + @log(1.0 - reciprocal);

    const meissel_mertens = euler + sum;
    print("The Meissel-Mertens constant = {d:.8}\n", .{meissel_mertens});
}

fn listPrimeReciprocals(allocator: mem.Allocator, limit: usize) ![]f64 {
    const half_limit = if (limit % 2 == 0) limit / 2 else 1 + limit / 2;

    var composite = try allocator.alloc(bool, half_limit);
    defer allocator.free(composite);
    @memset(composite, false);

    {
        // Sieve of Eratosthenes. Skipping even digits.
        var p: usize = 3;
        for (1..half_limit) |i| {
            if (!composite[i]) {
                var a = i + p;
                while (a < half_limit) : (a += p)
                    composite[a] = true;
            }
            p += 2;
        }
    }

    var result = std.ArrayList(f64).init(allocator);
    {
        var p: f64 = 3;
        try result.append(0.5);
        for (1..half_limit) |i| {
            if (!composite[i])
                try result.append(1.0 / p);
            p += 2;
        }
    }
    return try result.toOwnedSlice();
}
