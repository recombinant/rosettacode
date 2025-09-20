// https://rosettacode.org/wiki/Fibonacci_word
// {{works with|Zig|0.15.1}}
// {{trans|Nim}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print(" n    length       entropy\n", .{});
    try stdout.print("————————————————————————————————\n", .{});
    try stdout.flush();

    var n: usize = 0;

    var fibword: FibWord = try .init(allocator);
    defer fibword.deinit();

    while (true) {
        const str = try fibword.next();
        n += 1;
        try stdout.print("{d:2}  {d:8}  {d:16.16}\n", .{ n, str.len, entropy(str) });
        try stdout.flush();
        if (n == 37)
            break;
    }
}

/// return the entropy of a fibword string
fn entropy(s: []const u8) f64 {
    if (s.len <= 1)
        return 0.0;
    const len: f64 = @floatFromInt(s.len);
    var count0: f64 = 0;
    var count1: f64 = 0;
    for (s) |c| {
        switch (c) {
            '0' => count0 += 1,
            '1' => count1 += 1,
            else => unreachable,
        }
    }
    return -(count0 / len * @log2(count0 / len) + count1 / len * @log2(count1 / len));
}

const FibWord = struct {
    const State = enum { first, second, many };

    allocator: std.mem.Allocator,
    a: []const u8,
    b: []const u8,
    state: State = .first,

    fn init(allocator: std.mem.Allocator) !FibWord {
        return .{
            .allocator = allocator,
            .a = try allocator.dupe(u8, "1"),
            .b = try allocator.dupe(u8, "0"),
        };
    }
    fn deinit(self: FibWord) void {
        self.allocator.free(self.a);
        self.allocator.free(self.b);
    }
    fn next(self: *FibWord) ![]const u8 {
        switch (self.state) {
            .first => {
                self.state = .second;
                return self.a;
            },
            .second => {
                self.state = .many;
                return self.b;
            },
            .many => {
                const old = self.a;
                var new = try self.allocator.alloc(u8, self.a.len + self.b.len);
                @memcpy(new[0..self.b.len], self.b);
                @memcpy(new[self.b.len..], self.a);
                self.allocator.free(old);
                self.a = new; // a = b ++ a
                std.mem.swap([]const u8, &self.a, &self.b);
                return self.b;
            },
        }
    }
};
