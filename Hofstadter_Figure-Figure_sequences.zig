// https://rosettacode.org/wiki/Hofstadter_Figure-Figure_sequences
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var figure_sequence = try FigureSequence(u16).init(allocator);
    defer figure_sequence.deinit();

    // task 3
    for (1..11) |n|
        std.debug.print("r({d}): {d}\n", .{ n, try figure_sequence.ffr(n) });

    // task 4
    var found = std.mem.zeroes([1001]usize);
    for (1..41) |n| found[try figure_sequence.ffr(n)] += 1;
    for (1..961) |n| found[try figure_sequence.ffs(n)] += 1;
    for (found[1..]) |n|
        if (n != 1) {
            std.debug.print("task 4: FAIL\n", .{});
            return;
        };
    std.debug.print("task 4: PASS\n", .{});
}

fn FigureSequence(T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        // task 1, 2
        r: std.ArrayList(T),
        s: std.ArrayList(T),

        const Self = @This();
        fn init(allocator: std.mem.Allocator) !Self {
            var r: std.ArrayList(T) = .empty;
            var s: std.ArrayList(T) = .empty;
            try r.appendSlice(allocator, &[2]T{ 0, 1 });
            try s.appendSlice(allocator, &[2]T{ 0, 2 });
            return Self{
                .allocator = allocator,
                .r = r,
                .s = s,
            };
        }
        fn deinit(self: *Self) void {
            self.r.deinit(self.allocator);
            self.s.deinit(self.allocator);
        }
        fn ffr(self: *Self, n: usize) !T {
            while (self.r.items.len <= n) {
                const nrk = self.r.items.len - 1; // last n for which r(n) is known
                const next_nrk = self.r.items[nrk] + self.s.items[nrk]; // next value of r:  r(nrk+1)
                try self.r.append(self.allocator, next_nrk); // extend sequence r by one element
                var sn = self.r.items[nrk] + 2;
                while (sn < next_nrk) : (sn += 1)
                    try self.s.append(self.allocator, sn); // extend sequence s up to next_nrk
                try self.s.append(self.allocator, next_nrk + 1); // extend sequence s one past next_nrk
            }
            return self.r.items[n];
        }
        fn ffs(self: *Self, n: usize) !T {
            while (self.s.items.len <= n)
                _ = try self.ffr(self.r.items.len);
            return self.s.items[n];
        }
    };
}
