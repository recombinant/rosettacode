// https://rosettacode.org/wiki/CORDIC
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const Io = std.Io;
const PI = std.math.pi;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    {
        // 64 bit floating point
        var c_cos: f64 = undefined;
        var c_sin: f64 = undefined;

        try stdout_writer.writeAll("  x       sin(x)     diff. sine     cos(x)    diff. cosine\n");
        var th: i32 = -90;
        while (th <= 90) : (th += 15) {
            const thr = std.math.degreesToRadians(@as(f64, @floatFromInt(th)));
            Cordic(f64).cordic(thr, 24, &c_cos, &c_sin);
            try stdout_writer.print("{d:3}.0°  {d:11.8} ({d:11.8}) {d:11.8} ({d:11.8})\n", .{ th, c_sin, c_sin - @sin(thr), c_cos, c_cos - @cos(thr) });
        }
    }
    inline for ([_]type{ f16, f32, f64, f80, f128 }) |T| {
        try stdout_writer.print("\n{} bit floating point\n", .{@typeInfo(T).float.bits});

        var c_cos: T = undefined;
        var c_sin: T = undefined;

        const test_angles: []const T = &.{ -9.0, 0.0, 1.5, 6.0 };
        try stdout_writer.writeAll("x(rads)   sin(x)     diff. sine     cos(x)    diff. cosine\n");
        for (test_angles) |angle| {
            const thr = angle;
            Cordic(T).cordic(thr, 24, &c_cos, &c_sin);
            try stdout_writer.print("{d:4.1}    {d:11.8} ({d:11.8}) {d:11.8} ({d:11.8})\n", .{ thr, c_sin, c_sin - @sin(thr), c_cos, c_cos - @cos(thr) });
        }
    }
    try stdout_writer.flush();
}

fn Cordic(T: type) type {
    if (@typeInfo(T) != .float)
        @compileError("Cordic() expected floating point type argument, found " ++ @typeName(T));

    return struct {
        // Constants for angles and kvalues
        const ANGLES: []const T = &.{
            0.78539816339745, 0.46364760900081, 0.24497866312686, 0.12435499454676,
            0.06241880999596, 0.03123983343027, 0.01562372862048, 0.00781234106010,
            0.00390623013197, 0.00195312251648, 0.00097656218956, 0.00048828121119,
            0.00024414062015, 0.00012207031189, 0.00006103515617, 0.00003051757812,
            0.00001525878906, 0.00000762939453, 0.00000381469727, 0.00000190734863,
            0.00000095367432, 0.00000047683716, 0.00000023841858, 0.00000011920929,
            0.00000005960464, 0.00000002980232, 0.00000001490116, 0.00000000745058,
        };

        const KVALUES: []const T = &.{
            0.70710678118655, 0.63245553203368, 0.61357199107790, 0.60883391251775,
            0.60764825625617, 0.60735177014130, 0.60727764409353, 0.60725911229889,
            0.60725447933256, 0.60725332108988, 0.60725303152913, 0.60725295913894,
            0.60725294104140, 0.60725293651701, 0.60725293538591, 0.60725293510314,
            0.60725293503245, 0.60725293501477, 0.60725293501035, 0.60725293500925,
            0.60725293500897, 0.60725293500890, 0.60725293500889, 0.60725293500888,
        };

        // Cordic algorithm implementation
        fn cordic(alpha: T, n: usize, c_cos: *T, c_sin: *T) void {
            var x: T = 1.0;
            var y: T = 0.0;
            // Fixed the modulo operation with signed integers
            const floor_val: i32 = @intFromFloat(@floor(alpha / (2.0 * PI)));
            const newsgn: T = if (@mod(floor_val, 2) == 1) 1.0 else -1.0;

            if (alpha < -PI / 2.0 or alpha > PI / 2.0) {
                if (alpha < 0.0)
                    cordic(alpha + PI, n, &x, &y)
                else
                    cordic(alpha - PI, n, &x, &y);
                c_cos.* = x * newsgn;
                c_sin.* = y * newsgn;
                return;
            }

            const ix = if (n - 1 > 23) 23 else n - 1;
            const kn = KVALUES[ix];
            var theta: T = 0.0;
            var pow2: T = 1.0;

            for (0..n) |i| {
                const atn = ANGLES[i];
                const sigma: T = if (theta < alpha) 1.0 else -1.0;
                theta += sigma * atn;
                const t = x;
                x -= sigma * y * pow2;
                y += sigma * t * pow2;
                pow2 /= 2.0;
            }
            c_cos.* = x * kn;
            c_sin.* = y * kn;
        }
    };
}
