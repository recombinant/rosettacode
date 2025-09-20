// https://rosettacode.org/wiki/Element-wise_operations
// {{works with|Zig|0.15.1}}
// Copied from rosettacode
const std = @import("std");

// Assumes input and output slices are all equal length.
fn Matrix(comptime T: type, comptime M: usize, comptime N: usize) type {
    return struct {
        pub const ops = struct {
            fn add(a: T, b: T) T {
                return a + b;
            }

            fn sub(a: T, b: T) T {
                return a - b;
            }

            fn mul(a: T, b: T) T {
                return a * b;
            }

            fn div(a: T, b: T) T {
                return a / b;
            }
        };

        fn new() [N][M]T {
            const s: [N][M]T = undefined;
            return s;
        }

        fn apply(r: *[N][M]T, a: []const []const T, b: []const []const T, func: fn (a: T, b: T) T) void {
            for (a, 0..) |e, i|
                for (e, 0..) |_, j| {
                    r[i][j] = func(a[i][j], b[i][j]);
                };
        }

        // In standard code it would be better to implement multi-dimensional arrays on
        // linear memory, handle the indexing in the struct and avoid allowing slices as
        // arguments.
        fn show(a: []const []const T, w: *std.Io.Writer) !void {
            for (a) |e|
                try w.print("{any}\n", .{e});
        }

        fn showF(a: [N][M]T, w: *std.Io.Writer) !void {
            for (a) |e|
                try w.print("{any}\n", .{e});
        }
    };
}

pub fn main() !void {
    const matrix = Matrix(f32, 3, 2);

    const m1 = [_][]const f32{
        &[_]f32{ 3, 1, 4 },
        &[_]f32{ 1, 5, 9 },
    };

    const m2 = [_][]const f32{
        &[_]f32{ 2, 7, 1 },
        &[_]f32{ 8, 2, 8 },
    };

    var r = matrix.new();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("m1:\n");
    try matrix.show(&m1, stdout);

    try stdout.writeAll("\nm2:\n");
    try matrix.show(&m2, stdout);

    matrix.apply(&r, &m1, &m2, matrix.ops.add);
    try stdout.writeAll("\nm1 + m2:\n");
    try matrix.showF(r, stdout);

    matrix.apply(&r, &m1, &m2, matrix.ops.sub);
    try stdout.writeAll("\nm1 - m2:\n");
    try matrix.showF(r, stdout);

    matrix.apply(&r, &m1, &m2, matrix.ops.mul);
    try stdout.writeAll("\nm1 * m2:\n");
    try matrix.showF(r, stdout);

    matrix.apply(&r, &m1, &m2, matrix.ops.div);
    try stdout.writeAll("\nm1 / m2:\n");
    try matrix.showF(r, stdout);

    try stdout.flush();
}
