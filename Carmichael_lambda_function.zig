// https://rosettacode.org/wiki/Carmichael_lambda_function
// Translation of C++
const std = @import("std");

const PrimePower = struct {
    prime: u32,
    power: u32,
};

pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var t0 = try std.time.Timer.start();

    try writer.writeAll(" n   carmichael(n) iterations(n)\n");
    try writer.writeAll("--------------------------------\n");
    var i: u32 = 1;
    while (i <= 25) : (i += 1)
        try writer.print("{d:2}{d:10}{d:14}\n", .{ i, try carmichaelLambda(allocator, i), try countIterationsToOne(allocator, i) });
    try writer.writeByte('\n');
    //
    try writer.writeAll("Iterations to 1     n     lambda(n)\n");
    try writer.writeAll("-----------------------------------\n");
    var n: u32 = 1;
    i = 0;
    while (i <= 15) : (i += 1) {
        while (try countIterationsToOne(allocator, n) != i)
            n += 1;
        try writer.print("{d:2}{d:19}{d:13}\n", .{ i, n, try carmichaelLambda(allocator, n) });
    }
    std.log.info("processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}

fn primePowers(allocator: std.mem.Allocator, number: u32) ![]PrimePower {
    var powers = std.ArrayList(PrimePower).init(allocator);
    var n = number;
    var i: u32 = 2;
    while (i <= std.math.sqrt(n)) : (i += 1)
        if (n % i == 0) {
            try powers.append(PrimePower{ .prime = i, .power = 0 });
            const power = &powers.items[powers.items.len - 1].power;
            while (n % i == 0) {
                power.* += 1;
                n /= i;
            }
        };
    if (n > 1)
        try powers.append(PrimePower{ .prime = n, .power = 1 });
    return powers.toOwnedSlice();
}

fn carmichaelLambda(allocator: std.mem.Allocator, number: u32) !u32 {
    if (number == 1)
        return 1;
    const powers = try primePowers(allocator, number);
    var result: u32 = 1;
    for (powers) |primePower| {
        var car = (primePower.prime - 1) * std.math.pow(u32, primePower.prime, primePower.power - 1);
        if (primePower.prime == 2 and primePower.power >= 3)
            car /= 2;
        result = lcm(result, car);
    }
    allocator.free(powers);
    return result;
}

fn countIterationsToOne(allocator: std.mem.Allocator, n: u32) !u32 {
    return if (n <= 1) 0 else try countIterationsToOne(allocator, try carmichaelLambda(allocator, n)) + 1;
}

fn lcm(a: anytype, b: anytype) @TypeOf(a, b) {
    // only unsigned integers are allowed and neither can be zero
    comptime switch (@typeInfo(@TypeOf(a, b))) {
        .int => |int| std.debug.assert(int.signedness == .unsigned),
        .comptime_int => {
            std.debug.assert(a >= 0);
            std.debug.assert(b >= 0);
        },
        else => unreachable,
    };
    std.debug.assert(a != 0 or b != 0);

    return a / std.math.gcd(a, b) * b;
}
