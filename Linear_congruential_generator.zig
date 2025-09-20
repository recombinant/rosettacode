// https://rosettacode.org/wiki/Linear_congruential_generator
// {{works with|Zig|0.15.1}}
const std = @import("std");

const print = std.debug.print;

pub fn main() void {
    {
        const RndGen = Microsoft.lcg;

        var rnd = RndGen.init(0);
        print("\nMicrosoft random\n", .{});
        print("{}\n", .{rnd.random().int(i16)});
        print("{}\n", .{rnd.random().int(i16)});
        print("{}\n", .{rnd.random().int(i16)});
        print("{}\n", .{rnd.random().int(i16)});
        print("{}\n", .{rnd.random().int(i16)});
    }
    {
        const RndGen = BSD.lcg;

        var rnd = RndGen.init(0);
        print("\nBSD random\n", .{});
        print("random number is {}\n", .{rnd.random().int(u32)});
        print("random number is {}\n", .{rnd.random().int(u32)});
        print("random number is {}\n", .{rnd.random().int(u32)});
        print("random number is {}\n", .{rnd.random().int(u32)});
        print("random number is {}\n", .{rnd.random().int(u32)});
    }
    {
        const RndGen = Microsoft.lcg;

        var rnd = RndGen.init(1);
        print("\nMicrosoft random (emulated)\n", .{});
        print("{}\n", .{rnd.random().int(usize)});
        print("{}\n", .{rnd.random().int(usize)});
        print("{}\n", .{rnd.random().int(usize)});
        print("{}\n", .{rnd.random().int(usize)});
        print("{}\n", .{rnd.random().int(usize)});
    }
    {
        const c = @cImport({
            @cInclude("stdlib.h");
        });

        c.srand(1);
        print("\nMicrosoft random\n", .{});
        print("{}\n", .{c.rand()});
        print("{}\n", .{c.rand()});
        print("{}\n", .{c.rand()});
        print("{}\n", .{c.rand()});
        print("{}\n", .{c.rand()});
    }
}

pub const Microsoft = struct {
    pub const lcg = LinearCongruentialGenerator(u16, u15, .{
        .a = 214013,
        .c = 2531011,
        .m = std.math.shl(u32, 1, 31) - 1,
        .shift = 16,
    });
};

const BSD = struct {
    pub const lcg = LinearCongruentialGenerator(u16, u31, .{
        .a = 1103515245,
        .c = 12345,
        .m = std.math.shl(u32, 1, 31) - 1,
    });
};

/// S is the seed() parameter type, R is the next() result type.
fn LinearCongruentialGenerator(comptime S: type, comptime R: type, comptime params: struct { a: u32, c: u32, m: u32, shift: u8 = 0 }) type {
    return struct {
        const Self = @This();
        a: u64 = params.a,
        c: u64 = params.c,
        m: u64 = params.m,
        shift: u8 = params.shift,
        s: u64,

        pub fn init(init_s: S) Self {
            var x: Self = .{
                .s = undefined,
            };

            x.seed(init_s);
            return x;
        }

        /// Returns a structure backed by the current RNG.
        pub fn random(self: *Self) std.Random {
            return std.Random.init(self, fill);
        }

        pub fn next(self: *Self) R {
            self.s = (self.a * self.s + self.c) & self.m;
            return if (self.shift == 0)
                @truncate(self.s)
            else
                @truncate(std.math.shr(u64, self.s, self.shift));
        }

        pub fn seed(self: *Self, init_s: u64) void {
            self.s = init_s;
        }

        /// This function makes a single call to next().
        /// This is good enough to emulate C rand() with a call to Zig rnd.random().int()
        pub fn fill(self: *Self, buf: []u8) void {
            var i: usize = 0;
            var n = self.next();
            while (i < buf.len) : (i += 1) {
                buf[i] = @truncate(n);
                n >>= 8;
            }
        }
    };
}
