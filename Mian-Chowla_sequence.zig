// https://rosettacode.org/wiki/Mian-Chowla_sequence
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const mem = std.mem;
const time = std.time;
const print = std.debug.print;

pub fn main() !void {
    const n = 100;

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try run1(allocator, n);

    try run2(allocator, n);

    try run3(n);
}

fn run1(allocator: mem.Allocator, n: usize) !void {
    print("\n\n" ++ "-" ** 66 ++ "\n", .{});
    print("Calculating {d} terms of Mian-Chowla sequence (translation of C)\n", .{n});

    const mc = try getMianChowla2(allocator, n);
    defer allocator.free(mc);

    print("The first 30 terms of the Mian-Chowla sequence are:\n", .{});
    for (mc[0..30]) |number|
        print("{d} ", .{number});
    print("\n\nTerms 91 to 100 of the Mian-Chowla sequence are:\n", .{});
    for (mc[90..]) |number|
        print("{d} ", .{number});
}

// Translation of C Quick, but...
// Caller owns returned slice memory.
fn getMianChowla1(allocator: mem.Allocator, n: usize) ![]u64 {
    var mc = try allocator.alloc(u64, n);
    defer allocator.free(mc);
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
    return mc;
}

fn run2(allocator: mem.Allocator, n: usize) !void {
    print("\n\n" ++ "-" ** 66 ++ "\n", .{});
    print("Calculating {d} terms of Mian-Chowla sequence (translation of Go)\n", .{n});

    const mc = try getMianChowla2(allocator, n);
    defer allocator.free(mc);

    print("The first 30 terms of the Mian-Chowla sequence are:\n", .{});
    for (mc[0..30]) |number|
        print("{d} ", .{number});
    print("\n\nTerms 91 to 100 of the Mian-Chowla sequence are:\n", .{});
    for (mc[90..]) |number|
        print("{d} ", .{number});
}

/// Translation of Go
/// Caller owns returned slice memory.
fn getMianChowla2(allocator: mem.Allocator, n: usize) ![]u64 {
    var t0 = try time.Timer.start();

    var mc = try allocator.alloc(u64, n);
    mc[0] = 1;

    var is = std.AutoHashMap(u64, void).init(allocator);
    defer is.deinit();
    try is.put(2, {});

    var isx = std.ArrayList(u64).init(allocator);
    defer isx.deinit();

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
                try isx.append(sum);
            }
            for (isx.items) |x|
                try is.put(x, {});
            break;
        }
    }
    print("...processed in {}\n", .{fmt.fmtDuration(t0.read())});

    return mc;
}

fn run3(comptime n: usize) !void {
    print("\n\n" ++ "-" ** 66 ++ "\n", .{});
    print("Calculating {d} terms of Mian-Chowla sequence...\n", .{n});

    const mc = try getMianChowla3(n);

    print("The first 30 terms of the Mian-Chowla sequence are:\n", .{});
    for (mc[0..30]) |number|
        print("{d} ", .{number});
    print("\n\nTerms 91 to 100 of the Mian-Chowla sequence are:\n", .{});
    for (mc[90..]) |number|
        print("{d} ", .{number});
}

/// Simple brute force.
fn getMianChowla3(comptime n: usize) ![n]u64 {
    var t0 = try time.Timer.start();

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
                if (mem.lastIndexOfScalar(u64, sums[0..ss], sum) != null) {
                    ss = le;
                    continue :next_j;
                }
                sums[ss] = sum;
                ss += 1;
            }
            break;
        }
    }
    print("...processed in {}\n", .{fmt.fmtDuration(t0.read())});

    return mc;
}
