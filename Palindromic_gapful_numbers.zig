// https://rosettacode.org/wiki/Palindromic_gapful_numbers
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const n1 = 20;
    const n2 = 15;
    const n3 = 10;

    var a1: [9 * n1]u64 = undefined;
    var a2: [9 * n2]u64 = undefined;
    var a3: [9 * n3]u64 = undefined;

    // arrays of slices
    var pg1: [9][]u64 = undefined;
    var pg2: [9][]u64 = undefined;
    var pg3: [9][]u64 = undefined;

    // set up array slices
    for (&pg1, 0..) |*a, i|
        a.* = a1[i * n1 .. (i + 1) * n1];
    for (&pg2, 0..) |*a, i|
        a.* = a2[i * n2 .. (i + 1) * n2];
    for (&pg3, 0..) |*a, i|
        a.* = a3[i * n3 .. (i + 1) * n3];

    const m1 = 100;
    const m2 = 1000;

    var digit: u64 = 1;
    while (digit < 10) : (digit += 1) {
        var pgen: PalindromicGenerator = .init(digit);
        var i: usize = 0;
        while (i < m2) {
            const n = pgen.next();
            if (!isGapful(n))
                continue;
            if (i < n1)
                pg1[digit - 1][i] = n
            else if (i < m1 and i >= m1 - n2)
                pg2[digit - 1][i - (m1 - n2)] = n
            else if (i >= m2 - n3)
                pg3[digit - 1][i - (m2 - n3)] = n;
            i += 1;
        }
    }

    print("First {} palindromic gapful numbers ending in:\n", .{n1});
    printPG(pg1[0..]);

    print("\nLast {} of first {} palindromic gapful numbers ending in:\n", .{ n2, m1 });
    printPG(pg2[0..]);

    print("\nLast {} of first {} palindromic gapful numbers ending in:\n", .{ n3, m2 });
    printPG(pg3[0..]);
}

fn printPG(array: [][]u64) void {
    for (array, 1..) |values, digit| {
        print("{}:", .{digit});
        for (values) |n|
            print(" {}", .{n});
        print("\n", .{});
    }
}

const PalindromicGenerator = struct {
    power: u32,
    next_: u64,
    digit: u64,
    even: bool,

    fn init(digit: u64) PalindromicGenerator {
        const power = 10;
        return PalindromicGenerator{
            .power = power,
            .next_ = digit * power - 1,
            .digit = digit,
            .even = false,
        };
    }

    fn next(self: *PalindromicGenerator) u64 {
        self.next_ += 1;
        if (self.next_ == self.power * (self.digit + 1)) {
            if (self.even)
                self.power *= 10;
            self.next_ = self.digit * self.power;
            self.even = !self.even;
        }
        return self.next_ * (if (self.even) 10 * self.power else self.power) + reverse(if (self.even) self.next_ else self.next_ / 10);
    }
};

fn reverse(n_: u64) u64 {
    var result: u64 = 0;
    var n = n_;
    while (n != 0) {
        result = 10 * result + n % 10;
        n /= 10;
    }
    return result;
}

fn isGapful(n: u64) bool {
    var m = n;
    while (m >= 10)
        m /= 10;
    return n % (n % 10 + 10 * m) == 0;
}
