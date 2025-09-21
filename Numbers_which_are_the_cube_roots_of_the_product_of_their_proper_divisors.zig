// https://rosettacode.org/wiki/Numbers_which_are_the_cube_roots_of_the_product_of_their_proper_divisors
// {{works with|Zig|0.15.1}}
// {{trans|Wren (alternative version)}}
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var buffer: [50]u64 = undefined;
    var numbers50: std.ArrayList(u64) = .initBuffer(&buffer);

    var count: usize = 0;
    var n: u64 = 1;
    while (true) {
        const dc = divisorCount(n);
        // The OEIS A111398 formula...
        if (n == 1 or dc == 8) {
            count += 1;
            if (count <= 50) {
                try numbers50.appendBounded(n);
                if (count == 50) {
                    print("First 50 numbers which are the cube roots of the products of their proper divisors:\n", .{});
                    for (numbers50.items, 1..) |number, i| {
                        print("{d:3} ", .{number});
                        if (i % 10 == 0)
                            print("\n", .{});
                    }
                }
            } else if (count == 500)
                print("\n500th   : {}\n", .{n})
            else if (count == 5_000)
                print("5,000th : {}\n", .{n})
            else if (count == 50_000) {
                print("50,000th: {}\n", .{n});
                break;
            }
        }
        n += 1;
    }
}

fn divisorCount(n: u64) usize {
    var count: usize = 0;
    const k: u64 = if (n % 2 == 0) 1 else 2;
    var i: u64 = 1;
    while (i * i <= n) : (i += k)
        if (n % i == 0) {
            count += 1;
            if (n / i != i)
                count += 1;
        };
    return count;
}

const testing = std.testing;

test divisorCount {
    try testing.expectEqual(1, divisorCount(1));
    try testing.expectEqual(2, divisorCount(2));
    try testing.expectEqual(2, divisorCount(3));
    try testing.expectEqual(3, divisorCount(4));
    try testing.expectEqual(2, divisorCount(5));
    try testing.expectEqual(4, divisorCount(6));
    try testing.expectEqual(6, divisorCount(12));
    try testing.expectEqual(4, divisorCount(15));
}
