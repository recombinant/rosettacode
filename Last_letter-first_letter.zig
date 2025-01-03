// https://rosettacode.org/wiki/Last_letter-first_letter
// Translation of Wren
const std = @import("std");

pub fn main() !void {
    const pokemon =
        \\ audino bagon baltoy banette bidoof braviary bronzor carracosta charmeleon
        \\ cresselia croagunk darmanitan deino emboar emolga exeggcute gabite
        \\ girafarig gulpin haxorus heatmor heatran ivysaur jellicent jumpluff kangaskhan
        \\ kricketune landorus ledyba loudred lumineon lunatone machamp magnezone mamoswine
        \\ nosepass petilil pidgeotto pikachu pinsir poliwrath poochyena porygon2
        \\ porygonz registeel relicanth remoraid rufflet sableye scolipede scrafty seaking
        \\ sealeo silcoon simisear snivy snorlax spoink starly tirtouga trapinch treecko
        \\ tyrogue vigoroth vulpix wailord wartortle whismur wingull yamask
    ;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const names = try split(allocator, pokemon);
    defer allocator.free(names);

    var llfl = LastLetterFirstLetter.init(allocator, names);
    defer llfl.deinit();

    try llfl.search();

    // // sort example items lexicographically
    // std.mem.sort([]const u8, llfl.max_path_example.items, {}, lessThan);

    const writer = std.io.getStdOut().writer();
    try writer.print("Maximum path length         : {}\n", .{llfl.max_path_length});
    try writer.print("Paths of that length        : {}\n", .{llfl.max_path_length_count});
    try writer.print("Example path of that length : {s}\n", .{llfl.max_path_example.items});
}

const LastLetterFirstLetter = struct {
    allocator: std.mem.Allocator,
    names: [][]const u8,
    max_path_length: usize,
    max_path_length_count: usize,
    max_path_example: std.ArrayList([]const u8),

    fn init(allocator: std.mem.Allocator, names: [][]const u8) LastLetterFirstLetter {
        return .{
            .allocator = allocator,
            .names = names,
            .max_path_length = 0,
            .max_path_length_count = 0,
            .max_path_example = std.ArrayList([]const u8).init(allocator),
        };
    }
    fn deinit(self: *LastLetterFirstLetter) void {
        self.max_path_example.deinit();
    }
    /// Wrapper around recursive search_()
    fn search(self: *LastLetterFirstLetter) !void {
        for (0..self.names.len) |i| {
            std.mem.swap([]const u8, &self.names[0], &self.names[i]);
            try self.search_(1);
            std.mem.swap([]const u8, &self.names[0], &self.names[i]);
        }
    }
    /// Recursive function
    fn search_(self: *LastLetterFirstLetter, offset: usize) !void {
        if (offset > self.max_path_length) {
            self.max_path_length = offset;
            self.max_path_length_count = 1;
            self.max_path_example.clearRetainingCapacity();
            try self.max_path_example.appendSlice(self.names[0..offset]);
        } else if (offset == self.max_path_length) {
            self.max_path_length_count += 1;
        }
        const lastChar = self.names[offset - 1][self.names[offset - 1].len - 1];
        for (offset..self.names.len) |i| {
            if (self.names[i][0] == lastChar) {
                std.mem.swap([]const u8, &self.names[offset], &self.names[i]);
                try self.search_(offset + 1);
                std.mem.swap([]const u8, &self.names[offset], &self.names[i]);
            }
        }
    }
};
/// Split string at whitepace and de-duplicate.
/// Allocates memory for the result, which must be freed by the caller.
fn split(allocator: std.mem.Allocator, string: []const u8) ![][]const u8 {
    var name_set = std.StringArrayHashMap(void).init(allocator);
    defer name_set.deinit();
    // dedupe using set
    var it = std.mem.tokenizeAny(u8, string, " \n");
    while (it.next()) |name|
        try name_set.put(name, {});
    // deduped array of names
    return allocator.dupe([]const u8, name_set.keys());
}
// /// Case sensitive lexicographical comparison.
// fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
//     const len = @min(lhs.len, rhs.len);
//     for (lhs[0..len], rhs[0..len]) |c1, c2| {
//         switch (std.math.order(c1, c2)) {
//             .lt => return true,
//             .gt => return false,
//             .eq => break,
//         }
//     }
//     return lhs.len < rhs.len;
// }

const testing = std.testing;
test "LastLetterFirstLetter 0" {
    var names = [_][]const u8{};

    var llfl = LastLetterFirstLetter.init(testing.allocator, names[0..]);
    defer llfl.deinit();

    try llfl.search();

    try testing.expectEqual(0, llfl.max_path_length);
    try testing.expectEqual(0, llfl.max_path_length_count);
    try testing.expectEqual(0, llfl.max_path_example.items.len);
}
test "LastLetterFirstLetter 1" {
    var names = [_][]const u8{"aa"};

    var llfl = LastLetterFirstLetter.init(testing.allocator, names[0..]);
    defer llfl.deinit();

    try llfl.search();

    try testing.expectEqual(1, llfl.max_path_length);
    try testing.expectEqual(1, llfl.max_path_length_count);
    try testing.expectEqualSlices([]const u8, names[0..], llfl.max_path_example.items);
}
test "LastLetterFirstLetter 2" {
    var names = [_][]const u8{ "aa", "ab" };

    var llfl = LastLetterFirstLetter.init(testing.allocator, names[0..]);
    defer llfl.deinit();

    try llfl.search();

    try testing.expectEqual(2, llfl.max_path_length);
    try testing.expectEqual(1, llfl.max_path_length_count);
    try testing.expectEqualSlices([]const u8, names[0..], llfl.max_path_example.items);
}
test "LastLetterFirstLetter 3" {
    var names = [_][]const u8{ "zz", "aa", "bc", "ab" };

    var llfl = LastLetterFirstLetter.init(testing.allocator, names[0..]);
    defer llfl.deinit();

    try llfl.search();

    try testing.expectEqual(3, llfl.max_path_length);
    try testing.expectEqual(1, llfl.max_path_length_count);
    try testing.expectEqualSlices([]const u8, ([_][]const u8{ names[1], names[3], names[2] })[0..], llfl.max_path_example.items);
}
