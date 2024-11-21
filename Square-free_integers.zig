// https://rosettacode.org/wiki/Square-free_integers
// Translation of C++
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    try printSquareFreeNumbers(1, 145);
    const trillion = 1_000_000_000_000;
    try printSquareFreeNumbers(trillion, trillion + 145);
    printSquareFreeCount(1, 100);
    printSquareFreeCount(1, 1000);
    printSquareFreeCount(1, 10000);
    printSquareFreeCount(1, 100000);
    printSquareFreeCount(1, 1000000);
}

fn isSquareFree(n_: anytype) bool {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isSquareFree() expected unsigned integer argument, found " ++ @typeName(T));

    if (n_ % 4 == 0) return false;

    var n = n_;
    var p: T = 3;
    while (p * p <= n) : (p += 2) {
        var count: usize = 0;
        while (n % p == 0) : (n /= p) {
            count += 1;
            if (count > 1) return false;
        }
    }
    return true;
}

fn printSquareFreeNumbers(from: u64, to: u64) !void {
    print("Square-free numbers between {} and {}:\n", .{ from, to });
    var buffer: [128]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);
    const writer = stream.writer();
    var i = from;
    while (i <= to) : (i += 1) {
        if (isSquareFree(i)) {
            if (try stream.getPos() != 0)
                try writer.writeByte(' ');
            try std.fmt.formatInt(i, 10, .lower, .{}, writer);
            if (try stream.getPos() >= 80) {
                print("{s}\n", .{stream.getWritten()});
                try stream.seekTo(0);
            }
        }
    }
    if (try stream.getEndPos() != 0)
        print("{s}\n", .{stream.getWritten()});
    print("\n", .{});
}

fn printSquareFreeCount(from: u64, to: u64) void {
    var count: usize = 0;
    var i = from;
    while (i <= to) : (i += 1)
        if (isSquareFree(i)) {
            count += 1;
        };
    print("Number of square-free numbers between {} and {}: {}\n", .{ from, to, count });
}
