// https://rosettacode.org/wiki/L-system
// Translation of FreeBASIC

// This solution is overly sophisticated for a solution with only
// two rules - in this case the rules would not need to be sorted
// and a linear search (for loop) could be used to try to find a
// matching symbol.

const std = @import("std");
const math = std.math;
const mem = std.mem;
const sort = std.sort;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var rules = [_]Rule{ .{ 'I', "M" }, .{ 'M', "MI" } };
    mem.sort(Rule, &rules, {}, lessThanRule);

    try showLindenmayer(allocator, "I", rules[0..], 5);
}

const Rule = struct { u8, []const u8 };

fn lessThanRule(_: void, a: Rule, b: Rule) bool {
    return a[0] < b[0];
}

fn orderRule(symbol: u8, rule: Rule) math.Order {
    return math.order(symbol, rule[0]);
}

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
            if (sort.binarySearch(Rule, rules, c, orderRule)) |idx|
                try next.appendSlice(rules[idx][1]) // found
            else
                try next.append(c); // not found
        }

        s.clearRetainingCapacity();
        try s.appendSlice(next.items);
    }
}
