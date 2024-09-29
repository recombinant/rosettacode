// https://rosettacode.org/wiki/Addition_chains
// Translation of Go
// The slower version.
const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const mem = std.mem;
const time = std.time;
const print = std.debug.print;

const max_len = 13;
const max_non_brauer = 382;

var brauer_count: usize = 0;
var non_brauer_count: usize = 0;
var brauer_example: []const u64 = undefined;
var non_brauer_example: []const u64 = undefined;

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    var t0 = try time.Timer.start();

    const nums = [_]u64{ 7, 14, 21, 29, 32, 42, 64, 47, 79, 191, 382, 379 };
    // const nums = [_]u64{ 47, 79, 191, 382, 379, 12509 };

    print("Searching for Brauer chains up to a minimum length of {d}\n", .{max_len - 1});
    for (nums) |num| {
        _ = arena.reset(.retain_capacity);

        var t1 = try time.Timer.start();

        brauer_count = 0;
        non_brauer_count = 0;
        brauer_example = try allocator.alloc(u64, 0);
        non_brauer_example = try allocator.alloc(u64, 0);
        defer allocator.free(brauer_example);
        defer allocator.free(non_brauer_example);

        const chosen = try allocator.dupe(u64, &[1]u64{1});
        defer allocator.free(chosen);

        const le = try additionChains(allocator, num, max_len, chosen);
        print("\nN = {}\n", .{num});
        print("Minimum length of chains : L({}) = {}\n", .{ num, le - 1 });
        print("Number of minimum length Brauer chains: {}\n", .{brauer_count});
        if (brauer_count > 0)
            print("Brauer example: {any}\n", .{brauer_example});
        print("Number of minimum length non-Brauer chains: {}\n", .{non_brauer_count});
        if (non_brauer_count > 0)
            print("Non-Brauer example: {any}\n", .{non_brauer_example});

        print("processed in {}\n", .{fmt.fmtDuration(t1.read())});
    }

    print("\nprocessed in {}\n", .{fmt.fmtDuration(t0.read())});
}

fn isBrauer(a: []const u64) bool {
    loop: for (2..a.len) |i| {
        var j = i;
        while (j != 0) {
            j -= 1;
            if (a[i - 1] + a[j] == a[i])
                continue :loop;
        }
        return false;
    }
    return true;
}

fn additionChains(allocator: mem.Allocator, target: u64, length_: usize, chosen_: []const u64) !usize {
    var le = chosen_.len;
    var last = chosen_[le - 1];
    if (last == target) {
        if (le < length_) {
            brauer_count = 0;
            non_brauer_count = 0;
        }
        if (isBrauer(chosen_)) {
            brauer_count += 1;
            allocator.free(brauer_example);
            brauer_example = try allocator.dupe(u64, chosen_);
        } else {
            non_brauer_count += 1;
            allocator.free(non_brauer_example);
            non_brauer_example = try allocator.dupe(u64, chosen_);
        }
        return le;
    }
    if (le == length_)
        return length_;

    var length = length_;
    if (target > max_non_brauer) {
        var i = le;
        while (i != 0) {
            i -= 1;
            const next = last + chosen_[i];
            if (next <= target and next > chosen_[chosen_.len - 1] and i < length) {
                var chosen2 = try allocator.alloc(u64, chosen_.len + 1);
                defer allocator.free(chosen2);
                @memcpy(chosen2[0..chosen_.len], chosen_);
                chosen2[chosen_.len] = next;
                length = try additionChains(allocator, target, length, chosen2);
            }
        }
    } else {
        var ndone = std.ArrayList(u64).init(allocator);
        defer ndone.deinit();
        while (true) {
            var i = le;
            while (i != 0) {
                i -= 1;
                const next = last + chosen_[i];
                if (next <= target and next > chosen_[chosen_.len - 1] and i < length and
                    mem.indexOfScalar(u64, ndone.items, next) == null)
                {
                    try ndone.append(next);
                    var chosen2 = try allocator.alloc(u64, chosen_.len + 1);
                    defer allocator.free(chosen2);
                    @memcpy(chosen2[0..chosen_.len], chosen_);
                    chosen2[chosen_.len] = next;

                    length = try additionChains(allocator, target, length, chosen2);
                }
            }
            le -= 1;
            if (le == 0)
                break;

            last = chosen_[le - 1];
        }
    }
    return length;
}
