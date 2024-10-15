// https://rosettacode.org/wiki/Equal_prime_and_composite_sums
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const mem = std.mem;
const time = std.time;

const print = std.debug.print;

// https://rosettacode.org/wiki/Extensible_prime_generator
const PrimeGen = @import("Extensible_prime_generator_alternate.zig").PrimeGen;
const AutoSieveType = @import("Extensible_prime_generator_alternate.zig").AutoSieveType;

pub fn main() !void {
    const limit = 400_000_000;

    var t0 = try time.Timer.start();

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var c = Composite(limit).init(allocator);
    defer c.deinit();
    var p = Prime(limit).init(allocator);
    defer p.deinit();

    print("          Sum         |   Prime Index   | Composite Index \n", .{});
    print("──────────────────────────────────────────────────────────\n", .{});

    var ic, var nc, var csum = c.next();
    var ip, var np, var psum = p.next();

    while (true) {
        if (psum == csum) {
            ic, nc, csum = c.next();
            ip, np, psum = p.next();
            print("{d:>21} | {d:>15} | {d:>15}\n", .{ psum, ip, ic });
        } else if (psum < csum)
            ip, np, psum = p.next()
        else
            ic, nc, csum = c.next();

        if (np > limit or nc > limit)
            break;
    }
    print("\nprocessed in {}\n", .{fmt.fmtDuration(t0.read())});
}

fn Prime(comptime limit: u64) type {
    const T = AutoSieveType(limit);
    return struct {
        const Self = @This();

        ip: usize = 0,
        psum: u64 = 0,

        primegen: PrimeGen(T),

        fn init(allocator: mem.Allocator) Self {
            return Self{
                .primegen = PrimeGen(T).init(allocator),
            };
        }
        fn deinit(self: *Self) void {
            self.primegen.deinit();
        }
        fn next(self: *Self) struct { usize, u64, u64 } {
            self.ip += 1;
            const prime = (self.primegen.next() catch unreachable).?;
            self.psum += prime;
            return .{ self.ip, prime, self.psum };
        }
    };
}

fn Composite(comptime limit: u64) type {
    const T = AutoSieveType(limit);
    return struct {
        const Self = @This();

        ic: usize = 1,
        nc: u64 = 4,
        csum: u64 = 4,

        primegen: PrimeGen(T),
        prime: u64,

        fn init(allocator: mem.Allocator) Self {
            var primegen = PrimeGen(T).init(allocator);
            const prime = (primegen.next() catch unreachable).?;
            return Self{
                .primegen = primegen,
                .prime = prime,
            };
        }
        fn deinit(self: *Self) void {
            self.primegen.deinit();
        }

        fn next(self: *Self) struct { usize, u64, u64 } {
            const result0 = self.ic;
            const result1 = self.nc;
            const result2 = self.csum;

            self.nc += 1;
            while (self.isPrime(self.nc))
                self.nc += 1;
            self.csum += self.nc;
            self.ic += 1;
            return .{ result0, result1, result2 };
        }

        fn isPrime(self: *Self, number: u64) bool {
            while (self.prime < number)
                self.prime = (self.primegen.next() catch unreachable).?;
            return self.prime == number;
        }
    };
}
