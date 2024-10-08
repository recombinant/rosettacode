// https://rosettacode.org/wiki/Quaternion_type
const std = @import("std");
const fmt = std.fmt;
const math = std.math;
const mem = std.mem;

const print = std.debug.print;

pub fn main() void {
    const Q = Quaternion(f64);
    const q = Q.init(1, 2, 3, 4);
    const q1 = Q.init(2, 3, 4, 5);
    const q2 = Q.init(3, 4, 5, 6);

    const r = 7;

    print("Inputs\n", .{});
    print("q  : {d:.0}\n", .{q});
    print("q1 : {d:.0}\n", .{q1});
    print("q2 : {d:.0}\n", .{q2});
    print("r  : {d:.0}\n", .{r});

    print("\nFunctions\n", .{});
    print("q.norm()   : {d:.3}\n", .{q.norm()});
    print("q.neg()    : {d}\n", .{q.neg()});
    print("q.conj()   : {d}\n", .{q.conj()});
    print("q.add(r)   : {d}\n", .{q.add(r)});
    print("q1.add(q2) : {d}\n", .{q1.add(q2)});
    print("q.mul(r)   : {d}\n", .{q.mul(r)});
    print("q1.mul(q2) : {d}\n", .{q1.mul(q2)});
    print("q2.mul(q1) : {d}\n", .{q2.mul(q1)});
}

fn Quaternion(T: type) type {
    if (@typeInfo(T) != .float)
        @compileError("Quaternion requires a float, found " ++ @typeName(T));

    return struct {
        const Self = @This();
        r: T,
        i: T,
        j: T,
        k: T,

        fn init(r: T, i: T, j: T, k: T) Self {
            return .{ .r = r, .i = i, .j = j, .k = k };
        }
        pub fn format(self: Self, comptime fmt_: []const u8, option: std.fmt.FormatOptions, writer: anytype) !void {
            const mode: fmt.format_float.Format = comptime if (mem.eql(u8, "d", fmt_)) .decimal else .scientific;
            const options = fmt.format_float.FormatOptions{ .mode = mode, .precision = option.precision };
            var buffer: [fmt.format_float.bufferSize(mode, T)]u8 = undefined;

            try writer.writeByte('(');

            var started = false;
            for ([_]T{ self.r, self.i, self.j, self.k }) |v| {
                if (started) try writer.writeAll(", ") else started = true;
                const s = try fmt.formatFloat(&buffer, v, options);
                try writer.writeAll(s);
            }
            try writer.writeByte(')');
        }
        fn norm(self: Self) T {
            return math.sqrt(self.r * self.r + self.i * self.i + self.j * self.j + self.k * self.k);
        }
        fn neg(self: Self) Self {
            return .{ .r = -self.r, .i = -self.i, .j = -self.j, .k = -self.k };
        }
        fn conj(self: Self) Self {
            return .{ .r = self.r, .i = -self.i, .j = -self.j, .k = -self.k };
        }
        fn add(self: Self, other: anytype) Self {
            if (@TypeOf(other) == Self or @TypeOf(other) == *Self or @TypeOf(other) == *const Self)
                return .{ .r = self.r + other.r, .i = self.i + other.i, .j = self.j + other.j, .k = self.k + other.k };

            const r: T = switch (@typeInfo(@TypeOf(other))) {
                .float, .comptime_float => @floatCast(other),
                .int, .comptime_int => @floatFromInt(other),
                else => unreachable,
            };
            return .{ .r = self.r + r, .i = self.i, .j = self.j, .k = self.k };
        }
        fn mul(self: Self, other: anytype) Self {
            if (@TypeOf(other) == Self or @TypeOf(other) == *Self or @TypeOf(other) == *const Self)
                return .{
                    .r = self.r * other.r - self.i * other.i - self.j * other.j - self.k * other.k,
                    .i = self.r * other.i + self.i * other.r + self.j * other.k - self.k * other.j,
                    .j = self.r * other.j - self.i * other.k + self.j * other.r + self.k * other.i,
                    .k = self.r * other.k + self.i * other.j - self.j * other.i + self.k * other.r,
                };

            const r: T = switch (@typeInfo(@TypeOf(other))) {
                .float, .comptime_float => @floatCast(other),
                .int, .comptime_int => @floatFromInt(other),
                else => unreachable,
            };
            return .{ .r = self.r * r, .i = self.i * r, .j = self.j * r, .k = self.k * r };
        }
    };
}
