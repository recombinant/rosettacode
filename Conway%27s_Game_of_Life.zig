// https://rosettacode.org/wiki/Conway%27s_Game_of_Life
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    // ---------------------------- pseudo random number generator
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ----------------------------------------------------------
    // zero size buffer means unbuffered (to slow it down)
    var buffer: [0]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    try stdout.writeAll("\x1b[?25l"); // hide cursor
    var life = Life(80, 15).init(random);
    for (0..300) |_| {
        life.step();
        try stdout.writeAll("\x1b[1;1H"); // move cursor to 1,1
        try stdout.print("{f}", .{life});
        try stdout.flush();
        // FIXME: not Ok with Zig 0.15.1 on Windows
        // sleep if using buffered stdout
        // std.posix.nanosleep(1_000_000_000 / 30, 0); // 1/30th second
    }
    try stdout.writeAll("\x1b[?25h"); // show cursor
}
fn Life(comptime w: usize, comptime h: usize) type {
    return struct {
        const Self = @This();
        a: Field(w, h),
        b: Field(w, h),

        fn init(random: std.Random) Self {
            var life: Self = .{
                .a = Field(w, h).init(),
                .b = Field(w, h).init(),
            };
            for (0..w * h / 2) |_| {
                const x = random.uintLessThan(usize, w);
                const y = random.uintLessThan(usize, h);
                life.a.set(x, y, true);
            }
            return life;
        }
        fn step(self: *Self) void {
            for (0..h) |y|
                for (0..w) |x|
                    self.b.set(x, y, self.a.next(x, y));
            std.mem.swap(Field(w, h), &self.a, &self.b);
        }
        pub fn format(self: *const Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
            for (0..h) |y| {
                for (0..w) |x|
                    try writer.writeByte(if (self.a.state(x, y)) '*' else ' ');
                try writer.writeByte('\n');
            }
        }
    };
}
fn Field(comptime w: usize, comptime h: usize) type {
    return struct {
        const Self = @This();
        s: std.StaticBitSet(w * h),

        fn init() Self {
            return .{ .s = std.StaticBitSet(w * h).initEmpty() };
        }
        fn set(self: *Self, x: usize, y: usize, b: bool) void {
            self.s.setValue(y * w + x, b);
        }
        fn next(self: *const Self, x_: usize, y_: usize) bool {
            var on: usize = 0;
            // Use wraparound arithmetic, i.e. -%
            inline for ([3]usize{ x_ -% 1, x_, x_ + 1 }) |x|
                inline for ([3]usize{ y_ -% 1, y_, y_ + 1 }) |y|
                    if (self.state(x, y)) {
                        on += 1;
                    };
            return on == 3 or on == 2 and self.state(x_, y_);
        }
        fn state(self: *const Self, x: usize, y: usize) bool {
            if (x >= w or y >= h) return false;
            return self.s.isSet(y * w + x);
        }
    };
}
