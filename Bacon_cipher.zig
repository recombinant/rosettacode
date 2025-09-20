// https://rosettacode.org/wiki/Bacon_cipher
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

// maps successively from 'a' to 'z' plus ' ' to denote any non-letter
const codes = [27][]const u8{
    "AAAAA", "AAAAB", "AAABA", "AAABB", "AABAA",
    "AABAB", "AABBA", "AABBB", "ABAAA", "ABAAB",
    "ABABA", "ABABB", "ABBAA", "ABBAB", "ABBBA",
    "ABBBB", "BAAAA", "BAAAB", "BAABA", "BAABB",
    "BABAA", "BABAB", "BABBA", "BABBB", "BBAAA",
    "BBAAB", "BBBAA",
};

fn getCode(c: u8) []const u8 {
    return switch (c) {
        'a'...'z' => codes[c - 'a'],
        else => codes[codes.len - 1],
    };
}

fn getChar(code: []const u8) !u8 {
    if (std.mem.eql(u8, code, codes[codes.len - 1]))
        return ' ';
    for (codes[0 .. codes.len - 1], 'a'..) |candidate, c|
        if (std.mem.eql(u8, code, candidate))
            return @truncate(c);
    std.log.err("Code \"{s}\" is invalid", .{code});
    return error.InvalidCode;
}

/// Allocates memory for the result, which must be freed by the caller.
fn baconEncode(allocator: std.mem.Allocator, plain_text: []const u8, message: []const u8) ![]u8 {
    const et: []const u8 = blk: {
        var et_list: std.ArrayList(u8) = try .initCapacity(allocator, plain_text.len * 5);
        for (plain_text) |c|
            try et_list.appendSlice(allocator, getCode(std.ascii.toLower(c)));
        break :blk try et_list.toOwnedSlice(allocator);
    };
    defer allocator.free(et);

    // 'A's to be in lower case, 'B's in upper case
    var mt: std.ArrayList(u8) = .empty;
    var count: usize = 0;
    for (message) |c_| {
        const c = std.ascii.toLower(c_);
        switch (c) {
            'a'...'z' => {
                if (et[count] == 'A')
                    try mt.append(allocator, c)
                else
                    try mt.append(allocator, c ^ 0x20); // to uppercase
                count += 1;
                if (count == et.len)
                    break;
            },
            else => try mt.append(allocator, c),
        }
    }
    return mt.toOwnedSlice(allocator);
}

/// Allocates memory for the result, which must be freed by the caller.
fn baconDecode(allocator: std.mem.Allocator, cipher_text: []const u8) ![]u8 {
    const ct = blk: {
        var ct_list: std.ArrayList(u8) = .empty;

        var count: usize = 0;
        for (cipher_text) |c| {
            const font: u8 = switch (c) {
                'a'...'z' => 'A',
                'A'...'Z' => 'B',
                else => continue,
            };
            try ct_list.append(allocator, font);
            count += 1;
        }
        break :blk try ct_list.toOwnedSlice(allocator);
    };
    defer allocator.free(ct);

    var pt_list: std.ArrayList(u8) = try .initCapacity(allocator, ct.len / 5);
    defer pt_list.deinit(allocator);

    var it = std.mem.window(u8, ct, 5, 5);
    while (it.next()) |quintet|
        try pt_list.append(allocator, try getChar(quintet));

    return pt_list.toOwnedSlice(allocator);
}

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const plain_text: []const u8 = "the quick brown fox jumps over the lazy dog";
    const message: []const u8 = "bacon's cipher is a method of steganography created by francis bacon." ++
        "this task is to implement a program for encryption and decryption of " ++
        "plaintext using the simple alphabet of the baconian cipher or some " ++
        "other kind of representation of this alphabet (make anything signify anything). " ++
        "the baconian alphabet may optionally be extended to encode all lower " ++
        "case characters individually and/or adding a few punctuation characters " ++
        "such as the space.";

    const cipher_text = try baconEncode(allocator, plain_text, message);
    defer allocator.free(cipher_text);
    try stdout.print("Cipher text ->\n\n{s}\n", .{cipher_text});

    const hidden_text = try baconDecode(allocator, cipher_text);
    defer allocator.free(hidden_text);
    try stdout.print("\nHidden text ->\n\n{s}\n", .{hidden_text});

    try stdout.flush();
}
