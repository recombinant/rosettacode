// https://rosettacode.org/wiki/Kaprekar_numbers
// Translation of Go
const std = @import("std");
const fmt = std.fmt;
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

pub fn main() void {
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
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        var buffer1 = std.ArrayList(u8).init(allocator);
        var buffer2 = std.ArrayList(u8).init(allocator);
        defer buffer1.deinit();
        defer buffer2.deinit();
        const writer1 = buffer1.writer();
        const writer2 = buffer2.writer();

        const base = 17;
        const max_b = "1_000_000";
        print("\nKaprekar numbers between 1 and {s}(base {d}):\n", .{ max_b, base });

        const max = fmt.parseInt(u64, max_b, base) catch unreachable;

        print("  Base 10  Base {d}        Square       Split\n", .{base});
        var m: u64 = 1;
        while (m < max) : (m += 1) {
            const is, const optional_pos = kaprekar(m, base);
            if (!is)
                continue;

            buffer1.clearRetainingCapacity();
            buffer2.clearRetainingCapacity();

            fmt.formatInt(m, base, .lower, .{}, writer1) catch unreachable;
            fmt.formatInt(m * m, base, .lower, .{}, writer2) catch unreachable;

            const str = buffer1.items;
            const sq = buffer2.items;

            print(" {d:8}  {s:7}  {s:12}", .{ m, str, sq });

            if (optional_pos) |pos| {
                const split = sq.len - pos;
                print("  {s:6} + {s}", .{ sq[0..split], sq[split..] });
            }
            print("\n", .{});
        }
    }
}
