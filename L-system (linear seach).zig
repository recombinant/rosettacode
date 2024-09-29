// https://rosettacode.org/wiki/L-system
// Translation of FreeBASIC
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

// This is a simple solution suitable for a rule count.

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const rules = [2]Rule{ .{ 'I', "M" }, .{ 'M', "MI" } };
    try showLindenmayer(allocator, "I", &rules, 5);
}

const Rule = struct { u8, []const u8 };

fn showLindenmayer(allocator: mem.Allocator, axiom: []const u8, rules: []const Rule, count: usize) !void {
    var next = std.ArrayList(u8).init(allocator);
    defer next.deinit();

    var s = std.ArrayList(u8).init(allocator);
    defer s.deinit();
    try s.appendSlice(axiom);

    for (0..count + 1) |_| {
        next.clearRetainingCapacity();

        print("{s}\n", .{s.items});

        for (s.items) |c| {
            for (rules) |rule| {
                if (c == rule[0]) {
                    try next.appendSlice(rule[1]); // found
                    break;
                }
            } else try next.append(c); // not found
        }
        s.clearRetainingCapacity();
        try s.appendSlice(next.items);
    }
}
