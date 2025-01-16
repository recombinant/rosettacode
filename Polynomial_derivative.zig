// https://rosettacode.org/wiki/Polynomial_derivative
// Translation of C++
const std = @import("std");

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try writer.writeAll("The derivatives of the following polynomials are:\n\n");
    const polynomials = [_][]const i32{ &.{5}, &.{ 4, -3 }, &.{ -1, 6, 5 }, &.{ -4, 3, -2, 1 }, &.{ 1, 1, 0, -1, -1 } };
    for (polynomials) |polynomial| {
        try printVector(polynomial, writer);
        try writer.writeAll(" => ");
        const d = try differentiate(allocator, polynomial);
        try printVector(d, writer);
        allocator.free(d);
        try writer.writeByte('\n');
    }
}

fn printVector(vec: []const i32, writer: anytype) !void {
    try writer.writeByte('[');
    for (vec[0..vec.len], 1..) |n, i| {
        try writer.print("{}", .{n});
        if (i != vec.len)
            try writer.writeAll(", ");
    }
    try writer.writeByte(']');
}

fn differentiate(allocator: std.mem.Allocator, polynomial: []const i32) ![]const i32 {
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
