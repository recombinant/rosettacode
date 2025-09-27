// https://rosettacode.org/wiki/ASCII_art_diagram_converter
// {{works with|Zig|0.15.1}}
// {{trans|Wren}}
const std = @import("std");

pub fn main() !void {
    const diagram =
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                      ID                       |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    QDCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    ANCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    NSCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    ARCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ;

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const lines = try validate(allocator, diagram);
    defer allocator.free(lines);
    try stdout.writeAll("Diagram after trimming whitespace and removal of blank lines:\n");
    for (lines) |line| {
        try stdout.writeAll(line);
        try stdout.writeByte('\n');
    }
    try stdout.writeAll("\nDecoded:\n\n");
    const results = try decode(allocator, lines, stdout);
    defer allocator.free(results);
    const hex = "78477bbf5496e12e1bf169a4"; // test string
    try unpack(allocator, results, hex, stdout);

    try stdout.flush();
}

const ValidationError = error{
    EmptyDiagram,
    ExpectedMultipleLines,
    ExpectedOddLineCount,
    InconsistentLineWidths,
    InvalidColumnCount,
    InvalidHeaderLine,
    InvalidLineEndChar,
    InvalidLineStartChar,
    InvalidSeparatorLine,
};

const Result = struct {
    name: []const u8,
    size: usize,
    start: usize,
    end: usize,
};

fn validate(allocator: std.mem.Allocator, diagram: []const u8) ![][]const u8 {
    var line_list: std.ArrayList([]const u8) = .empty;
    defer line_list.deinit(allocator);
    var it = std.mem.tokenizeScalar(u8, diagram, '\n');
    while (it.next()) |untrimmed_line| {
        const line = std.mem.trim(u8, untrimmed_line, " \t");
        if (line.len != 0)
            try line_list.append(allocator, line);
    }
    const lines = line_list.items;
    if (lines.len == 0)
        return ValidationError.EmptyDiagram; // diagram has no non-empty lines
    if (lines.len == 1)
        return ValidationError.ExpectedMultipleLines; // diagram has one line
    if (lines.len & 1 == 0)
        return ValidationError.ExpectedOddLineCount; // diagram missing final line

    const first_line = lines[0];
    const width = first_line.len;
    const cols: usize = @intFromFloat(@floor((@as(f32, @floatFromInt(width - 1))) / 3));
    // number of columns should be 8, 16, 32 or 64
    if (cols != 8 and cols != 16 and cols != 32 and cols != 64)
        return ValidationError.InvalidColumnCount;

    // validate the characters in the first line
    var err1 = false;
    for (0..cols) |col| {
        const x = col * 3;
        if (!std.mem.eql(u8, first_line[x .. x + 3], "+--"))
            err1 = true;
    }
    const err2 = !std.mem.endsWith(u8, first_line, "+");
    if (err1 or err2)
        return ValidationError.InvalidHeaderLine;

    // validate subsequent lines
    for (lines, 0..) |line, i| {
        if (i == 0)
            continue
        else if (i % 2 == 0) {
            if (!std.mem.eql(u8, line, first_line))
                return ValidationError.InvalidSeparatorLine;
        } else if (line.len != width)
            return ValidationError.InconsistentLineWidths
        else if (line[0] != '|')
            return ValidationError.InvalidLineStartChar
        else if (line[width - 1] != '|')
            return ValidationError.InvalidLineEndChar;
    }
    return line_list.toOwnedSlice(allocator);
}

fn decode(allocator: std.mem.Allocator, lines: [][]const u8, w: *std.Io.Writer) ![]Result {
    try w.writeAll("Name     Bits  Start  End\n");
    try w.writeAll("=======  ====  =====  ===\n");
    var start: usize = 0;
    const width = lines[0].len;
    var results: std.ArrayList(Result) = .empty;
    for (lines, 0..) |line0, i| {
        if (i % 2 == 0)
            continue;

        const line = line0[1 .. width - 1];
        var it = std.mem.tokenizeScalar(u8, line, '|');
        while (it.next()) |name0| {
            const size: usize = @intFromFloat(@floor(@as(f32, @floatFromInt(name0.len + 1)) / 3));
            const name = std.mem.trim(u8, name0, " ");
            const r = Result{
                .name = name,
                .size = size,
                .start = start,
                .end = start + size - 1,
            };
            try results.append(allocator, r);
            try w.print("{s:<7}   {d:2}    {d:3}   {d:3}\n", .{ r.name, r.size, r.start, r.end });
            start += size;
        }
    }
    return results.toOwnedSlice(allocator);
}

fn unpack(allocator: std.mem.Allocator, results: []Result, hex: []const u8, w: *std.Io.Writer) !void {
    try w.writeAll("\nTest string in hex:\n");
    try w.print("{s}\n", .{hex});

    // write hex string as binary to allocating writer
    var a: std.Io.Writer.Allocating = .init(allocator);
    defer a.deinit();
    for (hex) |c|
        switch (c) {
            '0'...'9' => try a.writer.print("{b:0>4}", .{c - '0'}),
            'a'...'f' => try a.writer.print("{b:0>4}", .{c - 'a' + 10}),
            'A'...'F' => try a.writer.print("{b:0>4}", .{c - 'A' + 10}),
            else => unreachable,
        };
    const bin: []const u8 = a.written();

    try w.writeAll("\nTest string in binary:\n");
    try w.print("{s}\n", .{bin});

    try w.writeAll("\nUnpacked:\n\n");
    try w.writeAll("Name     Size  Bit pattern\n");
    try w.writeAll("=======  ====  ================\n");
    for (results) |r| {
        try w.print("{s:<7}   {d:2}   {s}\n", .{ r.name, r.size, bin[r.start .. r.end + 1] });
        try w.flush();
    }
}

const testing = std.testing;

test "EmptyDiagram 1" {
    const diagram = "";
    try testing.expectError(ValidationError.EmptyDiagram, validate(std.testing.allocator, diagram));
}

test "EmptyDiagram 2" {
    const diagram =
        \\
        \\
    ;
    try testing.expectError(ValidationError.EmptyDiagram, validate(std.testing.allocator, diagram));
}

test "1 Line" {
    const diagram = "+--+--+--+--+--+--+--+--+";
    try testing.expectError(ValidationError.ExpectedMultipleLines, validate(std.testing.allocator, diagram));
}

test "2 Lines" {
    const diagram =
        \\ +--+--+--+--+--+--+--+--+
        \\ |                       |
    ;
    try testing.expectError(ValidationError.ExpectedOddLineCount, validate(std.testing.allocator, diagram));
}

test "Invalid Column Count" {
    const diagram =
        \\ +--+
        \\ |  |
        \\ +--+
    ;
    try testing.expectError(ValidationError.InvalidColumnCount, validate(std.testing.allocator, diagram));
}

test "Inconsistent Column Count" {
    const diagram =
        \\ +--+--+--+--+--+--+--+--+
        \\ |                    |
        \\ +--+--+--+--+--+--+--+--+
    ;
    try testing.expectError(ValidationError.InconsistentLineWidths, validate(std.testing.allocator, diagram));
}

test "Invalid Header Line" {
    const diagram =
        \\ +-----------------------+
        \\ +                       +
        \\ +--+--+--+--+--+--+--+--+
    ;
    try testing.expectError(ValidationError.InvalidHeaderLine, validate(std.testing.allocator, diagram));
}

test "Invalid Line Start Char" {
    const diagram =
        \\ +--+--+--+--+--+--+--+--+
        \\ +                       |
        \\ +--+--+--+--+--+--+--+--+
    ;
    try testing.expectError(ValidationError.InvalidLineStartChar, validate(std.testing.allocator, diagram));
}

test "Invalid Line End Char" {
    const diagram =
        \\ +--+--+--+--+--+--+--+--+
        \\ |                       +
        \\ +--+--+--+--+--+--+--+--+
    ;
    try testing.expectError(ValidationError.InvalidLineEndChar, validate(std.testing.allocator, diagram));
}

test "Invalid Separator Line 1" {
    const diagram =
        \\ +--+--+--+--+--+--+--+--+
        \\ |                       |
        \\ +--+--+--+-----+--+--+--+
        \\ |                       |
        \\ +--+--+--+--+--+--+--+--+
    ;
    try testing.expectError(ValidationError.InvalidSeparatorLine, validate(std.testing.allocator, diagram));
}

test "Invalid Separator Line 2" {
    const diagram =
        \\ +--+--+--+--+--+--+--+--+
        \\ |                       |
        \\ +--+--+--+--+--+--+--+--+
        \\ |                       |
        \\ +--+--+--+-----+--+--+--+
    ;
    try testing.expectError(ValidationError.InvalidSeparatorLine, validate(std.testing.allocator, diagram));
}

test "Blank Line Removal" {
    const diagram1 =
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                      ID                       |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    QDCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    ANCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    NSCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    ARCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ;
    const diagram2 =
        \\
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                      ID                       |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    QDCOUNT                    |
        \\
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    ANCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    NSCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\ |                    ARCOUNT                    |
        \\ +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
        \\
    ;
    const lines1 = try validate(testing.allocator, diagram1);
    const lines2 = try validate(testing.allocator, diagram2);
    try testing.expectEqual(lines1.len, lines2.len);
    for (lines1, lines2) |line1, line2|
        try testing.expectEqualSlices(u8, line1, line2);
    testing.allocator.free(lines1);
    testing.allocator.free(lines2);
}
