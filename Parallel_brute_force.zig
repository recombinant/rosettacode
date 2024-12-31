// https://rosettacode.org/wiki/Parallel_brute_force
const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const alphabet: []const u8 = "abcdefghijklmnopqrstuvwxyz";
    const hashes = [_]*Hash{
        try createHash(allocator, "1115dd800feaacefdf481f1f9070374a2a81e27880f187396db67958b207cbad"),
        try createHash(allocator, "3a7bd3e2360a3d29eea436fcfb7e44c735d117c42d1c1835420b6b9942dd4f1b"),
        try createHash(allocator, "74e1bb62f8dabb8125a58852b63bdf6eaef667cb56ac7f7cdba6d7305c50a22f"),
        // try createHash(allocator, "ed968e840d10d2d313a870bc131a4e2c311d7ad09bdf32b3418147221f51a6e2"), // aaaaa
        // try createHash(allocator, "68a55e5b1e43c67f4ef34065a86c4c583f532ae8e3cda7e36cc79b611802ac07"), // zzzzz
        // try createHash(allocator, "ed968e840d10d2d313a870bc131a4e2c311d7ad09bdf32b3418147221f51a6e2"), // aaaaa
    };
    defer for (hashes) |hash| allocator.destroy(hash);

    var n_jobs = std.Thread.getCpuCount() catch 1;
    // std.log.debug("cpu count = {}", .{n_jobs});

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator, .n_jobs = n_jobs });
    defer pool.deinit();

    var start: usize = 0;
    while (n_jobs != 0) : (n_jobs -= 1) {
        const n_letters = (alphabet.len - start) / n_jobs;
        if (n_letters == 0)
            continue;
        const end = start + n_letters;
        // std.log.debug("{} {} {} {} {}", .{ n_jobs, alphabet.len, start, end, n_letters });
        try pool.spawn(bruteForce, .{ alphabet, &hashes, start, end });
        start = end;
    }
}

const Hash = struct {
    hex: [Sha256.digest_length * 2:0]u8,
    digest: [Sha256.digest_length]u8,
};

fn createHash(allocator: std.mem.Allocator, hex: *const [Sha256.digest_length * 2:0]u8) !*Hash {
    const hash = try allocator.create(Hash);
    hash.* = Hash{
        .hex = hex.*,
        .digest = undefined,
    };
    const output = std.fmt.hexToBytes(&hash.digest, &hash.hex) catch unreachable;
    std.debug.assert(output.len == hash.digest.len);
    return hash;
}

fn bruteForce(alphabet: []const u8, hashes: []const *const Hash, start: usize, end: usize) void {
    var digest: [Sha256.digest_length]u8 = undefined;

    for (alphabet[start..end]) |a|
        for (alphabet) |b|
            for (alphabet) |c|
                for (alphabet) |d|
                    for (alphabet) |e| {
                        const password: []const u8 = &[_]u8{ a, b, c, d, e };
                        Sha256.hash(password, &digest, .{});
                        for (hashes) |hash|
                            if (std.mem.eql(u8, &digest, &hash.digest))
                                std.debug.print("{s} {s}\n", .{ password, hash.hex });
                        // if the same hash digest occurs in multiple hashes
                        // then its password will re-occur
                    };
}
