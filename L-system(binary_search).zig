// https://rosettacode.org/wiki/L-system
// {{works with|Zig|0.15.1}}
// {{trans|FreeBASIC}}

// This solution is overly sophisticated for a solution with only
// two rules - in this case the rules would not need to be sorted
// and a linear search (for loop) could be used to try to find a
// matching symbol.

const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var rules = [_]Rule{ .{ 'I', "M" }, .{ 'M', "MI" } };
    std.mem.sort(Rule, &rules, {}, lessThanRule);

    try showLindenmayer(allocator, "I", rules[0..], 5);
}

const Rule = struct { u8, []const u8 };

fn lessThanRule(_: void, a: Rule, b: Rule) bool {
    return a[0] < b[0];
}

fn orderRule(symbol: u8, rule: Rule) std.math.Order {
    return std.math.order(symbol, rule[0]);
}

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
            if (std.sort.binarySearch(Rule, rules, c, orderRule)) |idx|
                try next.appendSlice(allocator, rules[idx][1]) // found
            else
                try next.append(allocator, c); // not found
        }

        s.clearRetainingCapacity();
        try s.appendSlice(allocator, next.items);
    }
}
