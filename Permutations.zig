// https://rosettacode.org/wiki/Permutations
// Translation of Nim
const std = @import("std");
const mem = std.mem;

// TODO: work in progress

/// iterative Boothroyd method
fn Permutations(T: type) type {
    return struct {
        const Self = @This();

        count: usize,
        array: []T,

        fn init(allocator: mem.Allocator, array: []const T) !Self {
            _ = allocator; // autofix
            return .{ .count = factorial(array.len) };
        }

        fn next() ?[]const T {}
        // iterator permutations[T](ys: openarray[T]): seq[T] =
        //   var
        //     d = 1
        //     c = newSeq[int](ys.len)
        //     xs = newSeq[T](ys.len)
        //
        //   for i, y in ys: xs[i] = y
        //   yield xs
        //
        //   block outer:
        //     while true:
        //       while d > 1:
        //         dec d
        //         c[d] = 0
        //       while c[d] >= d:
        //         inc d
        //         if d >= ys.len: break outer
        //       let i = if (d and 1) == 1: c[d] else: 0
        //       swap xs[i], xs[d]
        //       yield xs
        //       inc c[d]
    };
}

pub fn main() void {
    var x = [_]u4{ 1, 2, 3 };

    var perms = Permutations(u4).init(u4, x);

    while (perms.next()) |p|
        print("{any}\n", .{p});
}

fn factorial(n_: usize) usize {
    var result: usize = n_;
    var n = n_;

    while (n > 1) {
        n -= 1;
        result *= n;
    }
    return result;
}
