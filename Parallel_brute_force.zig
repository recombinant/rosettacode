// https://rosettacode.org/wiki/Parallel_brute_force
// {{works with|Zig|0.16.0}}
const std = @import("std");
const Io = std.Io;
const Sha256 = std.crypto.hash.sha2.Sha256;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const alphabet: []const u8 = "abcdefghijklmnopqrstuvwxyz";

    const hashes = [_]Hash{
        try .init("1115dd800feaacefdf481f1f9070374a2a81e27880f187396db67958b207cbad"),
        try .init("3a7bd3e2360a3d29eea436fcfb7e44c735d117c42d1c1835420b6b9942dd4f1b"),
        try .init("74e1bb62f8dabb8125a58852b63bdf6eaef667cb56ac7f7cdba6d7305c50a22f"),
        // try createHash(allocator, "ed968e840d10d2d313a870bc131a4e2c311d7ad09bdf32b3418147221f51a6e2"), // aaaaa
        // try createHash(allocator, "68a55e5b1e43c67f4ef34065a86c4c583f532ae8e3cda7e36cc79b611802ac07"), // zzzzz
        // try createHash(allocator, "ed968e840d10d2d313a870bc131a4e2c311d7ad09bdf32b3418147221f51a6e2"), // aaaaa
    };

    var t0: Io.Timestamp = .now(io, .real);

    // Split into 26 async tasks, each task will brute-force all passwords
    // starting with a different letter of the alphabet.
    var g: Io.Group = .init;
    for (alphabet) |letter| {
        const work: Work = .{
            .alphabet = alphabet,
            .hashes = &hashes,
            .letter = letter,
        };
        g.async(io, bruteForce, .{ io, &g, work });
    }
    try g.await(io);

    std.log.info("processed in {f}", .{t0.untilNow(io, .real)});
}

const Work = struct {
    alphabet: []const u8,
    hashes: []const Hash,
    letter: u8,
};

/// Brute-force all 5-letter passwords starting with `work.letter` and
/// check if their hash matches any of the target hashes.
fn bruteForce(_: Io, _: *Io.Group, work: Work) void {
    var digest: [Sha256.digest_length]u8 = undefined;
    const alphabet = work.alphabet;

    for (alphabet) |b|
        for (alphabet) |c|
            for (alphabet) |d|
                for (alphabet) |e| {
                    const password: []const u8 = &[_]u8{ work.letter, b, c, d, e };
                    Sha256.hash(password, &digest, .{});
                    for (work.hashes) |hash|
                        if (std.mem.eql(u8, &digest, &hash.digest))
                            std.debug.print("{s} {s}\n", .{ password, hash.hex });
                    // if the same hash digest occurs in multiple hashes
                    // then its password will re-occur
                };
    // std.debug.print("done {c}\n", .{work.letter});
}

const Hash = struct {
    hex: [Sha256.digest_length * 2:0]u8,
    digest: [Sha256.digest_length]u8,

    fn init(hex: *const [Sha256.digest_length * 2:0]u8) !Hash {
        var hash: Hash = .{
            .hex = hex.*,
            .digest = undefined,
        };
        const output = try std.fmt.hexToBytes(&hash.digest, &hash.hex);
        std.debug.assert(output.len == hash.digest.len);
        return hash;
    }
};
