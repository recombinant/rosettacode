// https://rosettacode.org/wiki/Alternade_words
const std = @import("std");
const mem = std.mem;
const print = std.debug.print;

pub fn main() !void {
    const filename = "data/unixdict.txt";
    const text = @embedFile(filename);

    // ------------------------------------------ allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------- set of words
    var words = std.StringArrayHashMap(void).init(allocator);
    defer words.deinit();
    {
        try words.ensureTotalCapacity(mem.count(u8, text, "\n") + 1);

        var it = mem.splitSequence(u8, text, "\n");
        while (it.next()) |word|
            try words.put(word, {});
    }
    // ----------------------------------------------------
    var count: u32 = 0;

    var w1 = std.ArrayList(u8).init(allocator);
    var w2 = std.ArrayList(u8).init(allocator);
    defer w1.deinit();
    defer w2.deinit();

    print("\"{s}\" contains the following alternades of length 6 or more:\n", .{filename});

    for (words.keys()) |word| {
        if (word.len < 6)
            continue;
        w1.clearRetainingCapacity();
        w2.clearRetainingCapacity();
        for (word, 0..) |c, i|
            if (i % 2 == 0)
                try w1.append(c)
            else
                try w2.append(c);

        if (words.get(w1.items) != null and words.get(w2.items) != null) {
            count += 1;
            print("{d:2}: {s:<8} -> {s:<4} {s:<4}\n", .{ count, word, w1.items, w2.items });
        }
    }
}
