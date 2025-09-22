// https://rosettacode.org/wiki/Square-free_integers
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
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
    var writer: std.Io.Writer = .fixed(&buffer);
    var i = from;
    while (i <= to) : (i += 1) {
        if (isSquareFree(i)) {
            if (writer.end != 0)
                try writer.writeByte(' ');
            try writer.printInt(i, 10, .lower, .{});
            if (writer.end >= 80) {
                print("{s}\n", .{writer.buffered()});
                _ = writer.consumeAll();
            }
        }
    }
    if (writer.end != 0)
        print("{s}\n", .{writer.buffered()});
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
