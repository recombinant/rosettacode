// https://rosettacode.org/wiki/Verhoeff_algorithm
// Translation of Wren
const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    // allocator ------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // buffer stdout --------------------------------------
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // dynamic string for digits --------------------------
    var digits = std.ArrayList(u8).init(allocator);
    defer digits.deinit();

    // data for task --------------------------------------
    const ss: []const []const u8 = &.{ "236", "12345", "123456789012" };
    const vs = [_]bool{ true, true, false };

    // perform task ---------------------------------------
    for (ss, vs) |s, verbose| {
        digits.clearRetainingCapacity();
        try digits.appendSlice(s);

        const c: u8 = try verhoeff(&digits, false, verbose, stdout);
        try stdout.print("\nThe check digit for '{s}' is '{d}'.\n\n", .{ s, c });

        for ([2]u8{ c + '0', '9' }) |ch| {
            digits.shrinkRetainingCapacity(s.len); // keep s in buffer
            try digits.append(@truncate(ch));

            const v = try verhoeff(&digits, true, verbose, stdout);
            try stdout.print("\nThe validation for '{s}' is {s}.\n\n", .{ digits.items, if (v != 0) "correct" else "incorrect" });
        }
    }

    // flush buffered stdout ------------------------------
    try bw.flush();
}

fn verhoeff(digits: *std.ArrayList(u8), validate: bool, verbose: bool, writer: anytype) !u8 {
    if (verbose) {
        const what: []const u8 = if (validate) "Validation" else "Check digit";
        try writer.print("{s} calculations for '{s}':\n\n", .{ what, digits.items });
        try writer.writeAll(" i  nᵢ  p[i,nᵢ]  c\n");
        try writer.writeAll("------------------\n");
    }
    if (!validate) try digits.append('0');
    const len = digits.items.len;
    var c: u8 = 0;
    var i = len;
    while (i > 0) {
        i -= 1;
        const ni: u8 = digits.items[i] - '0';
        assert(ni >= 0 and ni < 10);
        const pi: u8 = p[(len - i - 1) % 8][ni];
        c = d[c][pi];
        if (verbose)
            try writer.print("{d:2}  {d}      {d}     {d}\n", .{ len - i - 1, ni, pi, c });
    }
    if (verbose and !validate)
        try writer.print("\ninv[{d}] = {d}\n", .{ c, inv[c] });

    return if (validate) if (c == 0) 1 else 0 else inv[c];
}

// Multiplication table
const d: [10][10]u8 = [10][10]u8{
    [10]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    [10]u8{ 1, 2, 3, 4, 0, 6, 7, 8, 9, 5 },
    [10]u8{ 2, 3, 4, 0, 1, 7, 8, 9, 5, 6 },
    [10]u8{ 3, 4, 0, 1, 2, 8, 9, 5, 6, 7 },
    [10]u8{ 4, 0, 1, 2, 3, 9, 5, 6, 7, 8 },
    [10]u8{ 5, 9, 8, 7, 6, 0, 4, 3, 2, 1 },
    [10]u8{ 6, 5, 9, 8, 7, 1, 0, 4, 3, 2 },
    [10]u8{ 7, 6, 5, 9, 8, 2, 1, 0, 4, 3 },
    [10]u8{ 8, 7, 6, 5, 9, 3, 2, 1, 0, 4 },
    [10]u8{ 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 },
};

const inv: [10]u8 = [10]u8{ 0, 4, 3, 2, 1, 5, 6, 7, 8, 9 };

// Permutation table
const p: [8][10]u8 = [8][10]u8{
    [10]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    [10]u8{ 1, 5, 7, 6, 2, 8, 3, 0, 9, 4 },
    [10]u8{ 5, 8, 0, 3, 7, 9, 6, 1, 4, 2 },
    [10]u8{ 8, 9, 1, 6, 0, 4, 3, 5, 2, 7 },
    [10]u8{ 9, 4, 5, 3, 1, 2, 6, 8, 7, 0 },
    [10]u8{ 4, 2, 8, 6, 5, 7, 3, 9, 0, 1 },
    [10]u8{ 2, 7, 9, 3, 8, 0, 6, 4, 1, 5 },
    [10]u8{ 7, 0, 4, 6, 9, 1, 3, 2, 5, 8 },
};
