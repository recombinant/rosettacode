// https://rosettacode.org/wiki/Two_bullet_roulette
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // --------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------- pseudo random number generator
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    // ----------------------------------------------------
    var revolver: Revolver = .init(allocator, rand);

    const combinations = [_][]const u8{
        "LSLSFSF",
        "LSLSFF",
        "LLSFSF",
        "LLSFF",
    };
    for (combinations) |string| {
        const result = try revolver.roulette(string);
        defer allocator.free(result.text);
        try stdout.print(
            "{s: <40} produces {d:6.3}% deaths.\n",
            .{ result.text, result.percent },
        );
    }
    try stdout.flush();
}

const Revolver = struct {
    allocator: std.mem.Allocator,
    rand: std.Random = undefined,
    cylinder: [6]bool = std.mem.zeroes([6]bool),

    fn init(allocator: std.mem.Allocator, rand: std.Random) Revolver {
        return Revolver{
            .allocator = allocator,
            .rand = rand,
        };
    }

    /// Caller owns text memory returned in struct
    fn roulette(self: *Revolver, src: []const u8) !struct { text: []const u8, percent: f64 } {
        var a: std.Io.Writer.Allocating = .init(self.allocator);
        defer a.deinit();

        const test_count = 100_000;
        var sum: u32 = 0;
        for (0..test_count) |_|
            sum += try self.method(src);

        try mstring(src, &a.writer);
        const percent = (100.0 * @as(f64, @floatFromInt(sum))) / test_count;

        return .{
            .text = try a.toOwnedSlice(),
            .percent = percent,
        };
    }

    fn mstring(s: []const u8, w: *std.Io.Writer) !void {
        for (s) |c| {
            const word: []const u8 = switch (c) {
                'L' => "load",
                'S' => "spin",
                'F' => "fire",
                else => unreachable,
            };
            if (w.end != 0)
                try w.writeAll(", ");
            try w.writeAll(word);
        }
    }

    fn method(self: *Revolver, s: []const u8) !u1 {
        self.unload();
        for (s) |c|
            switch (c) {
                'L' => try self.load(),
                'S' => self.spin(),
                'F' => {
                    if (self.fire())
                        return 1;
                },
                else => unreachable,
            };
        return 0;
    }

    fn unload(self: *Revolver) void {
        for (&self.cylinder) |*chamber|
            chamber.* = false;
    }

    const CylinderError = error{
        Full,
    };

    fn load(self: *Revolver) !void {
        var count: u8 = 0;
        while (self.cylinder[0]) {
            self.rshift();
            count += 1;
            if (count == self.cylinder.len)
                return CylinderError.Full;
        }
        self.cylinder[0] = true;
        self.rshift();
    }
    /// Cylinder to take a random position from 1 to 6
    fn spin(self: *Revolver) void {
        const rotation = self.rand.uintLessThan(u3, self.cylinder.len);
        for (0..rotation) |_|
            self.rshift();
    }
    fn fire(self: *Revolver) bool {
        const shot = self.cylinder[0];
        self.rshift();
        return shot;
    }
    fn rshift(self: *Revolver) void {
        std.mem.rotate(bool, &self.cylinder, self.cylinder.len - 1);
    }
};

const testing = std.testing;

test "rshift" {
    var revolver: Revolver = .{ .allocator = testing.allocator };

    try testing.expectEqual(6, revolver.cylinder.len);

    @memcpy(&revolver.cylinder, &[6]bool{ true, false, false, false, false, false });
    try testing.expectEqualSlices(bool, &revolver.cylinder, &revolver.cylinder);
    try testing.expectEqualSlices(bool, &[6]bool{ true, false, false, false, false, false }, &revolver.cylinder);

    revolver.rshift();
    try testing.expectEqual(false, revolver.cylinder[0]);
    try testing.expectEqual(true, revolver.cylinder[1]);
    try testing.expectEqual(false, revolver.cylinder[2]);
    try testing.expectEqual(false, revolver.cylinder[3]);
    try testing.expectEqual(false, revolver.cylinder[4]);
    try testing.expectEqual(false, revolver.cylinder[5]);
    try testing.expectEqualSlices(bool, &[6]bool{ false, true, false, false, false, false }, &revolver.cylinder);

    revolver.rshift();
    revolver.rshift();
    revolver.rshift();
    revolver.rshift();
    try testing.expectEqualSlices(bool, &[6]bool{ false, false, false, false, false, true }, &revolver.cylinder);

    revolver.rshift();
    try testing.expectEqualSlices(bool, &[6]bool{ true, false, false, false, false, false }, &revolver.cylinder);
}

test "unload/load" {
    var revolver: Revolver = .{ .allocator = testing.allocator };

    try testing.expectEqual(6, revolver.cylinder.len);

    revolver.unload();
    try testing.expect(std.mem.allEqual(bool, &revolver.cylinder, false));
    // 1st
    try revolver.load();
    try testing.expectEqualSlices(bool, &[6]bool{ false, true, false, false, false, false }, &revolver.cylinder);
    // 2nd
    try revolver.load();
    try testing.expectEqualSlices(bool, &[6]bool{ false, true, true, false, false, false }, &revolver.cylinder);
    // 3rd
    try revolver.load();
    try testing.expectEqualSlices(bool, &[6]bool{ false, true, true, true, false, false }, &revolver.cylinder);
    // 4th
    try revolver.load();
    try testing.expectEqualSlices(bool, &[6]bool{ false, true, true, true, true, false }, &revolver.cylinder);
    // 5th
    try revolver.load();
    try testing.expectEqualSlices(bool, &[6]bool{ false, true, true, true, true, true }, &revolver.cylinder);
    // 6th
    try revolver.load();
    try testing.expect(std.mem.allEqual(bool, &revolver.cylinder, true));
    // oops, should be full
    try testing.expectError(Revolver.CylinderError.Full, revolver.load());
}
