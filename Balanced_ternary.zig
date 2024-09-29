// https://rosettacode.org/wiki/Balanced_ternary
const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    const a = try BalancedTernary.initString(allocator, "+-0++0+");
    const b = try BalancedTernary.initInt(allocator, -436);
    const c = try BalancedTernary.initString(allocator, "+-++-");
    defer a.deinit();
    defer b.deinit();
    defer c.deinit();

    try stdout.writeAll("Balanced ternary numbers:\n");
    try stdout.print("a = {}\n", .{a});
    try stdout.print("b = {}\n", .{b});
    try stdout.print("c = {}\n", .{c});
    try stdout.writeByte('\n');

    try stdout.writeAll("Their decimal representation:\n");
    try stdout.print("a = {:4}\n", .{try a.toInt()});
    try stdout.print("b = {:4}\n", .{try b.toInt()});
    try stdout.print("c = {:4}\n", .{try c.toInt()});
    try stdout.writeByte('\n');

    var t = try BalancedTernary.init(allocator);
    defer t.deinit();
    var d = try BalancedTernary.init(allocator);
    defer d.deinit();
    try t.sub(b, c);
    try d.mul(a, t);
    try stdout.writeAll("a × (b - c):\n");
    try stdout.print(" in ternary: {}\n", .{d});
    try stdout.print(" in decimal: {d}\n", .{try d.toInt()});
}

const Trit = struct {
    const Symbol = enum(i2) {
        tn = -1,
        tz = 0,
        tp = 1,
    };

    symbol: Symbol,

    fn fromChar(ch: u8) Trit {
        return Trit{
            .symbol = switch (ch) {
                '-' => .tn,
                '0' => .tz,
                '+' => .tp,
                else => unreachable,
            },
        };
    }
    fn fromDigit(n: i3) Trit {
        return Trit{
            .symbol = switch (n) {
                2 => .tn,
                0 => .tz,
                1 => .tp,
                else => unreachable,
            },
        };
    }
    fn toChar(self: *const Trit) u8 {
        return switch (self.symbol) {
            .tn => '-',
            .tz => '0',
            .tp => '+',
        };
    }
    fn toDigit(self: *const Trit) i32 {
        return switch (self.symbol) {
            .tn => -1,
            .tz => 0,
            .tp => 1,
        };
    }

    fn isZero(self: Trit) bool {
        return self.symbol == .tz;
    }

    fn eql(self: Trit, other: Trit) bool {
        return self.symbol == other.symbol;
    }

    fn negate(self: *Trit) void {
        self.symbol = switch (self.symbol) {
            .tn => .tp,
            .tz => .tz,
            .tp => .tn,
        };
    }

    /// Add two trits. See also addc() for three trits.
    fn add(a: Trit, b: Trit) struct {
        trit: Trit,
        carry: Trit,
    } {
        const result = switch (a.symbol) {
            .tn => switch (b.symbol) {
                .tn => Symbol.tp,
                .tz => Symbol.tn,
                .tp => Symbol.tz,
            },
            .tz => switch (b.symbol) {
                .tn => Symbol.tn,
                .tz => Symbol.tz,
                .tp => Symbol.tp,
            },
            .tp => switch (b.symbol) {
                .tn => Symbol.tz,
                .tz => Symbol.tp,
                .tp => Symbol.tn,
            },
        };
        const carry = if (a.symbol == b.symbol) switch (a.symbol) {
            .tn => Symbol.tn,
            .tz => Symbol.tz,
            .tp => Symbol.tp,
        } else .tz;
        return .{
            .trit = Trit{ .symbol = result },
            .carry = Trit{ .symbol = carry },
        };
    }
    /// Add three Trits - a, b & c (carry). See also add() for two trits.
    fn addc(a: Trit, b: Trit, c: Trit) struct {
        trit: Trit,
        carry: Trit,
    } {
        var trit_count: i3 = 0;
        for ([3]Trit{ a, b, c }) |trit| {
            switch (trit.symbol) {
                .tn => trit_count -= 1,
                .tz => {},
                .tp => trit_count += 1,
            }
        }
        const result = switch (trit_count) {
            -3, 0, 3 => Symbol.tz,
            -2, 1 => Symbol.tp,
            -1, 2 => Symbol.tn,
            else => unreachable,
        };
        const carry = switch (trit_count) {
            2, 3 => Symbol.tp,
            -2, -3 => Symbol.tn,
            -1, 0, 1 => Symbol.tz,
            else => unreachable,
        };
        return .{
            .trit = Trit{ .symbol = result },
            .carry = Trit{ .symbol = carry },
        };
    }
};

const AddOptions = struct {
    carry: Trit.Symbol = .tz,
};

const BalancedTernary = struct {
    trits: []Trit,
    allocator: mem.Allocator,

    /// Initialise BalancedTernary (to zero)
    fn init(allocator: mem.Allocator) !BalancedTernary {
        var trit = try allocator.alloc(Trit, 1);
        trit[0] = Trit{ .symbol = .tz };
        return BalancedTernary{
            .trits = trit,
            .allocator = allocator,
        };
    }
    /// Build a BalancedTernary number from its string representation.
    fn initString(allocator: mem.Allocator, string: []const u8) !BalancedTernary {
        var trits = try allocator.alloc(Trit, string.len);
        for (string, 1..) |ch, i| {
            trits[string.len - i] = Trit.fromChar(ch);
        }
        return BalancedTernary{
            .trits = trits,
            .allocator = allocator,
        };
    }
    /// Build a BalancedTernary number from a decimal integer.
    fn initInt(allocator: mem.Allocator, integer: i32) !BalancedTernary {
        var val = integer;
        var array = std.ArrayList(Trit).init(allocator);
        while (true) {
            const trit = Trit.fromDigit(@intCast(@mod(val, 3)));
            try array.append(trit);
            val = @divTrunc(val - trit.toDigit(), 3);
            if (val == 0)
                break;
        }
        return BalancedTernary{
            .trits = try array.toOwnedSlice(),
            .allocator = allocator,
        };
    }
    fn deinit(self: *const BalancedTernary) void {
        self.allocator.free(self.trits);
    }

    fn clone(self: BalancedTernary) mem.Allocator.Error!BalancedTernary {
        return BalancedTernary{
            .trits = try self.allocator.dupe(Trit, self.trits),
            .allocator = self.allocator,
        };
    }
    fn cloneFrom(self: *BalancedTernary, other: BalancedTernary) mem.Allocator.Error!void {
        if (self.trits.len == other.trits.len) {
            if (self.trits.ptr != other.trits.ptr)
                @memcpy(self.trits, other.trits);
        } else {
            self.allocator.free(self.trits);
            self.trits = try self.allocator.dupe(Trit, other.trits);
        }
    }

    /// custom formatter for BalancedTernary
    pub fn format(self: BalancedTernary, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        const trits = self.trits;
        var i = self.trits.len;
        while (i != 0) {
            i -= 1;
            try writer.writeByte(trits[i].toChar());
        }
    }

    /// Return the string representation of a BalancedTernary number.
    /// Caller owns returned memory slice.
    fn toString(self: BalancedTernary, allocator: mem.Allocator) mem.Allocator.Error![]const u8 {
        var string = try allocator.alloc(u8, self.trits.len);
        for (self.trits, 1..) |trit, i| {
            string[self.trits.len - i] = trit.toChar();
        }
        return string;
    }

    /// Convert a BalancedTernary number to an integer.
    fn toInt(self: BalancedTernary) !i32 {
        var m: i32 = 1;
        var result: i32 = 0;
        for (self.trits) |trit| {
            // result += m * trit.toDigit()
            const ov_mul = @mulWithOverflow(m, trit.toDigit());
            if (ov_mul[1] != 0) return error.Overflow;
            //
            const ov_add = @addWithOverflow(result, ov_mul[0]);
            if (ov_add[1] != 0) return error.Overflow;
            result = ov_add[0];
            // m *= 3
            const ov_inc = @mulWithOverflow(m, @as(i32, 3));
            if (ov_inc[1] != 0) return error.Overflow;
            m = ov_inc[0];
        }
        return result;
    }

    fn eql(self: BalancedTernary, other: BalancedTernary) bool {
        if (self.trits.len != other.trits.len)
            return false;
        for (self.trits, other.trits) |a, b|
            if (!a.eql(b))
                return false;
        return true;
    }
    fn isZero(self: BalancedTernary) bool {
        for (self.trits) |trit|
            if (!trit.isZero())
                return false;
        return true;
    }

    fn negate(self: *BalancedTernary) void {
        for (self.trits) |*trit|
            trit.*.negate();
    }

    fn sub(self: *BalancedTernary, a: BalancedTernary, b: BalancedTernary) !void {
        var temp = try b.clone();
        defer temp.deinit();
        temp.negate();
        try self.add(a, temp);
    }

    fn add(self: *BalancedTernary, a: BalancedTernary, b: BalancedTernary) !void {
        if (a.isZero())
            try self.cloneFrom(b)
        else if (b.isZero())
            try self.cloneFrom(a)
        else {
            var result = std.ArrayList(Trit).init(self.allocator);
            const shortest = @min(a.trits.len, b.trits.len);
            var carry = Trit{ .symbol = Trit.Symbol.tz };
            for (a.trits[0..shortest], b.trits[0..shortest]) |trit_a, trit_b| {
                const sum = Trit.addc(trit_a, trit_b, carry);
                try result.append(sum.trit);
                carry = sum.carry;
            }
            if (a.trits.len == b.trits.len) {
                if (!carry.isZero())
                    try result.append(carry);
            } else {
                const tail_trits = if (a.trits.len > b.trits.len) a.trits[shortest..] else b.trits[shortest..];
                for (tail_trits) |trit| {
                    const sum = Trit.add(trit, carry);
                    try result.append(sum.trit);
                    carry = sum.carry;
                }
                if (!carry.isZero())
                    try result.append(carry);
            }
            // remove leading 0 trits
            while (result.items.len > 1 and result.items[result.items.len - 1].symbol == Trit.Symbol.tz)
                _ = result.pop();
            //
            self.allocator.free(self.trits);
            self.trits = try result.toOwnedSlice();
        }
        return;
    }

    fn mul(self: *BalancedTernary, a: BalancedTernary, b: BalancedTernary) !void {
        if (a.isZero()) {
            try self.cloneFrom(a);
        } else if (b.isZero()) {
            try self.cloneFrom(b);
        } else {
            var na = try a.clone();
            defer na.deinit();
            na.negate();
            var pos_trits = try self.allocator.alloc(Trit, a.trits.len + b.trits.len);
            var neg_trits = try self.allocator.alloc(Trit, a.trits.len + b.trits.len);
            @memset(pos_trits, Trit{ .symbol = Trit.Symbol.tz });
            @memset(neg_trits, Trit{ .symbol = Trit.Symbol.tz });
            @memcpy(pos_trits[0..a.trits.len], a.trits);
            @memcpy(neg_trits[0..na.trits.len], na.trits);
            var pos = BalancedTernary{ .trits = pos_trits, .allocator = self.allocator };
            var neg = BalancedTernary{ .trits = neg_trits, .allocator = self.allocator };
            defer pos.deinit();
            defer neg.deinit();

            // Avoid 'b' is self issues.
            const b_trits = try self.allocator.dupe(Trit, b.trits);
            defer self.allocator.free(b_trits);

            var result = try BalancedTernary.initString(self.allocator, "0");
            // result.deinit(); // not required

            for (b_trits, 0..) |trit, i| {
                switch (trit.symbol) {
                    .tn => try result.add(result, neg),
                    .tz => {},
                    .tp => try result.add(result, pos),
                }
                mem.copyBackwards(Trit, pos.trits[i + 1 .. i + a.trits.len + 1], pos.trits[i .. i + a.trits.len]);
                mem.copyBackwards(Trit, neg.trits[i + 1 .. i + a.trits.len + 1], neg.trits[i .. i + a.trits.len]);
                pos.trits[i].symbol = Trit.Symbol.tz;
                neg.trits[i].symbol = Trit.Symbol.tz;
            }
            self.allocator.free(self.trits);
            self.trits = result.trits;
        }
    }
};

test "@mod" {
    try testing.expectEqual(@as(i32, 0), @mod(@as(i32, -6), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 1), @mod(@as(i32, -5), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 2), @mod(@as(i32, -4), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 0), @mod(@as(i32, -3), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 1), @mod(@as(i32, -2), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 2), @mod(@as(i32, -1), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 0), @mod(@as(i32, 0), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 1), @mod(@as(i32, 1), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 2), @mod(@as(i32, 2), @as(i32, 3)));
    try testing.expectEqual(@as(i32, 0), @mod(@as(i32, 3), @as(i32, 3)));
}

test "conversion" {
    const allocator = testing.allocator;

    const table = [_]struct { decimal: i32, bt: []const u8 }{
        .{ .decimal = 0, .bt = "0" },    .{ .decimal = 0, .bt = "0" },
        .{ .decimal = 1, .bt = "+" },    .{ .decimal = -1, .bt = "-" },
        .{ .decimal = 2, .bt = "+-" },   .{ .decimal = -2, .bt = "-+" },
        .{ .decimal = 3, .bt = "+0" },   .{ .decimal = -3, .bt = "-0" },
        .{ .decimal = 4, .bt = "++" },   .{ .decimal = -4, .bt = "--" },
        .{ .decimal = 5, .bt = "+--" },  .{ .decimal = -5, .bt = "-++" },
        .{ .decimal = 6, .bt = "+-0" },  .{ .decimal = -6, .bt = "-+0" },
        .{ .decimal = 7, .bt = "+-+" },  .{ .decimal = -7, .bt = "-+-" },
        .{ .decimal = 8, .bt = "+0-" },  .{ .decimal = -8, .bt = "-0+" },
        .{ .decimal = 9, .bt = "+00" },  .{ .decimal = -9, .bt = "-00" },
        .{ .decimal = 10, .bt = "+0+" }, .{ .decimal = -10, .bt = "-0-" },
        .{ .decimal = 11, .bt = "++-" }, .{ .decimal = -11, .bt = "--+" },
        .{ .decimal = 12, .bt = "++0" }, .{ .decimal = -12, .bt = "--0" },
        .{ .decimal = 13, .bt = "+++" }, .{ .decimal = -13, .bt = "---" },
    };
    for (table) |line| {
        const a = try BalancedTernary.initString(allocator, line.bt);
        defer a.deinit();
        const b = try BalancedTernary.initInt(allocator, line.decimal);
        defer b.deinit();
        try testing.expect(a.eql(a));
        try testing.expect(b.eql(a));
        try testing.expect(a.eql(b));

        const sa = try a.toString(allocator);
        defer allocator.free(sa);
        const sb = try b.toString(allocator);
        defer allocator.free(sb);

        try testing.expectEqualStrings(line.bt, sa);
        try testing.expectEqualStrings(line.bt, sb);

        try testing.expectEqual(line.decimal, try a.toInt());
        try testing.expectEqual(line.decimal, try b.toInt());
        // ----------------------------------------- negate
        var c = try BalancedTernary.initString(allocator, line.bt);
        var d = try BalancedTernary.initInt(allocator, line.decimal);
        defer c.deinit();
        defer d.deinit();

        c.negate();
        try testing.expectEqual(-line.decimal, try c.toInt());
        d.negate();
        try testing.expectEqual(-line.decimal, try d.toInt());
        d.negate();
        // ------------------------------------------ clone
        var e = try a.clone();
        var f = try d.clone();
        defer e.deinit();
        defer f.deinit();
        try testing.expect(e.eql(a));
        try testing.expect(e.eql(b));
        try testing.expect(f.eql(a));
        try testing.expect(f.eql(b));
        try testing.expect(a.eql(e));
        try testing.expect(b.eql(e));
        try testing.expect(a.eql(f));
        try testing.expect(b.eql(f));
    }
}

test "add" {
    const allocator = testing.allocator;

    var result = try BalancedTernary.init(allocator);
    defer result.deinit();
    const zero = try BalancedTernary.init(allocator);
    defer zero.deinit();
    const a = try BalancedTernary.initInt(allocator, 1);
    defer a.deinit();
    const b = try BalancedTernary.initInt(allocator, 9);
    defer b.deinit();

    try testing.expect(result.isZero());
    try testing.expect(zero.isZero());
    try testing.expect(result.eql(zero));
    try testing.expect(zero.eql(result));

    try result.add(zero, zero);
    try testing.expect(result.isZero());

    try result.add(a, zero);
    try testing.expect(result.eql(a));

    try result.add(b, zero);
    try testing.expect(result.eql(b));

    try result.add(zero, a);
    try testing.expect(result.eql(a));

    try result.add(zero, b);
    try testing.expect(result.eql(b));
}

test "trit add" {
    const tn = Trit.Symbol.tn;
    const tz = Trit.Symbol.tz;
    const tp = Trit.Symbol.tp;

    const table = [_]struct { a: Trit.Symbol, b: Trit.Symbol, result: Trit.Symbol, carry: Trit.Symbol }{
        .{ .a = tn, .b = tn, .carry = tn, .result = tp },
        .{ .a = tn, .b = tz, .carry = tz, .result = tn },
        .{ .a = tn, .b = tp, .carry = tz, .result = tz },
        .{ .a = tz, .b = tn, .carry = tz, .result = tn },
        .{ .a = tz, .b = tz, .carry = tz, .result = tz },
        .{ .a = tz, .b = tp, .carry = tz, .result = tp },
        .{ .a = tp, .b = tn, .carry = tz, .result = tz },
        .{ .a = tp, .b = tz, .carry = tz, .result = tp },
        .{ .a = tp, .b = tp, .carry = tp, .result = tn },
    };
    for (table) |expected| {
        const expected_result = Trit{ .symbol = expected.result };
        const expected_carry = Trit{ .symbol = expected.carry };
        const actual = Trit.add(Trit{ .symbol = expected.a }, Trit{ .symbol = expected.b });
        try testing.expectEqual(expected_result.symbol, actual.trit.symbol);
        try testing.expectEqual(expected_carry.symbol, actual.carry.symbol);
    }
}

test "trit addc" {
    const tn = Trit.Symbol.tn;
    const tz = Trit.Symbol.tz;
    const tp = Trit.Symbol.tp;

    const table = [_]struct { a: Trit.Symbol, b: Trit.Symbol, c: Trit.Symbol, result: Trit.Symbol, carry: Trit.Symbol }{
        .{ .a = tn, .b = tn, .c = .tn, .carry = tn, .result = tz },
        .{ .a = tn, .b = tn, .c = .tz, .carry = tn, .result = tp },
        .{ .a = tn, .b = tn, .c = .tp, .carry = tz, .result = tn },
        .{ .a = tn, .b = tz, .c = .tn, .carry = tn, .result = tp },
        .{ .a = tn, .b = tz, .c = .tz, .carry = tz, .result = tn },
        .{ .a = tn, .b = tz, .c = .tp, .carry = tz, .result = tz },
        .{ .a = tn, .b = tp, .c = .tn, .carry = tz, .result = tn },
        .{ .a = tn, .b = tp, .c = .tz, .carry = tz, .result = tz },
        .{ .a = tn, .b = tp, .c = .tp, .carry = tz, .result = tp },

        .{ .a = tz, .b = tn, .c = .tn, .carry = tn, .result = tp },
        .{ .a = tz, .b = tn, .c = .tz, .carry = tz, .result = tn },
        .{ .a = tz, .b = tn, .c = .tp, .carry = tz, .result = tz },
        .{ .a = tz, .b = tz, .c = .tn, .carry = tz, .result = tn },
        .{ .a = tz, .b = tz, .c = .tz, .carry = tz, .result = tz },
        .{ .a = tz, .b = tz, .c = .tp, .carry = tz, .result = tp },
        .{ .a = tz, .b = tp, .c = .tn, .carry = tz, .result = tz },
        .{ .a = tz, .b = tp, .c = .tz, .carry = tz, .result = tp },
        .{ .a = tz, .b = tp, .c = .tp, .carry = tp, .result = tn },

        .{ .a = tp, .b = tn, .c = .tn, .carry = tz, .result = tn },
        .{ .a = tp, .b = tn, .c = .tz, .carry = tz, .result = tz },
        .{ .a = tp, .b = tn, .c = .tp, .carry = tz, .result = tp },
        .{ .a = tp, .b = tz, .c = .tn, .carry = tz, .result = tz },
        .{ .a = tp, .b = tz, .c = .tz, .carry = tz, .result = tp },
        .{ .a = tp, .b = tz, .c = .tp, .carry = tp, .result = tn },
        .{ .a = tp, .b = tp, .c = .tn, .carry = tz, .result = tp },
        .{ .a = tp, .b = tp, .c = .tz, .carry = tp, .result = tn },
        .{ .a = tp, .b = tp, .c = .tp, .carry = tp, .result = tz },
    };
    for (table) |expected| {
        const expected_result = Trit{ .symbol = expected.result };
        const expected_carry = Trit{ .symbol = expected.carry };
        const actual = Trit.addc(Trit{ .symbol = expected.a }, Trit{ .symbol = expected.b }, Trit{ .symbol = expected.c });
        try testing.expectEqual(expected_result.symbol, actual.trit.symbol);
        try testing.expectEqual(expected_carry.symbol, actual.carry.symbol);
    }
}

test "balanced ternary add" {
    const allocator = testing.allocator;
    for (0..64 + 1) |i|
        for (0..64 + 1) |j| {
            const ii = @as(i32, @intCast(i)) - 32;
            const jj = @as(i32, @intCast(j)) - 32;
            var sum = try BalancedTernary.init(allocator);
            defer sum.deinit();
            const a = try BalancedTernary.initInt(allocator, ii);
            defer a.deinit();
            const b = try BalancedTernary.initInt(allocator, jj);
            defer b.deinit();
            try sum.add(a, b);
            try testing.expectEqual(ii + jj, try sum.toInt());
        };
}

test "balanced ternary add to self" {
    const allocator = testing.allocator;

    const n: i32 = 7;
    const m: i32 = 3;
    var result = try BalancedTernary.initInt(allocator, n);
    var addend = try BalancedTernary.initInt(allocator, m);
    defer result.deinit();
    defer addend.deinit();
    try result.add(result, addend);
    try testing.expectEqual(n + m, try result.toInt());
    try result.add(result, result);
    try testing.expectEqual(n + m + n + m, try result.toInt());
}

test "balanced ternary mul" {
    const allocator = testing.allocator;

    for (0..64 + 1) |i|
        for (0..64 + 1) |j| {
            const ii = @as(i32, @intCast(i)) - 32;
            const jj = @as(i32, @intCast(j)) - 32;
            var product = try BalancedTernary.init(allocator);
            defer product.deinit();
            const a = try BalancedTernary.initInt(allocator, ii);
            defer a.deinit();
            const b = try BalancedTernary.initInt(allocator, jj);
            defer b.deinit();
            try product.mul(a, b);
            try testing.expectEqual(ii * jj, try product.toInt());
        };
}

test "balanced ternary mul by self" {
    const allocator = testing.allocator;
    const n: i32 = 7;
    const m: i32 = 3;
    var result = try BalancedTernary.initInt(allocator, n);
    var muliplier = try BalancedTernary.initInt(allocator, m);
    defer result.deinit();
    defer muliplier.deinit();
    try result.mul(result, muliplier);
    try testing.expectEqual(n * m, try result.toInt());
    try result.mul(result, result);
    try testing.expectEqual(n * m * n * m, try result.toInt());
}
