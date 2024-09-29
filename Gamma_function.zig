// https://rosettacode.org/wiki/Gamma_function
// Translation of C++
const std = @import("std");
const mem = std.mem;
const math = std.math;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // estimate the gamma function with 1, 4, and 10 coefficients
    const coeff1 = try calculateCoefficients(allocator, 1);
    const coeff4 = try calculateCoefficients(allocator, 4);
    const coeff10 = try calculateCoefficients(allocator, 10);
    defer allocator.free(coeff1);
    defer allocator.free(coeff4);
    defer allocator.free(coeff10);

    const inputs = [_]f64{
        0.001, 0.01, 0.1, 0.5, 1.0, //
        1.461632145, // minimum of the gamma function
        2, 2.5, 3, 4, 5, 6, 7, 8, 9, 10, 50, 100, //
        150, // causes overflow for implementation of Gamma below
    };

    print("{s:16}{s:16}{s:16}{s:16}{s:16}\n", .{ "gamma( x ) =", "Spouge 1", "Spouge 4", "Spouge 10", "built-in" });
    for (inputs) |x| {
        const g = math.gamma(f64, x); // built-in gamma function

        // `fmt` parameter to print has to comptime known.
        // Floating point printed as decimal or scientific is decided here.
        if (g < 1_000_000_000)
            print("gamma({d:7.3}) = {d:16.6} {d:16.6} {d:16.6} {d:16.6}\n", .{
                x, //
                gamma(coeff1, x), //
                gamma(coeff4, x), //
                gamma(coeff10, x), //
                g, // built-in gamma function
            })
        else
            print("gamma({d:7.3}) = {e:>16.10} {e:>16.10} {e:>16.10} {e:>16.10}\n", .{
                x, //
                gamma(coeff1, x), //
                gamma(coeff4, x), //
                gamma(coeff10, x), //
                g, // built-in gamma function
            });
    }
}

/// Calculate the coefficients used by Spouge's approximation (based on the C implementation)
/// Caller owns returned memory.
fn calculateCoefficients(allocator: mem.Allocator, num_coeff: usize) ![]f64 {
    const f_num_coeff: f64 = @floatFromInt(num_coeff);
    var c = try allocator.alloc(f64, num_coeff);
    var k1_factrl: f64 = 1.0;
    c[0] = @sqrt(2.0 * math.pi);
    for (1..num_coeff) |k| {
        const f_k: f64 = @floatFromInt(k);
        c[k] = @exp(f_num_coeff - f_k) * math.pow(f64, f_num_coeff - f_k, f_k - 0.5) / k1_factrl;
        k1_factrl *= -f_k;
    }
    return c;
}

/// The Spouge approximation
fn gamma(coeffs: []const f64, x: f64) f64 {
    const num_coeff = coeffs.len;
    const f_num_coeff: f64 = @floatFromInt(num_coeff);

    var accm = coeffs[0];
    for (1..num_coeff) |k| {
        accm += coeffs[k] / (x + @as(f64, @floatFromInt(k)));
    }
    accm *= @exp(-(x + f_num_coeff)) * math.pow(f64, x + f_num_coeff, x + 0.5);
    return accm / x;
}
