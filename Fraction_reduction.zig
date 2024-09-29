// https://rosettacode.org/wiki/Fraction_reduction
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

fn toNumber(digits_: std.ArrayList(u32), removeDigit: u4) !u32 {
    var digits = try digits_.clone();
    defer digits.deinit();
    if (removeDigit != 0) {
        const idx = mem.indexOfScalar(u32, digits.items, removeDigit).?;
        _ = digits.orderedRemove(idx);
    }
    var res = digits.items[0];
    for (digits.items[1..]) |digit|
        res = res * 10 + digit;
    return res;
}

fn ndigits(allocator: mem.Allocator, n: usize) ![]u32 {
    // generate numbers with unique digits efficiently
    // and store them in an array for multiple re-use,
    // along with an array of the removed-digit values.
    var res = std.ArrayList(u32).init(allocator);
    const digits = try allocator.alloc(u32, n);
    defer allocator.free(digits);
    const used = std.StaticBitSet(9).initFull();
    while (true) {
        var nine: [9]u32 = undefined;
        for (used, &nine, 0..) |used_, *nine_, i|
            if (used_) {
                nine_.* = toNumber(digits, i);
            };
        //         res = append(res,{to_n(digits),nine})
        var found = false;
        //         for i=n to 1 by -1 do
        {
            //             integer d = digits[i]
            //             if not used[d] then ?9/0
            //             used[d] = 0
            //             for j=d+1 to 9 do
            {
                //                 if not used[j] then
                {
                    //                     used[j] = 1
                    //                     digits[i] = j
                    //                     for k=i+1 to n do
                    {
                        //                         digits[k] = find(0,used)
                        //                         used[digits[k]] = 1
                    }
                    found = true;
                    break;
                }
            }
            if (found) break;
        }
        if (!found) break;
    }
    return try res.toOwnedSlice();
}

pub fn main() void {
    var t0 = try std.time.Timer.start();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for (2..5) |n| {
        const d = ndigits(allocator, n);
        defer allocator.free(d);
        const count: usize = 0;
        _ = count; // autofix
        //     sequence omitted = repeat(0,9)
        //     for i=1 to length(d)-1 do
        //         {integer xn, sequence rn} = d[i]
        //         for j=i+1 to length(d) do
        //             {integer xd, sequence rd} = d[j]
        //             for k=1 to 9 do
        //                 integer yn = rn[k], yd = rd[k]
        //                 if yn!=0 and yd!=0 and xn/xd = yn/yd then
        //                     count += 1
        //                     omitted[k] += 1
        //                     if count<=12 then
        //                         printf(1,"%d/%d => %d/%d (removed %d)\n",{xn,xd,yn,yd,k})
        //                     elsif time()>t1 and platform()!=JS then
        //                         printf(1,"working (%d/%d)...\r",{i,length(d)})
        //                         t1 = time()+1
        //                     }
        //                 }
        //             }
        //         }
        //     }
        //     printf(1,"%d-digit fractions found:%d, omitted %v\n\n",{n,count,omitted})
    }
    print("processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
}

const testing = std.testing;

test toNumber {
    const number = [_]u32{ 5, 6, 1, 2 };

    var digits = std.ArrayList(u32).init(testing.allocator);
    defer digits.deinit();
    try digits.appendSlice(&number);

    try testing.expectEqual(512, try toNumber(digits, 6));

    digits.clearAndFree();
    try digits.appendSlice(&number);

    try testing.expectEqual(5612, try toNumber(digits, 0));
}
