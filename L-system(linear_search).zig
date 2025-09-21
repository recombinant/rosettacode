// https://rosettacode.org/wiki/L-system
// {{works with|Zig|0.15.1}}
// {{trans|FreeBASIC}}
const std = @import("std");
const print = std.debug.print;

// This is a simple solution suitable for a rule count.

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const rules = [2]Rule{ .{ 'I', "M" }, .{ 'M', "MI" } };
    try showLindenmayer(allocator, "I", &rules, 5);
}

const Rule = struct { u8, []const u8 };

fn showLindenmayer(allocator: std.mem.Allocator, axiom: []const u8, rules: []const Rule, count: usize) !void {
    var next: std.ArrayList(u8) = .empty;
    defer next.deinit(allocator);

    var s: std.ArrayList(u8) = .empty;
    defer s.deinit(allocator);
    try s.appendSlice(allocator, axiom);

    for (0..count + 1) |_| {
        next.clearRetainingCapacity();

        print("{s}\n", .{s.items});

        for (s.items) |c| {
            for (rules) |rule| {
                if (c == rule[0]) {
                    try next.appendSlice(allocator, rule[1]); // found
                    break;
                }
            } else try next.append(allocator, c); // not found
        }
        s.clearRetainingCapacity();
        try s.appendSlice(allocator, next.items);
    }
}
