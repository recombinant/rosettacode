// https://rosettacode.org/wiki/Old_lady_swallowed_a_fly
// {{works with|Zig|0.15.1}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const Animal = struct {
        const Self = @This();
        name: []const u8,
        lyric: []const u8,
        fn init(name: []const u8, lyric: []const u8) Self {
            return .{ .name = name, .lyric = lyric };
        }
    };
    const animals = [_]Animal{
        .init("fly", "I don't know why she swallowed a fly. Perhaps she'll die.\n"),
        .init("spider", "That wiggled and jiggled and tickled inside her.\n"),
        .init("bird", "How absurd, to swallow a bird.\n"),
        .init("cat", "Imagine that, she swallowed a cat.\n"),
        .init("dog", "What a hog, to swallow a dog.\n"),
        .init("goat", "She just opened her throat and swallowed that goat.\n"),
        .init("cow", "I don't know how she swallowed that cow.\n"),
        .init("horse", "She's dead, of course.\n"),
    };

    for (animals, 0..) |animal, i| {
        try stdout.print("There was an old lady who swallowed a {s},\n", .{animal.name});
        if (i != 0)
            try stdout.writeAll(animal.lyric);
        if (i == animals.len - 1)
            break;
        var n = i;
        while (n != 0) {
            n -= 1;
            try stdout.print(
                "She swallowed the {s} to catch the {s},\n",
                .{ animals[n + 1].name, animals[n].name },
            );
        }
        try stdout.writeAll(animals[0].lyric);
        try stdout.writeByte('\n');
    }

    try stdout.flush();
}
