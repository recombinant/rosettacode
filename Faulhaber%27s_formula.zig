// https://rosettacode.org/wiki/Faulhaber%27s_formula
// {{works with|Zig|0.14.1}}
// {{trans|Python}}

// Over four times the size of the Python implementation
// (bloated primarily by allocation, rational arithmetic
// and pretty printing code)

// This Zig implementation uses two allocators.
// (1) for items that remain in scope for the program duration.
// (2) for ephemeral items that are only in scope for a single
// loop of the main() while loop.

// This reduces memory fragmentation in the first allocator and
// eliminates the need to free/deinit variables by using a
// resettable arena for the second allocator. The result is a
// measureably faster program than using a single general
// purpose allocator.
const std = @import("std");
const Int = std.math.big.int.Managed;
const Rational = std.math.big.Rational;

// At module scope a const variable is comptime.
const use_ephemeral_allocator = true; // true uses (faster) ArenaAllocator
const use_pretty_print = true; // false uses ASCII

pub fn main() !void {
    var t0: std.time.Timer = try .start();

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var arena: std.heap.ArenaAllocator = undefined;
    var ephemeral_allocator: std.mem.Allocator = undefined;
    if (use_ephemeral_allocator) {
        arena = .init(std.heap.page_allocator);
        ephemeral_allocator = arena.allocator();
    } else {
        ephemeral_allocator = allocator;
    }
    defer if (use_ephemeral_allocator) arena.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = bw.writer();

    // 64 bit numbers can generate the first 20 expressions before failure caused by integer overflow.
    var it: SumPolynomialIterator(10) = .init(allocator);
    defer it.deinit();

    var i: usize = 0;
    while (true) : (i += 1) {
        var p = try it.next(ephemeral_allocator) orelse break;
        defer if (!use_ephemeral_allocator) p.deinit();
        try writer.print("{}: {any}\n", .{ i, p });
        // free all allocated memory used in the creation of `p`
        if (use_ephemeral_allocator) _ = arena.reset(.retain_capacity);
    }

    const t1 = t0.read();
    try bw.flush();
    std.debug.print("\nprocessed in {}\n", .{std.fmt.fmtDuration(t1)});
}

fn SumPolynomialIterator(comptime n: usize) type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        count: usize,
        u: std.ArrayList(u64),
        v: std.ArrayList([]const i64),

        fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .count = 0,
                .u = .init(allocator),
                .v = .init(allocator),
            };
        }
        fn deinit(self: *Self) void {
            self.u.deinit();
            for (self.v.items) |a|
                self.allocator.free(a);
            self.v.deinit();
        }
        fn next(self: *Self, ephemeral_allocator: std.mem.Allocator) !?SumPolynomialResult {
            const allocator = ephemeral_allocator;
            switch (self.count) {
                0 => {
                    self.count += 1;
                    try self.u.appendSlice(&[2]u64{ 0, 1 });
                    const v0 = try self.allocator.alloc(i64, 1);
                    const v1 = try self.allocator.alloc(i64, 2);
                    @memcpy(v0, &[1]i64{1});
                    @memcpy(v1, &[2]i64{ 1, 1 });
                    try self.v.appendSlice(&[2][]const i64{ v0, v1 });
                    //
                    var zero: Rational = try .init(ephemeral_allocator);
                    var one: Rational = try .init(ephemeral_allocator);
                    try zero.setInt(0);
                    try one.setInt(1);
                    var t = try allocator.alloc(Rational, 2);
                    t[0] = zero;
                    t[1] = one;
                    return try SumPolynomialResult.init(ephemeral_allocator, t);
                },
                n => {
                    return null;
                },
                else => {
                    self.count += 1;
                    try self.v.append(try self.nextv());
                    // t = [0] * (i + 2)
                    var zero: Int = try .initSet(allocator, 0);
                    defer if (!use_ephemeral_allocator) zero.deinit();
                    const t = try allocator.alloc(Rational, self.count + 2);
                    for (t) |*value| {
                        value.* = try .init(allocator);
                        try value.copyInt(zero);
                    }
                    // initialize here for repeated reuse in for() loop
                    var r: Rational = try .init(allocator);
                    defer if (!use_ephemeral_allocator) r.deinit();
                    var s: Rational = try .init(allocator);
                    defer if (!use_ephemeral_allocator) s.deinit();
                    var rma1: Rational = try .init(allocator);
                    defer if (!use_ephemeral_allocator) rma1.deinit();
                    var rma2: Rational = try .init(allocator);
                    defer if (!use_ephemeral_allocator) rma2.deinit();

                    const u: []const u64 = self.u.items;
                    for (u, 1..) |r_, j| {
                        try r.setRatio(r_, j);
                        const v: []const i64 = self.v.items[j];
                        for (v, t[0..v.len]) |s_, *tk| {
                            try s.setInt(s_);
                            try rma1.mul(r, s);
                            try rma2.add(tk.*, rma1);
                            rma2.swap(tk); // using rma2 avoids aliasing t[k]
                        }
                    }
                    try self.nextu();
                    return try SumPolynomialResult.init(ephemeral_allocator, t);
                },
            }
        }
        fn nextu(self: *Self) !void {
            try self.u.append(1);
            var i: usize = self.u.items.len - 1;
            const a = self.u.items;
            while (i != 1) {
                i -= 1;
                a[i] = i * a[i] + a[i - 1];
            }
        }
        fn nextv(self: *const Self) ![]const i64 {
            const a = self.v.items[self.v.items.len - 1];
            var b = try self.allocator.alloc(i64, a.len + 1);
            const nn: i64 = @intCast(a.len - 1);
            for (b[0..a.len], a) |*dest, x|
                dest.* = (1 - nn) * x;
            b[a.len] = 1;
            for (b[1..a.len], a[0 .. a.len - 1]) |*dest, x|
                dest.* += x;
            return b;
        }
    };
}

const SumPolynomialResult = struct {
    allocator: std.mem.Allocator,
    t: []Rational,
    one: Int,
    fn init(allocator: std.mem.Allocator, t: []Rational) !SumPolynomialResult {
        return SumPolynomialResult{
            .allocator = allocator,
            .t = t,
            .one = try .initSet(allocator, 1),
        };
    }
    fn deinit(self: *SumPolynomialResult) void {
        std.debug.assert(!use_ephemeral_allocator);
        if (!use_ephemeral_allocator) {
            for (self.t) |*rational|
                rational.deinit();
            self.allocator.free(self.t);
            self.one.deinit();
        }
    }
    pub fn format(self: *const SumPolynomialResult, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const allocator = self.allocator;
        var tmp: Int = try .init(allocator);
        defer if (!use_ephemeral_allocator) tmp.deinit();
        var first = true;
        const t = try allocator.dupe(Rational, self.t);
        defer if (!use_ephemeral_allocator) allocator.free(t);
        std.mem.reverse(Rational, t);
        for (t, 1..) |value, i| {
            const power = self.t.len - i;
            if (value.p.eqlZero())
                continue;
            if (value.p.isPositive()) {
                if (!first)
                    try writer.writeAll(" + ");
            } else {
                if (first)
                    try writer.writeByte('-')
                else
                    try writer.writeAll(" - ");
            }
            first = false;

            try tmp.copy(value.p.toConst());
            tmp.abs();
            const p = tmp;
            const q = value.q;

            if (q.eql(self.one)) {
                if (!p.eql(self.one)) {
                    const p_str = try p.toString(allocator, 10, .lower);
                    defer if (!use_ephemeral_allocator)
                        allocator.free(p_str);
                    try writer.print("{s} ", .{p_str});
                }
            } else {
                const p_str = try p.toString(allocator, 10, .lower);
                defer if (!use_ephemeral_allocator)
                    allocator.free(p_str);
                const q_str = try q.toString(allocator, 10, .lower);
                defer if (!use_ephemeral_allocator)
                    allocator.free(q_str);
                try writer.print("{s}/{s} ", .{ p_str, q_str });
            }

            try writer.writeByte('n');
            if (power > 1) {
                if (use_pretty_print)
                    try writePower(writer, power)
                else
                    try writer.print("^{d}", .{power});
            }
        }
    }
};

/// Pretty print the power using unicode superscript decimal numerals.
fn writePower(writer: anytype, power: usize) !void {
    const powers = [10][]const u8{ "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹" };
    if (power < 10)
        try writer.writeAll(powers[power])
    else {
        // output most significant decimal digit first
        var i: usize = 1;
        var j = power;
        var n_digits: usize = 1;
        while (i <= j / 10) {
            n_digits += 1;
            i *= 10;
        }
        while (n_digits > 0) {
            try writer.writeAll(powers[j / i]);
            j %= i;
            i /= 10;
            n_digits -= 1;
        }
    }
}
