// https://rosettacode.org/wiki/Zebra_puzzle
// Translated from Go
// This Zig version assumes Ascii text to reduce code clutter.
const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const enums = std.enums;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    // Using an arena means that free() is optional and possibly meaningless.
    // arena.deinit() cleans up all allocations.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    //
    const n, const solution = try simpleBruteForce(allocator);
    print("{} solution found\n\n", .{n});

    for (solution.houses) |h|
        if (h.a == .zebra)
            print("The {} owns the {}\n\n", .{ h.n, h.a });

    print("{}\n", .{solution});
}

/// Simple brute force solution
fn simpleBruteForce(allocator: mem.Allocator) !struct { usize, HouseSet } {
    var array = std.ArrayList(House).init(allocator);
    defer array.deinit();

    for (enums.values(Nationality)) |n|
        for (enums.values(Colour)) |c|
            for (enums.values(Animal)) |a|
                for (enums.values(Drink)) |d|
                    for (enums.values(Smoke)) |s| {
                        const h = House{
                            .n = n,
                            .c = c,
                            .a = a,
                            .d = d,
                            .s = s,
                        };
                        if (!h.isValid())
                            continue;
                        try array.append(h);
                    };

    const v = array.items;
    const n = v.len;
    print("Generated {} valid houses\n", .{n});

    var combos: usize = 0;
    var first: usize = undefined;
    var valid_count: usize = 0;
    var valid_set: ?HouseSet = null;

    for (0..n) |a| { // first house
        if (v[a].n != .Norwegian) // Condition 10:
            continue;

        for (0..n) |b| { // second house
            if (b == a)
                continue;

            if (v[b].anyDups(.{v[a]}))
                continue;

            for (0..n) |c| { // third house
                if (c == b or c == a)
                    continue;

                if (v[c].d != .milk) // Condition 9:
                    continue;

                if (v[c].anyDups(.{ &v[b], &v[a] }))
                    continue;

                for (0..n) |d| { // fourth house
                    if (d == c or d == b or d == a)
                        continue;

                    if (v[d].anyDups(.{ &v[c], &v[b], &v[a] }))
                        continue;

                    for (0..n) |e| { // fifth and final house
                        if (e == d or e == c or e == b or e == a)
                            continue;

                        if (v[e].anyDups(.{ &v[d], &v[c], &v[b], &v[a] }))
                            continue;

                        combos += 1;
                        const set = HouseSet.init(.{ &v[a], &v[b], &v[c], &v[d], &v[e] });
                        if (set.isValid()) {
                            assert(valid_set == null); // oops, expected only one solution
                            valid_count += 1;
                            if (valid_count == 1)
                                first = combos;
                            valid_set = set;
                        }
                    }
                }
            }
        }
    }
    assert(valid_set != null);
    print("Tested {} different combinations of valid houses before finding solution\n", .{first});
    print("Tested {} different combinations of valid houses in total\n", .{combos});
    return .{ valid_count, valid_set.? };
}

fn dist(a: usize, b: usize) usize {
    return if (a > b) a - b else b - a;
}

// Define some types

const HouseSet = struct {
    houses: [5]House,

    fn init(houses: [5]*const House) HouseSet {
        var result = HouseSet{ .houses = undefined };

        for (&result.houses, houses) |*dest, source|
            dest.* = source.*;

        return result;
    }

    pub fn format(self: HouseSet, comptime _: []const u8, _: fmt.FormatOptions, writer: anytype) !void {
        for (self.houses, 1..) |h, i|
            try writer.print("{} {}\n", .{ i, h });
    }

    fn isValid(self: *const HouseSet) bool {
        var ni: [5]usize = undefined; // Nationality
        var ci: [5]usize = undefined; // Colour
        var ai: [5]usize = undefined; // Animal
        var di: [5]usize = undefined; // Drink
        var si: [5]usize = undefined; // Smoke
        for (self.houses, 0..) |h, i| {
            ni[@intFromEnum(h.n)] = i;
            ci[@intFromEnum(h.c)] = i;
            ai[@intFromEnum(h.a)] = i;
            di[@intFromEnum(h.d)] = i;
            si[@intFromEnum(h.s)] = i;
        }
        // Condition 5:
        if (ci[@intFromEnum(Colour.green)] + 1 != ci[@intFromEnum(Colour.white)])
            return false;

        // Condition 11:
        if (dist(ai[@intFromEnum(Animal.cats)], si[@intFromEnum(Smoke.Blend)]) != 1)
            return false;

        // Condition 12:
        if (dist(ai[@intFromEnum(Animal.horse)], si[@intFromEnum(Smoke.Dunhill)]) != 1)
            return false;

        // Condition 15:
        if (dist(ni[@intFromEnum(Nationality.Norwegian)], ci[@intFromEnum(Colour.blue)]) != 1)
            return false;

        // Condition 16:
        if (dist(di[@intFromEnum(Drink.water)], si[@intFromEnum(Smoke.Blend)]) != 1)
            return false;

        // Condition 9: (already tested elsewhere)
        if (self.houses[2].d != .milk)
            return false;

        // Condition 10: (already tested elsewhere)
        if (self.houses[0].n != .Norwegian)
            return false;

        return true;
    }
};

const House = struct {
    n: Nationality,
    c: Colour,
    a: Animal,
    d: Drink,
    s: Smoke,

    pub fn format(self: *const House, comptime _: []const u8, _: fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{s:<9}  {s:<6}  {s:<5}  {s:<6}  {}", .{ self.n, self.c, self.a, self.d, self.s });
    }

    fn isValid(self: *const House) bool {
        // Condition 2:
        if (self.n == .English and self.c != .red or self.n != .English and self.c == .red)
            return false;

        // Condition 3:
        if (self.n == .Swede and self.a != .dog or self.n != .Swede and self.a == .dog)
            return false;

        // Condition 4:
        if (self.n == .Dane and self.d != .tea or self.n != .Dane and self.d == .tea)
            return false;

        // Condition 6:
        if (self.c == .green and self.d != .coffee or self.c != .green and self.d == .coffee)
            return false;

        // Condition 7:
        if (self.a == .birds and self.s != .@"Pall Mall" or self.a != .birds and self.s == .@"Pall Mall")
            return false;

        // Condition 8:
        if (self.c == .yellow and self.s != .Dunhill or self.c != .yellow and self.s == .Dunhill)
            return false;

        // Condition 11:
        if (self.a == .cats and self.s == .Blend)
            return false;

        // Condition 12:
        if (self.a == .horse and self.s == .Dunhill)
            return false;

        // Condition 13:
        if (self.d == .beer and self.s != .@"Blue Master" or self.d != .beer and self.s == .@"Blue Master")
            return false;

        // Condition 14:
        if (self.n == .German and self.s != .Prince or self.n != .German and self.s == .Prince)
            return false;

        // Condition 15:
        if (self.n == .Norwegian and self.c == .blue)
            return false;

        // Condition 16:
        if (self.d == .water and self.s == .Blend)
            return false;

        return true;
    }

    /// anyDups returns true if house `self` has any duplicate attributes with any of the other specified houses
    fn anyDups(self: *const House, others: anytype) bool {
        const ArgsType = @TypeOf(others);
        const args_type_info = @typeInfo(ArgsType);
        if (args_type_info != .@"struct")
            @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));

        inline for (others) |other|
            if (self.n == other.n or self.c == other.c or self.a == other.a or self.d == other.d or self.s == other.s)
                return true;

        return false;
    }
};

// Define the possible values

const Nationality = enum {
    English,
    Swede,
    Dane,
    Norwegian,
    German,

    pub fn format(self: Nationality, comptime fmt_: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        if (fmt_.len != 0 and fmt_[0] != 's' or fmt_.len > 1)
            @compileError("invalid format string '" ++ fmt_ ++ "' for type '" ++ @typeName(@TypeOf(self)) ++ "'");

        try formatTagName(@tagName(self), options, writer);
    }
};
const Colour = enum {
    red,
    green,
    white,
    yellow,
    blue,

    pub fn format(self: @This(), comptime fmt_: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        if (fmt_.len != 0 and fmt_[0] != 's' or fmt_.len > 1)
            @compileError("invalid format string '" ++ fmt_ ++ "' for type '" ++ @typeName(@TypeOf(self)) ++ "'");

        try formatTagName(@tagName(self), options, writer);
    }
};
const Animal = enum {
    dog,
    birds,
    cats,
    horse,
    zebra,

    pub fn format(self: @This(), comptime fmt_: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        if (fmt_.len != 0 and fmt_[0] != 's' or fmt_.len > 1)
            @compileError("invalid format string '" ++ fmt_ ++ "' for type '" ++ @typeName(@TypeOf(self)) ++ "'");

        try formatTagName(@tagName(self), options, writer);
    }
};
const Drink = enum {
    tea,
    coffee,
    milk,
    beer,
    water,

    pub fn format(self: @This(), comptime fmt_: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        if (fmt_.len != 0 and fmt_[0] != 's' or fmt_.len > 1)
            @compileError("invalid format string '" ++ fmt_ ++ "' for type '" ++ @typeName(@TypeOf(self)) ++ "'");

        try formatTagName(@tagName(self), options, writer);
    }
};
const Smoke = enum {
    @"Pall Mall",
    Dunhill,
    Blend,
    @"Blue Master",
    Prince,

    pub fn format(self: @This(), comptime fmt_: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        if (fmt_.len != 0 and fmt_[0] != 's' or fmt_.len > 1)
            @compileError("invalid format string '" ++ fmt_ ++ "' for type '" ++ @typeName(@TypeOf(self)) ++ "'");

        try formatTagName(@tagName(self), options, writer);
    }
};

/// Write enum tag name to writer.
fn formatTagName(value: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
    if (options.width) |min_width| {
        const padding = if (value.len < min_width) min_width - value.len else 0;
        switch (options.alignment) {
            .left => {
                try writer.writeAll(value);
                try writer.writeByteNTimes(' ', padding);
            },
            .center => {
                const left_padding = padding / 2;
                const right_padding = (padding + 1) / 2;
                try writer.writeByteNTimes(' ', left_padding);
                try writer.writeAll(value);
                try writer.writeByteNTimes(' ', right_padding);
            },
            .right => {
                try writer.writeByteNTimes(' ', padding);
                try writer.writeAll(value);
            },
        }
    } else {
        try writer.writeAll(value);
    }
}
