// https://rosettacode.org/wiki/Hamming_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");
const Int = std.math.big.int.Managed;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------

    for (1..21) |i| {
        var h = try hamming(allocator, i);
        _ = try h.format(stdout);
        try stdout.writeByte(' ');
        h.deinit();
    }
    try stdout.writeByte('\n');
    try stdout.flush();

    var h2 = try hamming(allocator, 1691);
    _ = try h2.format(stdout);
    try stdout.writeByte('\n');
    h2.deinit();
    try stdout.flush();

    var h3 = try hamming(allocator, 1_000_000);
    _ = try h3.format(stdout);
    try stdout.writeByte('\n');
    h3.deinit();
    try stdout.flush();
}

fn hamming(allocator: std.mem.Allocator, limit: usize) !Int {
    var _2: Int = try .initSet(allocator, 2);
    var _3: Int = try .initSet(allocator, 3);
    var _5: Int = try .initSet(allocator, 5);
    defer _2.deinit();
    defer _3.deinit();
    defer _5.deinit();

    var h = try allocator.alloc(Int, limit);
    defer {
        for (h) |*h_| {
            h_.deinit();
            h_.* = undefined;
        }
        allocator.free(h);
        h = undefined;
    }
    for (h) |*h_|
        h_.* = try .initSet(allocator, 1);
    var x2: Int = try .initSet(allocator, 2);
    var x3: Int = try .initSet(allocator, 3);
    var x5: Int = try .initSet(allocator, 5);
    defer x2.deinit();
    defer x3.deinit();
    defer x5.deinit();

    var rma: Int = try .init(allocator);
    defer rma.deinit();

    var i: usize = 0;
    var j: usize = 0;
    var k: usize = 0;
    for (1..limit) |n| {
        h[n].deinit();
        h[n] = try min3(x2, x3, x5);
        if (x2.eql(h[n])) {
            i += 1;
            try rma.mul(&_2, &h[i]);
            rma.swap(&x2);
        }
        if (x3.eql(h[n])) {
            j += 1;
            try rma.mul(&_3, &h[j]);
            rma.swap(&x3);
        }
        if (x5.eql(h[n])) {
            k += 1;
            try rma.mul(&_5, &h[k]);
            rma.swap(&x5);
        }
    }

    var result: Int = try .initSet(allocator, 0);
    // quicker than clone
    result.swap(&h[h.len - 1]);

    return result;
}

/// Minimum of 3 big integers - equivalent to @min(a, @min(b, c))
fn min3(a: Int, b: Int, c: Int) !Int {
    var min: Int =
        switch (a.order(b)) {
            .lt, .eq => switch (a.order(c)) {
                .lt, .eq => a,
                .gt => c,
            },
            .gt => switch (b.order(c)) {
                .lt, .eq => b,
                .gt => c,
            },
        };
    return try min.clone();
}
