// https://rosettacode.org/wiki/Long_multiplication
// Translation of C
const std = @import("std");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    const result = longmulti("-18446744073709551616", "-18446744073709551616", &buffer);

    const writer = std.io.getStdOut().writer();
    try writer.print("{s}\n", .{result});
}

// Returns a * b.  Caller is responsible for memory.
// output must not be the same as either a or b
fn longmulti(a: []const u8, b: []const u8, output: []u8) []u8 {
    // either is zero, return "0"
    if (std.mem.eql(u8, a, "0") or std.mem.eql(u8, b, "0")) {
        output[0] = '0';
        return output[0..1];
    }

    {
        var i: usize = 0;
        var j: usize = 0;
        var sign = false;

        // see if either a or b is negative */
        if (a[0] == '-') {
            i = 1;
            sign = !sign;
        }
        if (b[0] == '-') {
            j = 1;
            sign = !sign;
        }

        // if yes, prepend minus sign if needed and skip the sign
        if (i != 0 or j != 0) {
            if (sign)
                output[0] = '-';
            const sign_offset = @intFromBool(sign);
            const result = longmulti(a[i..], b[j..], output[sign_offset..]);
            if (std.mem.eql(u8, "0", result)) {
                // if result is "0" return "0" regardless of sign
                output[0] = '0';
                return output[0..1];
            } else {
                // otherwise return possible "-" plus result
                return output[0 .. sign_offset + result.len];
            }
        }
    }
    var output_len = a.len + b.len;
    @memset(output[0..output_len], '0');
    var i = a.len;
    while (i != 0) {
        i -= 1;
        var carry: u8 = 0;
        var k = i + b.len;
        var j = b.len;
        while (j != 0) : (k -= 1) {
            j -= 1;
            const n = ord(a[i]) * ord(b[j]) + ord(output[k]) + carry;
            carry = n / 10;
            output[k] = chr(n % 10);
        }
        output[k] += carry;
    }
    if (output[0] == '0') {
        // Remove leading zero.
        std.mem.copyForwards(u8, output[0 .. output_len - 1], output[1..output_len]);
        output_len -= 1;
    }
    return output[0..output_len];
}

/// Return the ASCII character `ch` as number 0 to 9
/// Panic if `ch` is not an ASCII digit.
fn ord(ch: u8) u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        else => unreachable,
    };
}

/// Return the ASCII digit representing the number, `n`, 0 to 9 incl.
/// Panic if `n` is outside the range 0 to 9 incl.
fn chr(n: u8) u8 {
    return switch (n) {
        0...9 => n + '0',
        else => unreachable,
    };
}

const testing = std.testing;
test "zero" {
    // if either is "0" the result is "0"
    var buffer1: [1]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "0", longmulti("0", "0", &buffer1));
    try std.testing.expectEqualSlices(u8, "0", longmulti("0", "1", &buffer1));
    try std.testing.expectEqualSlices(u8, "0", longmulti("1", "0", &buffer1));
    try std.testing.expectEqualSlices(u8, "0", longmulti("-0", "0", &buffer1));
    try std.testing.expectEqualSlices(u8, "0", longmulti("0", "-0", &buffer1));
    try std.testing.expectEqualSlices(u8, "0", longmulti("0", "-1", &buffer1));
    try std.testing.expectEqualSlices(u8, "0", longmulti("-1", "0", &buffer1));

    // if either is -0 the result is "0"
    var buffer2: [2]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "0", longmulti("-0", "-0", &buffer2));
    try std.testing.expectEqualSlices(u8, "0", longmulti("-0", "1", &buffer2));
    try std.testing.expectEqualSlices(u8, "0", longmulti("-0", "-1", &buffer2));
    try std.testing.expectEqualSlices(u8, "0", longmulti("-1", "-0", &buffer2));
    try std.testing.expectEqualSlices(u8, "0", longmulti("1", "-0", &buffer2));
}

test "one" {
    var buffer1: [2]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "1", longmulti("1", "1", &buffer1));
    try std.testing.expectEqualSlices(u8, "1", longmulti("-1", "-1", &buffer1));

    // allow space for '-' plus two for digits
    var buffer2: [3]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "-1", longmulti("1", "-1", &buffer2));
    try std.testing.expectEqualSlices(u8, "-1", longmulti("-1", "1", &buffer2));
}

test "nine" {
    var buffer1: [2]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "81", longmulti("9", "9", &buffer1));
    try std.testing.expectEqualSlices(u8, "81", longmulti("-9", "-9", &buffer1));

    // allow space for '-' plus two for digits
    var buffer2: [3]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "-81", longmulti("9", "-9", &buffer2));
    try std.testing.expectEqualSlices(u8, "-81", longmulti("-9", "9", &buffer2));
}

test "ten" {
    var buffer1: [3]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "10", longmulti("10", "1", &buffer1));
    try std.testing.expectEqualSlices(u8, "10", longmulti("1", "10", &buffer1));
    try std.testing.expectEqualSlices(u8, "10", longmulti("-10", "-1", &buffer1));
    try std.testing.expectEqualSlices(u8, "10", longmulti("-1", "-10", &buffer1));

    // allow space for '-' plus three for digits
    var buffer2: [4]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "-10", longmulti("-10", "1", &buffer2));
    try std.testing.expectEqualSlices(u8, "-10", longmulti("-1", "10", &buffer2));
    try std.testing.expectEqualSlices(u8, "-10", longmulti("10", "-1", &buffer2));
    try std.testing.expectEqualSlices(u8, "-10", longmulti("1", "-10", &buffer2));
}

test "ninety-seven" {
    var buffer1: [4]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "9409", longmulti("97", "97", &buffer1));
    try std.testing.expectEqualSlices(u8, "9409", longmulti("-97", "-97", &buffer1));

    // allow space for '-' plus four for digits
    var buffer2: [5]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "-9409", longmulti("97", "-97", &buffer2));
    try std.testing.expectEqualSlices(u8, "-9409", longmulti("-97", "97", &buffer2));
}
