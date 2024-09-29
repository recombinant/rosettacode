// https://rosettacode.org/wiki/Smith_numbers
// Translated from C
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------- stdout
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    // ----------------------------------------------------

    try stdout.writeAll("All the Smith Numbers < 10000 are:\n");
    const count = try listAllSmithNumbers(allocator, stdout, 10_000);
    try stdout.print("\nFound {d} Smith numbers.\n", .{count});

    // ----------------------------------------------------
    try bw.flush();
}

fn listAllSmithNumbers(allocator: mem.Allocator, writer: anytype, x: u64) !u16 {
    var array = std.ArrayList(u64).init(allocator);
    defer array.deinit();

    var count: u16 = 0;

    for (4..x) |a| {
        array.clearRetainingCapacity();
        try primeFactors(a, &array);
        if (array.items.len < 2)
            continue;
        if (sumDigits(a) == sumFactors(array.items)) {
            try writer.print("{d:4}", .{a});
            count += 1;
            try writer.writeByte(if (count % 20 == 0) '\n' else ' ');
        }
    }
    return count;
}

fn primeFactors(x_: u64, array: *std.ArrayList(u64)) !void {
    var p: u64 = 2;
    if (x_ == 1)
        try array.append(1)
    else {
        var x = x_;
        while (true)
            if ((x % p) == 0) {
                try array.append(p);
                x /= p;
                if (x == 1)
                    return;
            } else {
                p += 1;
            };
    }
}

fn sumDigits(x_: u64) u64 {
    var sum: u64 = 0;
    var x = x_;
    while (x != 0) {
        sum += x % 10;
        x /= 10;
    }
    return sum;
}

fn sumFactors(array: []const u64) u64 {
    var sum: u64 = 0;
    for (array) |n|
        sum += sumDigits(n);
    return sum;
}
