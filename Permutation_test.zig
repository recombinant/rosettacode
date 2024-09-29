// https://rosettacode.org/wiki/Permutation_test
// Translation of C
const std = @import("std");
const print = std.debug.print;

const data = [_]u32{
    85, 88, 75, 66, 25, 29, 83, 39,
    97, 68, 41, 10, 49, 16, 65, 32,
    92, 28, 98,
};

fn pick(at: u32, remain: u32, accu: u32, treat: u32) u32 {
    if (remain == 0)
        return if (accu > treat) 1 else 0;
    return pick(at - 1, remain - 1, accu + data[at - 1], treat) +
        (if (at > remain) pick(at - 1, remain, accu, treat) else 0);
}

pub fn main() void {
    var total: f32 = 1.0;
    const T = @TypeOf(total);

    var treat: u32 = 0;
    for (data[0..9]) |n|
        treat += n;

    var i: u32 = 20;
    while (i != 11) {
        i -= 1;
        total *= @floatFromInt(i);
    }

    i = 10;
    while (i != 1) {
        i -= 1;
        total /= @floatFromInt(i);
    }

    const gt = pick(19, 9, 0, treat);
    // le = total - gt;
    const le: u32 = @intFromFloat(total - @as(T, @floatFromInt(gt)));

    // 100 * le / total
    print("<= : {d:9.6}%  {d}\n", .{ 100 * @as(T, @floatFromInt(le)) / total, le });
    // 100 * gt / total
    print(" > : {d:9.6}%  {d}\n", .{ 100 * @as(T, @floatFromInt(gt)) / total, gt });
}
