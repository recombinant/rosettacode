// https://rosettacode.org/wiki/Smith_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // ----------------------------------------------------

    try stdout.writeAll("All the Smith Numbers < 10000 are:\n");
    const count = try listAllSmithNumbers(allocator, stdout, 10_000);
    try stdout.print("\nFound {d} Smith numbers.\n", .{count});

    // ----------------------------------------------------
    try stdout.flush();
}

fn listAllSmithNumbers(allocator: std.mem.Allocator, w: *std.Io.Writer, x: u64) !u16 {
    var array: std.ArrayList(u64) = .empty;
    defer array.deinit(allocator);

    var count: u16 = 0;

    for (4..x) |a| {
        array.clearRetainingCapacity();
        try primeFactors(allocator, a, &array);
        if (array.items.len < 2)
            continue;
        if (sumDigits(a) == sumFactors(array.items)) {
            try w.print("{d:4}", .{a});
            count += 1;
            try w.writeByte(if (count % 20 == 0) '\n' else ' ');
        }
    }
    return count;
}

fn primeFactors(allocator: std.mem.Allocator, x_: u64, array: *std.ArrayList(u64)) !void {
    var p: u64 = 2;
    if (x_ == 1)
        try array.append(allocator, 1)
    else {
        var x = x_;
        while (true)
            if ((x % p) == 0) {
                try array.append(allocator, p);
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
