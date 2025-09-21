// https://rosettacode.org/wiki/Horner%27s_rule_for_polynomial_evaluation
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Example coefficients for polynomial -19 + 7x - 4x^2 + 6x^3
    const coefficients = [_]f64{ -19, 7, -4, 6 };
    const x = 3;
    try stdout.print(
        "The result of the polynomial evaluation is: {d:.1}\n",
        .{horner(&coefficients, x)},
    );

    try stdout.flush();
}

fn horner(coefficients: []const f64, x: f64) f64 {
    var accumulator: f64 = 0;
    var i = coefficients.len;
    while (i != 0) {
        i -= 1;
        accumulator = @mulAdd(f64, accumulator, x, coefficients[i]);
    }
    return accumulator;
}
