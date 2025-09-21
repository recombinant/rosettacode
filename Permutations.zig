// https://rosettacode.org/wiki/Permutations
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

const N = 4;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var x: [N]usize = undefined;
    for (&x, 1..) |*value, i|
        value.* = i;

    const args = ShowArgs{ .writer = stdout };

    try perm1(&x, args, &show);
    try stdout.writeByte('\n');

    try perm2(&x, args, &show);
    try stdout.writeByte('\n');

    try perm3(allocator, &x, args, &show);

    try stdout.flush();
}

const ShowArgs = struct { writer: *std.Io.Writer };

// print a list of ints
fn show(x: []usize, args: ShowArgs) !void {
    for (x, 1..) |value, i|
        try args.writer.print("{d}{c}", .{ value, @as(u8, if (i == x.len) '\n' else ' ') });
}

fn perm1(x: []usize, args: anytype, callback: *const fn ([]usize, @TypeOf(args)) anyerror!void) !void {
    if (x.len != 0)
        while (true) {
            try callback(x, args);
            if (!nextLexPerm(x))
                break;
        };
}

/// entry for Boothroyd method
fn perm2(x: []usize, args: anytype, callback: *const fn ([]usize, @TypeOf(args)) anyerror!void) !void {
    if (x.len != 0) {
        try callback(x, args);
        try boothroyd(x, x.len, args, callback);
    }
}

/// same as perm2, but flattened recursions into iterations
fn perm3(allocator: std.mem.Allocator, x: []usize, args: anytype, callback: *const fn ([]usize, @TypeOf(args)) anyerror!void) !void {
    if (x.len != 0) {
        try callback(x, args);

        if (x.len > 1) {
            var c = try allocator.alloc(usize, x.len);
            defer allocator.free(c);
            @memset(c, 0);

            var d: usize = 1;
            while (true) : (c[d] += 1) {
                while (d > 1) {
                    d -= 1;
                    c[d] = 0;
                }
                while (c[d] >= d) {
                    d += 1;
                    if (d >= x.len)
                        return;
                }
                const i: usize = if (d & 1 != 0) c[d] else 0;
                std.mem.swap(usize, &x[i], &x[d]);
                try callback(x, args);
            }
        }
    }
}

fn nextLexPerm(a: []usize) bool {
    // 1. Find the largest index k such that a[k] < a[k + 1]. If no such
    //    index exists, the permutation is the last permutation.
    var k = a.len - 1;
    while (k != 0 and a[k - 1] >= a[k])
        k -= 1;
    if (k == 0)
        return false;
    k -= 1;

    // 2. Find the largest index l such that a[k] < a[l]. Since k + 1 is
    //    such an index, l is well defined
    var l = a.len - 1;
    while (a[l] <= a[k])
        l -= 1;

    // 3. Swap a[k] with a[l]
    std.mem.swap(usize, &a[k], &a[l]);

    // 4. Reverse the sequence from a[k + 1] to the end
    k += 1;
    l = a.len - 1;
    while (l > k) : ({
        l -= 1;
        k += 1;
    })
        std.mem.swap(usize, &a[k], &a[l]);
    return true;
}

/// Boothroyd method; exactly N! swaps, about as fast as it gets
fn boothroyd(x: []usize, n: usize, args: anytype, callback: *const fn ([]usize, @TypeOf(args)) anyerror!void) !void {
    var c: usize = 0;
    while (true) {
        if (n > 2)
            try boothroyd(x, n - 1, args, callback);
        if (c >= n - 1) return;

        const i: usize = if (n & 1 != 0) 0 else c;
        c += 1;
        std.mem.swap(usize, &x[n - 1], &x[i]);
        try callback(x, args);
    }
}
