// https://rosettacode.org/wiki/Magnanimous_numbers
// Translation of Go
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();

    try listMags(allocator, 1, 45, 15, writer);
    try listMags(allocator, 241, 250, 10, writer);
    try listMags(allocator, 391, 400, 10, writer);
}

fn listMags(allocator: std.mem.Allocator, from: u32, thru: u32, perLine: u8, writer: anytype) !void {
    if (from < 2)
        try writer.print("\nFirst {} magnanimous numbers:\n", .{thru})
    else {
        const s0 = try ordinal(allocator, from);
        const s1 = try ordinal(allocator, thru);
        try writer.print("\n{s} through {s} magnanimous numbers:\n", .{ s0, s1 });
        allocator.free(s1);
        allocator.free(s0);
    }
    var c: u32 = 0;
    var i: u32 = 0;
    while (c < thru) : (i += 1) {
        if (isMagnanimous(i)) {
            c += 1;
            if (c >= from) {
                try writer.print("{d:3} ", .{i});
                if (c % perLine == 0)
                    try writer.writeByte('\n');
            }
        }
    }
}

fn ordinal(allocator: std.mem.Allocator, n: anytype) ![]const u8 {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("ordinal() expected unsigned integer argument, found " ++ @typeName(T));

    var m = n % 100;
    if (m >= 4 and m <= 20) {
        return std.fmt.allocPrint(allocator, "{}th", .{n});
    }
    m %= 10;
    const suffix: []const u8 = switch (m) {
        1 => "st",
        2 => "nd",
        3 => "rd",
        else => "th",
    };
    return std.fmt.allocPrint(allocator, "{d}{s}", .{ n, suffix });
}

fn isMagnanimous(n: anytype) bool {
    const T = @TypeOf(n);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isMagnanimous() expected unsigned integer argument, found " ++ @typeName(T));

    if (n < 10)
        return true;

    var p: T = 10;
    while (true) : (p *= 10) {
        const q = n / p;
        const r = n % p;
        if (!isPrime(q + r))
            return false;
        if (q < 10)
            break;
    }
    return true;
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
