// https://rosettacode.org/wiki/De_Bruijn_sequences
// Translation of Wren
const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var de_bruijn_list = std.ArrayList(u8).init(allocator);
    defer de_bruijn_list.deinit();

    for (0..100) |n| {
        var buffer_a: [2]u8 = undefined;
        const a = try std.fmt.bufPrint(&buffer_a, "{d:02}", .{n});
        const a1 = a[0];
        const a2 = a[1];
        if (a2 >= a1) {
            if (a1 == a2)
                try de_bruijn_list.append(a1)
            else
                try de_bruijn_list.appendSlice(a);
            var m = n + 1;
            while (m <= 99) : (m += 1) {
                var buffer_m: [2]u8 = undefined;
                const ms = try std.fmt.bufPrint(&buffer_m, "{d:02}", .{m});

                if (ms[1] > a1) {
                    try de_bruijn_list.appendSlice(a);
                    try de_bruijn_list.appendSlice(ms);
                }
            }
        }
    }
    try de_bruijn_list.appendSlice(de_bruijn_list.items[0..3]);
    var de_bruijn = try de_bruijn_list.toOwnedSlice();
    defer allocator.free(de_bruijn);

    print("de Bruijn sequence length: {}\n\n", .{de_bruijn.len});
    print("First 130 characters:\n{s}\n\n", .{de_bruijn[0..130]});
    print("Last 130 characters:\n{s}\n\n", .{de_bruijn[de_bruijn.len - 130 .. de_bruijn.len]});

    const result1 = try check(allocator, de_bruijn);
    print("Missing 4 digit PINs in this sequence:{s}", .{result1});

    mem.reverse(u8, de_bruijn);
    const result2 = try check(allocator, de_bruijn);
    print("Missing 4 digit PINs in the reversed sequence:{s}", .{result2});
    mem.reverse(u8, de_bruijn);

    print("\n4,444th digit in the sequence: '{c}' (setting it to '.')\n", .{de_bruijn[4443]});
    de_bruijn[4443] = '.';
    print("Re-running checks:", .{});
    const result3 = try check(allocator, de_bruijn);
    print("{s}", .{result3});

    allocator.free(result3);
    allocator.free(result2);
    allocator.free(result1);
}

/// Caller owns returned slice.
fn check(allocator: mem.Allocator, text: []const u8) ![]const u8 {
    var found: [10_000]u16 = undefined;
    @memset(&found, 0);

    next_pin: for (0..text.len - 3) |i| {
        const s = text[i .. i + 4];
        const k = fmt.parseInt(usize, s, 10) catch |err| {
            switch (err) {
                fmt.ParseIntError.InvalidCharacter => continue :next_pin,
                fmt.ParseIntError.Overflow => return err,
            }
        };
        found[k] += 1;
    }

    var errors = std.ArrayList([]u8).init(allocator);
    defer {
        for (errors.items) |line| allocator.free(line);
        errors.deinit();
    }
    for (found, 0..) |k, i| {
        if (k != 1) {
            var buffer = std.ArrayList(u8).init(allocator);
            const writer = buffer.writer();
            try writer.print("  Pin number {d:04} ", .{i});
            if (k == 0)
                try writer.print("missing", .{})
            else
                try writer.print("occurs {} times", .{k});
            try errors.append(try buffer.toOwnedSlice());
        }
    }
    if (errors.items.len == 0)
        return try allocator.dupe(u8, " no errors found\n")
    else {
        var buffer = std.ArrayList(u8).init(allocator);
        const writer = buffer.writer();
        const plural: []const u8 = if (errors.items.len == 1) "" else "s";
        const error_string = try mem.join(allocator, "\n", errors.items);
        try writer.print("\n {} error{s} found:\n{s}\n", .{ errors.items.len, plural, error_string });
        allocator.free(error_string);
        return buffer.toOwnedSlice();
    }
}
