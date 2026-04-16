// https://rosettacode.org/wiki/Equilibrium_index
// {{works with|Zig|0.16.0}}
// {{trans|Wren}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
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
        const eqm = try equilibrium(gpa, numbers);
        defer gpa.free(eqm);
        const s = try std.fmt.allocPrint(gpa, "{any}", .{numbers});
        defer gpa.free(s);
        try stdout.print("{s:>26} -> {any}\n", .{ s, eqm });
    }
    try stdout.flush();
}

/// Allocates memory for the result, which must be freed by the caller.
fn equilibrium(allocator: Allocator, a: []const i16) ![]i16 {
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
