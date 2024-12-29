// https://rosettacode.org/wiki/Euler%27s_identity
const std = @import("std");
const Complex = std.math.Complex(f64);
const complex = std.math.complex;

pub fn main() void {
    const r = complex.exp(Complex.init(0, std.math.pi)).add(Complex.init(1, 0));
    std.debug.print("e ^ πi + 1 = [{d}, {d}] ≅ 0\n", .{ r.re, r.im });
}
