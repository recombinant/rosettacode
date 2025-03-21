// https://rosettacode.org/wiki/Addition_chains
// Only handles Brauer addition chains.
pub fn main() !void {
    var arena: heap.ArenaAllocator = .init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var t0 = try time.Timer.start();

    const nums = [_]u64{ 7, 13, 14, 21, 29, 32, 42, 64, 47, 79, 191, 382, 379 };
    // const nums = [_]u64{ 47, 79, 191, 382, 379, 12509 };
    inline for (nums) |i| {
        try brauer(allocator, i);
        _ = arena.reset(.retain_capacity);
    }

    try std.io.getStdOut().writer().print("\nprocessed in {}\n", .{fmt.fmtDuration(t0.read())});
}

fn Brauer(comptime n: u64) type {
    return struct {
        const Self = @This();

        allocator: mem.Allocator,

        chain: [n]u64 = undefined,
        in_chain: [n + 1]bool = undefined,
        best: std.ArrayList(u64),
        best_len: usize = n,
        cnt: u64 = 0,

        fn init(allocator: mem.Allocator) Self {
            var b = Self{
                .allocator = allocator,
                .best = .init(allocator),
            };
            @memset(&b.chain, 0);
            @memset(&b.in_chain, false);
            return b;
        }

        fn deinit(self: Self) void {
            self.best.deinit();
        }

        fn extend_chain(self: *Self, params: struct { x: usize = 1, pos: usize = 0 }) !void {
            const x = params.x;
            var pos = params.pos;

            // # Python
            // if x<<(best_len - pos) < n:
            //    return
            {
                // This is a Translation of the above two lines of Python code.

                const diff = self.best_len - pos;
                // Avoid shifting a u64 more than 63 bits left.
                if (diff < comptime math.maxInt(u6)) {
                    // With overflow then (diff > n) and no need to check.
                    const ov = @shlWithOverflow(x, @as(u6, @intCast(diff)));
                    if (ov[1] == 0) {
                        // No overflow, so check.
                        if (ov[0] < n)
                            return;
                    }
                }
            }

            self.chain[pos] = x;
            self.in_chain[x] = true;
            pos += 1;

            if (self.in_chain[n - x]) { // found solution
                if (pos == self.best_len) {
                    self.cnt += 1;
                } else {
                    self.best.clearRetainingCapacity();
                    try self.best.appendSlice(self.chain[0..pos]);
                    self.best_len = pos;
                    self.cnt = 1;
                }
            } else if (pos < self.best_len) {
                var i: u64 = pos;
                while (i > 0) {
                    i -= 1;
                    const c = x + self.chain[i];
                    if (c < n)
                        try self.extend_chain(.{ .x = c, .pos = pos });
                }
            }
            self.in_chain[x] = false;
        }
    };
}

fn isBrauer(a: []const u64) bool {
    var j: isize = 0;

    loop: for (2..a.len) |i| {
        j = @as(isize, @bitCast(i)) - 1;
        while (j >= 0) : (j -= 1) {
            if (a[i - 1] + a[@bitCast(j)] == a[i])
                continue :loop;
        } else {
            return false;
        }
    }
    return true;
}

fn isAdditionChain(a: []const u64) bool {
    if (a.len < 3)
        return false;
    loop: for (2..a.len) |i| {
        if (a[i] > a[i - 1] * 2)
            return false;

        var j = i;
        while (j != 0) {
            var k = j;
            j -= 1;
            while (k != 0) {
                k -= 1;
                if (a[j] + a[k] == a[i])
                    continue :loop;
            }
        } else {
            return false;
        }
    }
    return true;
}

fn brauer(allocator: mem.Allocator, comptime n: usize) !void {
    var b = Brauer(n).init(allocator);
    defer b.deinit();

    try b.extend_chain(.{});
    try b.best.append(n);

    const best = try b.best.toOwnedSlice();
    defer allocator.free(best);

    try std.io.getStdOut().writer().print(
        "L({d}) = {d}, count of Brauer minimum chain: {d}\ne.g.: {any}\n\n",
        .{ n, best.len - 1, b.cnt, best },
    );
}

test "isBrauer" {
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 3, 5, 8, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 3, 5, 10, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 3, 6, 7, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 3, 6, 12, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 4, 5, 9, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 4, 6, 7, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 4, 6, 12, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 4, 8, 9, 13 }));
    try testing.expect(isBrauer(&[_]u64{ 1, 2, 4, 8, 12, 13 }));
    try testing.expect(!isBrauer(&[_]u64{ 1, 2, 4, 5, 8, 13 }));

    try testing.expect(isAdditionChain(&[_]u64{ 1, 2, 4, 5, 8, 13 }));
    try testing.expect(!isAdditionChain(&[_]u64{ 1, 2, 4, 5, 7, 13 }));
}

const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const math = std.math;
const mem = std.mem;
const time = std.time;
const testing = std.testing;
