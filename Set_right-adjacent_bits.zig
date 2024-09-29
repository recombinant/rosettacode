// https://rosettacode.org/wiki/Set_right-adjacent_bits
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    // ------------------------------------------ allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ----------------------------------------------------
    const b: []const u8 = "010000000000100000000010000000010000000100000010000010000100010010";
    const sample_data = [_]struct { bits: []const u8, n: u4 }{
        .{ .bits = "1000", .n = 2 }, .{ .bits = "0100", .n = 2 },
        .{ .bits = "0010", .n = 2 }, .{ .bits = "0000", .n = 2 },
        .{ .bits = b, .n = 0 },      .{ .bits = b, .n = 1 },
        .{ .bits = b, .n = 2 },      .{ .bits = b, .n = 3 },
    };
    for (sample_data) |s| {
        const result = try setRightBits(allocator, s.bits, s.n);
        defer allocator.free(result);
        try stdout.print("n = {}; Width e = {}\n\n", .{ s.n, s.bits.len });
        try stdout.print("     Input b: {s}\n", .{s.bits});
        try stdout.print("     Result:  {s}\n\n", .{result});
    }
}

fn setRightBits(allocator: mem.Allocator, bits: []const u8, n: u4) ![]const u8 {
    const result = try allocator.dupe(u8, bits);
    var remaining: usize = 0;
    for (result) |*bit| {
        if (bit.* == '1') {
            remaining = n;
        } else if (remaining != 0) {
            remaining -= 1;
            bit.* = '1';
        }
    }
    return result;
}

const testing = std.testing;

test "set right bits" {
    const b = "010000000000100000000010000000010000000100000010000010000100010010";
    //
    const b0 = "010000000000100000000010000000010000000100000010000010000100010010";
    const b1 = "011000000000110000000011000000011000000110000011000011000110011011";
    const b2 = "011100000000111000000011100000011100000111000011100011100111011111";
    const b3 = "011110000000111100000011110000011110000111100011110011110111111111";

    const test_data = [_]struct {
        n: u4,
        width: usize,
        bits: []const u8,
        expected: []const u8,
    }{
        .{ .n = 2, .width = 4, .bits = "1000", .expected = "1110" },
        .{ .n = 2, .width = 4, .bits = "0100", .expected = "0111" },
        .{ .n = 2, .width = 4, .bits = "0010", .expected = "0011" },
        .{ .n = 2, .width = 4, .bits = "0000", .expected = "0000" },
        .{ .n = 0, .width = 66, .bits = b, .expected = b0 },
        .{ .n = 1, .width = 66, .bits = b, .expected = b1 },
        .{ .n = 2, .width = 66, .bits = b, .expected = b2 },
        .{ .n = 3, .width = 66, .bits = b, .expected = b3 },
    };
    for (test_data) |s| {
        const result = try setRightBits(testing.allocator, s.bits, s.n);
        defer testing.allocator.free(result);
        // check the width is consistent
        try testing.expectEqual(s.width, s.bits.len);
        try testing.expectEqual(s.width, s.expected.len);
        try testing.expectEqual(s.width, result.len);
        // check the result has the expected bit twiddling
        try testing.expect(mem.eql(u8, s.expected, result));
    }
}
