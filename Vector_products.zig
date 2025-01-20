// https://rosettacode.org/wiki/Vector_products
// Uses Zig vectors https://ziglang.org/documentation/master/#Vectors
const std = @import("std");

const Vector = struct {
    // refer https://geometrian.com/resources/cross_product/
    // 3 element vector, 4th element is ignored and should be zero
    data: @Vector(4, f32),

    fn init(x: f32, y: f32, z: f32) Vector {
        return Vector{ .data = .{ x, y, z, 0 } };
    }
    fn dotProduct(u: Vector, v: Vector) f32 {
        // Takes advantage of SIMD instructions
        return @reduce(.Add, u.data * v.data);
    }
    fn crossProduct(u: Vector, v: Vector) Vector {
        // https://geometrian.com/resources/cross_product/
        // Method 1: Simple SSE
        const tmp0 = @shuffle(f32, u.data, u.data, @Vector(4, i32){ 3, 0, 2, 1 });
        const tmp1 = @shuffle(f32, v.data, v.data, @Vector(4, i32){ 3, 1, 0, 2 });
        const tmp2 = @shuffle(f32, u.data, u.data, @Vector(4, i32){ 3, 1, 0, 2 });
        const tmp3 = @shuffle(f32, v.data, v.data, @Vector(4, i32){ 3, 0, 2, 1 });
        const tmp4 = tmp0 * tmp1 - tmp2 * tmp3;
        return Vector{
            .data = @shuffle(f32, tmp4, tmp4, @Vector(4, i32){ 3, 2, 1, 0 }),
        };
    }
    fn scalarTripleProduct(a: Vector, b: Vector, c: Vector) f32 {
        return a.dotProduct(b.crossProduct(c));
    }
    fn vectorTripleProduct(a: Vector, b: Vector, c: Vector) Vector {
        return a.crossProduct(b.crossProduct(c));
    }
    pub fn format(u: Vector, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("({d}, {d}, {d})", .{ u.data[0], u.data[1], u.data[2] });
    }
};

pub fn main() !void {
    const writer = std.io.getStdOut().writer();

    const a: Vector = .init(3, 4, 5);
    const b: Vector = .init(4, 3, 5);
    const c: Vector = .init(-5, -12, -13);

    try writer.print("a = {}\n", .{a});
    try writer.print("b = {}\n", .{b});
    try writer.print("c = {}\n", .{c});
    try writer.print("a · b = {d}\n", .{a.dotProduct(b)});
    try writer.print("a ⨯ b = {}\n", .{a.crossProduct(b)});
    try writer.print("a · (b ⨯ c) = {d}\n", .{a.scalarTripleProduct(b, c)});
    try writer.print("a ⨯ (b ⨯ c) = {}\n", .{a.vectorTripleProduct(b, c)});
}
