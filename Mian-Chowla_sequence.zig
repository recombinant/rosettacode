// https://rosettacode.org/wiki/Mian-Chowla_sequence
// {{works with|Zig|0.15.1}}
// {{trans|C}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    const n = 100;

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try run1(allocator, n, stdout); // translation of C

    try run2(allocator, n, stdout); // translation of Go

    try run3(n, stdout); // naive brute force

    try run4(allocator, n, stdout); // tweaked translation of C
}

fn run1(allocator: std.mem.Allocator, n: usize, w: *std.Io.Writer) !void {
    try w.writeAll("\n\n" ++ "-" ** 66 ++ "\n");
    try w.print("Calculating {d} terms of Mian-Chowla sequence (translation of C)...\n", .{n});
    try w.flush();

    const mc = try getMianChowla1(allocator, n);
    defer allocator.free(mc);

    try w.writeAll("\nThe first 30 terms of the Mian-Chowla sequence are:\n");
    for (mc[0..30]) |number|
        try w.print("{d} ", .{number});
    try w.writeAll("\n\nTerms 91 to 100 of the Mian-Chowla sequence are:\n");
    for (mc[90..]) |number|
        try w.print("{d} ", .{number});

    try w.flush();
}

// Translation of C Quick, but...
// Caller owns returned slice memory.
fn getMianChowla1(allocator: std.mem.Allocator, n: usize) ![]u64 {
    var t0: std.time.Timer = try .start();

    var mc = try allocator.alloc(u64, n);
    var nn = n * (n + 1) / 2;
    var is_sum = try allocator.alloc(bool, nn);
    defer allocator.free(is_sum);
    @memset(is_sum, false);

    var c: usize = 0;
    var i: usize = 1;
    while (c < n) : (i += 1) {
        mc[c] = i;
        if (i + i > nn) {
            var new_capacity = nn;
            // Grow memory exponentially.
            while (new_capacity < i + i)
                new_capacity *|= 2;
            if (!allocator.resize(is_sum, new_capacity)) {
                const old_memory = is_sum;
                is_sum = try allocator.alloc(bool, new_capacity);
                @memcpy(is_sum[0..nn], old_memory);
                allocator.free(old_memory);
            }
            @memset(is_sum[nn..], false);
            nn = new_capacity;
        }
        var is_unique = true;
        var j: usize = 0;
        while (j < c and is_unique) : (j += 1)
            is_unique = !is_sum[i + mc[j]];
        if (is_unique) {
            for (mc[1 .. c + 1]) |existing|
                is_sum[i + existing] = true;
            c += 1;
        }
    }
    std.log.info("Mian-Chowla sequence (translation of C) processed in {D}", .{t0.read()});

    return mc;
}

fn run2(allocator: std.mem.Allocator, n: usize, w: *std.Io.Writer) !void {
    try w.writeAll("\n\n" ++ "-" ** 66 ++ "\n");
    try w.print("Calculating {d} terms of Mian-Chowla sequence (translation of Go)...\n", .{n});
    try w.flush();

    const mc = try getMianChowla2(allocator, n);
    defer allocator.free(mc);

    try w.writeAll("\nThe first 30 terms of the Mian-Chowla sequence are:\n");
    for (mc[0..30]) |number|
        try w.print("{d} ", .{number});
    try w.writeAll("\n\nTerms 91 to 100 of the Mian-Chowla sequence are:\n");
    for (mc[90..]) |number|
        try w.print("{d} ", .{number});

    try w.flush();
}

/// Translation of Go
/// Caller owns returned slice memory.
fn getMianChowla2(allocator: std.mem.Allocator, n: usize) ![]u64 {
    var t0: std.time.Timer = try .start();

    var mc = try allocator.alloc(u64, n);
    mc[0] = 1;

    var is = std.AutoHashMap(u64, void).init(allocator);
    defer is.deinit();
    try is.put(2, {});

    var isx: std.ArrayList(u64) = .empty;
    defer isx.deinit(allocator);

    for (1..n) |i| {
        isx.clearRetainingCapacity();
        var j: u64 = mc[i - 1] + 1;
        jloop: while (true) : (j += 1) {
            mc[i] = j;
            for (mc[0 .. i + 1]) |existing| {
                const sum = existing + j;
                if (is.get(sum) != null) {
                    isx.clearRetainingCapacity();
                    continue :jloop;
                }
                try isx.append(allocator, sum);
            }
            for (isx.items) |x|
                try is.put(x, {});
            break;
        }
    }
    std.log.info("Mian-Chowla sequence (translation of Go) processed in {D}", .{t0.read()});

    return mc;
}

fn run3(comptime n: usize, w: *std.Io.Writer) !void {
    try w.writeAll("\n\n" ++ "-" ** 66 ++ "\n");
    try w.print("Calculating {d} terms of Mian-Chowla sequence (naive)...\n", .{n});
    try w.flush();

    const mc = try getMianChowla3(n);

    try w.writeAll("\nThe first 30 terms of the Mian-Chowla sequence are:\n");
    for (mc[0..30]) |number|
        try w.print("{d} ", .{number});
    try w.writeAll("\n\nTerms 91 to 100 of the Mian-Chowla sequence are:\n");
    for (mc[90..]) |number|
        try w.print("{d} ", .{number});

    try w.flush();
}

/// Simple brute force.
fn getMianChowla3(comptime n: usize) ![n]u64 {
    var t0: std.time.Timer = try .start();

    const nn = (n * (n + 1)) * 2;

    var mc: [n]u64 = undefined;
    var sums: [nn]u64 = undefined;

    mc[0] = 1;
    sums[0] = 2;

    var ss: u64 = 1;
    for (1..n) |i| {
        const le = ss;
        var j: u64 = mc[i - 1] + 1;
        next_j: while (true) : (j += 1) {
            mc[i] = j;
            for (0..i + 1) |k| {
                const sum = mc[k] + j;
                if (std.mem.lastIndexOfScalar(u64, sums[0..ss], sum) != null) {
                    ss = le;
                    continue :next_j;
                }
                sums[ss] = sum;
                ss += 1;
            }
            break;
        }
    }
    std.log.info("Mian-Chowla sequence processed in {D}", .{t0.read()});

    return mc;
}

fn run4(allocator: std.mem.Allocator, n: usize, w: *std.Io.Writer) !void {
    try w.writeAll("\n\n" ++ "-" ** 66 ++ "\n");
    try w.print("Calculating {d} terms of Mian-Chowla sequence (tweaked translation of C)...\n", .{n});
    try w.flush();

    const mc = try getMianChowla1(allocator, n);
    defer allocator.free(mc);

    try w.writeAll("\nThe first 30 terms of the Mian-Chowla sequence are:\n");
    for (mc[0..30]) |number|
        try w.print("{d} ", .{number});
    try w.writeAll("\n\nTerms 91 to 100 of the Mian-Chowla sequence are:\n");
    for (mc[90..]) |number|
        try w.print("{d} ", .{number});

    try w.flush();
}

// Tweaked version of C using std.DynamicBitSet instead of slice of bool.
// Caller owns returned slice memory.
fn getMianChowla4(allocator: std.mem.Allocator, n: usize) ![]u64 {
    var t0: std.time.Timer = try .start();

    var mc = try allocator.alloc(u64, n);
    var nn = n * (n + 1) / 2;
    var is_sum = try std.DynamicBitSet.initEmpty(allocator, nn);
    defer is_sum.deinit();

    var c: usize = 0;
    var i: usize = 1;
    while (c < n) : (i += 1) {
        mc[c] = i;
        if (i + i > nn) {
            var new_capacity = nn;
            // Grow memory exponentially.
            while (new_capacity < i + i)
                new_capacity *|= 2;
            try is_sum.resize(new_capacity, false);
            nn = new_capacity;
        }
        var is_unique = true;
        var j: usize = 0;
        while (j < c and is_unique) : (j += 1)
            is_unique = !is_sum.isSet(i + mc[j]);
        if (is_unique) {
            for (mc[1 .. c + 1]) |existing|
                is_sum.set(i + existing);
            c += 1;
        }
    }
    std.log.info("Mian-Chowla sequence (tweaked translation of C) processed in {D}", .{t0.read()});

    return mc;
}
