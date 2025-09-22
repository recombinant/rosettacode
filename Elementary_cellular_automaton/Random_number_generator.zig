// https://rosettacode.org/wiki/Elementary_cellular_automaton/Random_number_generator
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

pub fn main() !void {
    evolve(1, 30);
}

const N = 64;

fn pow2(x: u7) u64 {
    return @as(u64, 1) << @intCast(x);
}

fn evolve(state_: u64, rule: u16) void {
    var state = state_;
    for (0..10) |_| {
        var b: u64 = 0;
        var q: u4 = 8;
        while (q != 0) {
            q -= 1;
            const st: u64 = state;
            b |= (st & 1) << q;
            var i: u7 = 0;
            state = 0;
            while (i < N) : (i += 1) {
                const t1: u64 = if (i > 0)
                    st >> @intCast(i - 1)
                else
                    st >> 63;
                const t2: u64 = switch (i) {
                    0 => st << 1,
                    1 => st << 63,
                    else => st << @intCast(N + 1 - i),
                };
                const t3: u6 = @intCast(7 & (t1 | t2));
                if (@as(u64, rule) & pow2(t3) != 0)
                    state |= pow2(i);
            }
        }
        std.debug.print(" {}", .{b});
    }
    std.debug.print("\n", .{});
}
