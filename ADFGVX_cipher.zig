// https://rosettacode.org/wiki/ADFGVX_cipher
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
// Note: The C++ is/was missing the columnar transposition
const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    // -------------------------------------------- random number
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();
    // ------------------------------------------------ allocator
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // ----------------------------------------------------------
    const polybius = initialisePolybiusSquare(random);
    printPolybius(polybius);

    const key = try createKey(allocator, random, 9);
    defer allocator.free(key);
    print("The key is {s}\n\n", .{key});

    const plain_text = "ATTACKAT1200AM";
    print("Plain text: {s}\n\n", .{plain_text});

    const encrypted_text = try encrypt(allocator, plain_text, polybius, key);
    defer allocator.free(encrypted_text);
    print("Encrypted: {s}\n\n", .{encrypted_text});

    const decrypted_text = try decrypt(allocator, encrypted_text, polybius, key);
    defer allocator.free(decrypted_text);
    print("Decrypted: {s}\n", .{decrypted_text});
}

const PolybiusSquare = [6][6]u8;

const ADFGVX = "ADFGVX";
const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

fn initialisePolybiusSquare(random: std.Random) PolybiusSquare {
    var alphabet: [ALPHABET.len]u8 = undefined;
    @memcpy(&alphabet, ALPHABET);
    random.shuffle(u8, &alphabet);

    var result: PolybiusSquare = undefined;

    var n: usize = 0;
    for (&result) |*row|
        for (row) |*c| {
            c.* = alphabet[n];
            n += 1;
        };
    assert(result.len == ADFGVX.len);
    return result;
}

fn printPolybius(polybius: PolybiusSquare) void {
    print("The {d} x {d} Polybius square:\n |", .{ polybius.len, polybius[0].len });
    for (ADFGVX) |ch|
        print(" {c}", .{ch});
    print("\n--------------\n", .{});
    for (polybius, 0..) |row, j| {
        print("{c}|", .{ADFGVX[j]});
        for (row) |ch|
            print(" {c}", .{ch});
        print("\n", .{});
    }
    print("\n", .{});
}

/// Create a key using a word from the dictionary 'unixdict.txt'
fn createKey(allocator: std.mem.Allocator, random: std.Random, size: usize) ![]const u8 {
    if (size < 7 or size > 12)
        return error.INVALID_KEY_SIZE;

    const data = @embedFile("data/unixdict.txt");

    var candidates: std.ArrayList([]const u8) = .empty;
    defer {
        for (candidates.items) |word|
            allocator.free(word);
        candidates.deinit(allocator);
    }

    var buffer: [12]u8 = undefined;
    assert(size <= buffer.len);

    var it = std.mem.tokenizeScalar(u8, data, '\n');
    outer: while (it.next()) |word|
        if (word.len == size) {
            @memcpy(buffer[0..size], word);
            var uppercased = std.ascii.upperString(&buffer, word);
            std.mem.sortUnstable(u8, uppercased, {}, std.sort.asc(u8));
            for (uppercased[0 .. uppercased.len - 1], uppercased[1..]) |ch1, ch2|
                if (ch1 == ch2)
                    continue :outer;
            if (std.mem.indexOfNone(u8, uppercased, ALPHABET) != null)
                continue :outer;

            try candidates.append(allocator, try std.ascii.allocUpperString(allocator, word));
        };
    const idx = random.uintLessThan(usize, candidates.items.len);
    return candidates.swapRemove(idx);
}

fn encrypt(allocator: std.mem.Allocator, plain_text: []const u8, polybius: PolybiusSquare, key: []const u8) ![]const u8 {
    // Create the fractionated text.
    var code_array: std.ArrayList(u8) = .empty;
    for (plain_text) |letter|
        for (polybius, 0..) |row, i|
            for (row, 0..) |ch, j|
                if (ch == letter) {
                    try code_array.append(allocator, ADFGVX[i]);
                    try code_array.append(allocator, ADFGVX[j]);
                };
    const code = try code_array.toOwnedSlice(allocator);
    defer allocator.free(code);
    // Sort the key letters to get the column transposition order.
    const order = blk: {
        const sorted_key = try allocator.dupe(u8, key);
        defer allocator.free(sorted_key);
        std.mem.sortUnstable(u8, sorted_key, {}, std.sort.asc(u8));
        const order = try allocator.alloc(usize, sorted_key.len);
        for (sorted_key, order) |ch, *i|
            i.* = std.mem.indexOfScalar(u8, key, ch).?;
        break :blk order;
    };
    defer allocator.free(order);
    // This effectively transposes and concatenates columns to create the encrypted text.
    var encrypted: std.ArrayList(u8) = .empty;
    for (order) |i_| {
        if (encrypted.items.len != 0)
            try encrypted.append(allocator, ' ');
        var i = i_;
        while (i < code.len) : (i += key.len)
            try encrypted.append(allocator, code[i]);
    }
    return encrypted.toOwnedSlice(allocator);
}

fn decrypt(
    allocator: std.mem.Allocator,
    encrypted_text: []const u8,
    polybius: PolybiusSquare,
    key: []const u8,
) ![]const u8 {
    // Retrieve the transposed columns from the encryped text.
    const transposed_columns = blk: {
        var it = std.mem.tokenizeScalar(u8, encrypted_text, ' ');
        var columns_array: std.ArrayList([]const u8) = .empty;
        while (it.next()) |word|
            try columns_array.append(allocator, word);
        break :blk try columns_array.toOwnedSlice(allocator);
    };
    defer allocator.free(transposed_columns);
    // Sort the key letters to get the column transposition reversal order.
    const order = blk: {
        const sorted_key = try allocator.dupe(u8, key);
        defer allocator.free(sorted_key);
        std.mem.sortUnstable(u8, sorted_key, {}, std.sort.asc(u8));
        const order = try allocator.alloc(usize, sorted_key.len);
        for (key, order) |ch, *i|
            i.* = std.mem.indexOfScalar(u8, sorted_key, ch).?;
        break :blk order;
    };
    defer allocator.free(order);
    // Knowing the order now un-transpose to get the columns.
    const columns = try allocator.alloc([]const u8, transposed_columns.len);
    defer allocator.free(columns);
    for (columns, order) |*column, i|
        column.* = transposed_columns[i];
    //
    const space_count = std.mem.count(u8, encrypted_text, " ");
    const code_size = encrypted_text.len - space_count;
    // Recreate the fractionated text from the columns.
    const code = blk: {
        var code_array: std.ArrayList(u8) = try .initCapacity(allocator, code_size);
        var i: usize = 0;
        while (code_array.items.len < code_size) : (i += 1)
            for (columns) |column|
                if (code_array.items.len < code_size)
                    try code_array.append(allocator, column[i]);
        break :blk try code_array.toOwnedSlice(allocator);
    };
    defer allocator.free(code);
    // Extract the plain text from the fractionated text using the Polybius square.
    var plain_text: std.ArrayList(u8) = try .initCapacity(allocator, code.len / 2);
    var i: usize = 0;
    while (i < code_size - 1) : (i += 2) {
        const row = std.mem.indexOfScalar(u8, ADFGVX, code[i]).?;
        const col = std.mem.indexOfScalar(u8, ADFGVX, code[i + 1]).?;
        try plain_text.append(allocator, polybius[row][col]);
    }
    return plain_text.toOwnedSlice(allocator);
}
