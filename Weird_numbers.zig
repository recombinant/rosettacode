// https://rosettacode.org/wiki/Weird_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    const w: []bool = try sieve(allocator, 17_000);
    defer allocator.free(w);

    var count: usize = 0;
    const required: usize = 25;
    try stdout.print("The first {} weird numbers:\n", .{required});
    var n: usize = 2;
    while (count < required) : (n += 2)
        if (!w[n]) {
            try stdout.print("{} ", .{n});
            count += 1;
        };
    try stdout.writeByte('\n');

    try stdout.flush();
}

fn sieve(allocator: std.mem.Allocator, limit: usize) ![]bool {
    const w: []bool = try allocator.alloc(bool, limit);

    var i: usize = 2;
    while (i < limit) : (i += 2) {
        if (w[i]) continue;
        const divs: []usize = try divisors(allocator, i);
        defer allocator.free(divs);
        if (!isAbundant(i, divs)) {
            w[i] = true;
        } else if (isSemiperfect(i, divs)) {
            var j = i;
            while (j < limit) : (j += i)
                w[j] = true;
        }
    }
    return w;
}
fn divisors(allocator: std.mem.Allocator, n: usize) ![]usize {
    var divs1: std.ArrayList(usize) = .empty;
    defer divs1.deinit(allocator);
    var divs2: std.ArrayList(usize) = .empty;
    defer divs2.deinit(allocator);

    try divs1.append(allocator, 1);

    var i: usize = 2;
    while (i * i <= n) : (i += 1)
        if (n % i == 0) {
            const j = n / i;
            try divs1.append(allocator, i);
            if (i != j)
                try divs2.append(allocator, j);
        };
    std.mem.reverse(usize, divs1.items);
    try divs2.appendSlice(allocator, divs1.items);
    return divs2.toOwnedSlice(allocator);
}
fn isAbundant(n: usize, divs: []const usize) bool {
    var sum: usize = 0;
    for (divs) |value|
        sum += value;
    return sum > n;
}
fn isSemiperfect(n: usize, divs: []const usize) bool {
    if (divs.len != 0) {
        const h = divs[0];
        const t = divs[1..];
        return if (n < h)
            isSemiperfect(n, t)
        else
            n == h or isSemiperfect(n - h, t) or isSemiperfect(n, t);
    }
    return false;
}
