// https://rosettacode.org/wiki/De_Bruijn_sequences
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var de_bruijn_list: std.ArrayList(u8) = .empty;
    defer de_bruijn_list.deinit(allocator);

    for (0..100) |n| {
        var buffer_a: [2]u8 = undefined;
        const a = try std.fmt.bufPrint(&buffer_a, "{d:02}", .{n});
        const a1 = a[0];
        const a2 = a[1];
        if (a2 >= a1) {
            if (a1 == a2)
                try de_bruijn_list.append(allocator, a1)
            else
                try de_bruijn_list.appendSlice(allocator, a);
            var m = n + 1;
            while (m <= 99) : (m += 1) {
                var buffer_m: [2]u8 = undefined;
                const ms = try std.fmt.bufPrint(&buffer_m, "{d:02}", .{m});

                if (ms[1] > a1) {
                    try de_bruijn_list.appendSlice(allocator, a);
                    try de_bruijn_list.appendSlice(allocator, ms);
                }
            }
        }
    }
    try de_bruijn_list.appendSlice(allocator, de_bruijn_list.items[0..3]);
    var de_bruijn = try de_bruijn_list.toOwnedSlice(allocator);
    defer allocator.free(de_bruijn);

    print("de Bruijn sequence length: {}\n\n", .{de_bruijn.len});
    print("First 130 characters:\n{s}\n\n", .{de_bruijn[0..130]});
    print("Last 130 characters:\n{s}\n\n", .{de_bruijn[de_bruijn.len - 130 .. de_bruijn.len]});

    const result1 = try check(allocator, de_bruijn);
    print("Missing 4 digit PINs in this sequence:{s}", .{result1});

    std.mem.reverse(u8, de_bruijn);
    const result2 = try check(allocator, de_bruijn);
    print("Missing 4 digit PINs in the reversed sequence:{s}", .{result2});
    std.mem.reverse(u8, de_bruijn);

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
fn check(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    var found: [10_000]u16 = undefined;
    @memset(&found, 0);

    next_pin: for (0..text.len - 3) |i| {
        const s = text[i .. i + 4];
        const k = std.fmt.parseInt(usize, s, 10) catch |err| {
            switch (err) {
                std.fmt.ParseIntError.InvalidCharacter => continue :next_pin,
                std.fmt.ParseIntError.Overflow => return err,
            }
        };
        found[k] += 1;
    }

    var errors: std.ArrayList([]u8) = .empty;
    defer {
        for (errors.items) |line| allocator.free(line);
        errors.deinit(allocator);
    }
    for (found, 0..) |k, i| {
        if (k != 1) {
            var a: std.Io.Writer.Allocating = .init(allocator);
            try a.writer.print("  Pin number {d:04} ", .{i});
            if (k == 0)
                try a.writer.print("missing", .{})
            else
                try a.writer.print("occurs {} times", .{k});
            try errors.append(allocator, try a.toOwnedSlice());
        }
    }
    if (errors.items.len == 0)
        return try allocator.dupe(u8, " no errors found\n")
    else {
        var a: std.Io.Writer.Allocating = .init(allocator);
        const plural: []const u8 = if (errors.items.len == 1) "" else "s";
        const error_string = try std.mem.join(allocator, "\n", errors.items);
        try a.writer.print("\n {} error{s} found:\n{s}\n", .{ errors.items.len, plural, error_string });
        allocator.free(error_string);
        return a.toOwnedSlice();
    }
}
