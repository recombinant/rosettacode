// https://rosettacode.org/wiki/Quaternion_type
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const Q = Quaternion(f64);
    const q: Q = .init(1, 2, 3, 4);
    const q1: Q = .init(2, 3, 4, 5);
    const q2: Q = .init(3, 4, 5, 6);

    const r = 7;

    try stdout.writeAll("Inputs\n");
    try stdout.print("q  : {d:.0}\n", .{q});
    try stdout.print("q1 : {d:.0}\n", .{q1});
    try stdout.print("q2 : {d:.0}\n", .{q2});
    try stdout.print("r  : {d:.0}\n", .{r});

    try stdout.writeAll("\nFunctions\n");
    try stdout.print("q.norm()   : {d:.3}\n", .{q.norm()});
    try stdout.print("q.neg()    : {d}\n", .{q.neg()});
    try stdout.print("q.conj()   : {d}\n", .{q.conj()});
    try stdout.print("q.add(r)   : {d}\n", .{q.add(r)});
    try stdout.print("q1.add(q2) : {d}\n", .{q1.add(q2)});
    try stdout.print("q.mul(r)   : {d}\n", .{q.mul(r)});
    try stdout.print("q1.mul(q2) : {d}\n", .{q1.mul(q2)});
    try stdout.print("q2.mul(q1) : {d}\n", .{q2.mul(q1)});

    try stdout.flush();
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
        pub fn formatNumber(self: *const Self, w: *std.Io.Writer, number: std.fmt.Number) !void {
            _ = number;

            try w.print("({}, {}, {}, {})", .{ self.r, self.i, self.j, self.k });
        }
        fn norm(self: Self) T {
            return @sqrt(self.r * self.r + self.i * self.i + self.j * self.j + self.k * self.k);
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
