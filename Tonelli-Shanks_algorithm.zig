// https://rosettacode.org/wiki/Tonelli-Shanks_algorithm
// {{works with|Zig|0.17.1}}
// copied from rosettacode and tweaked
const std = @import("std");
const Io = std.Io;

fn multiplyModulus(a: anytype, b: anytype, modulus: anytype) @TypeOf(a, b, modulus) {
    const T = @TypeOf(a, b, modulus);

    var a_mod: T = a % modulus;
    var b_mod: T = b % modulus;

    if (b_mod < a_mod)
        std.mem.swap(T, &a_mod, &b_mod);

    var result: T = 0;
    var a_temp = a_mod;
    var b_temp = b_mod;

    while (a_temp > 0) {
        if (a_temp % 2 == 1)
            result = (result + b_temp) % modulus;
        b_temp = (b_temp << 1) % modulus;
        a_temp >>= 1;
    }
    return result;
}

fn powerModulus(base: anytype, exponent: anytype, modulus: anytype) @TypeOf(base, exponent, modulus) {
    if (modulus == 1)
        return 0;

    const T = @TypeOf(base, exponent, modulus);

    var base_mod = base % modulus;
    var result: T = 1;
    var exp = exponent;

    while (exp > 0) {
        if ((exp & 1) == 1)
            result = multiplyModulus(result, base_mod, modulus);
        base_mod = multiplyModulus(base_mod, base_mod, modulus);
        exp >>= 1;
    }
    return result;
}

fn calcLegendre(a: anytype, p: anytype) @TypeOf(a, p) {
    return powerModulus(a, (p - 1) / 2, p);
}

fn solveTonelliShanks(n: anytype, p: anytype) ?struct {
    root1: @TypeOf(n, p),
    root2: @TypeOf(n, p),
} {
    const T = @TypeOf(n, p);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("solveTonelliShanks() expected unsigned integer arguments, found " ++ @typeName(@TypeOf(n)) ++ " and " ++ @typeName(@TypeOf(p)));

    if (calcLegendre(n, p) != 1)
        return null;

    // Factor out powers of 2 from p - 1
    var q = p - 1;
    var s: T = 0;
    while (q % 2 == 0) {
        q /= 2;
        s += 1;
    }

    if (s == 1) {
        const result = powerModulus(n, (p + 1) / 4, p);
        return .{ .root1 = result, .root2 = p - result };
    }

    // Find a non-square z such as ( z | p ) = -1
    var z: T = 2;
    while (calcLegendre(z, p) != p - 1)
        z += 1;

    var c = powerModulus(z, q, p);
    var t = powerModulus(n, q, p);
    var m = s;
    var result = powerModulus(n, (q + 1) >> 1, p);

    while (t != 1) {
        var i: T = 1;
        var z_temp = multiplyModulus(t, t, p);
        while (z_temp != 1 and i < m - 1) {
            i += 1;
            z_temp = multiplyModulus(z_temp, z_temp, p);
        }
        const b = powerModulus(c, @as(T, 1) << @intCast(m - i - 1), p);
        c = multiplyModulus(b, b, p);
        t = multiplyModulus(t, c, p);
        m = i;
        result = multiplyModulus(result, b, p);
    }

    return .{ .root1 = result, .root2 = p - result };
}

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout_writer = &stdout_file.interface;

    const tests: []const struct { n: u64, p: u64 } = &.{
        .{ .n = 10, .p = 13 },
        .{ .n = 56, .p = 101 },
        .{ .n = 1_030, .p = 1_009 },
        .{ .n = 1_032, .p = 1_009 },
        .{ .n = 44_402, .p = 100_049 },
        .{ .n = 665_820_697, .p = 1_000_000_009 },
        .{ .n = 881_398_088_036, .p = 1_000_000_000_039 },
    };

    for (tests) |my_test| {
        try stdout_writer.print("n = {}, p = {}", .{ my_test.n, my_test.p });
        if (solveTonelliShanks(my_test.n, my_test.p)) |solution|
            try stdout_writer.print(" has solutions: {} and {}\n\n", .{ solution.root1, solution.root2 })
        else
            try stdout_writer.print(" has no solutions because n is not a square modulo p\n\n", .{});
    }
    try stdout_writer.flush();
}
