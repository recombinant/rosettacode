// https://rosettacode.org/wiki/Combinations
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    // ------------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // --------------------------------------------------------------

    const ArrayType = u8;

    const arr: [5]ArrayType = .{ 1, 2, 3, 4, 5 };

    try comb(stdout, ArrayType, arr[0..], 3);

    var it: CombinationIterator(ArrayType, 5, 3) = .init();
    while (it.next()) |combination|
        try stdout.print("{any}\n", .{combination});

    try stdout.flush();
}

fn CombinationIterator(comptime T: type, comptime m: T, comptime n: T) type {
    std.debug.assert(m >= n);
    std.debug.assert(n > 0);

    return struct {
        const Self = @This();

        const limit = std.math.pow(T, 2, m);

        bits: std.StaticBitSet(m),
        count: usize,
        count_ok: bool,

        fn init() Self {
            return .{
                .bits = .initEmpty(),
                .count = 0,
                .count_ok = true,
            };
        }

        fn next(self: *Self) ?[n]T {
            while (self.count < limit) {
                if (self.count_ok and self.bits.count() == n) {
                    var it = self.bits.iterator(.{});
                    var result: [n]T = undefined;
                    var i: usize = 0;
                    while (it.next()) |bit| {
                        result[i] = @intCast(bit);
                        i += 1;
                    }
                    self.count_ok = false;
                    return result;
                }
                self.count += 1;
                self.count_ok = true;

                // iterate to next combination
                // equivalent of bits += 1
                for (0..self.bits.capacity()) |i| {
                    if (self.bits.isSet(i) != true) { // xor
                        self.bits.set(i);
                        break; // no carry
                    } else {
                        self.bits.unset(i);
                    }
                }
            }
            return null;
        }
    };
}

/// Brute force by iterating through all possible combinations of "m"
/// and only selecting those where the count matches "n".
fn comb(w: *std.Io.Writer, comptime T: type, comptime m: []const T, n: u8) !void {
    var bits: std.StaticBitSet(m.len) = .initEmpty();

    // number of possible combinations
    const limit = std.math.pow(T, 2, m.len);

    for (0..limit) |_| {
        if (bits.count() == n) {
            var space: []const u8 = ""; // pretty print
            var it = bits.iterator(.{});
            while (it.next()) |bit| {
                try w.print("{s}{}", .{ space, m[bit] });
                space = " ";
            }
            try w.writeByte('\n');
        }

        // iterate to next combination
        // equivalent of bits += 1
        for (0..bits.capacity()) |i| {
            if (bits.isSet(i) != true) { // xor
                bits.set(i);
                break; // no carry
            } else {
                bits.unset(i);
            }
        }
    }
}
