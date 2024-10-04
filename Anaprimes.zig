// https://rosettacode.org/wiki/Anaprimes
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const time = std.time;

const assert = std.debug.assert;
const print = std.debug.print;

// https://rosettacode.org/wiki/Extensible_prime_generator
const PrimeGen = @import("sieve.zig").PrimeGen;

const AnaprimeLookup = std.AutoArrayHashMap(u40, std.ArrayList(u64));

pub fn main() !void {
    var t0 = try time.Timer.start();

    const max: u64 = 1_000_000_000;
    var limit: u64 = 1_000;

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var primegen = PrimeGen(u64).init(allocator);
    defer primegen.deinit();

    var anaprimes = AnaprimeLookup.init(allocator);
    defer {
        clear(&anaprimes);
        anaprimes.deinit();
    }

    var longest = std.ArrayList([]const u64).init(allocator);
    defer longest.deinit();

    while (true) {
        const p = (try primegen.next()).?;
        if (p < 100) // ignore less than three digits
            continue
        else if (p > limit) {
            longest.clearRetainingCapacity();
            // find the longest groups
            for (anaprimes.values()) |primes| {
                if (longest.items.len == 0 or longest.items[0].len == primes.items.len)
                    try longest.append(primes.items)
                else if (primes.items.len > longest.items[0].len) {
                    longest.clearRetainingCapacity();
                    try longest.append(primes.items);
                }
            }
            // print the longest groups
            const plural: []const u8 = if (longest.items.len > 1) "s" else "";
            print(
                "Largest anaprime group{s} less than {} - {} group{s} of {} primes\n",
                .{ plural, limit, longest.items.len, plural, longest.items[0].len },
            );
            for (longest.items) |primes| {
                assert(primes.len > 1);
                print("  {}, ", .{primes[0]});
                if (primes.len > 1) print("... ", .{});
                print("{}\n", .{primes[primes.len - 1]});
            }
            print("\n", .{});
            //
            limit *= 10;
            if (limit >= max)
                break; // finished
            clear(&anaprimes);
        }
        const key = calcSignature(@TypeOf(p), p);
        const gop = try anaprimes.getOrPut(key);
        if (!gop.found_existing)
            gop.value_ptr.* = std.ArrayList(u64).init(allocator);

        try gop.value_ptr.append(p);
    }
    print("\nprocessed in {}\n", .{fmt.fmtDuration(t0.read())});
}

fn clear(anaprimes: *std.AutoArrayHashMap(u40, std.ArrayList(u64))) void {
    for (anaprimes.values()) |primes|
        primes.deinit();
    anaprimes.clearRetainingCapacity();
}

/// Same digits different order will give the same signature.
/// Count of each digit in 'n_' packed into an integer.
/// 40 bits (10 decimal digits 0 to 9 inclusive, 4 bits per digit)
/// - for a number with up to 15 identical decimal digits.
fn calcSignature(T: type, n_: T) u40 {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("calcSignature requires an unsigned integer, found " ++ @typeName(T));

    // n == 0 will return zero
    var n = n_;
    var signature: u40 = 0;

    // Zig's comptime will expand inline switch branch.
    while (n > 0) {
        signature += switch (n % 10) {
            inline 0...9 => |shift| comptime 1 << (shift * 4),
            else => unreachable,
        };
        n /= 10;
    }
    return signature;
}
