// https://rosettacode.org/wiki/Honaker_primes
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const time = std.time;

const print = std.debug.print;

// https://rosettacode.org/wiki/Extensible_prime_generator
const PrimeGen = @import("sieve.zig").PrimeGen;

pub fn main() !void {
    var t0 = try time.Timer.start();

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var primegen = PrimeGen(u64).init(allocator);
    defer primegen.deinit();

    const task1 = 50;
    const task2 = 10_000;

    var count: usize = 0;
    var idx: u64 = 1;
    while (try primegen.next()) |p| : (idx += 1) {
        if (sumDigits(p) == sumDigits(idx)) {
            count += 1;
            if (count == 1)
                print("The first {} Honaker primes:\n", .{task1});
            if (count <= task1) {
                const sep: u8 = if (count % 5 == 0) '\n' else ' ';
                print("({d:3}, {d:4}){c}", .{ idx, p, sep });
            } else if (count == task2) {
                print("\n\nThe {d}th Honaker prime: ({}, {})\n", .{ task2, idx, p });
                break;
            }
        }
    }

    print("\nprocessed in {}\n", .{fmt.fmtDuration(t0.read())});
}

fn sumDigits(n_: u64) u64 {
    var sum: u64 = 0;
    var n = n_;
    while (n != 0) {
        sum += n % 10;
        n /= 10;
    }
    return sum;
}
