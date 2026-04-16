// https://rosettacode.org/wiki/Substitution_cipher
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const gpa: Allocator = init.gpa;
    const io: Io = init.io;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    //
    var key: [127 - 32]u8 = undefined; // All printable characters.
    for (&key, 32..) |*ptr, ch|
        ptr.* = @truncate(ch);
    rand.shuffle(u8, &key);
    //
    var cypher: SubstitutionCypher = try .init(gpa, &key);
    defer cypher.deinit();
    //
    const message = "The quick brown fox jumps over the lazy dog, who barks VERY loudly!";
    const encrypted = try cypher.encrypt(message);
    const decrypted = try cypher.decrypt(encrypted);
    defer gpa.free(encrypted);
    defer gpa.free(decrypted);
    //
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Key       = “{s}”\n", .{cypher.key});
    try stdout.print("Message   = “{s}”\n", .{message});
    try stdout.print("Encrypted = “{s}”\n", .{encrypted});
    try stdout.print("Decrypted = “{s}”\n", .{decrypted});

    try stdout.flush();
}

const SubstitutionCypher = struct {
    key: []const u8,
    allocator: Allocator,

    fn init(allocator: Allocator, key: []const u8) !SubstitutionCypher {
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
            out.* = @as(u8, @truncate(std.mem.indexOfScalar(u8, self.key, in).?)) + 32;
        return result;
    }
};
