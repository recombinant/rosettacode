// https://rosettacode.org/wiki/Polynomial_derivative
// {{works with|Zig|0.16.0}}
// {{trans|C++}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("The derivatives of the following polynomials are:\n\n");
    const polynomials = [_][]const i32{ &.{5}, &.{ 4, -3 }, &.{ -1, 6, 5 }, &.{ -4, 3, -2, 1 }, &.{ 1, 1, 0, -1, -1 } };
    for (polynomials) |polynomial| {
        try printVector(polynomial, stdout);
        try stdout.writeAll(" => ");
        const d = try differentiate(gpa, polynomial);
        try printVector(d, stdout);
        gpa.free(d);
        try stdout.writeByte('\n');
    }

    try stdout.flush();
}

fn printVector(vec: []const i32, writer: *Io.Writer) !void {
    try writer.writeByte('[');
    for (vec[0..vec.len], 1..) |n, i| {
        try writer.print("{}", .{n});
        if (i != vec.len)
            try writer.writeAll(", ");
    }
    try writer.writeByte(']');
}

fn differentiate(allocator: Allocator, polynomial: []const i32) ![]const i32 {
    if (polynomial.len == 1) {
        var result = try allocator.alloc(i32, 1);
        result[0] = 0;
        return result;
    }
    const result = try allocator.alloc(i32, polynomial.len - 1);
    for (result, polynomial[1..polynomial.len], 1..) |*dest, source, i|
        dest.* = source * @as(i32, @intCast(i));
    return result;
}
