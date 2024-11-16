// https://rosettacode.org/wiki/Hofstadter_Q_sequence
// Translation of Nim
const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var Q: [100_000]u32 = undefined;
    Q[0] = 1;
    Q[1] = 1;

    for (2..Q.len) |i|
        Q[i] = Q[i - Q[i - 1]] + Q[i - Q[i - 2]];

    // Task 1
    print("Q(1..10) : \n", .{});
    for (0..10) |i|
        print("{} ", .{Q[i]});
    print("\n", .{});
    // Task 2
    print("Q(1000) : {}\n", .{Q[999]});
    // Optional extra credit
    var lt: usize = 0;
    for (1..Q.len) |i|
        if (Q[i - 1] > Q[i]) {
            lt += 1;
        };
    print("Q(i) is less than Q(i-1) for i [2..{}] {} times.", .{ Q.len, lt });
}
