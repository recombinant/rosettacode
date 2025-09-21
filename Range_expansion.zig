// https://rosettacode.org/wiki/Range_expansion
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    const input = "-6,-3--1,3-5,7-11,14,15,17-20";

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("range:{s}\n", .{input});

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var r: std.ArrayList(i8) = .empty;
    defer r.deinit(allocator);

    var last: i8 = undefined;
    var it = std.mem.tokenizeScalar(u8, input, ',');
    while (it.next()) |part| {
        if (std.mem.indexOfScalar(u8, part[1..], '-')) |i| {
            const n1 = try std.fmt.parseInt(i8, part[0 .. i + 1], 10);
            const n2 = try std.fmt.parseInt(i8, part[i + 2 ..], 10);
            if (n2 < n1 + 2) {
                std.log.err("invalid range: {s}", .{part});
                return error.InvalidRange;
            }
            if (r.items.len > 0) {
                if (last == n1) {
                    std.log.err("duplicate value: {}", .{n1});
                    return error.DuplicateValue;
                } else if (last > n1) {
                    std.log.err("out of order: {} > {}", .{ last, n1 });
                    return error.OutOfOrder;
                }
            }
            var n = n1;
            while (n <= n2) : (n += 1)
                try r.append(allocator, n);
            last = n2;
        } else {
            const n = try std.fmt.parseInt(i8, part, 10);
            if (r.items.len > 0) {
                if (last == n) {
                    std.log.err("duplicate value: {}", .{n});
                    return error.DuplicateValue;
                } else if (last > n) {
                    std.log.err("out of order: {} > {}", .{ last, n });
                    return error.OutOfOrder;
                }
            }
            try r.append(allocator, n);
            last = n;
        }
    }
    try stdout.print("expanded:{any}\n", .{r.items});

    try stdout.flush();
}
