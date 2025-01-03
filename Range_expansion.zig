// https://rosettacode.org/wiki/Range_expansion
// Translation of Go
const std = @import("std");

pub fn main() !void {
    const input = "-6,-3--1,3-5,7-11,14,15,17-20";

    const writer = std.io.getStdOut().writer();
    try writer.print("range:{s}\n", .{input});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var r = std.ArrayList(i8).init(allocator);
    defer r.deinit();

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
                try r.append(n);
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
            try r.append(n);
            last = n;
        }
    }
    try writer.print("expanded:{any}\n", .{r.items});
}
