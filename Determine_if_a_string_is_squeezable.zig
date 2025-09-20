// https://rosettacode.org/wiki/Determine_if_a_string_is_squeezable
// {{works with|Zig|0.15.1}}
const std = @import("std");

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

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (data_array) |data| {
        try stdout.print("Character: '{c}'\n", .{data.c});
        try stdout.print("{d}: <<<{s}>>>\n", .{ data.s.len, data.s });

        const squeezed = try squeeze(allocator, data.s, data.c);
        try stdout.print("{d}: <<<{s}>>>\n\n", .{ squeezed.len, squeezed });

        allocator.free(squeezed);
    }

    try stdout.flush();
}

fn squeeze(allocator: std.mem.Allocator, s: []const u8, c: u8) ![]u8 {
    if (s.len < 2) return try allocator.dupe(u8, s);

    var result: std.ArrayList(u8) = try .initCapacity(allocator, s.len);

    var i: usize = 0;
    while (i != s.len) {
        try result.append(allocator, s[i]);
        if (s[i] == c) {
            var j = i + 1;
            while (j != s.len and s[j] == c)
                j += 1;
            i = j;
        } else {
            i += 1;
        }
    }
    return try result.toOwnedSlice(allocator);
}

const testing = std.testing;

test "squeeze" {
    const allocator = testing.allocator;
    const result1 = try squeeze(allocator, "---", '-');
    try testing.expectEqualStrings("-", result1);
    allocator.free(result1);

    try testing.expectError(error.OutOfMemory, squeeze(testing.failing_allocator, "---", '-'));
}
