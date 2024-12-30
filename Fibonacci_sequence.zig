const std = @import("std");

pub fn main() !void {
    const n: u128 = 100;

    // calculate at compile time
    const f0 = comptime fibonacci(n);
    // ...and at run time
    const f1 = fibonacci(n);

    std.debug.print("{} (comptime)\n", .{f0});
    std.debug.print("{}\n", .{f1});
}

fn fibonacci(n_: anytype) @TypeOf(n_) {
    const T = @TypeOf(n_);
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("fibonnaci() expected unsigned integer type argument, found " ++ @typeName(T));

    var n = n_;

    var first: T = 0;
    var second: T = 1;

    while (n != 0) : (n -= 1) {
        std.mem.swap(T, &first, &second);
        second += first;
    }
    return first;
}

const testing = std.testing;
test fibonacci {
    // test against the first 24 Fibonacci numbers
    const expected = [_]u16{
        0,    1,     1,     2,     3,   5,   8,   13,   21,   34,
        55,   89,    144,   233,   377, 610, 987, 1597, 2584, 4181,
        6765, 10946, 17711, 28657,
    };
    var i: u16 = 0;
    while (i != expected.len) : (i += 1)
        try testing.expectEqual(expected[i], fibonacci(i));
}
