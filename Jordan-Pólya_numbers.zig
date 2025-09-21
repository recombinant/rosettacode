// https://rosettacode.org/wiki/Jordan-Pólya_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const v = try jordanPolya(allocator, 1 << 53);
    defer allocator.free(v);

    try stdout.writeAll("First 50 Jordan-Pólya numbers:\n");
    for (v[0..50], 1..) |jp, i| {
        try stdout.print("{d:4} ", .{jp});
        if (i % 10 == 0) try stdout.writeByte('\n');
    }

    try stdout.writeAll("\nThe largest Jordan-Pólya number before 100 millon: ");
    const ix = findNearestInArray(v, 100_000_000);
    try stdout.print("{d}\n\n", .{v[ix - 1]});

    const targets = [5]u64{ 800, 1050, 1800, 2800, 3800 };
    for (targets) |target| {
        const t1 = v[target - 1];
        try stdout.print("The {d}th Jordan-Pólya number is : {d}\n", .{ target, t1 });
        const w = try decompose(allocator, t1, 0);
        defer allocator.free(w);
        var x_print = false;
        var count: usize = 1;
        var t = w[0];
        try stdout.writeAll(" = ");
        for (w) |u| {
            if (u != t) {
                if (x_print) try stdout.writeAll(" x ") else x_print = true;
                if (count == 1)
                    try stdout.print("{d}!", .{t})
                else {
                    var buf: [7]u8 = undefined;
                    try stdout.print("({d}!){!s}", .{ t, superscript(&buf, count) });
                    count = 1;
                }
                t = u;
            } else count += 1;
        }
        if (x_print) try stdout.writeAll(" x ") else x_print = true;
        if (count == 1)
            try stdout.print("{d}!", .{t})
        else {
            var buf: [7]u8 = undefined;
            try stdout.print("({d}!){!s}", .{ t, superscript(&buf, count) });
        }
        try stdout.writeAll("\n\n");
    }

    try stdout.flush();
}

// This are calculated at comptime.
const factorials: [19]u64 = [2]u64{ 1, 1 } ++ calcFactorials(17);

fn calcFactorials(comptime n: usize) [n]u64 {
    var _factorials: [n]u64 = undefined;
    var fact: u64 = 1;

    for (&_factorials, 2..) |*ptr, i| {
        fact *= i;
        ptr.* = fact;
    }
    return _factorials;
}

fn findNearestFact(n: u64) usize {
    for (factorials[1..], 1..) |f, i|
        if (f >= n)
            return i;
    return factorials.len - 1;
}

fn findNearestInArray(a: []u64, n: u64) usize {
    var l: usize = 0;
    var r = a.len;
    while (l < r) {
        const m = (l + r) / 2;
        if (a[m] > n)
            r = m
        else
            l = m + 1;
    }
    if (r > 0 and a[r - 1] == n)
        return r - 1;
    return r;
}

fn jordanPolya(allocator: std.mem.Allocator, limit: u64) ![]u64 {
    var res: std.ArrayList(u64) = .empty;
    const ix = findNearestFact(limit);

    for (0..ix + 1) |i|
        try res.append(allocator, factorials[i]);

    var k: usize = 2;
    while (k < res.items.len) : (k += 1) {
        const rk = res.items[k];
        for (2..res.items.len) |l| {
            const t = res.items[l];
            if (t > limit / rk)
                break;
            var kl = t * rk;
            while (true) {
                const p = findNearestInArray(res.items, kl);
                if (p < res.items.len and res.items[p] != kl)
                    try res.insert(allocator, p, kl)
                else if (p == res.items.len)
                    try res.append(allocator, kl);
                if (kl > limit / rk)
                    break;
                kl *= rk;
            }
        }
    }
    _ = res.orderedRemove(0);
    return res.toOwnedSlice(allocator);
}

fn decompose(allocator: std.mem.Allocator, n: u64, start_: usize) ![]usize {
    var start = if (start_ == 0)
        factorials.len
    else
        start_;

    while (start > 0) {
        start -= 1;

        if (start < 2)
            return allocator.alloc(usize, 0);

        var m = n;
        var f: std.ArrayList(usize) = .empty;
        defer f.deinit(allocator);

        while (m % factorials[start] == 0) {
            try f.append(allocator, start);
            m = m / factorials[start];
            if (m == 1)
                return f.toOwnedSlice(allocator);
        }
        if (f.items.len > 0) {
            const g = try decompose(allocator, m, start - 1);
            defer allocator.free(g);
            if (g.len > 0) {
                var prod: u64 = 1;
                for (g) |e| prod *= factorials[e];
                if (prod == m) {
                    try f.appendSlice(allocator, g);
                    return f.toOwnedSlice(allocator);
                }
            }
        }
    }
    unreachable;
}

fn superscript(buf: []u8, n: usize) ![]const u8 {
    const ss = [10][]const u8{ "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹" };
    if (n < 10)
        return std.fmt.bufPrint(buf, "{s}", .{ss[n]});
    return std.fmt.bufPrint(buf, "{s}{s}", .{ ss[n / 10], ss[n % 10] });
}
