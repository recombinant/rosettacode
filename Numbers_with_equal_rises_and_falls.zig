// https://rosettacode.org/wiki/Numbers_with_equal_rises_and_falls
// Translated from C
// https://oeis.org/A296712
// Pipe through fmt for columnar output.

const std = @import("std");

/// Check whether a number has an equal amount of rises and falls
fn riseEqFall(arg_num: u64) bool {
    var digit1 = arg_num % 10; // rightmost digit (one's)
    var num = arg_num / 10;
    var height: i32 = 0;
    while (num != 0) : (num /= 10) {
        const digit2 = num % 10; // ten's
        height += @intFromBool(digit2 > digit1);
        height -= @intFromBool(digit2 < digit1);
        digit1 = digit2;
    }
    return height == 0;
}

/// Get the next member of the sequence, in order, starting at 1
const RiseAndFall = struct {
    last_number: u64 = 0,

    fn nextNum(self: *RiseAndFall) u64 {
        self.last_number += 1;
        while (!riseEqFall(self.last_number)) : (self.last_number += 1) {}
        return self.last_number;
    }
};

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    {
        // Generate first 200 numbers
        var rf: RiseAndFall = .{};
        for (0..200) |_|
            try stdout.print("{d} ", .{rf.nextNum()});
    }
    {
        // Generate 10,000,000th number
        var rf: RiseAndFall = .{};
        for (0..10_000_000) |_| _ = rf.nextNum();

        try stdout.writeAll("\n\nThe 10,000,000th number is: ");
        try stdout.print("{d}\n", .{rf.last_number});
    }

    try bw.flush();
}

const testing = std.testing;

test "rise and fall" {
    try testing.expect(!riseEqFall(726_169));
    try testing.expect(riseEqFall(83_548));
}
