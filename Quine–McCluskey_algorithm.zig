// https://rosettacode.org/wiki/Quine–McCluskey_algorithm
// {{works with|Zig|0.17.1}}
// {{trans|C++}}
// copied from rosettacode and tweaked
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    const ones: []const u32 = &.{ 1, 2, 5 };
    const zeros: []const u32 = &.{};
    const dc: []const u32 = &.{ 0, 7 };

    var result: SetType = .empty;
    try qm(allocator, ones, zeros, dc, &result);

    for (result.items) |item|
        std.debug.print("{s} ", .{item});

    std.debug.print("\n", .{});
}

const SetType = std.ArrayList([]const u8);

fn b2s(allocator: Allocator, i: u32, vars: u32) ![]const u8 {
    var s = try allocator.alloc(u8, vars);
    var idx: u32 = vars;
    var num = i;
    while (idx > 0) {
        idx -= 1;
        s[idx] = if (num & 1 == 1) '1' else '0';
        num >>= 1;
    }
    return s;
}

fn bitCount(s: []const u8) u32 {
    var count: u32 = 0;
    for (s) |c| {
        if (c == '1')
            count += 1;
    }
    return count;
}

fn merge(allocator: Allocator, i: []const u8, j: []const u8) !?[]const u8 {
    const len = @min(i.len, j.len);
    var difCnt: u32 = 0;
    var s = try allocator.alloc(u8, len);
    for (0..len) |k| {
        const a = i[k];
        const b = j[k];
        if (a == 'X' or b == 'X') {
            if (a != b) {
                allocator.free(s);
                return null;
            }
            s[k] = a;
        } else if (a != b) {
            difCnt += 1;
            if (difCnt > 1) {
                allocator.free(s);
                return null;
            }
            s[k] = 'X';
        } else {
            s[k] = a;
        }
    }
    return s;
}

fn addToSet(set: *SetType, allocator: Allocator, item: []const u8) !void {
    for (set.items) |s|
        if (std.mem.eql(u8, s, item))
            return;

    const dup = try allocator.dupe(u8, item);
    try set.append(allocator, dup);
}

fn inSet(set: *const SetType, item: []const u8) bool {
    for (set.items) |s|
        if (std.mem.eql(u8, s, item))
            return true;
    return false;
}

fn unionSets(dest: *SetType, src: *const SetType, allocator: Allocator) !void {
    for (src.items) |item|
        try addToSet(dest, allocator, item);
}

fn computePrimes(allocator: Allocator, cubes: *const SetType, vars: u32, primes: *SetType) !void {
    // Allocate sigma for counts 0..vars
    var sigma = try allocator.alloc(SetType, vars + 1);
    @memset(sigma, .empty);

    var sigmaCount: usize = 0;

    for (0..(vars + 1)) |j| {
        for (cubes.items) |cube|
            if (bitCount(cube) == j)
                try addToSet(&sigma[j], allocator, cube);

        if (sigma[j].items.len > 0)
            sigmaCount = j + 1;
    }

    primes.clearRetainingCapacity();

    while (sigmaCount > 0) {
        const nsigma_len = if (sigmaCount > 1) sigmaCount - 1 else 0;
        var nsigma = try allocator.alloc(SetType, nsigma_len);

        var redundant: SetType = .empty;
        defer redundant.deinit(allocator);

        for (0..(sigmaCount - 1)) |i| {
            nsigma[i] = .empty;
            const c1 = &sigma[i];
            const c2 = &sigma[i + 1];
            for (c1.items) |a|
                for (c2.items) |b| {
                    if (try merge(allocator, a, b)) |m| {
                        try addToSet(&nsigma[i], allocator, m);
                        try addToSet(&redundant, allocator, a);
                        try addToSet(&redundant, allocator, b);
                    }
                };
        }

        for (0..sigmaCount) |i|
            for (sigma[i].items) |cube| {
                if (!inSet(&redundant, cube))
                    try addToSet(primes, allocator, cube);
            };

        // Free the current sigma
        for (sigma) |*set|
            set.deinit(allocator);
        allocator.free(sigma);

        sigma = nsigma;
        sigmaCount = nsigma_len;
    }

    // Free the last sigma (which might be of length 0)
    for (sigma) |*set|
        set.deinit(allocator);
    allocator.free(sigma);
}

fn activePrimes(allocator: Allocator, cubesel: u32, primes: *const SetType, result: *SetType) !void {
    std.debug.assert(result.items.len == 0); // should have been cleared
    const s = try b2s(allocator, cubesel, @intCast(primes.items.len));
    defer allocator.free(s);
    for (primes.items, 0..) |prime, i|
        if (s[i] == '1')
            try addToSet(result, allocator, prime);
}

fn isCover(prime: []const u8, one: []const u8) bool {
    const len = @min(prime.len, one.len);
    for (0..len) |i| {
        const p = prime[i];
        const o = one[i];
        if (p != 'X' and p != o)
            return false;
    }
    return true;
}

fn isFullCover(allPrimes: *const SetType, ones: *const SetType) !bool {
    for (ones.items) |one| {
        var covered = false;
        for (allPrimes.items) |prime|
            if (isCover(prime, one)) {
                covered = true;
                break;
            };

        if (!covered)
            return false;
    }
    return true;
}

fn unateCover(allocator: Allocator, primes: *const SetType, ones: *const SetType, result: *SetType) !void {
    var minCount: u32 = 1000;
    var minSel: u32 = 0;
    var found = false;
    var active: SetType = .empty;
    defer active.deinit(allocator);

    const total = @as(u32, 1) << @intCast(primes.items.len);
    for (0..total) |cubesel| {
        active.clearRetainingCapacity();
        try activePrimes(allocator, @intCast(cubesel), primes, &active);
        if (try isFullCover(&active, ones)) {
            var cnt: u32 = 0;
            const binRep = try b2s(allocator, @intCast(cubesel), @intCast(primes.items.len));
            defer allocator.free(binRep);
            for (binRep) |c| {
                if (c == '1')
                    cnt += 1;
            }
            if (cnt < minCount) {
                minCount = cnt;
                minSel = @intCast(cubesel);
                found = true;
            }
        }
    }

    result.clearRetainingCapacity();
    if (found)
        try activePrimes(allocator, minSel, primes, result);
}

fn qm(allocator: Allocator, ones: []const u32, zeros: []const u32, dc: []const u32, result: *SetType) !void {
    if (ones.len == 0 and zeros.len == 0 and dc.len == 0)
        return;

    var maxVal: u32 = 0;
    for (ones) |val| {
        if (val > maxVal)
            maxVal = val;
    }
    for (zeros) |val| {
        if (val > maxVal)
            maxVal = val;
    }
    for (dc) |val| {
        if (val > maxVal)
            maxVal = val;
    }

    var numvars: u32 = 0;
    if (maxVal == 0)
        numvars = 1
    else {
        var tmp = maxVal;
        while (tmp != 0) {
            numvars += 1;
            tmp >>= 1;
        }
    }

    var onesSet: SetType = .empty;
    defer onesSet.deinit(allocator);
    var zerosSet: SetType = .empty;
    defer zerosSet.deinit(allocator);
    var dcSet: SetType = .empty;
    defer dcSet.deinit(allocator);

    for (ones) |val| {
        const s = try b2s(allocator, val, numvars);
        defer allocator.free(s);
        try addToSet(&onesSet, allocator, s);
    }
    for (zeros) |val| {
        const s = try b2s(allocator, val, numvars);
        defer allocator.free(s);
        try addToSet(&zerosSet, allocator, s);
    }
    for (dc) |val| {
        const s = try b2s(allocator, val, numvars);
        defer allocator.free(s);
        try addToSet(&dcSet, allocator, s);
    }

    var cubes: SetType = .empty;
    defer cubes.deinit(allocator);
    try unionSets(&cubes, &onesSet, allocator);
    try unionSets(&cubes, &dcSet, allocator);

    var primes: SetType = .empty;
    defer primes.deinit(allocator);
    try computePrimes(allocator, &cubes, numvars, &primes);

    try unateCover(allocator, &primes, &onesSet, result);
}
