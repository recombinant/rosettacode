// https://rosettacode.org/wiki/Pell%27s_equation
// {{works with|Zig|0.15.1}}
// {{trans|C}}

// Neither C nor C++ gave the correct answer for 277 because of integer overflow which was performed silently as undefined behaviour.

// Zig gives the correct answer for 277.
// *Zig does not allow integer overflow at runtime on operators such as + and -.
// *Zig provides integer operators which can detect overflow, e.g. @subWithOverflow()
// *Zig supports arbitrary bit-width integers, e.g. u256.
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try printSolvedPell(61, stdout);
    try printSolvedPell(109, stdout);
    try printSolvedPell(181, stdout);
    try printSolvedPell(277, stdout);

    try stdout.flush();
}

const Pair = struct {
    v1: u256,
    v2: u256,

    fn init(a: u256, b: u256) Pair {
        return Pair{
            .v1 = a,
            .v2 = b,
        };
    }
};

fn solvePell(n: u256) Pair {
    const x: u256 = std.math.sqrt(n);

    // n is a perfect square - no solution other than 1,0
    if (x * x == n)
        return .init(1, 0);

    // there are non-trivial solutions
    var y = x;
    var z: u256 = 1;
    var r = 2 * x;
    var e: Pair = .init(1, 0);
    var f: Pair = .init(0, 1);
    var a: u256 = 0;
    var b: u256 = 0;

    while (true) {
        y = r * z - y;
        z = (n - y * y) / z;
        r = (x + y) / z;
        e = .init(e.v2, r * e.v2 + e.v1);
        f = .init(f.v2, r * f.v2 + f.v1);
        a = e.v2 + x * f.v2;
        b = f.v2;
        const ov = @subWithOverflow(a * a, n * b * b);
        if (ov[1] != 0)
            continue;
        if (ov[0] == 1) // a * a, n * b * b == 1
            break;
    }
    return Pair.init(a, b);
}

fn printSolvedPell(n: u256, w: *std.Io.Writer) !void {
    const r = solvePell(n);
    try w.print("x^2 - {d:3} * y^2 = 1 for x = {d:21} and y = {d:19}\n", .{ n, r.v1, r.v2 });
}
