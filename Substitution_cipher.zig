// https://rosettacode.org/wiki/Substitution_cipher
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const rand = prng.random();
    //
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    //
    var key: [127 - 32]u8 = undefined; // All printable characters.
    for (&key, 32..) |*ptr, ch|
        ptr.* = @truncate(ch);
    rand.shuffle(u8, &key);
    //
    var cypher = try SubstitutionCypher.init(allocator, &key);
    defer cypher.deinit();
    //
    const message = "The quick brown fox jumps over the lazy dog, who barks VERY loudly!";
    const encrypted = try cypher.encrypt(message);
    const decrypted = try cypher.decrypt(encrypted);
    defer allocator.free(encrypted);
    defer allocator.free(decrypted);
    //
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Key       = “{s}”\n", .{cypher.key});
    try stdout.print("Message   = “{s}”\n", .{message});
    try stdout.print("Encrypted = “{s}”\n", .{encrypted});
    try stdout.print("Decrypted = “{s}”\n", .{decrypted});
}

const SubstitutionCypher = struct {
    key: []const u8,
    allocator: mem.Allocator,

    fn init(allocator: mem.Allocator, key: []const u8) !SubstitutionCypher {
        return .{
            .key = try allocator.dupe(u8, key),
            .allocator = allocator,
        };
    }

    fn deinit(self: *SubstitutionCypher) void {
        self.allocator.free(self.key);
    }

    fn encrypt(self: *const SubstitutionCypher, message: []const u8) ![]const u8 {
        const result = try self.allocator.alloc(u8, message.len);
        for (message, result) |in, *out|
            out.* = self.key[in - 32];
        return result;
    }

    fn decrypt(self: *const SubstitutionCypher, message: []const u8) ![]const u8 {
        const result = try self.allocator.alloc(u8, message.len);
        for (message, result) |in, *out|
            out.* = @as(u8, @truncate(mem.indexOfScalar(u8, self.key, in).?)) + 32;
        return result;
    }
};
