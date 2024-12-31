// https://rosettacode.org/wiki/Vampire_number
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    //
    const writer = std.io.getStdOut().writer();
    //
    var solutions = std.ArrayList(Solution).init(allocator);
    defer solutions.deinit();
    // --------------------------------------------------- task 1
    {
        var found_count: usize = 0;
        var i: u64 = 1;
        outer: while (true) {
            const start: u64 = try std.math.powi(u64, 10, i);
            const end = start * 10;
            var num = start;
            while (num < end) : (num += 1)
                if (try isVampireNumber(allocator, num, &solutions)) {
                    defer solutions.clearRetainingCapacity();
                    found_count += 1;
                    try writer.print("{}: {} ", .{ found_count, num });
                    for (solutions.items) |fangs|
                        try writer.print(" = {} ✕ {}", .{ fangs[0], fangs[1] });
                    try writer.writeByte('\n');
                    if (found_count == 25)
                        break :outer;
                };
            i += 2;
        }
        try writer.writeByte('\n');
    }
    // --------------------------------------------------- task 2
    {
        const numbers = [_]u64{ 16_758_243_290_880, 24_959_017_348_650, 14_593_825_548_650 };
        for (numbers) |num| {
            if (try isVampireNumber(allocator, num, &solutions)) {
                defer solutions.clearRetainingCapacity();
                try writer.print("{}", .{num});
                for (solutions.items) |pair|
                    try writer.print(" = {} ✕ {}", .{ pair[0], pair[1] });
                try writer.writeByte('\n');
            } else {
                try writer.print("{} is not a vampire number\n", .{num});
            }
        }
    }
}

const Solution = struct { u64, u64 };

fn isVampireNumber(allocator: std.mem.Allocator, n: u64, solutions: *std.ArrayList(Solution)) !bool {
    const n_digits = std.math.log10_int(n) + 1;
    std.debug.assert(n_digits & 1 == 0); // must be even
    //
    const buffer1 = try allocator.alloc(u8, n_digits);
    defer allocator.free(buffer1);
    const buffer2 = try allocator.alloc(u8, n_digits + 1);
    defer allocator.free(buffer2);
    //
    const len_n = std.fmt.formatIntBuf(buffer1, n, 10, .lower, .{});
    std.debug.assert(len_n == buffer1.len);
    const string1 = buffer1[0..len_n];
    std.mem.sort(u8, string1, {}, std.sort.asc(u8));
    //
    const fang_len = n_digits / 2;
    const start = try std.math.powi(u64, 10, fang_len - 1);
    const end = std.math.sqrt(n);
    var a = start;
    while (a <= end) : (a += 1) {
        if (n % a != 0)
            continue;
        const b = n / a;
        if (a % 10 == 0 and b % 10 == 0)
            continue;
        const len_a = std.fmt.formatIntBuf(buffer2, a, 10, .lower, .{});
        std.debug.assert(len_a == fang_len);
        const len_b = std.fmt.formatIntBuf(buffer2[len_a..], b, 10, .lower, .{});
        if (len_a != len_b)
            continue;
        const string2 = buffer2[0 .. len_a + len_b];
        std.mem.sort(u8, string2, {}, std.sort.asc(u8));
        if (std.mem.eql(u8, string1, string2))
            try solutions.append(.{ a, b });
    }
    return solutions.items.len != 0;
}
