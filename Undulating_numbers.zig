// https://rosettacode.org/wiki/Undulating_numbers
// {{works with|Zig|0.15.1}}
// {{trans|Python}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for ([2]u8{ 10, 7 }) |base|
        try undulating(allocator, base, 600, stdout);

    try stdout.flush();
}

fn undulating(allocator: std.mem.Allocator, base: u8, n: u16, w: *std.Io.Writer) !void {
    const mpow = 53;
    const limit = try std.math.powi(u64, 2, mpow) - 1;
    const bsquare = @as(u64, base) * @as(u64, base);

    var u3_list: std.ArrayList(u64) = .empty;
    defer u3_list.deinit(allocator);
    var u4_list: std.ArrayList(u64) = .empty;
    defer u4_list.deinit(allocator);

    for (1..base) |a| {
        for (0..base) |b| {
            if (b == a)
                continue;
            const u = a * bsquare + b * base + a;
            const v = a * base + b;
            try u3_list.append(allocator, u);
            try u4_list.append(allocator, v * bsquare + v);
        }
    }
    // --------------------------------------------------- task 1
    try w.print("All 3 digit undulating numbers in base {}:\n", .{base});
    try printTable(u3_list.items, 9, w);
    // --------------------------------------------------- task 2
    try w.print("\nAll 4 digit undulating numbers in base {}:\n", .{base});
    try printTable(u4_list.items, 9, w);
    // --------------------------------------------------- task 3
    try w.print("\nAll 3 digit undulating numbers which are primes in base {}:\n", .{base});

    var primes: std.ArrayList(u64) = .empty;
    defer primes.deinit(allocator);
    for (u3_list.items) |u|
        if (u % 2 == 1 and u % 5 != 0 and isPrime(u))
            try primes.append(allocator, u);

    try printTable(primes.items, 9, w);
    // --------------------------------------------------- task 4
    const unc = u3_list.items.len + u4_list.items.len;
    var un_list: std.ArrayList(u64) = .empty;
    defer un_list.deinit(allocator);
    try un_list.ensureTotalCapacity(allocator, n);
    try un_list.appendSlice(allocator, u3_list.items);
    try un_list.appendSlice(allocator, u4_list.items);

    var j: usize = 0;
    outer: while (true) : (j += 1)
        for (0..unc) |i| {
            const u = un_list.items[j * unc + i] * bsquare + un_list.items[j * unc + i] % bsquare;
            if (u > limit)
                break :outer;
            try un_list.append(allocator, u);
        };
    try w.print("\nThe {} undulating number in base {} is: {}\n", .{ n, base, un_list.items[n - 1] });
    if (base != 10) {
        // bonus
        try w.print("or expressed in base {} : ", .{base});
        try w.printInt(un_list.items[n - 1], base, .lower, .{});
        try w.writeByte('\n');
    }
    // --------------------------------------------------- task 5
    try w.print("\nTotal number of undulating numbers in base {} < 2^{} = {} ", .{ base, mpow, un_list.items.len });
    try w.print("of which the largest is: {}\n", .{un_list.items[un_list.items.len - 1]});
    if (base != 10) {
        // bonus
        try w.print("or expressed in base {} : ", .{base});
        try w.printInt(un_list.items[un_list.items.len - 1], base, .lower, .{});
        try w.writeByte('\n');
    }
    try w.writeByte('\n');
}

fn printTable(nums: []const u64, cols: u8, w: *std.Io.Writer) !void {
    var lf = false;
    for (nums, 1..) |n, i| {
        try w.print(" {}", .{n});
        lf = (i % cols == 0 and i != 0);
        if (lf)
            try w.writeByte('\n');
    }
    if (!lf)
        try w.writeByte('\n');
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
