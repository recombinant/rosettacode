// https://rosettacode.org/wiki/Jaro-Winkler_distance
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

const WD = struct {
    word: []const u8,
    dist: f32,

    fn lessThan(_: void, lhs: WD, rhs: WD) bool {
        switch (std.math.order(lhs.dist, rhs.dist)) {
            .lt => return true,
            .gt => return false,
            .eq => {
                return switch (std.mem.order(u8, lhs.word, rhs.word)) {
                    .lt => return true,
                    .eq, .gt => return false,
                };
            },
        }
    }
};

pub fn main() !void {
    // var gpa: std.heap.DebugAllocator(.{}) = .init;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var jw: JaroWinkler = try .init(allocator);
    defer jw.deinit();

    const misspelt = [_][]const u8{
        "accomodate", "definately", "goverment", "occured", "publically",
        "recieve",    "seperate",   "untill",    "wich",    "unecesary",
    };
    for (misspelt) |ms| {
        const closest = try jw.within_distance(0.15, ms, 5);
        defer allocator.free(closest);
        try stdout.print("Close dictionary words (distance < 0.15 using Jaro-Winkler distance) to '{s}' are:\n        Word   |  Distance\n", .{ms});
        for (closest) |wd|
            try stdout.print("{s:>14} | {d:.4}\n", .{ wd.word, wd.dist });
        try stdout.writeByte('\n');
    }

    try stdout.flush();
}

const JaroWinkler = struct {
    allocator: std.mem.Allocator,
    words: [][]const u8,

    fn init(allocator: std.mem.Allocator) !JaroWinkler {
        return JaroWinkler{
            .allocator = allocator,
            .words = try loadDictionary(allocator),
        };
    }

    fn deinit(self: JaroWinkler) void {
        defer self.allocator.free(self.words);
    }

    fn jaro_winkler_distance(self: *JaroWinkler, arg_str1: []const u8, arg_str2: []const u8) !f32 {
        var str1 = arg_str1;
        var str2 = arg_str2;
        var len1 = str1.len;
        var len2 = str2.len;
        if (len1 < len2) {
            std.mem.swap([]const u8, &str1, &str2);
            std.mem.swap(usize, &len1, &len2);
        }
        if (len2 == 0)
            return if (len1 == 0) 0 else 1;
        const delta = @max(1, len1 / 2) - 1;
        var flag = try self.allocator.alloc(bool, len2);
        defer self.allocator.free(flag);
        @memset(flag, false);
        var ch1_match: std.ArrayList(u8) = try .initCapacity(self.allocator, len1);
        defer ch1_match.deinit(self.allocator);
        for (0..len1) |idx1| {
            const ch1 = str1[idx1];
            for (0..len2) |idx2| {
                const ch2 = str2[idx2];
                if (idx2 <= idx1 + delta and idx2 + delta >= idx1 and ch1 == ch2 and !flag[idx2]) {
                    flag[idx2] = true;
                    try ch1_match.append(self.allocator, ch1);
                    break;
                }
            }
        }
        const matches = ch1_match.items.len;
        if (matches == 0)
            return 1;
        var transpositions: f32 = 0;
        var idx1: usize = 0;
        for (0..len2) |idx2| {
            if (flag[idx2]) {
                if (str2[idx2] != ch1_match.items[idx1])
                    transpositions += 1;
                idx1 += 1;
            }
        }
        const m: f32 = @floatFromInt(matches);
        const f_len1: f32 = @floatFromInt(len1);
        const f_len2: f32 = @floatFromInt(len2);
        const jaro = (m / f_len1 + m / f_len2 + (m - transpositions / 2) / m) / 3;
        var common_prefix: f32 = 0;
        len2 = @min(4, len2);
        for (0..len2) |i| {
            if (str1[i] == str2[i])
                common_prefix += 1;
        }
        return 1 - (jaro + common_prefix * 0.1 * (1 - jaro));
    }

    fn within_distance(self: *JaroWinkler, max_distance: f32, str: []const u8, max_to_return: u16) ![]WD {
        var wd_array: std.ArrayList(WD) = .empty;
        for (self.words) |word| {
            const jaro = try self.jaro_winkler_distance(word, str);
            if (jaro <= max_distance)
                try wd_array.append(self.allocator, WD{ .word = word, .dist = jaro });
        }
        var result = try wd_array.toOwnedSlice(self.allocator);
        std.mem.sortUnstable(WD, result, {}, WD.lessThan);
        if (result.len > max_to_return) {
            const temp = result;
            result = try self.allocator.dupe(WD, result[0..max_to_return]);
            self.allocator.free(temp);
        }
        return result;
    }
};

fn loadDictionary(allocator: std.mem.Allocator) ![][]const u8 {
    const lw = @embedFile("data/linuxwords.txt");

    var words_array: std.ArrayList([]const u8) = .empty;

    var it = std.mem.tokenizeAny(u8, lw, " \t\n");
    while (it.next()) |word|
        try words_array.append(allocator, word);

    return try words_array.toOwnedSlice(allocator);
}
