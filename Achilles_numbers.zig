// https://rosettacode.org/wiki/Achilles_numbers
// {{works with|Zig|0.16.0}}
// {{trans|C++}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var t0: Io.Timestamp = .now(io, .real);
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------

    const limit: u64 = 1_000_000_000_000_000;

    const pps = try perfectPowers(gpa, limit);
    defer gpa.free(pps);
    const ach = try achilles(gpa, u64, 1, 1_000_000, pps);
    defer gpa.free(ach);

    try stdout.writeAll("First 50 Achilles numbers:\n");
    for (ach[0..@min(50, ach.len)], 1..) |a, i|
        try stdout.print("{d:7}{c}", .{ a, @as(u8, if (i % 10 == 0) '\n' else ' ') });
    try stdout.flush();

    try stdout.writeAll("\nFirst 50 strong Achilles numbers:\n");
    var i: usize = 0;
    var count: usize = 0;
    while (count < 50 and i < ach.len) : (i += 1)
        if (std.sort.binarySearch(u64, ach, totient(ach[i]), orderU64) != null) {
            count += 1;
            try stdout.print("{d:7}{c}", .{ ach[i], @as(u8, if (count % 10 == 0) '\n' else ' ') });
        };
    try stdout.flush();

    var digits: usize = 2;
    try stdout.writeAll("\nNumber of Achilles numbers with:\n");
    var from: u64 = 1;
    var to: u64 = 100;
    while (to <= limit) : ({
        to *= 10;
        digits += 1;
    }) {
        const ach2 = try achilles(gpa, u64, from, to, pps);
        try stdout.print("{d:2} digits: {d}\n", .{ digits, ach2.len });
        try stdout.flush();
        gpa.free(ach2);
        from = to;
    }
    try stdout.writeByte('\n');
    try stdout.flush();

    std.log.info("processed in {f}", .{t0.untilNow(io, .real)});
}

/// Return sorted slice of unique items. Caller owns returned slice.
fn uniqueSort(T: type, allocator: Allocator, vector: std.ArrayList(T)) ![]T {
    var result: std.ArrayList(T) = try .initCapacity(allocator, vector.items.len);
    std.mem.sortUnstable(T, vector.items, {}, std.sort.asc(T));

    for (vector.items[0 .. vector.items.len - 1], vector.items[1..]) |p0, p1|
        if (p0 != p1) {
            result.appendAssumeCapacity(p0);
        };
    return result.toOwnedSlice(allocator);
}

fn perfectPowers(allocator: Allocator, n: anytype) ![]@TypeOf(n) {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("perfectPowers() expected unsigned integer argument, found " ++ @typeName(T));

    // to prevent variable p overflow
    const P = std.meta.Int(.unsigned, @typeInfo(T).int.bits * 2); // u128 in long-hand

    var result: std.ArrayList(T) = .empty;
    defer result.deinit(allocator);

    const s = std.math.sqrt(n);
    var i: T = 2;
    while (i <= s) : (i += 1) {
        var p: P = i * i;
        while (p < n) : (p *= i)
            try result.append(allocator, @intCast(p));
    }

    return uniqueSort(T, allocator, result);
}

fn orderU64(context: u64, item: u64) std.math.Order {
    return std.math.order(context, item);
}

fn achilles(allocator: Allocator, T: type, from: T, to: T, pps: []T) ![]T {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("achilles() expected unsigned integer type argument, found " ++ @typeName(T));
    var result: std.ArrayList(T) = .empty;
    defer result.deinit(allocator);

    const c: T = @intFromFloat(std.math.cbrt(@as(f64, @floatFromInt(to / 4))));
    const s = std.math.sqrt(to / 8);
    var b: T = 2;
    while (b <= c) : (b += 1) {
        const b3 = b * b * b;
        var a: T = 2;
        while (a <= s) : (a += 1) {
            const p = b3 * a * a;
            if (p >= to)
                break;
            if (p >= from and std.sort.binarySearch(T, pps, p, orderU64) == null)
                try result.append(allocator, p);
        }
    }
    return uniqueSort(T, allocator, result);
}

// /// Simple implementation of totient
// fn totient(n: anytype) @TypeOf(n) {
//     const T = @TypeOf(n);
//     if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
//         @compileError("totient() expected unsigned integer argument, found " ++ @typeName(T));
//
//     var tot: T = 0;
//     var m: T = 0;
//     while (m != n) : (m += 1)
//         tot += @intFromBool(std.math.gcd(m, n) == 1);
//     return tot;
// }

fn totient(n_: anytype) @TypeOf(n_) {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("totient() expected unsigned integer argument, found " ++ @typeName(T));
    var n = n_;
    var tot = n_;
    if ((n & 1) == 0) {
        while ((n & 1) == 0)
            n >>= 1;
        tot -= tot >> 1;
    }
    var p: T = 3;
    while (p * p <= n) : (p += 2) {
        if (n % p == 0) {
            while (n % p == 0)
                n /= p;
            tot -= tot / p;
        }
    }
    if (n > 1)
        tot -= tot / n;
    return tot;
}

// ==================== alternative method of calculating totient
/// From stackoverflow 40952209
fn coprime(a_: anytype, b_: anytype) @TypeOf(a_, b_) {
    const T = @TypeOf(a_, b_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("coprime() expected unsigned integer argument, found " ++ @typeName(T));

    var a: T = a_;
    var b: T = b_;
    while (b != 0) {
        a %= b;
        std.mem.swap(T, &a, &b);
    }
    return a;
}
/// From stackoverflow 40952209
/// Euler's Totient (phi === totient)
fn phi(n: anytype) @TypeOf(n) {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("phi() expected unsigned integer argument, found " ++ @typeName(T));

    var result: T = 0;
    var k: T = 1;
    while (k <= n) : (k += 1)
        result += @intFromBool(coprime(k, n) == 1);
    return result;
}
