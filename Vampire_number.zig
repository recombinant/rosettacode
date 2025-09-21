// https://rosettacode.org/wiki/Vampire_number
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    //
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    //
    var solutions: std.ArrayList(Solution) = .empty;
    defer solutions.deinit(allocator);
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
                    try stdout.print("{}: {} ", .{ found_count, num });
                    for (solutions.items) |fangs|
                        try stdout.print(" = {} ✕ {}", .{ fangs[0], fangs[1] });
                    try stdout.writeByte('\n');
                    if (found_count == 25)
                        break :outer;
                };
            i += 2;
        }
        try stdout.writeByte('\n');
    }
    // --------------------------------------------------- task 2
    {
        const numbers = [_]u64{ 16_758_243_290_880, 24_959_017_348_650, 14_593_825_548_650 };
        for (numbers) |num| {
            if (try isVampireNumber(allocator, num, &solutions)) {
                defer solutions.clearRetainingCapacity();
                try stdout.print("{}", .{num});
                for (solutions.items) |pair|
                    try stdout.print(" = {} ✕ {}", .{ pair[0], pair[1] });
                try stdout.writeByte('\n');
            } else {
                try stdout.print("{} is not a vampire number\n", .{num});
            }
        }
    }
    // ----------------------------------------------------- done
    try stdout.flush();
}

const Solution = struct { u64, u64 };

fn isVampireNumber(allocator: std.mem.Allocator, n: u64, solutions: *std.ArrayList(Solution)) !bool {
    const n_digits: usize = std.math.log10_int(n) + 1;
    std.debug.assert(n_digits & 1 == 0); // must be even
    //
    var buffer1 = try allocator.alloc(u8, n_digits);
    defer allocator.free(buffer1);
    var buffer2 = try allocator.alloc(u8, n_digits + 1);
    defer allocator.free(buffer2);
    //
    const len_n = std.fmt.printInt(buffer1, n, 10, .lower, .{});
    std.debug.assert(len_n == buffer1.len);
    const string1 = buffer1[0..len_n];
    std.mem.sortUnstable(u8, string1, {}, std.sort.asc(u8));
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
        const len_a = std.fmt.printInt(buffer2, a, 10, .lower, .{});
        std.debug.assert(len_a == fang_len);
        const len_b = std.fmt.printInt(buffer2[len_a..], b, 10, .lower, .{});
        if (len_a != len_b)
            continue;
        const string2 = buffer2[0 .. len_a + len_b];
        std.mem.sortUnstable(u8, string2, {}, std.sort.asc(u8));
        if (std.mem.eql(u8, string1, string2))
            try solutions.append(allocator, .{ a, b });
    }
    return solutions.items.len != 0;
}
