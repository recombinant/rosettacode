// https://rosettacode.org/wiki/Ranking_methods
// {{works with|Zig|0.15.1}}
// {{trans|Nim}}
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var data = [_]Record{
        .init(44, "Solomon"), .init(42, "Jason"),
        .init(43, "Errol"),   .init(41, "Garry"),
        .init(41, "Bernard"), .init(41, "Barry"),
        .init(39, "Stephen"),
    };

    // Use tagged union for results to reduce repetitive boiler plate code.
    const RankingFn = fn (std.mem.Allocator, []Record) std.mem.Allocator.Error!RankingResultsType;

    const table = [_]struct { title: []const u8, rankingFn: RankingFn, fmt: []const u8 }{
        .{ .title = "Standard ranking", .rankingFn = standardRanks, .fmt = "{d}" },
        .{ .title = "Modified ranking", .rankingFn = modifiedRanks, .fmt = "{d}" },
        .{ .title = "Dense ranking", .rankingFn = standardRanks, .fmt = "{d}" },
        .{ .title = "Ordinal ranking", .rankingFn = ordinalRanks, .fmt = "{d}" },
        .{ .title = "Fractional ranking", .rankingFn = fractionalRanks, .fmt = "{d:.1}" },
    };

    inline for (table, 1..) |entry, i| {
        try stdout.print("{s}:\n", .{entry.title});
        switch (try entry.rankingFn(allocator, &data)) {
            inline else => |ranks| {
                for (ranks) |rank| {
                    try stdout.print(entry.fmt, .{rank.rank});
                    try stdout.print(": {s} {}\n", .{ rank.name, rank.score });
                }
                allocator.free(ranks);
            },
        }
        if (i != table.len)
            try stdout.writeByte('\n');
    }

    try stdout.flush();
}

const Record = struct {
    score: u8,
    name: []const u8,
    fn init(score: u8, name: []const u8) Record {
        return Record{ .score = score, .name = name };
    }
};
const RankInt = struct {
    rank: usize,
    name: []const u8,
    score: u8,
    fn init(rank: usize, name: []const u8, score: u8) RankInt {
        return RankInt{ .rank = rank, .name = name, .score = score };
    }
};
const RankFract = struct {
    rank: f32,
    name: []const u8,
    score: u8,
    fn init(rank: f32, name: []const u8, score: u8) RankFract {
        return RankFract{ .rank = rank, .name = name, .score = score };
    }
};

const RankingResultsTag = enum {
    rankings_integer,
    rankings_fractional,
};
// Tagged union
const RankingResultsType = union(RankingResultsTag) {
    rankings_integer: []RankInt,
    rankings_fractional: []RankFract,
};

fn standardRanks(allocator: std.mem.Allocator, records: []Record) !RankingResultsType {
    std.mem.sort(Record, records, {}, greaterThan);
    var result: std.ArrayList(RankInt) = .empty;

    var rank: usize = 1;
    var current_score = records[0].score;
    for (records, 1..) |record, idx| {
        if (record.score != current_score) {
            rank = idx;
            current_score = record.score;
        }
        try result.append(allocator, RankInt.init(rank, record.name, record.score));
    }
    return RankingResultsType{ .rankings_integer = try result.toOwnedSlice(allocator) };
}

fn modifiedRanks(allocator: std.mem.Allocator, records: []Record) !RankingResultsType {
    std.mem.sort(Record, records, {}, greaterThan);
    std.mem.reverse(Record, records);
    var result: std.ArrayList(RankInt) = .empty;

    var rank: usize = records.len;
    var current_score = records[0].score;
    for (records, 0..) |record, idx| {
        if (record.score != current_score) {
            rank = records.len - idx;
            current_score = record.score;
        }
        try result.append(allocator, RankInt.init(rank, record.name, record.score));
    }
    std.mem.reverse(RankInt, result.items);
    return RankingResultsType{ .rankings_integer = try result.toOwnedSlice(allocator) };
}

fn denseRanks(allocator: std.mem.Allocator, records: []Record) !RankingResultsType {
    std.mem.sort(Record, records, {}, greaterThan);
    var result: std.ArrayList(RankInt) = .empty;

    var rank: usize = 1;
    var current_score = records[0].score;
    for (records) |record| {
        if (record.score != current_score) {
            rank += 1;
            current_score = record.score;
        }
        try result.append(allocator, RankInt.init(rank, record.name, record.score));
    }
    return RankingResultsType{ .rankings_integer = try result.toOwnedSlice(allocator) };
}

fn ordinalRanks(allocator: std.mem.Allocator, records: []Record) !RankingResultsType {
    std.mem.sort(Record, records, {}, greaterThan);
    var result: std.ArrayList(RankInt) = .empty;

    var rank: usize = 0;
    for (records) |record| {
        rank += 1;
        try result.append(allocator, RankInt.init(rank, record.name, record.score));
    }
    return RankingResultsType{ .rankings_integer = try result.toOwnedSlice(allocator) };
}

fn fractionalRanks(allocator: std.mem.Allocator, records: []Record) !RankingResultsType {
    std.mem.sort(Record, records, {}, greaterThan);
    var result: std.ArrayList(RankFract) = .empty;

    // Build a list of ranks.
    var ranks: std.ArrayList(f32) = .empty;
    defer ranks.deinit(allocator);
    var current_score = records[0].score;
    var sum: f32 = 0;
    var count: f32 = 0;
    for (records, 1..) |record, idx| {
        if (record.score == current_score) {
            count += 1;
            sum += @floatFromInt(idx);
        } else {
            try ranks.append(allocator, sum / count);
            count = 1;
            current_score = record.score;
            sum = @floatFromInt(idx);
        }
    }
    try ranks.append(allocator, sum / count);

    // Give a rank to each record.
    current_score = records[0].score;
    var rankIndex: usize = 0;
    for (records) |record| {
        if (record.score != current_score) {
            rankIndex += 1;
            current_score = record.score;
        }
        try result.append(
            allocator,
            RankFract{
                .rank = ranks.items[rankIndex],
                .name = record.name,
                .score = record.score,
            },
        );
    }
    return RankingResultsType{ .rankings_fractional = try result.toOwnedSlice(allocator) };
}

/// Helper function for std.mem.sort of Record arrays.
fn greaterThan(context: void, lhs: Record, rhs: Record) bool {
    _ = context;
    // first compare scores
    return switch (std.math.order(lhs.score, rhs.score)) {
        .gt => true,
        .lt => false,
        .eq => blk: {
            // if equal scores, compare names
            // case sensitive lexicographical comparison
            const name1 = lhs.name;
            const name2 = rhs.name;
            const len = @min(name1.len, name2.len);
            for (name1[0..len], name2[0..len]) |c1, c2| {
                switch (std.math.order(c1, c2)) {
                    .lt => break :blk true,
                    .gt => break :blk false,
                    .eq => continue,
                }
            }
            return name1.len < name2.len;
        },
    };
}
