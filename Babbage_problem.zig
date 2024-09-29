// https://rosettacode.org/wiki/Babbage_problem
// Translated from D
const std = @import("std");
const math = std.math;
const print = std.debug.print;

// Quote from the D example:
// It's basically the same as any other version.
// What can be observed is that 269696 is even, so we have to consider only even numbers,
// because only the square of even numbers are even.

pub fn main() void {
    const Integer = u32; // 32 binary bits to represent integer number.

    // The number. Start at minimum number possible.
    var n: Integer = math.sqrt(269696);

    if (n % 2 == 1) // If root is odd, make it even.
        n -= 1;

    // Largest number that can represent the square root of target.
    const upper_bound: Integer = math.sqrt(math.maxInt(Integer));

    // Cycle through the numbers.
    // Remainder division to check if last 6 last digits are 269696
    // Check that n is not out of bounds.
    while ((n * n) % 1_000_000 != 269_696 and n <= upper_bound)
        n += 2;

    // Display output.
    if (n > upper_bound)
        print("Condition not satisfied before upper bound reached.", .{})
    else
        print("The smallest number whose square ends in 269696 is {d}\n", .{n});
}
