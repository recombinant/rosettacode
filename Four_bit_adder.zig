// https://rosettacode.org/wiki/Four_bit_adder
// {{works with|Zig|0.15.1}}
// {{trans|C}}
// Zig has a bit type, u1,
const std = @import("std");

pub fn main() void {
    const a0, const a1, const a2, const a3 = [4]u1{ 0, 1, 0, 0 };
    const b0, const b1, const b2, const b3 = [4]u1{ 0, 1, 1, 1 };
    const s0, const s1, const s2, const s3, const ov = fourBitAdder(a0, a1, a2, a3, b0, b1, b2, b3);

    std.debug.print(
        "{b}{b}{b}{b} + {b}{b}{b}{b} = {b}{b}{b}{b}, overflow = {b}\n",
        .{
            a3, a2, a1, a0,
            b3, b2, b1, b0,
            s3, s2, s1, s0,
            ov,
        },
    );
}

/// A four-bit ripple-carry adder can be realized using four 1-bit full adders.
fn fourBitAdder(a0: u1, a1: u1, a2: u1, a3: u1, b0: u1, b1: u1, b2: u1, b3: u1) struct { u1, u1, u1, u1, u1 } {
    // sum bits and carry bits
    const s0, const c0 = fullAdder(a0, b0, 0); // this first adder could be a half adder
    const s1, const c1 = fullAdder(a1, b1, c0);
    const s2, const c2 = fullAdder(a2, b2, c1);
    const s3, const ov = fullAdder(a3, b3, c2); // final carry is overflow
    return .{ s0, s1, s2, s3, ov };
}

/// A half adder can be made using an "xor" gate and an "and" gate.
/// Takes two bits and returns sum and carry bits
fn halfAdder(a: u1, b: u1) struct { u1, u1 } {
    const sum: u1 = xor(a, b);
    const carry: u1 = a & b;
    return .{ sum, carry };
}

/// 1-bit full adders can be built with two half adders and an "or" gate.
/// Takes three bits and returns sum and carry bits
fn fullAdder(a: u1, b: u1, c0: u1) struct { u1, u1 } {
    // partial sum, first carry
    const sa, const ca = halfAdder(a, b);
    // final sum, second carry
    const s, const cb = halfAdder(sa, c0);
    // final carry
    const c1 = ca | cb;
    return .{ s, c1 }; // sum and carry
}

/// The xor gate can be made using two "not"s, two "and"s and one "or".
fn xor(x: u1, y: u1) u1 {
    return (~x & y) | (x & ~y);
}
