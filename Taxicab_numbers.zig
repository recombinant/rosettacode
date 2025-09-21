// https://rosettacode.org/wiki/Taxicab_numbers
// {{works with|Zig|0.15.1}}
const std = @import("std");

const PQ = std.PriorityDequeue(CubePlus, void, compareCubes);
const CubePlus = struct { u32, u16, u16 };

const magic_number = 1188; // from 2,006th number

fn compareCubes(_: void, a: CubePlus, b: CubePlus) std.math.Order {
    return switch (std.math.order(a[0], b[0])) {
        .eq => std.math.order(a[1], b[1]),
        else => |order| order,
    };
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try main1(stdout);
    try stdout.flush();

    _ = try stdout.splatByte('\n', 2);

    try main2(stdout);
    try stdout.flush();
}

/// Easy to read and maintain but requires intermediate storage
/// for taxicab numbers.
pub fn main1(w: *std.Io.Writer) !void {
    const cubes: [magic_number]u32 = blk: {
        var cubes: [magic_number]u32 = undefined;
        for (&cubes, 1..) |*cube, n|
            cube.* = @intCast(n * n * n);
        break :blk cubes;
    };
    // ------------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    var queue: PQ = .init(allocator, {});
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
    var taxicab_numbers: std.ArrayList(std.ArrayList(CubePlus)) = .empty;
    defer {
        for (taxicab_numbers.items) |*list| list.deinit(allocator);
        taxicab_numbers.deinit(allocator);
    }
    // ------------------------------------- find taxicab numbers
    var previous: CubePlus = .{ 0, 0, 0 };
    var found = false;
    while (queue.removeMinOrNull()) |cube_plus| {
        if (cube_plus[0] == previous[0]) {
            if (!found) {
                try taxicab_numbers.append(allocator, .empty);
                try taxicab_numbers.items[taxicab_numbers.items.len - 1].append(allocator, previous);
            }
            try taxicab_numbers.items[taxicab_numbers.items.len - 1].append(allocator, cube_plus);
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
            try w.print("{d:4}: {d:10} = {d:4}^3 + {d:4}^3", .{ count, list.items[0][0], list.items[0][1], list.items[0][2] });
            for (list.items[1..]) |cube_plus|
                try w.print(" = {d:4}^3 + {d:4}^3", .{ cube_plus[1], cube_plus[2] });
            try w.writeByte('\n');
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
fn main2(w: *std.Io.Writer) !void {
    const cubes: [magic_number]u32 = blk: {
        var cubes: [magic_number]u32 = undefined;
        for (&cubes, 1..) |*cube, n|
            cube.* = @intCast(n * n * n);
        break :blk cubes;
    };
    // ------------------------------------------------ allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    var queue: PQ = .init(allocator, {});
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
                    try w.print("{d:4}: {d:10} = {d:4}^3 + {d:4}^3", .{ count, previous[0], previous[1], previous[2] });
            }
            if (print_flag)
                try w.print(" = {d:4}^3 + {d:4}^3", .{ cube_plus[1], cube_plus[2] });
            found = true;
        } else {
            if (found and print_flag)
                try w.writeByte('\n');
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
