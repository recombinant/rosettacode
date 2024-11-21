// https://rosettacode.org/wiki/Taxicab_numbers
const std = @import("std");
const print = std.debug.print;

const magic_number = 1188; // from 2,006th number

const PQ = std.PriorityDequeue(CubePlus, void, compareCubes);
const CubePlus = struct { u32, u16, u16 };

fn compareCubes(_: void, a: CubePlus, b: CubePlus) std.math.Order {
    return switch (std.math.order(a[0], b[0])) {
        .eq => std.math.order(a[1], b[1]),
        else => |order| order,
    };
}

pub fn main() !void {
    try main1();

    print("\n\n", .{});

    try main2();
}

/// Easier to read and maintain but requires intermediate storage
/// for taxicab numbers.
pub fn main1() !void {
    const cubes: [magic_number]u32 = blk: {
        var cubes: [magic_number]u32 = undefined;
        for (&cubes, 1..) |*cube, n|
            cube.* = @intCast(n * n * n);
        break :blk cubes;
    };
    // ------------------------------------------------ allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    var queue = PQ.init(allocator, {});
    defer queue.deinit();
    const capacity = magic_number * magic_number / 2 + magic_number / 2 + 1;
    try queue.ensureTotalCapacity(capacity);

    outer: for (cubes, 1..) |a, i|
        for (cubes, 1..) |b, j| {
            if (b > a)
                continue :outer;
            try queue.add(CubePlus{ a + b, @truncate(j), @truncate(i) });
        };
    // Verify adequate capacity
    std.debug.assert(capacity >= queue.count());
    // ------------------------------ storage for taxicab numbers
    var taxicab_numbers = std.ArrayList(std.ArrayList(CubePlus)).init(allocator);
    defer {
        for (taxicab_numbers.items) |list| list.deinit();
        taxicab_numbers.deinit();
    }
    // ------------------------------------- find taxicab numbers
    var previous: CubePlus = .{ 0, 0, 0 };
    var found = false;
    while (queue.removeMinOrNull()) |cube_plus| {
        if (cube_plus[0] == previous[0]) {
            if (!found) {
                try taxicab_numbers.append(std.ArrayList(CubePlus).init(allocator));
                try taxicab_numbers.items[taxicab_numbers.items.len - 1].append(previous);
            }
            try taxicab_numbers.items[taxicab_numbers.items.len - 1].append(cube_plus);
            found = true;
        } else {
            found = false;
        }
        previous = cube_plus;
    }
    // ------------------------------------ print taxicab numbers
    var print_flag = true;
    for (taxicab_numbers.items, 1..) |list, count| {
        if (print_flag) {
            print("{d:4}: {d:10} = {d:4}^3 + {d:4}^3", .{ count, list.items[0][0], list.items[0][1], list.items[0][2] });
            for (list.items[1..]) |cube_plus|
                print(" = {d:4}^3 + {d:4}^3", .{ cube_plus[1], cube_plus[2] });
            print("\n", .{});
        }
        if (count == 25)
            print_flag = false
        else if (count == 1999)
            print_flag = true
        else if (count == 2006)
            break;
    }
}

/// More difficult to read and maintain but requires less storage
/// than the above solution.
fn main2() !void {
    const cubes: [magic_number]u32 = blk: {
        var cubes: [magic_number]u32 = undefined;
        for (&cubes, 1..) |*cube, n|
            cube.* = @intCast(n * n * n);
        break :blk cubes;
    };
    // ------------------------------------------------ allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    var queue = PQ.init(allocator, {});
    defer queue.deinit();
    const capacity = magic_number * magic_number / 2 + magic_number / 2 + 1;
    try queue.ensureTotalCapacity(capacity);

    outer: for (cubes, 1..) |a, i|
        for (cubes, 1..) |b, j| {
            if (b > a)
                continue :outer;
            try queue.add(CubePlus{ a + b, @truncate(j), @truncate(i) });
        };
    // Verify adequate capacity
    std.debug.assert(capacity >= queue.count());
    // ------------------------------ storage for taxicab numbers
    var print_flag = true;
    var count: usize = 0;
    var previous: CubePlus = .{ 0, 0, 0 };
    var found = false;
    while (queue.removeMinOrNull()) |cube_plus| {
        if (cube_plus[0] == previous[0]) {
            if (!found) {
                count += 1;
                if (print_flag)
                    print("{d:4}: {d:10} = {d:4}^3 + {d:4}^3", .{ count, previous[0], previous[1], previous[2] });
            }
            if (print_flag)
                print(" = {d:4}^3 + {d:4}^3", .{ cube_plus[1], cube_plus[2] });
            found = true;
        } else {
            if (found and print_flag)
                print("\n", .{});
            found = false;
        }
        previous = cube_plus;
        if (count == 25)
            print_flag = false
        else if (count == 1999)
            print_flag = true
        else if (count == 2006)
            break;
    }
}
