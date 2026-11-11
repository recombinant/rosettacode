// https://rosettacode.org/wiki/Boustrophedon_transform
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Io = std.Io;

fn BoustrophedonIterator(comptime SequenceContext: type) type {
    return struct {
        index: i32,
        context: SequenceContext,
        cache: AutoHashMap(u32, AutoHashMap(u32, i64)),
        allocator: Allocator,

        const Self = @This();

        fn init(allocator: Allocator, context: SequenceContext) Self {
            return .{
                .index = -1,
                .context = context,
                .cache = .init(allocator),
                .allocator = allocator,
            };
        }

        fn deinit(self: *Self) void {
            var it = self.cache.iterator();
            while (it.next()) |entry|
                entry.value_ptr.deinit();
            self.cache.deinit();
        }

        fn next(self: *Self) !i64 {
            self.index += 1;
            const index: u32 = @intCast(self.index);
            return self.transform(index, index);
        }

        fn transform(self: *Self, k: u32, n: u32) !i64 {
            if (n == 0)
                return self.context.call(k);

            if (self.cache.get(k)) |inner_map|
                if (inner_map.get(n)) |value|
                    return value;

            const value = try self.transform(k, n - 1) + try self.transform(k - 1, k - n);

            if (!self.cache.contains(k))
                try self.cache.put(k, .init(self.allocator));

            var inner_map = self.cache.getPtr(k).?;
            try inner_map.put(n, value);
            return value;
        }
    };
}

fn sievePrimes(allocator: Allocator, limit: u32, primes: *ArrayList(u32)) !void {
    try primes.append(allocator, 2);
    const half_limit = (limit + 1) / 2;
    var composite = try allocator.alloc(bool, half_limit);
    defer allocator.free(composite);
    @memset(composite, false);

    var i: u32 = 1;
    var p: u32 = 3;

    while (i < half_limit) {
        if (!composite[i]) {
            try primes.append(allocator, p);
            var a = i + p;
            while (a < half_limit) {
                composite[a] = true;
                a += p;
            }
        }
        p += 2;
        i += 1;
    }
}

const OneOneContext = struct {
    pub fn call(_: @This(), number: u32) i64 {
        return if (number == 0) 1 else 0;
    }
};

const AllOnesContext = struct {
    pub fn call(_: @This(), _: u32) i64 {
        return 1;
    }
};

const AlternatingContext = struct {
    pub fn call(_: @This(), number: u32) i64 {
        return if (number % 2 == 0) 1 else -1;
    }
};

const PrimeContext = struct {
    primes: []const u32,

    pub fn call(self: @This(), number: u32) i64 {
        return @intCast(self.primes[number]);
    }
};

const FibonacciContext = struct {
    cache: *AutoHashMap(u32, i64),

    pub fn call(self: @This(), number: u32) !i64 {
        if (self.cache.get(number)) |value|
            return value;

        const value = if (number == 0 or number == 1)
            1
        else
            (try self.call(number - 2)) + (try self.call(number - 1));

        try self.cache.put(number, value);
        return value;
    }
};

const FactorialContext = struct {
    cache: *AutoHashMap(u32, i64),

    pub fn call(self: @This(), number: u32) !i64 {
        if (self.cache.get(number)) |value|
            return value;

        var value: i64 = 1;
        var i: u32 = 2;
        while (i <= number) : (i += 1)
            value *= @intCast(i);

        try self.cache.put(number, value);
        return value;
    }
};

fn display(io: Io, allocator: Allocator, title: []const u8, context: anytype) !void {
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ----------------------------------------------------------
    try stdout.print("{s}\n", .{title});

    var iterator: BoustrophedonIterator(@TypeOf(context)) = .init(allocator, context);
    defer iterator.deinit();

    for (0..15) |_|
        try stdout.print("{} ", .{try iterator.next()});

    try stdout.writeAll("\n\n");
    // ----------------------------------------------------------
    try stdout.flush();
}

pub fn main(init: std.process.Init) !void {
    const allocator: Allocator = init.gpa;
    const io: Io = init.io;

    var primes: ArrayList(u32) = .empty;
    defer primes.deinit(allocator);

    var fibonacci_cache: AutoHashMap(u32, i64) = .init(allocator);
    defer fibonacci_cache.deinit();

    var factorial_cache: AutoHashMap(u32, i64) = .init(allocator);
    defer factorial_cache.deinit();

    try sievePrimes(allocator, 8_000, &primes);

    try display(io, allocator, "One followed by an infinite series of zeros -> A000111", OneOneContext{});
    try display(io, allocator, "An infinite series of ones -> A000667", AllOnesContext{});
    try display(io, allocator, "(-1)^n: alternating 1, -1, 1, -1 -> A062162", AlternatingContext{});
    try display(io, allocator, "Sequence of prime numbers -> A000747", PrimeContext{ .primes = primes.items });
    try display(io, allocator, "Sequence of Fibonacci numbers -> A000744", FibonacciContext{ .cache = &fibonacci_cache });
    try display(io, allocator, "Sequence of factorial numbers -> A230960", FactorialContext{ .cache = &factorial_cache });
}
