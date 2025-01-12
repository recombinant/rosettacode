// https://rosettacode.org/wiki/Undulating_numbers
// Translation of Python
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([2]u8{ 10, 7 }) |base|
        try undulating(allocator, base, 600, writer);
}

fn undulating(allocator: std.mem.Allocator, base: u8, n: u16, writer: anytype) !void {
    const mpow = 53;
    const limit = try std.math.powi(u64, 2, mpow) - 1;
    const bsquare = @as(u64, base) * @as(u64, base);

    var u3_list = std.ArrayList(u64).init(allocator);
    defer u3_list.deinit();
    var u4_list = std.ArrayList(u64).init(allocator);
    defer u4_list.deinit();

    for (1..base) |a| {
        for (0..base) |b| {
            if (b == a)
                continue;
            const u = a * bsquare + b * base + a;
            const v = a * base + b;
            try u3_list.append(u);
            try u4_list.append(v * bsquare + v);
        }
    }
    // --------------------------------------------------- task 1
    try writer.print("All 3 digit undulating numbers in base {}:\n", .{base});
    try printTable(u3_list.items, 9, writer);
    // --------------------------------------------------- task 2
    try writer.print("\nAll 4 digit undulating numbers in base {}:\n", .{base});
    try printTable(u4_list.items, 9, writer);
    // --------------------------------------------------- task 3
    try writer.print("\nAll 3 digit undulating numbers which are primes in base {}:\n", .{base});

    var primes = std.ArrayList(u64).init(allocator);
    defer primes.deinit();
    for (u3_list.items) |u|
        if (u % 2 == 1 and u % 5 != 0 and isPrime(u))
            try primes.append(u);

    try printTable(primes.items, 9, writer);
    // --------------------------------------------------- task 4
    const unc = u3_list.items.len + u4_list.items.len;
    var un_list = std.ArrayList(u64).init(allocator);
    defer un_list.deinit();
    try un_list.ensureTotalCapacity(n);
    try un_list.appendSlice(u3_list.items);
    try un_list.appendSlice(u4_list.items);

    var j: usize = 0;
    outer: while (true) : (j += 1)
        for (0..unc) |i| {
            const u = un_list.items[j * unc + i] * bsquare + un_list.items[j * unc + i] % bsquare;
            if (u > limit)
                break :outer;
            try un_list.append(u);
        };
    try writer.print("\nThe {} undulating number in base {} is: {}\n", .{ n, base, un_list.items[n - 1] });
    if (base != 10) {
        // bonus
        try writer.print("or expressed in base {} : ", .{base});
        try std.fmt.formatInt(un_list.items[n - 1], base, .lower, .{}, writer);
        try writer.writeByte('\n');
    }
    // --------------------------------------------------- task 5
    try writer.print("\nTotal number of undulating numbers in base {} < 2^{} = {} ", .{ base, mpow, un_list.items.len });
    try writer.print("of which the largest is: {}\n", .{un_list.items[un_list.items.len - 1]});
    if (base != 10) {
        // bonus
        try writer.print("or expressed in base {} : ", .{base});
        try std.fmt.formatInt(un_list.items[un_list.items.len - 1], base, .lower, .{}, writer);
        try writer.writeByte('\n');
    }
    try writer.writeByte('\n');
}

fn printTable(nums: []const u64, cols: u8, writer: anytype) !void {
    var lf = false;
    for (nums, 1..) |n, i| {
        try writer.print(" {}", .{n});
        lf = (i % cols == 0 and i != 0);
        if (lf)
            try writer.writeByte('\n');
    }
    if (!lf)
        try writer.writeByte('\n');
}

fn isPrime(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isPrime() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 2) return false;

    inline for ([3]u3{ 2, 3, 5 }) |p| if (n % p == 0) return n == p;

    const wheel = comptime [_]u3{ 4, 2, 4, 2, 4, 6, 2, 6 };

    var p: T = 7;
    while (true)
        for (wheel) |w| {
            if (p * p > n) return true;
            if (n % p == 0) return false;
            p += w;
        };
}
