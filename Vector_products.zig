// https://rosettacode.org/wiki/Vector_products
// {{works with|Zig|0.15.1}}
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
    pub fn format(u: Vector, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("({d}, {d}, {d})", .{ u.data[0], u.data[1], u.data[2] });
    }
};

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const a: Vector = .init(3, 4, 5);
    const b: Vector = .init(4, 3, 5);
    const c: Vector = .init(-5, -12, -13);

    try stdout.print("a = {f}\n", .{a});
    try stdout.print("b = {f}\n", .{b});
    try stdout.print("c = {f}\n", .{c});
    try stdout.print("a · b = {d}\n", .{a.dotProduct(b)});
    try stdout.print("a ⨯ b = {f}\n", .{a.crossProduct(b)});
    try stdout.print("a · (b ⨯ c) = {d}\n", .{a.scalarTripleProduct(b, c)});
    try stdout.print("a ⨯ (b ⨯ c) = {f}\n", .{a.vectorTripleProduct(b, c)});

    try stdout.flush();
}
