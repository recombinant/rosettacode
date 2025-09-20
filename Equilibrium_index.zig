// https://rosettacode.org/wiki/Equilibrium_index
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");

pub fn main() !void {
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    const tests = &[_][]const i16{
        &[_]i16{ -7, 1, 5, 2, -4, 3, 0 },
        &[_]i16{ 2, 4, 6 },
        &[_]i16{ 2, 9, 2 },
        &[_]i16{ 1, -1, 1, -1, 1, -1, 1 },
        &[_]i16{1},
        &[_]i16{},
    };

    try stdout.writeAll("The equilibrium indices for the following sequences are:\n");

    for (tests) |numbers| {
        const eqm = try equilibrium(allocator, numbers);
        defer allocator.free(eqm);
        const s = try std.fmt.allocPrint(allocator, "{any}", .{numbers});
        defer allocator.free(s);
        try stdout.print("{s:>26} -> {any}\n", .{ s, eqm });
    }
    try stdout.flush();
}

/// Allocates memory for the result, which must be freed by the caller.
fn equilibrium(allocator: std.mem.Allocator, a: []const i16) ![]i16 {
    var equi: std.ArrayList(i16) = .empty;
    if (a.len == 0)
        return equi.toOwnedSlice(allocator); // sequence has no indices at all

    var rsum: i16 = 0;
    for (a) |x|
        rsum += x;

    var lsum: i16 = 0;
    for (a, 0..) |x, i| {
        rsum -= x;
        if (rsum == lsum)
            try equi.append(allocator, @intCast(i));
        lsum += x;
    }
    return equi.toOwnedSlice(allocator);
}
