// https://rosettacode.org/wiki/Intersecting_number_wheels
// This is a simple solution without tagged unions, allocators or hashmaps.
// It written purely to solve the rosettacode tasks. No error checking.
const std = @import("std");

const print = std.debug.print;

const Wheel = struct {
    name: u8,
    values: []const u8,
    next_index: usize = 0,

    fn init(name: u8, values: []const u8) Wheel {
        return Wheel{ .name = name, .values = values };
    }

    /// Next value.
    fn next(self: *Wheel) u8 {
        const result = self.values[self.next_index];
        self.next_index = (self.next_index + 1) % self.values.len;
        return result;
    }
};

pub fn main() void {
    var wheel1 = [_]Wheel{
        Wheel.init('A', &[_]u8{ 1, 2, 3 }),
    };
    var wheel2 = [_]Wheel{
        Wheel.init('A', &[_]u8{ 1, 'B', 2 }),
        Wheel.init('B', &[_]u8{ 3, 4 }),
    };
    var wheel3 = [_]Wheel{
        Wheel.init('A', &[_]u8{ 1, 'D', 'D' }),
        Wheel.init('D', &[_]u8{ 6, 7, 8 }),
    };
    var wheel4 = [_]Wheel{
        Wheel.init('A', &[_]u8{ 1, 'B', 'C' }),
        Wheel.init('B', &[_]u8{ 3, 4 }),
        Wheel.init('C', &[_]u8{ 5, 'B' }),
    };

    var wheel_groups = [_][]Wheel{
        &wheel1,
        &wheel2,
        &wheel3,
        &wheel4,
    };

    for (&wheel_groups) |wheel_group| {
        printWheelGroup(wheel_group);
        generate(wheel_group, 'A', 20);
        print("...\n\n", .{});
    }
}

/// Recursive.
fn generate(wheel_group: []Wheel, start_name: u8, max_count: usize) void {
    var count: usize = 0;
    var w = findWheel(wheel_group, start_name);
    while (true) {
        const value = w.next(); // next value
        switch (value) {
            0...9 => print("{d} ", .{value}),
            'A'...'Z' => generate(wheel_group, value, 1),
            else => unreachable,
        }
        count += 1;
        if (count == max_count)
            return;
    }
}

fn printWheelGroup(wheel_group: []const Wheel) void {
    print("Intersecting Number Wheel group:\n", .{});
    for (wheel_group) |wheel| {
        print("  {c}: [", .{wheel.name});
        for (wheel.values, 0..) |value, i| {
            if (i != 0) print(" ", .{});
            switch (value) {
                0...9 => print("{d}", .{value}),
                'A'...'Z' => print("{c}", .{value}),
                else => unreachable,
            }
        }
        print("]\n", .{});
    }
    print("  Generates:\n    ", .{});
}

/// Linear search. Assume a wheel will be found.
fn findWheel(wheel_group: []Wheel, name: u8) *Wheel {
    for (wheel_group) |*wheel|
        if (wheel.name == name)
            return wheel;
    unreachable;
}
