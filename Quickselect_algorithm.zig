// https://rosettacode.org/wiki/Quickselect_algorithm
// Two available partition algorithm functions - Hoare's and Lomuto's.
// A third, Alexandrescu's, is not here as it wouldn't work correctly
// "out of the box" with duplicates in the supplied slice.
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    var values = [_]u8{ 9, 8, 7, 6, 5, 0, 1, 2, 3, 4 };

    var k: usize = 0;
    while (k < values.len) : (k += 1)
        std.debug.print("{d:2}: {d}\n", .{ k, kthElement(u8, &values, k) });
}

/// Zero based.
fn kthElement(T: type, array: []T, k: usize) T {
    std.debug.assert(k < array.len);
    return quickselect(T, array, 0, array.len - 1, k);
}
fn quickselect(T: type, array: []T, lo: usize, hi: usize, k: usize) T {
    std.debug.assert(array.len != 0);
    std.debug.assert(hi < array.len);
    std.debug.assert(hi >= lo);
    if (lo == hi)
        return array[lo];

    const pivot = lo + partitionL(T, array[lo .. hi + 1]);
    // const pivot = lo + partitionH(T, array[lo .. hi + 1]);
    return if (pivot == k)
        array[pivot]
    else if (k < pivot)
        quickselect(T, array, lo, pivot - 1, k)
    else
        quickselect(T, array, pivot + 1, hi, k);
}

/// Hoare's Partition Algorithm
/// from https://en.wikipedia.org/wiki/Quickselect pseudocode
fn partitionH(T: type, slice: []T) usize {
    if (slice.len == 1)
        return 0;

    const pivot_index = slice.len - 1;
    const pivot = slice[pivot_index];

    var lo: usize = 0;
    var hi = pivot_index - 1;

    while (true) {
        while (slice[lo] < pivot and lo < hi)
            lo += 1;
        while (slice[hi] >= pivot and lo < hi)
            hi -= 1;
        if (lo < hi) {
            std.mem.swap(T, &slice[lo], &slice[hi]);
            lo += 1;
            hi -= 1;
        } else {
            if (slice[lo] <= pivot)
                lo += 1;
            std.mem.swap(T, &slice[lo], &slice[pivot_index]);
            return lo;
        }
    }
}

/// Lomuto's Partition Algorithm, simplest & slowest
fn partitionL(T: type, slice: []T) usize {
    if (slice.len == 1)
        return 0;

    var lo: usize = 0;
    const hi = slice.len - 1;

    // This entire switch can be removed.
    switch (slice.len) {
        2 => {
            // shortcut for slice with two elements
            if (slice[lo] > slice[hi])
                std.mem.swap(T, &slice[lo], &slice[hi]);
            return 0;
        },
        else => {
            // optimisation for kthElement()
            // reduces swap count
            if (slice[lo] < slice[hi])
                std.mem.swap(T, &slice[lo], &slice[hi]);
        },
    }
    // this is Lomuto's Partition Algorithm
    const pivot = slice[hi];
    for (0..hi) |i|
        if (slice[i] < pivot) {
            std.mem.swap(T, &slice[lo], &slice[i]);
            lo += 1;
        };
    std.mem.swap(T, &slice[lo], &slice[hi]);
    return lo;
}

const testing = std.testing;

test "partition" {
    const debug_timeit = false;
    var t0: std.time.Timer = undefined;
    var elapsed: u64 = undefined;
    var total_elapsed: u64 = undefined;
    var buffer: [6]u8 = undefined;

    const T = u8;
    // test both Hoare's and Lomuto's partition functions
    inline for ([_](*const fn (type, []T) usize){ partitionH, partitionL }) |partition| {
        if (debug_timeit) total_elapsed = 0;
        // test different array sizes
        for (1..buffer.len + 1) |array_len| {
            const max = std.math.powi(u64, 10, array_len) catch unreachable;
            if (debug_timeit) {
                elapsed = 0;
                t0 = try std.time.Timer.start();
            }
            // test all possible combinations for array
            for (0..max) |n| {
                // (Alexandrescu's Partition Algorithm) the partition algorithm
                // may tweak the array values by one so also test with even
                // numbers
                for (1..3) |multiplier| {
                    var array = digitsFromNumber(buffer[0..array_len], n);
                    for (array, 0..) |*value, i|
                        value.* = @intCast(i * multiplier);

                    // std.debug.print("len={}  {any}\n", .{ array.len, array });
                    if (debug_timeit) t0.reset();
                    const pivot_index = partition(T, array);
                    if (debug_timeit) elapsed += t0.read();
                    const pivot_value = array[pivot_index];
                    // std.debug.print("len={} pivot={} value={} {any}\n", .{ array.len, pivot_index, pivot_value, array });

                    // any values to the right of pivot_index should be pivot_value or greater
                    for (array[pivot_index..]) |value|
                        try std.testing.expect(value >= pivot_value);

                    // find leftmost pivot_value as there may be duplicates
                    var lo_index = pivot_index;
                    while (lo_index != 0 and array[lo_index - 1] == pivot_value)
                        lo_index -= 1;
                    // values left of lo_index should be less than pivot_value
                    for (array[0..lo_index]) |value|
                        try std.testing.expect(value < pivot_value);
                }
            }
            if (debug_timeit) {
                total_elapsed += elapsed;
                print("{} {}\n", .{ array_len, elapsed });
            }
        }
        if (debug_timeit) print("total elapsed {}\n", .{total_elapsed});
    }
}

test digitsFromNumber {
    var buffer: [5]u8 = undefined;
    try testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 1, 2, 3 }, digitsFromNumber(&buffer, 123));
    try testing.expectEqualSlices(u8, &[_]u8{ 3, 2, 1, 0, 0 }, digitsFromNumber(&buffer, 32100));
}

/// Helper function for testing (itself being tested)
fn digitsFromNumber(output: []u8, n_: usize) []u8 {
    @memset(output, 0);
    var n = n_;
    var idx: usize = output.len;
    while (n != 0) {
        idx -= 1;
        output[idx] = @truncate(n % 10);
        n /= 10;
    }
    return output;
}

// kthElement test uses random numbers. It would be more rigorous
// to iterate through number ranges as per the partition test.
test kthElement {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    for (0..100) |_|
        for (0..3) |multiplier| {
            const array = try std.testing.allocator.alloc(u8, random.intRangeLessThan(u8, 1, 24));
            for (array, 0..) |*n, i|
                n.* = if (multiplier != 0)
                    @intCast(i * multiplier)
                else
                    @intFromBool(random.boolean());
            defer std.testing.allocator.free(array);
            for (0..100) |_| {
                random.shuffle(u8, array);
                const k = random.intRangeLessThan(usize, 0, array.len);
                const value_q = quickselect(u8, array, 0, array.len - 1, k);
                const value = array[k];
                try std.testing.expectEqual(value, value_q);
                for (array[k..]) |n|
                    try std.testing.expect(n >= value);
                var index = k;
                while (index != 0 and array[index - 1] == array[k])
                    index -= 1;
                for (array[0..index]) |n|
                    try std.testing.expect(n < value);
            }
        };
}
