// https://rosettacode.org/wiki/Determine_if_a_string_is_squeezable
const std = @import("std");
const heap = std.heap;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;

const Data = struct {
    c: u8,
    s: []const u8,
};

pub fn main() !void {
    const data_array = [_]Data{
        .{ .c = 't', .s = "The better the 4-wheel drive, the further you'll be from help when ya get stuck!" },
        .{ .c = 'e', .s = "The better the 4-wheel drive, the further you'll be from help when ya get stuck!" },
        .{ .c = 'l', .s = "The better the 4-wheel drive, the further you'll be from help when ya get stuck!" },
        .{ .c = 's', .s = "headmistressship" },
        .{ .c = '-', .s = "\"If I were two-faced, would I be wearing this one?\" --- Abraham Lincoln" },
        .{ .c = '7', .s = "..1111111111111111111111111111111111111111111111111111111111111117777888" },
        .{ .c = '.', .s = "I never give 'em hell, I just tell the truth, and they think it's hell." },
        .{ .c = ' ', .s = "                                                   ---  Harry S Truman  " },
        .{ .c = '-', .s = "                                                   ---  Harry S Truman  " },
        .{ .c = 'r', .s = "                                                   ---  Harry S Truman  " },
    };

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for (data_array) |data| {
        print("Character: '{c}'\n", .{data.c});
        print("{d}: <<<{s}>>>\n", .{ data.s.len, data.s });

        const squeezed = try squeeze(allocator, data.s, data.c);
        print("{d}: <<<{s}>>>\n\n", .{ squeezed.len, squeezed });

        allocator.free(squeezed);
    }
}

fn squeeze(allocator: mem.Allocator, s: []const u8, c: u8) ![]u8 {
    if (s.len < 2) return try allocator.dupe(u8, s);

    var result = try std.ArrayList(u8).initCapacity(allocator, s.len);

    var i: usize = 0;
    while (i != s.len) {
        try result.append(s[i]);
        if (s[i] == c) {
            var j = i + 1;
            while (j != s.len and s[j] == c)
                j += 1;
            i = j;
        } else {
            i += 1;
        }
    }
    return try result.toOwnedSlice();
}

test "squeeze" {
    const allocator = testing.allocator;
    const result1 = try squeeze(allocator, "---", '-');
    try testing.expectEqualStrings("-", result1);
    allocator.free(result1);

    try testing.expectError(error.OutOfMemory, squeeze(testing.failing_allocator, "---", '-'));
}
