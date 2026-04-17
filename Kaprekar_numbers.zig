// https://rosettacode.org/wiki/Kaprekar_numbers
// {{works with|Zig|0.16.0}}
// {{trans|Go}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const print = std.debug.print;

fn kaprekar(n: u64, base: u64) struct { bool, ?usize } {
    if (n == 0) return .{ false, null };
    if (n == 1) return .{ true, null };
    var order: u64 = 0;

    const nn = n * n;
    var power: u64 = 1;
    while (power <= nn) {
        power *= base;
        order += 1;
    }

    power /= base;
    order -= 1;
    while (power > 1) : (power /= base) {
        const q = nn / power;
        const r = nn % power;
        if (q >= n)
            return .{ false, null };
        if (q + r == n)
            return .{ true, order };
        order -= 1;
    }
    return .{ false, null };
}

pub fn main(init: std.process.Init) !void {
    {
        // Task
        const max: u64 = 10_000;
        print("Kaprekar numbers < {}:\n", .{max});
        var m: u64 = 0;
        while (m < max) : (m += 1) {
            const is, _ = kaprekar(m, 10);
            if (is)
                print("  {}\n", .{m});
        }
    }
    {
        // Extra Credit
        const max = 1_000_000;
        var count: u32 = 0;
        var m: u64 = 0;
        while (m < max) : (m += 1) {
            const is, _ = kaprekar(m, 10);
            if (is)
                count += 1;
        }
        print("\nThere are {} Kaprekar numbers < {}.\n", .{ count, max });
    }
    {
        // Extra Extra Credit
        const gpa: Allocator = init.gpa;
        var wa1: Io.Writer.Allocating = .init(gpa);
        var wa2: Io.Writer.Allocating = .init(gpa);
        defer wa1.deinit();
        defer wa2.deinit();

        const base = 17;
        const max_b = "1_000_000";
        print("\nKaprekar numbers between 1 and {s}(base {d}):\n", .{ max_b, base });

        const max = std.fmt.parseInt(u64, max_b, base) catch unreachable;

        print("  Base 10  Base {d}        Square       Split\n", .{base});
        var m: u64 = 1;
        while (m < max) : (m += 1) {
            const is, const optional_pos = kaprekar(m, base);
            if (!is)
                continue;

            wa1.clearRetainingCapacity();
            wa2.clearRetainingCapacity();

            wa1.writer.printInt(m, base, .lower, .{}) catch unreachable;
            wa2.writer.printInt(m * m, base, .lower, .{}) catch unreachable;

            const str = wa1.written();
            const sq = wa2.written();

            print(" {d:8}  {s:7}  {s:12}", .{ m, str, sq });

            if (optional_pos) |pos| {
                const split = sq.len - pos;
                print("  {s:6} + {s}", .{ sq[0..split], sq[split..] });
            }
            print("\n", .{});
        }
    }
}
