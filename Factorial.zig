// https://rosettacode.org/wiki/Factorial
const std = @import("std");
const math = std.math;
const mem = std.mem;

const Int = math.big.int.Managed;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var factorial = try Factorial.init(allocator);
    defer factorial.deinit();

    const stdout = std.io.getStdOut().writer();
    for (0..41) |i| {
        var f1 = try factorial.recursive(@intCast(i));
        defer f1.deinit();
        var f2 = try factorial.iterative(@intCast(i));
        defer f2.deinit();

        try stdout.print("{d:2} {} {} {!} {!}\n", .{
            i,
            f1,
            f2,
            Factorial.recursivePrimitive(u128, @intCast(i)),
            Factorial.iterativePrimitive(u64, @intCast(i)),
        });
    }
}

const FactorialError = error{
    Overflow,
};

const Factorial = struct {
    allocator: mem.Allocator,
    one: Int,

    fn init(allocator: mem.Allocator) !Factorial {
        return Factorial{
            .allocator = allocator,
            .one = try Int.initSet(allocator, 1),
        };
    }
    fn deinit(self: *Factorial) void {
        self.one.deinit();
    }

    fn recursive(self: *const Factorial, n_: usize) !Int {
        var n = try Int.initSet(self.allocator, n_);
        defer n.deinit();
        return self._recursive(&n);
    }

    fn _recursive(self: *const Factorial, n_: *const Int) !Int {
        if (n_.eqlZero())
            return self.one.clone()
        else {
            // n_ - 1
            var n = try Int.init(self.allocator);
            try n.sub(n_, &self.one);
            // recursive(n_ - 1)
            var recurse = try self._recursive(&n);
            defer recurse.deinit();
            // overwrites result
            // n_ * recursive(n_ - 1)
            try n.mul(&recurse, n_); // reuse n
            //
            return n;
        }
    }

    fn iterative(self: *const Factorial, n_: usize) !Int {
        var n = try Int.initSet(self.allocator, n_);
        var i = try Int.initSet(self.allocator, 2);
        var result = try self.one.clone();
        defer n.deinit();
        defer i.deinit();
        // n < 2
        if (n.order(i) == math.Order.lt)
            return result;

        var tmp = try Int.init(self.allocator); // used to avoid aliasing
        defer tmp.deinit();

        // n + 1
        var n1 = try Int.init(self.allocator);
        defer n1.deinit();
        try n1.add(&n, &self.one);

        // while (i != n + 1)
        while (!i.eql(n1)) : ({
            // i += 1
            i.swap(&tmp); // avoid aliasing, quicker than clone
            try i.add(&tmp, &self.one);
        }) {
            // result *= i;
            result.swap(&tmp); // avoid aliasing, quicker than clone
            try result.mul(&tmp, &i);
        }
        return result;
    }

    fn recursivePrimitive(comptime T: type, n: u16) FactorialError!T {
        if (n > comptime maxFactorial(T))
            return FactorialError.Overflow;
        if (n == 0)
            return 1
        else
            return n * try recursivePrimitive(T, n - 1);
    }

    fn iterativePrimitive(comptime T: type, n_: u16) FactorialError!T {
        if (n_ > comptime maxFactorial(T))
            return FactorialError.Overflow;
        var result: T = 1;
        if (n_ < 2)
            return result;
        var i: T = 2;
        const n: T = @intCast(n_ + 1);
        while (i != n) : (i += 1)
            result *= i;
        return result;
    }

    /// Calculate the maximum number for that can fit number! into type `T`
    fn maxFactorial(comptime T: type) u16 {
        const type_info = @typeInfo(T);
        if (type_info != .int)
            @compileError("factorial type must be an integer.");
        if (type_info.int.signedness == .signed and type_info.int.bits == 1)
            @compileError("factorial type cannot be i1");
        const bits: u16 = type_info.int.bits - switch (type_info.int.signedness) {
            .unsigned => 0,
            .signed => 1,
        };
        if (bits == 1)
            return 1;
        if (bits == 2)
            return 2;

        var max = @log2(@as(f64, @floatFromInt(math.maxInt(T))));
        var n: u16 = 2;

        while (true) : (n += 1) {
            const next = @log2(@as(f64, @floatFromInt(n)));
            if (max > next)
                max -= next
            else
                return n - 1;
        }
    }
};

const testing = std.testing;

test "maxFactorial" {
    try testing.expectEqual(34, comptime Factorial.maxFactorial(u128));
    try testing.expectEqual(20, comptime Factorial.maxFactorial(u64));
    try testing.expectEqual(12, comptime Factorial.maxFactorial(u32));
    try testing.expectEqual(8, comptime Factorial.maxFactorial(u16));
    try testing.expectEqual(7, comptime Factorial.maxFactorial(i16));
    try testing.expectEqual(2, comptime Factorial.maxFactorial(u2));
    try testing.expectEqual(1, comptime Factorial.maxFactorial(u1));
}
