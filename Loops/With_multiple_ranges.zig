// https://rosettacode.org/wiki/Loops/With_multiple_ranges
const std = @import("std");

/// To avoid global variables use a struct as a namespace
const SumProd = struct {
    prod: i32 = 1,
    sum: u32 = 0,

    fn process(self: *SumProd, j: i32) void {
        self.sum += @abs(j);
        if ((@abs(self.prod) < 1 << 27) and (j != 0))
            self.prod *= j;
    }
};

fn ipow(n: i32, e: u4) i32 {
    if (e == 0) return 1;

    var pr = n;
    var i: u4 = 2;
    while (i <= e) : (i += 1)
        pr *= n;
    return pr;
}

pub fn main() void {
    const x = 5;
    const y = -5;
    const z = -2;
    const one = 1;
    const three = 3;
    const seven = 7;
    const p = ipow(11, x);

    var sum_prod = SumProd{};

    // start, end, step in an array of tuples
    const ranges = [_]struct { i32, i32, i32 }{
        .{ -three, ipow(3, 3), three },
        .{ -seven, seven, x },
        .{ 555, 550 - y, 1 },
        .{ 22, -28, -three },
        .{ 1927, 1939, 1 },
        .{ x, y, z },
        .{ p, p + one, 1 },
    };
    for (ranges) |range| {
        // use aggregate destructuring on `range`
        var j, const end, const step = range;
        while (j <= end) : (j += step) sum_prod.process(j);
    }
    std.debug.print("sum  = {}\n", .{sum_prod.sum});
    std.debug.print("prod = {}\n", .{sum_prod.prod});
}
