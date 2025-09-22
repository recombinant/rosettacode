// https://rosettacode.org/wiki/Own_digits_power_sum
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

const MAX_BASE = 10;

pub fn main() !void {
    var t0 = try std.time.Timer.start();

    var pd = PowerDgt.init();
    pd.nextDigit(0, 0);

    const numbers = pd.getNumbers();

    const t1 = t0.read();

    std.debug.print("Own digits power sums for N = 3 to 9 inclusive:\n", .{});
    for (numbers) |n|
        std.debug.print("{}\n", .{n});

    std.log.info("processed in {D}", .{t1});
}

const SumType = u32;

const PowerDgt = struct {
    used_digits: [MAX_BASE]u4 = undefined,
    power_dgt: [MAX_BASE][MAX_BASE]SumType,
    numbers: [60]SumType = undefined,
    n_count: usize,

    fn init() PowerDgt {
        var pd = PowerDgt{
            .power_dgt = undefined,
            .n_count = 0,
        };
        pd.power_dgt[0][0] = 0;
        for (1..MAX_BASE) |i| pd.power_dgt[0][i] = 1;
        for (1..MAX_BASE) |j|
            for (0..MAX_BASE) |i| {
                pd.power_dgt[j][i] = pd.power_dgt[j - 1][i] * @as(SumType, @truncate(i));
            };
        return pd;
    }
    fn getNumbers(self: *PowerDgt) []const SumType {
        var slice = self.numbers[0..self.n_count];

        std.mem.sort(SumType, slice, {}, std.sort.asc(SumType));
        // remove duplicates
        var j: usize = 0;
        while (j < slice.len) : (j += 1)
            slice = std.mem.collapseRepeats(SumType, slice, slice[j]);

        self.n_count = slice.len;
        return slice;
    }
    fn calcNum(self: *PowerDgt, depth_: usize, used: []u4) void {
        var depth = depth_;
        if (depth < 3) return;

        var result: SumType = 0;
        for (1..MAX_BASE) |i|
            if (used[i] != 0) {
                result += self.power_dgt[depth][i] * used[i];
            };
        if (result == 0) return;

        var n = result;
        while (true) {
            const r = n / MAX_BASE;
            used[n - (r * MAX_BASE)] -%= 1;
            n = r;
            depth -= 1;
            if (r == 0) break;
            if (depth == 0) return;
        }
        if (depth != 0) return;

        var i: usize = 1;
        while ((i < MAX_BASE) and used[i] == 0) i += 1;
        if (i >= MAX_BASE) {
            self.numbers[self.n_count] = result;
            self.n_count += 1;
        }
    }
    fn nextDigit(self: *PowerDgt, dgt_: usize, depth: usize) void {
        var dgt = dgt_;
        if (depth < MAX_BASE - 1)
            for (dgt..MAX_BASE) |i| {
                self.used_digits[dgt] += 1;
                self.nextDigit(i, depth + 1);
                self.used_digits[dgt] -= 1;
            };
        if (dgt == 0) dgt = 1;
        for (dgt..MAX_BASE) |i| {
            self.used_digits[i] += 1;
            var used: [MAX_BASE]u4 = undefined;
            @memcpy(&used, &self.used_digits);
            self.calcNum(depth, &used);
            self.used_digits[i] -= 1;
        }
    }
};
