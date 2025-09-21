// https://www.rosettacode.org/wiki/Magic_squares_of_odd_order
// {{works with|Zig|0.15.1}}
// {{trans|C}}
// Usage : executable <integer specifying rows in magic square>
const std = @import("std");

const MagicError = error{
    MissingCountArgument,
    CountArgumentNotInteger,
    CountArgumentLessThanThree,
    CountArgumentNotOdd,
};

pub fn main() !void {
    const n: u16 = try getN();
    // --------------------------------
    if (n < 3)
        return MagicError.CountArgumentLessThanThree;
    if (n & 1 != 1)
        return MagicError.CountArgumentNotOdd;
    // --------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    for (0..n) |i| {
        for (0..n) |j|
            try stdout.print("{d:4}", .{f(n, n - j - 1, i) * n + f(n, j, i) + 1});
        try stdout.writeByte('\n');
    }
    try stdout.print("\nMagic constant: {}\n", .{(n * n + 1) / 2 * n});
    // --------------------------------
    try stdout.flush();
}

fn f(n: u16, x: usize, y: usize) u16 {
    return @intCast((x + y * 2 + 1) % n);
}

/// Get the square dimension from the command line.
fn getN() !u16 {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    //
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip(); // current program
    //
    if (args.next()) |count_string| {
        const n = std.fmt.parseInt(u16, count_string, 10) catch
            return MagicError.CountArgumentNotInteger;
        return n; // ------------------- column / row count
    } else {
        return MagicError.MissingCountArgument;
    }
}
